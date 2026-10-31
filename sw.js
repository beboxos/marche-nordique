const CACHE_NAME = 'guide-mn-v4';
const STATIC_ASSETS = [
  './',
  './index.html',
  './circuits-data.js',
  './supabase-config.js',
  './vendor/leaflet.js',
  './vendor/leaflet.css',
  './manifest.json',
  './icon.svg'
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => cache.addAll(STATIC_ASSETS))
  );
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.filter((k) => k !== CACHE_NAME).map((k) => caches.delete(k)))
    )
  );
  self.clients.claim();
});

self.addEventListener('fetch', (event) => {
  const url = new URL(event.request.url);
  // Supabase (API, auth, fichiers) et écritures : jamais interceptés, l'appli gère son propre cache
  if (event.request.method !== 'GET' || url.hostname.endsWith('supabase.co') || url.pathname.endsWith('admin.html')) return;
  // Cache-first for map tiles and scanned images for offline forest usage
  if (
    url.pathname.includes('/scans/') ||
    url.hostname.includes('tile.openstreetmap.org') ||
    url.hostname.includes('tile.opentopomap.org') ||
    url.hostname.includes('arcgisonline.com') ||
    url.hostname.includes('unpkg.com')
  ) {
    event.respondWith(
      caches.match(event.request).then((cached) => {
        if (cached) return cached;
        return fetch(event.request)
          .then((response) => {
            if (response && response.status === 200) {
              const clone = response.clone();
              caches.open(CACHE_NAME).then((cache) => cache.put(event.request, clone));
            }
            return response;
          })
          .catch(() => cached);
      })
    );
    return;
  }

  // Network-first fallback to cache for app files
  event.respondWith(
    fetch(event.request)
      .then((response) => {
        const clone = response.clone();
        caches.open(CACHE_NAME).then((cache) => cache.put(event.request, clone));
        return response;
      })
      .catch(() => caches.match(event.request))
  );
});
