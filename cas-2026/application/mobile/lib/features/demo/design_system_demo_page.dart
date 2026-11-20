import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/sf_colors.dart';
import '../../core/sf_icon.dart';
import '../../core/sf_icons.dart';
import '../../core/sf_text.dart';
import '../../core/widgets/sf_bottom_nav.dart';
import '../../core/widgets/sf_button.dart';
import '../../core/widgets/sf_confirm_sheet.dart';
import '../../core/widgets/sf_data_row.dart';
import '../../core/widgets/sf_state_badge.dart';

/// Écran de démonstration INTERNE du design system (Phase 1) : tous les composants réunis pour
/// les comparer aux maquettes du design v2. Ce n'est pas un écran de l'application.
/// Ouvrir avec : `flutter run --dart-define=SF_START=demo`
class DesignSystemDemoPage extends StatefulWidget {
  const DesignSystemDemoPage({super.key});

  @override
  State<DesignSystemDemoPage> createState() => _DesignSystemDemoPageState();
}

class _DesignSystemDemoPageState extends State<DesignSystemDemoPage> {
  int _onglet = 1;
  int _duree = 1;
  static const _durees = ['5 min', '10 min', '15 min'];

  Future<void> _ouvrirFeuille() {
    var choix = _duree;
    return showSfConfirmSheet<void>(
      context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => SfConfirmSheet(
          title: 'Combien de temps ?',
          choices: _durees,
          selectedIndex: choix,
          onChoice: (i) {
            setLocal(() => choix = i);
            setState(() => _duree = i);
          },
          confirmLabel: 'Arroser ${_durees[choix].replaceFirst(' min', ' minutes')}',
          confirmIcon: SfIcons.arrosage,
          note: 'Vous prenez la main. Retour en auto dans 1 h.',
          onConfirm: () => Navigator.of(context).pop(),
          onCancel: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: SfBottomNav(currentIndex: _onglet, onTap: (i) => setState(() => _onglet = i)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            _padded(Text('Design system', style: SfText.titreEcran)),
            _padded(Text('Démonstration interne · à comparer au design v2', style: SfText.note)),
            _section('Écrans et états'),
            _padded(Column(children: [
              SfButton(label: 'Serre : tout va bien', variant: SfButtonVariant.contour, onPressed: () => context.go('/serre')),
              const SizedBox(height: 12),
              SfButton(label: 'Serre : à regarder', variant: SfButtonVariant.contour, onPressed: () => context.go('/serre/a-regarder')),
              const SizedBox(height: 12),
              SfButton(label: 'Alerte flamme', variant: SfButtonVariant.contour, onPressed: () => context.go('/flamme')),
              const SizedBox(height: 12),
              SfButton(label: 'Capteur : le sol', variant: SfButtonVariant.contour, onPressed: () => context.go('/serre/sol')),
              const SizedBox(height: 12),
              SfButton(label: "Capteur : l'air et la lumière", variant: SfButtonVariant.contour, onPressed: () => context.go('/serre/air')),
              const SizedBox(height: 12),
              SfButton(label: 'Alertes', variant: SfButtonVariant.contour, onPressed: () => context.go('/serre/alertes')),
              const SizedBox(height: 12),
              SfButton(label: 'Réglages', variant: SfButtonVariant.contour, onPressed: () => context.go('/serre/reglages')),
              const SizedBox(height: 12),
              SfButton(label: 'Ce que la serre surveille', variant: SfButtonVariant.contour, onPressed: () => context.go('/serre/reglages/seuils')),
              const SizedBox(height: 12),
              SfButton(label: 'Santé des plantes', variant: SfButtonVariant.contour, onPressed: () => context.go('/serre/plantes')),
              const SizedBox(height: 12),
              SfButton(label: 'Hors ligne', variant: SfButtonVariant.contour, onPressed: () => context.go('/serre/hors-ligne')),
              const SizedBox(height: 12),
              SfButton(label: 'Aide', variant: SfButtonVariant.contour, onPressed: () => context.go('/serre/reglages/aide')),
              const SizedBox(height: 12),
              SfButton(label: 'Premier lancement : chargement', variant: SfButtonVariant.contour, onPressed: () => context.go('/chargement')),
              const SizedBox(height: 12),
              SfButton(label: 'Premier lancement : bienvenue', variant: SfButtonVariant.contour, onPressed: () => context.go('/bienvenue')),
              const SizedBox(height: 12),
              SfButton(label: 'Premier lancement : connecter', variant: SfButtonVariant.contour, onPressed: () => context.go('/connecter')),
              const SizedBox(height: 12),
              SfButton(label: 'Succès : arrosage terminé', variant: SfButtonVariant.contour, onPressed: () => context.go('/succes')),
              const SizedBox(height: 12),
              SfButton(label: "Erreur : la vanne ne s'ouvre pas", variant: SfButtonVariant.contour, onPressed: () => context.go('/erreur')),
              const SizedBox(height: 12),
              SfButton(label: 'Sécurité', variant: SfButtonVariant.contour, onPressed: () => context.go('/serre/securite')),
              const SizedBox(height: 12),
              SfButton(label: 'Capteur muet', variant: SfButtonVariant.contour, onPressed: () => context.go('/serre/air-muet')),
            ])),
            _section('Palette'),
            _padded(const _Palette()),
            _section('Typographie'),
            _padded(const _Typo()),
            _section('Icônes (tracés du design)'),
            _padded(const _Icones()),
            _section('Boutons'),
            _padded(Column(children: [
              SfButton(label: 'Arroser maintenant', icon: SfIcons.arrosage, onPressed: () {}),
              const SizedBox(height: 12),
              SfButton(label: 'Réessayer', onPressed: () {}),
              const SizedBox(height: 12),
              SfButton(label: 'Merci', variant: SfButtonVariant.foret, onPressed: () {}),
              const SizedBox(height: 12),
              SfButton(label: 'Arrêter', variant: SfButtonVariant.contour, onPressed: () {}),
              const SizedBox(height: 12),
              SfButton(label: 'Indisponible', onPressed: null),
              const SizedBox(height: 4),
              SfLink(label: 'Voir les arrosages de la semaine', onPressed: () {}),
            ])),
            _section('Lignes de donnée'),
            SfDataRow(icon: SfIcons.sol, iconColor: SfColors.terre, title: 'Le sol', subtitle: 'Assez humide', value: '37 %', onTap: () {}),
            SfDataRow(icon: SfIcons.reservoir, iconColor: SfColors.eau, title: 'Le réservoir', subtitle: 'Eau pour 2 jours et demi', value: '41 %', onTap: () {}),
            SfDataRow(icon: SfIcons.air, iconColor: SfColors.ambreFonce, title: "L'air et la lumière", subtitle: 'Il fait 26 °C, ciel voilé', onTap: () {}),
            SfDataRow(icon: SfIcons.securite, iconColor: SfColors.flammeTrait, title: 'Sécurité', subtitle: 'Pas de flamme', onTap: () {}),
            SfDataRow(icon: SfIcons.plantes, iconColor: SfColors.grisDoux, title: 'Santé des plantes', subtitle: 'Bientôt', muted: true, onTap: () {}),
            SfDataRow(icon: SfIcons.sol, iconColor: SfColors.terre, title: 'Le sol', subtitle: 'Un peu sec', value: '27 %', state: SfState.warning, onTap: () {}),
            SfDataRow(icon: SfIcons.reservoir, iconColor: SfColors.eau, title: 'Le réservoir', subtitle: 'Bientôt bas', value: '19 %', state: SfState.warning, onTap: () {}),
            SfDataRow(icon: SfIcons.reservoir, iconColor: SfColors.eau, title: 'Le réservoir', subtitle: 'Vide', value: '0 %', state: SfState.critical, showSeparator: false, onTap: () {}),
            _section('Badges d’état'),
            _padded(const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SfStateBadge(state: SfState.normal, label: 'Tout va bien'),
              SfStateBadge(state: SfState.warning, label: 'Un peu sec'),
              SfStateBadge(state: SfState.critical, label: 'Réservoir vide'),
            ])),
            _section('Carte de confirmation'),
            _padded(Text('Choix actuel : ${_durees[_duree]}', style: SfText.sousTitre)),
            const SizedBox(height: 12),
            _padded(SfButton(label: 'Ouvrir la carte', variant: SfButtonVariant.contour, onPressed: _ouvrirFeuille)),
            _section('Barre du bas'),
            _padded(Text('Collée en bas de cet écran : touchez un onglet.', style: SfText.sousTitre)),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _padded(Widget child) => Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: child);

  Widget _section(String titre) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
        child: Text(titre.toUpperCase(), style: SfText.etiquetteCaps),
      );
}

