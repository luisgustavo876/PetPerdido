// Service worker do push no navegador (Firebase Cloud Messaging).
//
// Mostra a notificação quando o site está fechado ou em segundo plano:
// título, texto, foto do pet e, ao tocar, abre o post (o link vem da Cloud
// Function). Com o site aberto, quem mostra o aviso é o próprio app.
//
// A configuração do app vem do Firebase Hosting (/__/firebase/init.js), então
// nenhuma chave fica escrita aqui. Fora do Hosting (ex.: `flutter run` local)
// esse arquivo não existe: o push do navegador não funciona, mas os alertas
// continuam no sino do app.
//
// Versão do SDK = a usada pelo firebase_core_web (supportedFirebaseJsSdkVersion).
importScripts('https://www.gstatic.com/firebasejs/11.9.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/11.9.1/firebase-messaging-compat.js');

try {
  importScripts('/__/firebase/init.js');
  firebase.messaging();
} catch (e) {
  console.warn('PetPerdido: push do navegador indisponível aqui.', e);
}

// Botões da notificação ("Ver o pet" / "Ver no mapa"). O toque no corpo da
// notificação o próprio Firebase trata (abre o link do post); aqui só os
// botões. (As abas do site não são controladas por este service worker, que
// tem escopo próprio; por isso abre o endereço em vez de navegar a aba.)
self.addEventListener('notificationclick', (event) => {
  if (!event.action) return;
  event.notification.close();
  const msg = (event.notification.data || {}).FCM_MSG || {};
  const postId = msg.data && msg.data.postId;
  const destino = event.action === 'ver' && postId
    ? '/?post=' + encodeURIComponent(postId)
    : '/';
  event.waitUntil(clients.openWindow(new URL(destino, self.location.origin).href));
});
