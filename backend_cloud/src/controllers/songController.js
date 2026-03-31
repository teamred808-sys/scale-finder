const crypto = require('crypto');
const cheerio = require('cheerio');
const { query } = require('../config/database');
const { fetchAxios, extractArtistFromTitle, cleanString, extractMetaData, parseSections, logParserFailure, BASE_URL } = require('../parser/chordzone');

const SONG_TTL = 30 * 24 * 60 * 60; // 30 days
const SEARCH_TTL = 24 * 60 * 60; // 1 day

async function searchSongs(req, res) {
  const q = req.query.q;
  if (!q || !q.trim()) {
    return res.status(400).json({ error: 'Missing q parameter' });
  }

  const queryRaw = q.trim().toLowerCase();
  const queryHash = crypto.createHash('md5').update(queryRaw).digest('hex');
  const now = Math.floor(Date.now() / 1000);

  try {
    // Check Cache
    const [cached] = await query('SELECT json_results, last_synced_at FROM search_cache WHERE query_hash = ?', [queryHash]);
    if (cached) {
      if (now - cached.last_synced_at <= SEARCH_TTL) {
        return res.json({ results: cached.json_results, source: 'cache' });
      }
    }

    // Live Fetch
    const url = `${BASE_URL}/search?q=${encodeURIComponent(queryRaw)}`;
    const response = await fetchAxios.get(url);
    const $ = cheerio.load(response.data);

    const results = [];
    $('.post-title.entry-title a, h3.post-title a').each((_, el) => {
      const $el = $(el);
      const title = cleanString($el.text());
      const link = $el.attr('href') || '';
      
      if (title && link) {
         const parts = link.split('/');
         const slug = parts[parts.length - 1].replace('.html', '');
         results.push({
           slug,
           title,
           artist: extractArtistFromTitle(title),
           sourceUrl: link
         });
      }
    });

    // Save to Cache
    await query(`
      INSERT INTO search_cache (query_hash, query, json_results, last_synced_at)
      VALUES (?, ?, ?, ?)
      ON DUPLICATE KEY UPDATE query=VALUES(query), json_results=VALUES(json_results), last_synced_at=VALUES(last_synced_at)
    `, [queryHash, queryRaw, JSON.stringify(results), now]);

    return res.json({ results, source: 'live' });
  } catch (error) {
    console.error('Search failed:', error);
    res.status(500).json({ error: 'Failed to search songs.' });
  }
}

async function getSongDetail(req, res) {
  const slug = req.params.slug;
  const url = req.query.url;

  if (!url) {
    return res.status(400).json({ error: 'url required' });
  }

  const now = Math.floor(Date.now() / 1000);

  try {
    // Check cache
    const [cached] = await query('SELECT json_data, last_synced_at FROM song_cache WHERE slug = ?', [slug]);
    if (cached) {
      if (now - cached.last_synced_at <= SONG_TTL) {
         return res.json({ data: cached.json_data, source: 'cache' });
      }
    }

    // Live Fetch
    const response = await fetchAxios.get(url);
    const $ = cheerio.load(response.data);
    const $content = $('.post-body.entry-content');
    
    if ($content.length === 0) {
      throw new Error('Content body not found on source page');
    }

    const title = cleanString($('.post-title.entry-title').text() || 'Unknown');
    const metaData = extractMetaData($content);
    
    const originalKey = metaData['Original Key'];
    let scaleFamily = null;
    if (originalKey) {
      scaleFamily = (originalKey.toLowerCase().includes('m') || originalKey.toLowerCase().includes('minor')) 
        ? 'Natural Minor' : 'Major';
    }

    const sections = parseSections($content.html(), $content.text());

    const data = {
      sourceName: 'ChordZone',
      sourceUrl: url,
      title: metaData['Title'] || title,
      artist: extractArtistFromTitle(title).split(', ').filter(Boolean),
      originalKey: originalKey || null,
      scaleFamily,
      tempo: metaData['Tempo'] || null,
      timeSignature: metaData['Time Signature'] || null,
      suggestedStrumming: metaData['Suggested Strumming'] || null,
      sections,
      rawChordLyrics: $content.html() || '',
      lastSyncedAt: now
    };

    // Save Cache
    await query(`
      INSERT INTO song_cache (slug, title, artist, json_data, last_synced_at)
      VALUES (?, ?, ?, ?, ?)
      ON DUPLICATE KEY UPDATE title=VALUES(title), artist=VALUES(artist), json_data=VALUES(json_data), last_synced_at=VALUES(last_synced_at)
    `, [slug, data.title, data.artist.join(', '), JSON.stringify(data), now]);

    return res.json({ data, source: 'live' });

  } catch (error) {
    console.error('Detail fetch failed:', error.message);
    await logParserFailure(url, error.message);
    res.status(404).json({ error: 'Failed to parse song metadata.' });
  }
}

module.exports = {
  searchSongs,
  getSongDetail
};