class _Palette extends StatelessWidget {
  const _Palette();

  static const _couleurs = <(String, Color)>[
    ('forêt', SfColors.foret),
    ('pousse', SfColors.pousse),
    ('blé', SfColors.ble),
    ('kraft', SfColors.kraft),
    ('eau', SfColors.eau),
    ('terre', SfColors.terre),
    ('encre', SfColors.encre),
    ('texte doux', SfColors.texteDoux),
    ('sillon', SfColors.sillon),
    ('kraft foncé', SfColors.kraftFonce),
    ('ambre', SfColors.ambre),
    ('flamme', SfColors.flamme),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 10, runSpacing: 12, children: [
      for (final (nom, c) in _couleurs)
        SizedBox(
          width: 94,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              height: 44,
              decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(8), border: Border.all(color: SfColors.sillon)),
            ),
            const SizedBox(height: 4),
            Text(nom, style: SfText.sousTitre.copyWith(fontSize: 13, fontWeight: FontWeight.w700)),
            Text('#${c.toARGB32().toRadixString(16).substring(2).toUpperCase()}', style: SfText.note.copyWith(fontSize: 12)),
          ]),
        ),
    ]);
  }
}

class _Typo extends StatelessWidget {
  const _Typo();

  @override
  Widget build(BuildContext context) {
    final lignes = <(String, TextStyle)>[
      ('Sora Bold 33 · Vos tomates vont bien.', SfText.hero33.copyWith(color: SfColors.foret)),
      ('Sora Bold 24 · Eau pour 2 jours', SfText.titre24),
      ('Sora Bold 22 · Arrosage', SfText.titreEcran),
      ('Sora ExtraBold 18 · Arroser maintenant', SfText.bouton),
      ('Sora Bold 16 · 37 %', SfText.valeur),
      ('Nunito Bold 18 · Le réservoir', SfText.titreLigne),
      ('Nunito Bold 17 · 10 min', SfText.puceLabel),
      ('Nunito SemiBold 15 · Assez humide', SfText.sousTitre),
      ('Nunito SemiBold 14,5 · La serre décide seule.', SfText.note),
      ('Nunito Bold 13 · Arrosage', SfText.etiquetteOnglet),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (final (texte, style) in lignes) Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(texte, style: style)),
    ]);
  }
}

class _Icones extends StatelessWidget {
  const _Icones();

  @override
  Widget build(BuildContext context) {
    final icones = <(String, SfIconData, Color)>[
      ('serre', SfIcons.serre, SfColors.texteDoux),
      ('arrosage', SfIcons.arrosage, SfColors.foret),
      ('aération', SfIcons.aeration, SfColors.texteDoux),
      ('carnet', SfIcons.carnet, SfColors.texteDoux),
      ('sol', SfIcons.sol, SfColors.terre),
      ('réservoir', SfIcons.reservoir, SfColors.eau),
      ('air', SfIcons.air, SfColors.ambreFonce),
      ('sécurité', SfIcons.securite, SfColors.flammeTrait),
      ('plantes', SfIcons.plantes, SfColors.grisDoux),
      ('alerte', SfIcons.alerte, SfColors.ambre),
    ];
    return Wrap(spacing: 18, runSpacing: 14, children: [
      for (final (nom, data, c) in icones)
        SizedBox(
          width: 64,
          child: Column(children: [
            SizedBox(height: 28, child: Center(child: SfIcon(data, color: c))),
            const SizedBox(height: 4),
            Text(nom, style: SfText.note.copyWith(fontSize: 12)),
          ]),
        ),
    ]);
  }
}
