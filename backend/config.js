// backend/config.js
const APP_VERSION_CONFIG = "1.0.1_debug_cors_fix"; // Match the version in index.js for consistency

// Prefer the environment variable set by ECS, but have a default.
// IMPORTANT: This default will ONLY be used if the process.env.CORS_ORIGIN is NOT set.
const configuredOrigin = process.env.CORS_ORIGIN || 'http://34.205.29.35'; // Your frontend IP

console.log(`[Config.js v${APP_VERSION_CONFIG}] Loaded. process.env.CORS_ORIGIN: ${process.env.CORS_ORIGIN}, Default/Fallback: http://34.205.29.35, Effective CORS_ORIGIN for export: ${configuredOrigin}`);

module.exports = {
  CORS_ORIGIN: configuredOrigin,
  APP_VERSION: APP_VERSION_CONFIG // You can also export version from here if you like
};
