import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'sf_bottom_nav.dart';

/// Coque des 4 onglets : le contenu de l'onglet actif + la barre du bas.
class SfShell extends StatelessWidget {
  const SfShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: SfBottomNav(
        currentIndex: shell.currentIndex,
        // Toucher l'onglet déjà actif revient à sa page de départ.
        onTap: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
      ),
    );
  }
}
