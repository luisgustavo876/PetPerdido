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
