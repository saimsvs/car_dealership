# Used Car Dealership Management System

CS 341 Database Systems — Fall 2026
Stack: React (Vite) + Express on Vercel + PostgreSQL on Neon.

---

## Folder structure

```
car_dealership/
├── api/
│   └── index.js          The ONE Vercel function. Mounts routers, errors, CORS.
├── routes/               Route modules imported by api/index.js.
│                         Kept OUT of api/ so Vercel doesn't deploy each
│                         file as a separate function.
│   ├── cars.js           GET /api/cars, /api/cars/:id, PATCH status
│   ├── purchases.js      POST /api/purchases  (car + purchase + payment)
│   ├── maintenance.js    POST /api/maintenance, GET by car
│   ├── customers.js      GET/POST /api/customers
│   ├── sales.js          POST /api/sales, PATCH transfer
│   ├── transactions.js   POST /api/transactions (token, refund, payments)
│   └── reports.js        3 read-only report endpoints
├── db.js                 pg Pool (module scope, max 3)
├── server.js             local dev entry: npm run dev
├── sql/
│   ├── 01_schema.sql     8 tables, 54 columns, 9 FKs
│   ├── 02_triggers.sql   CNIC expiry, transfer due date, buy-back rules
│   ├── 03_seed.sql       demo data (to write)
│   └── 04_queries.sql    report queries kept for the report/demo
├── src/                  React app (Vite)
│   ├── components/       small reusable pieces
│   ├── pages/            one per screen
│   ├── lib/              fetch wrappers, formatters
│   └── assets/
├── public/               static files copied as-is by Vite
├── docs/
│   ├── erd/              draw.io / dbdiagram exports
│   ├── wireframes/       Figma exports
│   └── report/           milestone document, PDFs
├── .env                  real credentials (gitignored)
├── .env.example          template
├── vercel.json           /api/(.*) -> /api rewrite
└── package.json
```

## Screens (from the doc's use cases)

| # | Screen | Data shown | Endpoint(s) |
|---|---|---|---|
| 1 | Inventory | cars, filter by status | `GET /api/cars?status=` |
| 2 | Car detail | purchase, repairs, payments, sale, transfer | `GET /api/cars/:id` |
| 3 | New purchase | seller, price, date, payment mode, car details | `POST /api/purchases` |
| 4 | New sale | customer, price, token/payment | `POST /api/sales` |
| 5 | Customers | list + register | `GET` / `POST /api/customers` |
| 6 | Reports | profit per car, pending payments, overdue transfers | `GET /api/reports/*` |

## Setup (from scratch)

```bash
npm install
cp .env.example .env          # then paste the Neon connection string

# database (only when the schema changes)
psql "$DIRECT_URL" -v ON_ERROR_STOP=1 -f sql/01_schema.sql
psql "$DIRECT_URL" -v ON_ERROR_STOP=1 -f sql/02_triggers.sql

# run the API
npm run dev                   # http://localhost:3000
curl http://localhost:3000/api/ping
```

## Environments

| | Frontend | API | Database | Env var |
|---|---|---|---|---|
| Local | Vite :5173 | Express :3000 | Neon | `$DATABASE_URL` (or `$DIRECT_URL` for DDL) |
| Production | Vercel | Vercel function | Neon `main` | `DATABASE_URL` (pooled) |

## Conventions

- Values in SQL always via `$1, $2` — never template interpolation.
- Handlers wrapped in `ah(...)` so rejected promises reach the error middleware.
- Postgres error codes map to HTTP: `23505`→409, `23503`→400, `23514`→400, `P0001`→400 (trigger `RAISE`).
- Business rules live in the database (constraints + triggers), not in JS.
- Never run DDL from the app. `sql/*.sql` is the only schema source.
