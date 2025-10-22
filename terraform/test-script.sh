#!/usr/bin/env bash
# CloudShelf / Bookstore smoke test (Bash)
# Uses: IP=$(terraform output -raw public_ip)
# FRONTEND=http://$IP:3000  (React) | BASE=http://$IP:8080 (Gateway via routes)
set -u -o pipefail

sleep 20  # wait a bit for services to be ready

# --- Terraform output (run from your TF dir) ---
IP=$(terraform output -raw public_ip 2>/dev/null || true)
if [[ -z "${IP}" ]]; then
  echo "ERROR: 'terraform output -raw public_ip' returned empty. Run this script from your TF dir." >&2
  exit 2
fi

# Build targets (allow manual override)
: "${FRONTEND:=http://${IP}:3000}"
: "${BASE:=http://${IP}:8080}"
: "${TIMEOUT:=8}"

# --- helpers ---
have_jq=0; command -v jq >/dev/null 2>&1 && have_jq=1
http_status(){ local m="$1" u="$2" b="${3:-}"; 
  if [[ "$m" == GET || "$m" == DELETE ]]; then
    curl -sS -m "$TIMEOUT" -o /dev/null -w "%{http_code}" -X "$m" "$u" || echo "000"
  else
    curl -sS -m "$TIMEOUT" -o /dev/null -w "%{http_code}" -H "Content-Type: application/json" -X "$m" -d "$b" "$u" || echo "000"
  fi
}
http_body(){ local m="$1" u="$2" b="${3:-}";
  if [[ "$m" == GET || "$m" == DELETE ]]; then
    curl -sS -m "$TIMEOUT" -X "$m" "$u" || true
  else
    curl -sS -m "$TIMEOUT" -H "Content-Type: application/json" -X "$m" -d "$b" "$u" || true
  fi
}
in_2xx(){ [[ "$1" =~ ^2[0-9][0-9]$ ]]; }
extract_id(){
  local json="$1"
  if [[ $have_jq -eq 1 ]]; then
    echo "$json" | jq -r '.. | .id? // .authorId? // .uuid? | select(.!=null) | tostring' 2>/dev/null
  else
    echo "$json" | sed -n 's/.*"id"[[:space:]]*:[[:space:]]*"\{0,1\}\([^",}]*\)".*/\1/p' | head -n1
  fi
}

# --- results collector ---
N=0; declare -a NAMES STATUSES RESULTS DETAILS
record(){ NAMES[$N]="$1"; STATUSES[$N]="$2"; RESULTS[$N]="$3"; DETAILS[$N]="$4"; ((N++)); }

# 1) Frontend must be 200
s=$(http_status GET "$FRONTEND/")
if [[ "$s" == "200" ]]; then
  record "Frontend (React): GET /" "$s" "PASS" "OK"
else
  record "Frontend (React): GET /" "$s" "FAIL" "Expected 200"
fi

# 2) GET /api/authors
s=$(http_status GET "$BASE/api/authors")
if in_2xx "$s"; then
  body=$(http_body GET "$BASE/api/authors")
  count="n/a"; [[ $have_jq -eq 1 ]] && count=$(echo "$body" | jq 'if type=="array" then length else 0 end' 2>/dev/null)
  record "GET /api/authors" "$s" "PASS" "count=${count}"
else
  record "GET /api/authors" "$s" "FAIL" "Non-2xx"
fi

# 3) Author create + delete
create_payload='{"name":"Smoke Author","birthDate":"1974-02-19"}'
s=$(http_status POST "$BASE/api/authors" "$create_payload")
if in_2xx "$s"; then
  body=$(http_body POST "$BASE/api/authors" "$create_payload")
  new_id=$(extract_id "$body")
  if [[ -n "$new_id" ]]; then
    sdel=$(http_status DELETE "$BASE/api/authors/$new_id")
    if [[ "$sdel" == "204" || "$sdel" == "200" ]]; then
      record "POST+DELETE /api/authors" "$s/$sdel" "PASS" "id=$new_id"
    else
      record "POST+DELETE /api/authors" "$s/$sdel" "FAIL" "delete status=$sdel"
    fi
  else
    record "POST+DELETE /api/authors" "$s" "FAIL" "missing id"
  fi
else
  record "POST+DELETE /api/authors" "$s" "FAIL" "create failed"
fi

# 4) GraphQL list books
gql_list='{"query":"{ getAllBooks { id name } }"}'
s=$(http_status POST "$BASE/api/graphql" "$gql_list")
if in_2xx "$s"; then
  body=$(http_body POST "$BASE/api/graphql" "$gql_list")
  if echo "$body" | grep -q '"data"'; then
    count="n/a"; [[ $have_jq -eq 1 ]] && count=$(echo "$body" | jq -r '.data.getAllBooks | length' 2>/dev/null)
    record "POST /api/graphql (list)" "$s" "PASS" "books=${count}"
  else
    record "POST /api/graphql (list)" "$s" "FAIL" "no data field"
  fi
else
  record "POST /api/graphql (list)" "$s" "FAIL" "Non-2xx"
fi

