# Login Credentials

This folder contains sensitive credentials. **It must never be committed to a public repo.**

A `.gitignore` rule is included that excludes everything in this folder except `README.md`. Verify it works by running `git status` after creating/editing files inside — the secret files should NOT appear as tracked.

## Files

| File | Contents |
|---|---|
| `test-accounts.md` | Demo login credentials for testing the app (jobseeker, employer, HR, super admin) |
| `.env.example` | Template for backend secrets (JWT_SECRET, DATABASE_URL, SMTP, etc.) |
| `.env.production` | Real production secrets — fill this in locally and **NEVER push it** |
| `.env.development` | Local dev secrets — also do not push |

## How to use

### For local development
1. Copy `.env.example` to `server/.env` (in the repo root, not this folder)
2. Fill in real values
3. The `server/.env` file is already gitignored by Node's standard pattern

### For sharing with your friend
- Use a secure channel: 1Password shared vault, Bitwarden organization, or Signal
- Do NOT share via email, WhatsApp media, or Slack DMs that get logged

### When credentials leak
- Rotate the JWT secret (this invalidates ALL existing tokens — every user is logged out)
- Reset DB user password
- Rotate any SMTP / API keys
- Audit access logs for the last 30 days
