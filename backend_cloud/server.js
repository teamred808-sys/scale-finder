require('dotenv').config();
const express = require('express');
const cors = require('cors');
const apiRoutes = require('./src/routes/api');
const { query } = require('./src/config/database'); // Just ping DB immediately to ensure connection pool setup

const app = express();
const PORT = process.env.PORT || 8080;

app.use(cors());
app.use(express.json());

// Initialize DB schema on startup safely
(async () => {
  try {
    await query(`
      CREATE TABLE IF NOT EXISTS search_cache (
        query_hash VARCHAR(64) PRIMARY KEY,
        query VARCHAR(255) NOT NULL,
        json_results JSON NOT NULL,
        last_synced_at BIGINT NOT NULL
      );
    `);
    await query(`
      CREATE TABLE IF NOT EXISTS song_cache (
        slug VARCHAR(255) PRIMARY KEY,
        title VARCHAR(255) NOT NULL,
        artist VARCHAR(255),
        json_data JSON NOT NULL,
        last_synced_at BIGINT NOT NULL
      );
    `);
    await query(`
      CREATE TABLE IF NOT EXISTS parser_failures (
        id INT AUTO_INCREMENT PRIMARY KEY,
        url VARCHAR(512) NOT NULL,
        error_message TEXT,
        failed_at BIGINT NOT NULL
      );
    `);
    console.log('Database tables verified.');
  } catch (err) {
    console.error('Database setup failed. Is MySQL running?', err);
  }
})();

// Healthcheck
app.get('/healthz', (req, res) => {
  res.json({ status: 'ok', timestamp: Math.floor(Date.now() / 1000) });
});

// API Routes
app.use('/api', apiRoutes);

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
