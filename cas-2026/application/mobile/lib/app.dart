import 'package:flutter/material.dart';

import 'core/sf_router.dart';
import 'core/sf_theme.dart';

/// Racine de l'application : thème du design v2 et routage par onglets.
class SmartFarmApp extends StatefulWidget {
  const SmartFarmApp({super.key, this.depart});

  /// Page de départ ; par défaut, celle du routeur (le premier lancement).
  final String? depart;

  @override
  State<SmartFarmApp> createState() => _SmartFarmAppState();
}

class _SmartFarmAppState extends State<SmartFarmApp> {
  late final _routeur = creerRouteur(depart: widget.depart);

  @override
  void dispose() {
    _routeur.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SmartFarm',
      debugShowCheckedModeBanner: false,
      theme: buildSfTheme(),
      routerConfig: _routeur,
    );
  }
}
