// ------------------------------------------------------------
// db.js - one connection pool for the whole process.
//
// The pool lives at module scope on purpose: on Vercel a warm
// function reuses it across invocations. Creating it inside a
// handler would open a new connection per request and exhaust
// Neon's limit ("too many clients already").
// ------------------------------------------------------------
import 'dotenv/config';
import pg from 'pg';

const { Pool } = pg;

if (!process.env.DATABASE_URL) {
  throw new Error('DATABASE_URL is not set (copy .env.example to .env)');
}

export const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  max: 3,                 // small: Neon free tier shares compute
  idleTimeoutMillis: 30_000,
  connectionTimeoutMillis: 10_000,
});

// A dead idle connection should not crash the process.
pool.on('error', (err) => {
  console.error('idle postgres client error', err.message);
});
