// FIX L-3: No max length on text fields.
// Add a tiny middleware to cap field sizes before they hit the DB.

// ─── New file: server/middleware/validate.js ──────────────────────────
const FIELD_LIMITS = {
  // Auth
  name: 100, email: 200, password: 200, phone: 20,
  company_name: 200, city: 100, state: 100, pincode: 10,
  bio: 2000, skills: 1000, current_company: 200,

  // Jobs
  title: 200, location: 200, job_type: 50, category: 100, department: 50,
  description: 10000, requirements: 10000,

  // Applications
  full_name: 100, current_ctc: 50, expected_ctc: 50, notice_period: 100,
  cover_letter: 5000,

  // OTP / tokens
  otp: 10, token: 200,
};

const validateLengths = (req, res, next) => {
  if (!req.body || typeof req.body !== 'object') return next();
  for (const [key, value] of Object.entries(req.body)) {
    if (typeof value === 'string') {
      const limit = FIELD_LIMITS[key];
      if (limit && value.length > limit) {
        return res.status(400).json({
          error: `Field '${key}' exceeds maximum length of ${limit} characters.`,
        });
      }
    }
  }
  next();
};

module.exports = { validateLengths };

// ─── In server/app.js, BEFORE the route registrations: ─────────────────
//   const { validateLengths } = require('./middleware/validate');
//   app.use('/api', validateLengths);
