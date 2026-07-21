// File: api/resolve-maps-link.js
// Deploy this file inside your project's "api" folder on Vercel (same place as your
// other serverless functions like ai-assistant.js).
//
// Why this is needed: Google Maps "share" links from the phone (maps.app.goo.gl / goo.gl/maps)
// are short redirect links. Browsers block JavaScript from following those redirects itself
// (CORS security rule), so the site can't read the real address/coordinates directly.
// This tiny server-side function fetches the link on Vercel's server (no CORS restriction
// there) and returns the final, real Google Maps URL back to the app, which then reads the
// coordinates from it.

export default async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  const url = req.query.url;
  if (!url || typeof url !== 'string') {
    return res.status(400).json({ error: 'url query param required' });
  }
  try {
    const response = await fetch(url, {
      method: 'GET',
      redirect: 'follow',
      headers: { 'User-Agent': 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36' }
    });
    let finalUrl = response.url || url;
    // Some Google redirects land on an HTML page with the real link embedded in it
    // rather than in the URL bar; try to pull coordinates out of the page body too.
    let bodySnippet = '';
    try {
      const text = await response.text();
      bodySnippet = text.slice(0, 20000);
    } catch (e) {}
    return res.status(200).json({ finalUrl, bodySnippet });
  } catch (err) {
    return res.status(500).json({ error: 'Could not resolve link', detail: String(err) });
  }
}
