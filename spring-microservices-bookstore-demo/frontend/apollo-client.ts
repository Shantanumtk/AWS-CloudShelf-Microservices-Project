// apollo-client.ts - Updated to use proxy (no env vars needed!)
import { ApolloClient, InMemoryCache } from '@apollo/client';

// ✅ Use relative URL - Next.js will proxy to API Gateway
// No need for NEXT_PUBLIC_API_BASE anymore!
const GRAPHQL_URL = '/graphql';

console.log('[Apollo Client] GraphQL URL:', GRAPHQL_URL);

const client = new ApolloClient({
  uri: GRAPHQL_URL,
  cache: new InMemoryCache(),
  defaultOptions: {
    watchQuery: {
      fetchPolicy: 'cache-and-network',
    },
  },
});

export default client;