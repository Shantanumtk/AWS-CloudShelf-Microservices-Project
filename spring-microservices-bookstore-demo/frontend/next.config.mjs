/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  
  // Standalone output for optimized Docker builds
  output: 'standalone',
  
  // Server-side rewrites (proxy) - reads API_GATEWAY_URL at RUNTIME
  async rewrites() {
    const apiGatewayUrl = process.env.API_GATEWAY_URL || 'http://localhost:8080';
    
    console.log('[Next.js Config] API Gateway URL:', apiGatewayUrl);
    
    return [
      // Proxy all /api/* requests to API Gateway
      {
        source: '/api/:path*',
        destination: `${apiGatewayUrl}/:path*`,
      },
      // GraphQL endpoint
      {
        source: '/graphql',
        destination: `${apiGatewayUrl}/graphql`,
      },
      // Alternative GraphQL path
      {
        source: '/api/graphql',
        destination: `${apiGatewayUrl}/graphql`,
      },
    ];
  },
  
  // Security headers
  async headers() {
    return [
      {
        source: '/:path*',
        headers: [
          {
            key: 'X-Frame-Options',
            value: 'SAMEORIGIN',
          },
          {
            key: 'X-Content-Type-Options',
            value: 'nosniff',
          },
          {
            key: 'X-XSS-Protection',
            value: '1; mode=block',
          },
        ],
      },
    ];
  },
  
  // Disable x-powered-by header
  poweredByHeader: false,
  
  // Compression
  compress: true,
};

export default nextConfig;