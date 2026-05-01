// FIX M-3: Resume files at /uploads/resumes/* are publicly accessible.
// Add an authenticated download endpoint and tighten the static handler.

// ─── In server/app.js ─────────────────────────────────────────────────
// REPLACE this line:
//
//   app.use('/uploads', express.static(path.join(__dirname, 'uploads')));
//
// WITH this:

// Public uploads (gallery, board images) — safe to serve freely
app.use('/uploads/gallery', express.static(path.join(__dirname, 'uploads/gallery')));
app.use('/uploads/boards',  express.static(path.join(__dirname, 'uploads/boards')));

// Resumes are NOT served statically. Use the authenticated route below.

// ─── New file: server/routes/files.js ─────────────────────────────────
const express = require('express');
const path = require('path');
const fs = require('fs');
const { query } = require('../db-pg');
const { authenticate } = require('../middleware/auth');

const router = express.Router();

// GET /api/files/resume/:applicationId
// Allowed: the applicant themself, the employer who owns the job, or any HR/super_admin.
router.get('/resume/:applicationId', authenticate, async (req, res) => {
  try {
    const app = (await query(
      `SELECT a.applicant_id, a.resume_path, j.employer_id
       FROM applications a JOIN jobs j ON a.job_id = j.id
       WHERE a.id = $1`,
      [req.params.applicationId]
    )).rows[0];

    if (!app || !app.resume_path) {
      return res.status(404).json({ error: 'Resume not found' });
    }

    const isApplicant = req.user.id === app.applicant_id;
    const isEmployer  = req.user.id === app.employer_id;
    const isAdmin     = req.user.role === 'hr' || req.user.role === 'super_admin';

    if (!isApplicant && !isEmployer && !isAdmin) {
      return res.status(403).json({ error: 'Not authorized to view this resume' });
    }

    // Resolve safely — prevent path traversal
    const safeName = path.basename(app.resume_path);
    const filePath = path.join(__dirname, '../uploads', safeName);
    if (!fs.existsSync(filePath)) return res.status(404).json({ error: 'File missing on server' });

    return res.sendFile(filePath);
  } catch (err) {
    console.error('GET /files/resume error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

module.exports = router;

// ─── Then in server/app.js, register it ────────────────────────────────
//   const fileRoutes = require('./routes/files');
//   app.use('/api/files', fileRoutes);
