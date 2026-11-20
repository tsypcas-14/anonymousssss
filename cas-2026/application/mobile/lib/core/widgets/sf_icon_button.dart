import 'package:flutter/material.dart';

import '../sf_icon.dart';
import '../sf_icons.dart';

/// Bouton-icône : l'icône du design (case de 24 dp) dans une zone tactile de 48 dp, avec libellé d'accessibilité.
/// Sert à la cloche (alertes) et au volant (réglages) des écrans.
class SfIconButton extends StatelessWidget {
  const SfIconButton({super.key, required this.icon, required this.color, required this.label, this.onTap});

  final SfIconData icon;
  final Color color;
  final String label;
  final VoidCallback? onTap;

  static const double zone = 48;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(width: zone, height: zone, child: Center(child: SfIcon(icon, color: color))),
      ),
    );
  }
}
