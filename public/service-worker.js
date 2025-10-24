// Service Worker básico
self.addEventListener('install', event => {
  console.log('Service Worker instalado');
});

self.addEventListener('fetch', event => {
  // Permitir requests normales por ahora
  event.respondWith(fetch(event.request));
});
