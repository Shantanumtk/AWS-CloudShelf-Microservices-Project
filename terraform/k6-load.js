import http from 'k6/http';
import { check, sleep, fail } from 'k6';

export const options = {
  scenarios: {
    frontend:   { executor: 'constant-vus', vus: Number(__ENV.FRONT_VUS || 15), duration: __ENV.DUR || '1m', exec: 'hitFrontend' },
    authors:    { executor: 'constant-vus', vus: Number(__ENV.AUTHORS_VUS || 15), duration: __ENV.DUR || '1m', exec: 'getAuthors' },
    health:     { executor: 'constant-vus', vus: Number(__ENV.HEALTH_VUS || 8),  duration: __ENV.DUR || '1m', exec: 'getHealth' },
    prom:       { executor: 'constant-vus', vus: Number(__ENV.PROM_VUS || 5),    duration: __ENV.DUR || '1m', exec: 'getPromTargets' },
    grafana:    { executor: 'constant-vus', vus: Number(__ENV.GRAFANA_VUS || 5), duration: __ENV.DUR || '1m', exec: 'getGrafanaHealth' },
  },
  thresholds: {
    http_req_failed:   ['rate<0.02'],   // <2% errors allowed
    http_req_duration: ['p(95)<800'],   // 95% under 800ms
  },
};

const BASE  = __ENV.BASE;   // e.g., http://IP:8080
const FRONT = __ENV.FRONT;  // e.g., http://IP:3000
const PROM  = __ENV.PROM;   // e.g., http://IP:9090
const GRAF  = __ENV.GRAF;   // e.g., http://IP:3001
const VERBOSE = __ENV.VERBOSE === '1';

if (!BASE || !FRONT) {
  fail(`Missing BASE/FRONT. Example:
  IP=$(terraform output -raw public_ip)
  k6 run k6-get-only.js \\
    --env BASE=http://${IP}:8080 --env FRONT=http://${IP}:3000 \\
    --env PROM=http://${IP}:9090 --env GRAF=http://${IP}:3001`);
}

function dump(label, res) {
  if (VERBOSE && res) console.error(`--- ${label} status=${res.status}\n${res.body && res.body.substring(0,300)}`);
}

// Frontend GET /
export function hitFrontend() {
  const r = http.get(`${FRONT}/`);
  dump('frontend /', r);
  check(r, { 'frontend 200': (res) => res && res.status === 200 });
  sleep(0.2);
}

// REST GET /api/authors
export function getAuthors() {
  const r = http.get(`${BASE}/api/authors`);
  dump('authors GET', r);
  check(r, { 'authors 200': (res) => res && res.status === 200 });
  sleep(0.2);
}

// Health (via gateway) — adjust or add more if you expose them
export function getHealth() {
  const r = http.get(`${BASE}/order-service/actuator/health`);
  dump('order-service health', r);
  check(r, { 'health 200': (res) => res && res.status === 200 });
  sleep(0.3);
}

// Prometheus targets page (optional)
export function getPromTargets() {
  if (!PROM) { sleep(0.5); return; }
  const r = http.get(`${PROM}/targets`);
  dump('prom /targets', r);
  check(r, { 'prom targets 200': (res) => res && res.status === 200 });
  sleep(0.4);
}

// Grafana health (optional)
export function getGrafanaHealth() {
  if (!GRAF) { sleep(0.5); return; }
  const r = http.get(`${GRAF}/api/health`);
  dump('grafana /api/health', r);
  check(r, { 'grafana 200': (res) => res && res.status === 200 });
  sleep(0.4);
}
