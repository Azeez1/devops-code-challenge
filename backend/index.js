const express = require('express');
const { v4: uuidv4 } = require('uuid');
const { CORS_ORIGIN } = require('./config'); // Keep this if you intend to use the config file primarily

// Simple Versioning -  Increment this manually or use a build timestamp
const APP_VERSION = "1.0.1_debug_cors_fix"; // Change this with each deployment attempt

console.log(`[Backend v${APP_VERSION}] STARTING - Initial CORS_ORIGIN from config.js: ${CORS_ORIGIN}`);
console.log(`[Backend v${APP_VERSION}] Current process.env.CORS_ORIGIN: ${process.env.CORS_ORIGIN}`);

const ID = uuidv4();
const PORT = 8080;

const app = express();
app.use(express.json());

// Middleware to set CORS headers
app.use((req, res, next) => {
    // Determine the allowed origin. Prioritize environment variable, then config.js, then your hardcoded IP.
    const allowedOriginFromEnv = process.env.CORS_ORIGIN;
    const finalAllowedOrigin = allowedOriginFromEnv || CORS_ORIGIN || 'http://34.205.29.35'; // Fallback

    if (!process.env.CORS_ORIGIN) {
        console.warn(`[Backend v${APP_VERSION}] WARNING: CORS_ORIGIN environment variable is not set. Falling back to config.js or hardcoded value.`);
    }
    console.log(`[Backend v${APP_VERSION}] Request received. Setting Access-Control-Allow-Origin to: ${finalAllowedOrigin} for origin ${req.headers.origin}`);

    res.setHeader('Access-Control-Allow-Origin', finalAllowedOrigin);
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS, PUT, PATCH, DELETE'); // Allow common methods
    res.setHeader('Access-Control-Allow-Headers', 'X-Requested-With,content-type,Authorization'); // Allow common headers
    res.setHeader('Access-Control-Allow-Credentials', true); // If you use credentials/cookies

    // Handle preflight requests
    if (req.method === 'OPTIONS') {
        console.log(`[Backend v${APP_VERSION}] Responding to OPTIONS preflight request for origin ${req.headers.origin}`);
        return res.status(204).end(); // No Content for OPTIONS
    }
    next();
});

// Debug endpoint to check current environment variables and CORS config
app.get('/debug-cors', (req, res) => {
    console.log(`[Backend v${APP_VERSION}] DEBUG_CORS endpoint hit.`);
    res.json({
        message: "CORS Debug Information",
        appVersion: APP_VERSION,
        configuredCorsOriginFromConfigJs: CORS_ORIGIN,
        processEnvCorsOrigin: process.env.CORS_ORIGIN,
        actualAllowedOriginInEffect: process.env.CORS_ORIGIN || CORS_ORIGIN || 'http://34.205.29.35',
        ecsTaskDefinitionCorsOrigin: process.env.CORS_ORIGIN // This should reflect what ECS is passing
    });
});

app.get(/.*/, (req, res) => {
    console.log(`<span class="math-inline">\{new Date\(\)\.toISOString\(\)\} \[Backend v</span>{APP_VERSION}] GET request received for ${req.path}`);
    res.json({ id: ID, version: APP_VERSION }); // Include version in response
});

app.listen(PORT, () => {
    console.log(`[Backend v${APP_VERSION}] Backend started on ${PORT}. Waiting for requests...`);
    console.log(`[Backend v${APP_VERSION}] CORS_ORIGIN from config.js after app start: ${CORS_ORIGIN}`);
    console.log(`[Backend v${APP_VERSION}] process.env.CORS_ORIGIN after app start: ${process.env.CORS_ORIGIN}`);
});
