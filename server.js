// ------------------------------------------------------------
// server.js - local development entry point.
// Production uses api/index.js as a Vercel Function; this file
// is never deployed as the entry point.
// ------------------------------------------------------------
import 'dotenv/config';
import app from './api/index.js';

const port = process.env.PORT || 3000;

app.listen(port, () => {
  console.log(`API listening on http://localhost:${port}`);
});
