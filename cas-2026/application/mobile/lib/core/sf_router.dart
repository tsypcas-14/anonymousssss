import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'appel.dart';

import '../features/aeration/aeration_page.dart';
import '../features/alerte/alertes_page.dart';
import '../features/arrosage/arrosage_page.dart';
import '../features/arrosage/en_cours_data.dart';
import '../features/arrosage/en_cours_page.dart';
import '../features/capteurs/air_page.dart';
import '../features/capteurs/capteur_muet_page.dart';
import '../features/capteurs/sol_page.dart';
import '../features/carnet/carnet_page.dart';
import '../features/demo/design_system_demo_page.dart';
import '../features/alerte/flamme_data.dart';
import '../features/alerte/flamme_page.dart';
import '../features/demarrage/bienvenue_page.dart';
import '../features/demarrage/chargement_page.dart';
import '../features/demarrage/connecter_page.dart';
import '../features/fin/erreur_page.dart';
import '../features/fin/fin_data.dart';
import '../features/fin/securite_page.dart';
import '../features/fin/succes_page.dart';
import '../features/hors_ligne/hors_ligne_page.dart';
import '../features/plantes/plantes_page.dart';
import '../features/reglages/aide_page.dart';
import '../features/reglages/contact_flamme.dart';
import '../features/reglages/contact_page.dart';
import '../features/reglages/reglages_data.dart';
import '../features/reglages/reglages_page.dart';
import '../features/reglages/seuils_page.dart';
import '../features/serre/serre_data.dart';
import '../features/serre/serre_page.dart';
import 'widgets/sf_shell.dart';

/// Page de départ : le premier lancement (Chargement, puis Bienvenue, puis Connecter ma serre, puis l'accueil).
/// Pour ouvrir directement un écran, par exemple l'accueil ou la démonstration du design system :
/// `flutter run --dart-define=SF_START=serre` ou `--dart-define=SF_START=demo`
///
/// Seul le dernier segment est retenu (« demo », « /demo » ou « c:/Program Files/Git/demo » donnent « /demo ») :
/// Git Bash sous Windows transforme `/demo` en chemin Windows avant de le passer à Flutter.
const String _departBrut = String.fromEnvironment('SF_START', defaultValue: 'chargement');
final String _depart = '/${_departBrut.split('/').where((s) => s.isNotEmpty).last}';

