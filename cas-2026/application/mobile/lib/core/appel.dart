import 'package:url_launcher/url_launcher.dart';

/// Ouvre le composeur du téléphone sur [numero] (l'agriculteur n'a plus qu'à appeler). `false` si rien n'a pu s'ouvrir.
Future<bool> appeler(String numero) {
  final propre = numero.replaceAll(RegExp(r'[^0-9+]'), '');
  return launchUrl(Uri(scheme: 'tel', path: propre));
}
