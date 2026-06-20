import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Emit a self-contained .next/standalone (server.js + only the traced
  // node_modules) so the runtime image stays small.
  output: 'standalone',
  serverExternalPackages: ['better-sqlite3'],
};

export default nextConfig;