# 5) GraphQL create + delete book (robust delete verify)
gql_create='{"query":"mutation($b: BookRequest!){ createBook(bookRequest:$b){ id name } }","variables":{"b":{"name":"Smoke Test Book","description":"created by smoke test","price":19}}}'
s=$(http_status POST "$BASE/api/graphql" "$gql_create")
if in_2xx "$s"; then
  body=$(http_body POST "$BASE/api/graphql" "$gql_create")
  book_id=""
  if [[ $have_jq -eq 1 ]]; then
    book_id=$(echo "$body" | jq -r '.data.createBook.id // empty' 2>/dev/null)
  else
    book_id=$(echo "$body" | sed -n 's/.*"createBook"[^{]*{[^}]*"id"[[:space:]]*:[[:space:]]*"\{0,1\}\([^",}]*\)".*/\1/p' | head -n1)
  fi
  if [[ -n "$book_id" ]]; then
    gql_delete=$(printf '{"query":"mutation($id: ID!){ deleteBook(id:$id) }","variables":{"id":"%s"}}' "$book_id")
    s2=$(http_status POST "$BASE/api/graphql" "$gql_delete")
    body2=$(http_body POST "$BASE/api/graphql" "$gql_delete")
    del_ok="0"
    if [[ $have_jq -eq 1 ]]; then
      val=$(echo "$body2" | jq -r '.data.deleteBook // empty' 2>/dev/null)
      [[ "$val" == "true" || "$val" == "1" || "$val" == "True" ]] && del_ok="1"
    else
      echo "$body2" | grep -Eq '"deleteBook"[[:space:]]*:[[:space:]]*(true|1|"true"|"True")' && del_ok="1"
    fi
    if [[ "$del_ok" != "1" ]]; then
      gql_get=$(printf '{"query":"query($id:ID!){ getBook(id:$id){ id } }","variables":{"id":"%s"}}' "$book_id")
      s3=$(http_status POST "$BASE/api/graphql" "$gql_get")
      if in_2xx "$s3"; then
        body3=$(http_body POST "$BASE/api/graphql" "$gql_get")
        if [[ $have_jq -eq 1 ]]; then
          exists=$(echo "$body3" | jq -r '.data.getBook // empty')
          [[ "$exists" == "null" || -z "$exists" ]] && del_ok="1"
        else
          echo "$body3" | grep -q '"getBook":null' && del_ok="1"
        fi
      fi
    fi
    if [[ "$del_ok" == "1" ]]; then
      record "GraphQL create+delete book" "$s/$s2" "PASS" "id=$book_id"
    else
      record "GraphQL create+delete book" "$s/$s2" "FAIL" "delete not confirmed"
    fi
  else
    record "GraphQL create+delete book" "$s" "FAIL" "missing id"
  fi
else
  record "GraphQL create+delete book" "$s" "FAIL" "create non-2xx"
fi

# 6) POST /api/order
order_payload='{"orderLineItemsDtoList":[{"skuCode":"design_patterns_gof","price":29,"quantity":1}]}'
s=$(http_status POST "$BASE/api/order" "$order_payload")
if in_2xx "$s"; then
  record "POST /api/order" "$s" "PASS" "OK"
else
  record "POST /api/order" "$s" "FAIL" "Non-2xx"
fi

# 7) /order-service/actuator/health
s=$(http_status GET "$BASE/order-service/actuator/health")
body=$(http_body GET "$BASE/order-service/actuator/health")
if [[ "$s" == "200" ]] && echo "$body" | grep -q '"status"[[:space:]]*:[[:space:]]*"UP"'; then
  record "GET /order-service/actuator/health" "$s" "PASS" "status=UP"
else
  record "GET /order-service/actuator/health" "$s" "FAIL" "body: $(echo "$body" | tr -d '\n' | cut -c1-80)…"
fi

# --- results table ---
echo
echo "Target FRONTEND: $FRONTEND"
echo "Target BASE:     $BASE"
echo "Terraform PUBLIC_IP: $IP"

printf '\n%-44s | %-6s | %-6s | %s\n' "CHECK" "HTTP" "RESULT" "DETAIL"
printf -- '%.0s-' {1..90}; echo



fails=0
for i in $(seq 0 $((N-1))); do
  printf '%-44s | %-6s | %-6s | %s\n' "${NAMES[$i]}" "${STATUSES[$i]}" "${RESULTS[$i]}" "${DETAILS[$i]}"
  [[ "${RESULTS[$i]}" == "FAIL" ]] && ((fails++))
done
printf -- '%.0s-' {1..90}; echo
if [[ $fails -eq 0 ]]; then
  echo "OVERALL: PASS"
else
  echo "OVERALL: FAIL (${fails} failing)"
fi


k6 run k6-load.js \
  --env BASE="http://${IP}:8080" \
  --env FRONT="http://${IP}:3000" \
  --env PROM="http://${IP}:9090" \
  --env GRAF="http://${IP}:3001" \
  --env DUR=1m \
  --env FRONT_VUS=20 \
  --env AUTHORS_VUS=20 \
  --env HEALTH_VUS=10 \
  --env PROM_VUS=5 \
  --env GRAFANA_VUS=5


exit $fails

