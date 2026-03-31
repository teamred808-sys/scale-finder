const express = require('express');
const router = express.Router();
const { searchSongs, getSongDetail } = require('../controllers/songController');

// Routes mounted at /api/songs
router.get('/songs/search', searchSongs);
router.get('/songs/:slug', getSongDetail);

module.exports = router;
