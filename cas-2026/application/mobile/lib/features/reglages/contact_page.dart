import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/sf_colors.dart';
import '../../core/sf_icons.dart';
import '../../core/sf_radius.dart';
import '../../core/sf_text.dart';
import '../../core/widgets/sf_button.dart';
import '../../core/widgets/sf_icon_button.dart';
import 'contact_flamme.dart';

/// Écran « Contact en cas de flamme » : le nom et le numéro de la personne prévenue par SMS. Cet écran n'est pas dans le
/// design v2 : il reprend ses composants (flèche de retour, titre, champs beiges à coins en feuille, bouton vert).
class ContactPage extends StatefulWidget {
  const ContactPage({super.key, this.onRetour, this.onEnregistre});

  final VoidCallback? onRetour;

  /// Appelé quand le contact est enregistré.
  final VoidCallback? onEnregistre;

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  late final TextEditingController _nom = TextEditingController(text: contactFlamme.value.nom);
  late final TextEditingController _numero = TextEditingController(text: contactFlamme.value.numero);
  bool _erreur = false;

  @override
  void dispose() {
    _nom.dispose();
    _numero.dispose();
    super.dispose();
  }

  void _enregistrer() {
    final nom = _nom.text.trim();
    if (nom.isEmpty || !numeroValide(_numero.text)) {
      setState(() => _erreur = true);
      return;
    }
    contactFlamme.value = ContactFlamme(nom: nom, numero: _numero.text.trim());
    widget.onEnregistre?.call();
  }

  @override
  Widget build(BuildContext context) {
    final haut = math.max(0.0, MediaQuery.paddingOf(context).top - 34);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Material(
        color: SfColors.kraft,
        child: ListView(
          padding: EdgeInsets.fromLTRB(24, 40 + haut, 24, 24),
          children: [
            Row(children: [
              Transform.translate(
                offset: const Offset(-12.6, 0),
                child: SfIconButton(icon: SfIcons.retour, color: SfColors.foret, label: 'Retour', onTap: widget.onRetour),
              ),
              Expanded(
                child: Transform.translate(
                  offset: const Offset(-12.6, 0),
                  child: Text('Contact en cas de flamme', style: SfText.titreEcran, maxLines: 1, overflow: TextOverflow.fade, softWrap: false),
                ),
              ),
            ]),
            const SizedBox(height: 16),
            Text('Cette personne reçoit un SMS dès qu\'une flamme est détectée, même si l\'appli est fermée.',
                style: SfText.corps17.copyWith(height: 24.3 / 17)),
            const SizedBox(height: 28),
            Text('NOM', style: SfText.etiquetteCaps),
            const SizedBox(height: 8),
            _Champ(controleur: _nom, indice: 'Responsable', clavier: TextInputType.name),
            const SizedBox(height: 24),
            Text('NUMÉRO DE TÉLÉPHONE', style: SfText.etiquetteCaps),
            const SizedBox(height: 8),
            _Champ(controleur: _numero, indice: '+216 00 000 000', clavier: TextInputType.phone),
            if (_erreur) ...[
              const SizedBox(height: 12),
              Text('Entrez un nom et un numéro valide.', style: SfText.note.copyWith(color: SfColors.flammeTrait)),
            ],
            const SizedBox(height: 32),
            SfButton(label: 'Enregistrer', variant: SfButtonVariant.foret, onPressed: _enregistrer),
          ],
        ),
      ),
    );
  }
}

/// Champ de saisie beige (coins en feuille 18/6), texte Nunito Bold 17.
class _Champ extends StatelessWidget {
  const _Champ({required this.controleur, required this.indice, required this.clavier});

  final TextEditingController controleur;
  final String indice;
  final TextInputType clavier;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(color: SfColors.kraftFonce, borderRadius: SfRadius.feuille(18, 6)),
      alignment: Alignment.centerLeft,
      child: TextField(
        controller: controleur,
        keyboardType: clavier,
        cursorColor: SfColors.foret,
        style: SfText.puceLabel,
        decoration: InputDecoration(
          border: InputBorder.none,
          isCollapsed: true,
          hintText: indice,
          hintStyle: SfText.puceLabel.copyWith(color: SfColors.grisDoux),
        ),
      ),
    );
  }
}
