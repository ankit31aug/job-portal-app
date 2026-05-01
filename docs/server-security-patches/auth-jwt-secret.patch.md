// FILE: server/middleware/auth.js
// SECURITY FIX H-1: Refuse to start server without JWT_SECRET in env.
// REPLACE the top of the file from `const JWT_SECRET = ...` with the block below.

const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET;

if (!JWT_SECRET) {
  // Fail loud and early. Do not boot a server with a guessable secret.
  console.error('FATAL: JWT_SECRET environment variable is not set.');
  console.error('Generate one with: node -e "console.log(require(\'crypto\').randomBytes(64).toString(\'hex\'))"');
  console.error('Then add JWT_SECRET=<value> to your .env file.');
  process.exit(1);
}

if (JWT_SECRET.length < 32) {
  console.warn('WARNING: JWT_SECRET is shorter than 32 characters. Use at least 64 random hex chars in production.');
}

// ... rest of the file unchanged ...
