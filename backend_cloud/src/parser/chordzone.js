const axios = require('axios');
const cheerio = require('cheerio');
const crypto = require('crypto');
const { query } = require('../config/database');

const BASE_URL = 'https://www.chordzone.org';

const fetchAxios = axios.create({
  timeout: 8000,
  headers: {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) ScaleFinderbot/1.0',
  },
});

async function logParserFailure(url, errMessage) {
  try {
    await query(
      'INSERT INTO parser_failures (url, error_message, failed_at) VALUES (?, ?, ?)',
      [url, String(errMessage), Math.floor(Date.now() / 1000)]
    );
  } catch (dbErr) {
    console.error('Failed to log parser failure', dbErr);
  }
}

function cleanString(str) {
  return str ? str.replace(/[\n\r]+/g, ' ').trim() : '';
}

function extractArtistFromTitle(title) {
  if (title && title.includes(' - ')) {
    return title.split(' - ')[0].trim();
  }
  return 'Unknown Artist';
}

function parseSections(innerHtml, rawText) {
  const lines = rawText.split(/\n|\r\n/);
  const sections = [];
  let currentSection = null;

  const chordRegex = /^[\sA-Ga-g#mbdimaug791113sus]+$/;

  for (let line of lines) {
    const text = line.trimEnd();
    if (!text) continue;

    // Detect bracket header
    if (text.startsWith('[') && text.endsWith(']')) {
      if (currentSection) sections.push(currentSection);
      currentSection = {
        label: text.replace('[', '').replace(']', ''),
        lines: [],
      };
      continue;
    }

    if (!currentSection) {
      currentSection = { label: 'INTRO', lines: [] };
    }

    const trimmed = text.trim();
    const isChordLine = chordRegex.test(trimmed) && trimmed.length > 0;
    
    // Skip typical metadata lines
    if (text.toLowerCase().includes('original key:') || text.toLowerCase().includes('tempo:')) {
      continue;
    }

    currentSection.lines.push({
      raw: text,
      type: isChordLine ? 'chords' : 'lyrics',
    });
  }

  if (currentSection && currentSection.lines.length > 0) {
    sections.push(currentSection);
  }

  return sections;
}

function extractMetaData($content) {
  const meta = {};
  const querySelect = $content.find('p, div, span, b, strong');

  const keyMatches = ['original key:', 'key:', 'scale:'];
  const tempoMatches = ['tempo:'];
  const timeMatches = ['time signature:'];
  const strumMatches = ['suggested strumming:', 'strumming:'];

  querySelect.each((_, el) => {
    const text = cleanString(cheerio.load(el).text());
    const lower = text.toLowerCase();

    for (const km of keyMatches) {
      if (lower.startsWith(km)) meta['Original Key'] = text.substring(km.length).trim();
    }
    for (const tm of tempoMatches) {
      if (lower.startsWith(tm)) meta['Tempo'] = text.substring(tm.length).trim();
    }
    for (const tsm of timeMatches) {
      if (lower.startsWith(tsm)) meta['Time Signature'] = text.substring(tsm.length).trim();
    }
    for (const sm of strumMatches) {
      if (lower.startsWith(sm)) meta['Suggested Strumming'] = text.substring(sm.length).trim();
    }
  });

  if (!meta['Tempo']) {
    const rawText = $content.text();
    const match = rawText.match(/(\d{2,3})\s*bpm/i);
    if (match) {
      meta['Tempo'] = `${match[1]} bpm`;
    }
  }

  return meta;
}

module.exports = {
  fetchAxios,
  extractArtistFromTitle,
  cleanString,
  extractMetaData,
  parseSections,
  logParserFailure,
  BASE_URL
};