/// Crée le routeur : une branche par onglet de la barre du bas (l'état de chaque onglet est conservé),
/// plus la démonstration interne du design system, hors de la barre.
/// Chaque application en crée un nouveau : pas d'état partagé entre deux démarrages (ni entre deux tests).
GoRouter creerRouteur({String? depart}) => GoRouter(
  initialLocation: depart ?? _depart,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => SfShell(shell: shell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/serre',
            builder: (c, s) => SerrePage(onLigne: (rang) => _ouvrirLigne(c, rang), onAlertes: () => c.push('/serre/alertes'), onReglages: () => c.push('/serre/reglages')),
            routes: [
              // L'écran Serre quand il y a quelque chose à regarder (en-tête jaune) : la barre du bas reste affichée.
              GoRoute(
                path: 'a-regarder',
                builder: (c, s) => SerrePage(data: SerreData.aRegarder(), onLigne: (rang) => _ouvrirLigne(c, rang), onAlertes: () => c.push('/serre/alertes'), onReglages: () => c.push('/serre/reglages')),
              ),
              // Détail des capteurs : le sol, l'air et la lumière, et l'air quand le capteur ne répond plus.
              GoRoute(
                path: 'alertes',
                builder: (c, s) => AlertesPage(data: AlertesData.exemple(onSol: () => c.push('/serre/sol'), onReservoir: () => c.go('/arrosage')), onRetour: c.pop),
              ),
              GoRoute(
                path: 'reglages',
                builder: (c, s) => ValueListenableBuilder<ContactFlamme>(
                  valueListenable: contactFlamme,
                  builder: (_, contact, _) => ReglagesPage(
                    data: ReglagesData.exemple(contact: contact.nom),
                    onContact: () => c.push('/serre/reglages/contact'),
                    onSeuils: () => c.push('/serre/reglages/seuils'),
                    onAide: () => c.push('/serre/reglages/aide'),
                  ),
                ),
                routes: [
                  GoRoute(path: 'seuils', builder: (c, s) => SeuilsPage(onRetour: c.pop)),
                  GoRoute(path: 'aide', builder: (c, s) => AidePage(onRetour: c.pop)),
                  GoRoute(path: 'contact', builder: (c, s) => ContactPage(onRetour: c.pop, onEnregistre: c.pop)),
                ],
              ),
              GoRoute(path: 'securite', builder: (c, s) => ValueListenableBuilder<ContactFlamme>(
                  valueListenable: contactFlamme,
                  builder: (_, contact, _) => SecuritePage(
                    data: SecuriteData.exemple(contact: contact.nom, numero: contact.numeroMasque),
                    onContact: () => c.push('/serre/reglages/contact'),
                  ),
                ),
              ),
              GoRoute(path: 'plantes', builder: (c, s) => PlantesPage(onRetour: c.pop)),
              GoRoute(path: 'hors-ligne', builder: (c, s) => HorsLignePage(onReessayer: () => c.go('/serre'))),
              GoRoute(path: 'sol', builder: (c, s) => SolPage(onRetour: c.pop)),
              GoRoute(path: 'air', builder: (c, s) => AirPage(onRetour: c.pop)),
              GoRoute(path: 'air-muet', builder: (c, s) => CapteurMuetPage(onRetour: c.pop, onVerifier: () => c.push('/serre/reglages/aide'))),
            ],
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/arrosage',
            // Confirmer la carte « Combien de temps ? » ouvre le suivi de l'arrosage.
            builder: (c, s) => ArrosagePage(
              onArroser: (minutes) => c.push('/arrosage/en-cours?minutes=$minutes'),
              onAlertes: () => c.go('/serre/alertes'),
              onVoirSemaine: () => c.go('/carnet'),
            ),
            routes: [
              GoRoute(
                path: 'en-cours',
                builder: (c, s) => EnCoursPage(
                  data: EnCoursData.manuel(
                    minutes: int.tryParse(s.uri.queryParameters['minutes'] ?? '') ?? 10,
                    heure: _heureActuelle(),
                  ),
                  onRetour: c.pop,
                  onArreter: c.pop, // arrêter l'arrosage revient à l'écran Arrosage
                ),
              ),
            ],
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/aeration',
            builder: (c, s) => AerationPage(
              onAlertes: () => c.go('/serre/alertes'),
              onAerer: (minutes) => c.push('/aeration/en-cours?minutes=$minutes'),
            ),
            routes: [
              GoRoute(
                path: 'en-cours',
                builder: (c, s) => EnCoursPage(
                  data: EnCoursData.aeration(
                    minutes: int.tryParse(s.uri.queryParameters['minutes'] ?? '') ?? 20,
                    heure: _heureActuelle(),
                  ),
                  onRetour: c.pop,
                  onArreter: c.pop, // arrêter l'aération revient à l'écran Aération
                ),
              ),
            ],
          ),
        ]),
        StatefulShellBranch(routes: [GoRoute(path: '/carnet', builder: (c, s) => CarnetPage(onPourquoi: () => c.go('/arrosage')))]),
      ],
    ),
    // Premier lancement : plein écran, hors de la barre du bas. Chargement, puis Bienvenue, puis Connecter ma serre.
    GoRoute(path: '/chargement', builder: (c, s) => ChargementPage(onTermine: () => c.go('/bienvenue'))),
    GoRoute(path: '/bienvenue', builder: (c, s) => BienvenuePage(onConnecter: () => c.push('/connecter'))),
    GoRoute(path: '/connecter', builder: (c, s) => ConnecterPage(onRetour: c.pop, onTermine: () => c.go('/serre'))),
    // Fin d'arrosage : succès ou erreur, plein écran ; « Merci » et « Réessayer » renvoient à Arrosage.
    GoRoute(path: '/succes', builder: (c, s) => SuccesPage(onMerci: () => c.go('/arrosage'))),
    GoRoute(
      path: '/erreur',
      builder: (c, s) => ErreurPage(onReessayer: () => c.go('/arrosage'), onAutre: () => c.go('/serre/reglages/aide')),
    ),
    // Alerte flamme : plein écran, hors de la barre du bas ; « J'ai vu, je vérifie » ramène à l'écran Serre.
    GoRoute(
      path: '/flamme',
      builder: (c, s) => ValueListenableBuilder<ContactFlamme>(
        valueListenable: contactFlamme,
        builder: (_, contact, _) => FlammePage(
          data: FlammeData.exemple(contact: contact.nom),
          onVu: () => c.go('/serre'),
          onAppeler: () => appeler(contact.numero),
        ),
      ),
    ),
    // Raccourcis pour `SF_START` (seul le dernier segment est retenu).
    GoRoute(path: '/a-regarder', redirect: (c, s) => '/serre/a-regarder'),
    GoRoute(path: '/securite', redirect: (c, s) => '/serre/securite'),
    GoRoute(path: '/plantes', redirect: (c, s) => '/serre/plantes'),
    GoRoute(path: '/hors-ligne', redirect: (c, s) => '/serre/hors-ligne'),
    GoRoute(path: '/reglages', redirect: (c, s) => '/serre/reglages'),
    GoRoute(path: '/aide', redirect: (c, s) => '/serre/reglages/aide'),
    GoRoute(path: '/seuils', redirect: (c, s) => '/serre/reglages/seuils'),
    GoRoute(path: '/alertes', redirect: (c, s) => '/serre/alertes'),
    GoRoute(path: '/sol', redirect: (c, s) => '/serre/sol'),
    GoRoute(path: '/air', redirect: (c, s) => '/serre/air'),
    GoRoute(path: '/air-muet', redirect: (c, s) => '/serre/air-muet'),
    GoRoute(path: '/demo', builder: (c, s) => const DesignSystemDemoPage()),
  ],
);

/// Détail d'une ligne de l'écran Serre : 0 le sol, 1 le réservoir (onglet Arrosage), 2 l'air et la lumière, 3 la sécurité, 4 la santé des
/// plantes (les autres écrans viennent ensuite).
void _ouvrirLigne(BuildContext c, int rang) {
  if (rang == 0) c.push('/serre/sol');
  if (rang == 1) c.go('/arrosage');
  if (rang == 2) c.push('/serre/air');
  if (rang == 3) c.push('/serre/securite');
  if (rang == 4) c.push('/serre/plantes');
}

/// Heure du téléphone au format « 14:34 ».
String _heureActuelle() {
  final now = DateTime.now();
  return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
}
