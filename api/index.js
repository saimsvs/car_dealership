// ------------------------------------------------------------
// api/index.js - the Express app.
//
// Deployed as a single Vercel Function. Routes keep the /api
// prefix because vercel.json rewrites /api/(.*) -> /api
// without stripping the path.
//
// No DDL here: tables come from sql/01_schema.sql + 02_triggers.sql.
// ------------------------------------------------------------
import express from 'express';
import cors from 'cors';
import { pool } from '../db.js';

const app = express();

app.use(express.json());
app.use(
  cors({
    origin: [
      'http://localhost:5173',
      'http://localhost:3000',
      process.env.APP_ORIGIN, // e.g. https://car-dealership.vercel.app
    ].filter(Boolean),
  })
);

// Wrap async handlers so a rejected promise reaches Express.
const ah = (fn) => (req, res, next) => Promise.resolve(fn(req, res, next)).catch(next);

// ------------------------------------------------------------
// GET /api/ping - proves GitHub -> Vercel -> Neon end to end.
// ------------------------------------------------------------
app.get(
  '/api/ping',
  ah(async (req, res) => {
    const { rows } = await pool.query('SELECT now() AS db_time, current_database() AS db');
    res.json({ ok: true, ...rows[0] });
  })
);

// ------------------------------------------------------------
// GET /api/cars - every car with its status.
// ------------------------------------------------------------
app.get(
  '/api/cars',
  ah(async (req, res) => {
    const { rows } = await pool.query(
      `SELECT car_id, model, registration, chassis_no, engine_no, colour, status
         FROM car
        ORDER BY car_id`
    );
    res.json(rows);
  })
);

// ------------------------------------------------------------
// Fallbacks
// ------------------------------------------------------------
app.use((req, res) => {
  res.status(404).json({ error: 'not found', path: req.originalUrl });
});

// Postgres error codes -> HTTP codes, so a constraint violation
// is a 400 (bad input) rather than a 500 (server bug).
app.use((err, req, res, next) => {
  const pgCodes = {
    '23505': 409, // unique_violation
    '23503': 400, // foreign_key_violation
    '23514': 400, // check_violation
    '23502': 400, // not_null_violation
    P0001: 400,   // RAISE EXCEPTION from our triggers
  };
  const status = err.code ? pgCodes[err.code] ?? 500 : 500;
  if (status === 500) console.error(err);
  res.status(status).json({ error: err.message });
});

export default app;
