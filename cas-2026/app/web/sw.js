// Caches the app shell so it opens instantly; live data always comes from the network.
const CACHE = 'smartfarm-v3';
const SHELL = ['./', 'css/app.css', 'js/app.js', 'js/scene.js', 'js/plant.js', 'js/charts.js',
  'js/common.js', 'js/stats.js', 'js/ai.js', 'js/views.js', 'js/art.js',
  'fonts/sora-v17-latin-700.woff2', 'fonts/sora-v17-latin-800.woff2', 'fonts/nunito-v32-latin-regular.woff2', 'fonts/nunito-v32-latin-700.woff2',
  'vendor/three/three.module.min.js', 'vendor/three/addons/controls/OrbitControls.js',
  'icons/icon-192.png', 'manifest.webmanifest'];
self.addEventListener('install', e => e.waitUntil(caches.open(CACHE).then(c => c.addAll(SHELL)).then(() => self.skipWaiting())));
self.addEventListener('activate', e => e.waitUntil(
  caches.keys().then(ks => Promise.all(ks.filter(k => k !== CACHE).map(k => caches.delete(k)))).then(() => self.clients.claim())));
self.addEventListener('fetch', e => {
  const u = new URL(e.request.url);
  if (e.request.method !== 'GET' || u.pathname.startsWith('/api') || u.pathname.startsWith('/captures')) return;
  // network first, so an updated app is picked up; cache only when offline
  e.respondWith(fetch(e.request).then(r => {
    const copy = r.clone(); caches.open(CACHE).then(c => c.put(e.request, copy)); return r;
  }).catch(() => caches.match(e.request)));
});
