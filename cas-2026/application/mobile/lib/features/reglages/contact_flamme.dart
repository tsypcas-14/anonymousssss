import 'package:flutter/foundation.dart';

/// La personne prévenue par SMS en cas de flamme : son nom et son numéro.
/// Pour l'instant, le contact vit en mémoire (valeurs d'exemple du design) ; il sera enregistré avec les réglages.
class ContactFlamme {
  const ContactFlamme({required this.nom, required this.numero});

  final String nom;

  /// Numéro tel qu'il sera composé, par exemple « +216 00 000 000 ».
  final String numero;

  /// Numéro avec le milieu masqué : « +216 00 ••• 000 ».
  String get numeroMasque => masquer(numero);

  ContactFlamme copyWith({String? nom, String? numero}) => ContactFlamme(nom: nom ?? this.nom, numero: numero ?? this.numero);
}

/// Le contact en cas de flamme, partagé par les écrans Réglages, Sécurité, Contact et l'alerte flamme.
/// Le numéro d'exemple est à remplacer depuis « Contact en cas de flamme ».
final ValueNotifier<ContactFlamme> contactFlamme = ValueNotifier(const ContactFlamme(nom: 'Responsable', numero: '+216 00 000 000'));

/// Masque le milieu d'un numéro : on garde le début (indicatif et 2 chiffres) et les 3 derniers chiffres.
String masquer(String numero) {
  final propre = numero.trim();
  final chiffres = propre.replaceAll(RegExp(r'[^0-9+]'), '');
  if (chiffres.length < 9) return propre;
  final debut = chiffres.substring(0, chiffres.length - 3 - 3);
  final fin = chiffres.substring(chiffres.length - 3);
  final indicatif = debut.length > 4 ? '${debut.substring(0, 4)} ${debut.substring(4)}' : debut;
  return '$indicatif ••• $fin';
}

/// Un numéro est utilisable s'il contient au moins 8 chiffres.
bool numeroValide(String numero) => numero.replaceAll(RegExp(r'[^0-9]'), '').length >= 8;
