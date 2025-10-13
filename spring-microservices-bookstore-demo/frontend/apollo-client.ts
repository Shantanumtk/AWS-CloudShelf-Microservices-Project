// Apollo client for connecting to GraphQL endpoints.
import { ApolloClient, InMemoryCache } from '@apollo/client';

const base = (process.env.NEXT_PUBLIC_API_BASE || '').replace(/\/$/, '');
const GRAPHQL_URL =
  process.env.NEXT_PUBLIC_GRAPHQL_ENDPOINT ||
  (base ? `${base}/api/graphql` : 'http://localhost:8080/api/graphql');

const client = new ApolloClient({
  uri: GRAPHQL_URL,
  cache: new InMemoryCache(),
});



export default client;
