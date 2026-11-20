// Settings (behind the wheel), what the greenhouse watches, help, and the dashboard pages served by the Pi.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../art.dart';
import '../store.dart';
import '../theme.dart';
import '../ui.dart';
import 'fan.dart';
import 'home.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: store, builder: (context, _) {
        final u = (store.me?['user'] as J?) ?? {}, g = (store.me?['greenhouse'] as J?) ?? {};
        final notify = u['notify'] ?? 'important';
        Widget radio(String v, String t, String sub) => InkWell(
              onTap: () => _run(context, () => store.saveMe(notify: v), 'Saved.'),
              child: Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(notify == v ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: C.forest, size: 28),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(t, style: sora(18, color: C.forest)), Text(sub, style: nunito(15, color: C.ink2))])),
              ])));
        return Scaffold(body: SafeArea(child: Column(children: [
          const Header('Settings'),
          Expanded(child: Pad(children: [
            const Caps('Notify me'),
            radio('important', 'The important things', 'The rest goes into the log.'),
            radio('all', 'Everything', 'Finished waterings too.'),
            Row(children: [const Ic('flame', size: 18, color: C.flame), const SizedBox(width: 6),
              Text('The flame alert cannot be turned off.', style: nunito(14, color: C.ink2))]),
            if (store.st?['irrigation']['locked'] == true) ...[const SizedBox(height: 12), Note(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('The pump is locked: two faulty waterings in a row. Once you have checked the pump and the pipe:'),
              const SizedBox(height: 10),
              Btn('Unlock the pump', kind: BtnKind.forest, onTap: () => _run(context, store.unlock, 'Pump unlocked.')),
            ]), color: C.bleSoft)],
            LineRow(icon: 'contact', title: 'Contact in case of flame', sub: (g['contact_name'] as String?)?.isNotEmpty == true ? g['contact_name'] : 'Not set',
                onTap: () => _edit(context, 'Contact in case of flame', [('contact_name', 'Name', g['contact_name']), ('contact_phone', 'Phone', g['contact_phone'])],
                    (v) => store.saveGreenhouse(v))),
            LineRow(icon: 'soil', title: 'What the greenhouse watches', sub: 'The thresholds', onTap: () => push(context, const ThresholdsPage())),
            LineRow(icon: 'wheel', title: 'Who decides?', sub: 'Automatic or by hand, per equipment', onTap: () => push(context, const WhoPage())),
            LineRow(icon: 'help', title: 'Help', sub: 'If something goes wrong', onTap: () => push(context, const HelpPage())),
            const Caps('The dashboard'),
            LineRow(icon: 'cube', title: 'The greenhouse in 3D', sub: 'Every sensor, live', onTap: () => push(context, const DashboardPage(view: '3d', title: 'The greenhouse in 3D'))),
            LineRow(icon: 'chart', title: 'Statistics', sub: 'Waterings, water, fan, 7 days', onTap: () => push(context, const DashboardPage(view: 'stats', title: 'Statistics'))),
            LineRow(icon: 'ai', title: 'How the AI decides', sub: 'The 3 decision trees, live', onTap: () => push(context, const DashboardPage(view: 'ai', title: 'How the AI decides'))),
            if (store.st?['simulated'] == true)
              LineRow(icon: 'lab', title: 'Simulation lab', sub: 'Speed up time, create a problem', onTap: () => push(context, const DashboardPage(view: 'lab', title: 'Simulation lab'))),
            const Caps('Account'),
            LineRow(icon: 'user', title: u['name'] ?? '', sub: u['email'] ?? '',
                onTap: () => _edit(context, 'Your first name', [('name', 'First name', u['name'])], (v) => store.saveMe(name: v['name']))),
            LineRow(icon: 'greenhouse', title: g['name'] ?? '', sub: 'Growing ${g['crop'] ?? ''} · code ${store.me?['code'] ?? ''}',
                onTap: () => _edit(context, 'The greenhouse', [('name', 'Name of the greenhouse', g['name']), ('crop', 'What grows in it', g['crop'])],
                    (v) => store.saveGreenhouse(v))),
            LineRow(icon: 'link', title: 'Address of the greenhouse', sub: store.base.replaceFirst(RegExp(r'^https?://'), ''), last: true),
            const SizedBox(height: 16),
            Btn('Sign out', kind: BtnKind.outline, onTap: () async { await store.signout(); if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst); }),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('SmartFarm 1.0', style: nunito(15, color: C.ink2)), Text(g['name'] ?? '', style: nunito(15, color: C.ink2))]),
          ])),
        ])));
      });
}

Future<void> _run(BuildContext context, Future<dynamic> Function() f, String ok) async {
  try { await f(); if (context.mounted) toast(context, ok); } on ApiError catch (e) { if (context.mounted) toast(context, e.message); }
}

Future<void> _edit(BuildContext context, String title, List<(String key, String label, dynamic value)> fields, Future<void> Function(J) save) async {
  final ctrls = {for (final f in fields) f.$1: TextEditingController(text: (f.$3 ?? '').toString())};
  await showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: C.paper,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      builder: (c) => Padding(padding: EdgeInsets.fromLTRB(24, 18, 24, 22 + MediaQuery.viewInsetsOf(c).bottom),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(title, style: sora(22)),
            const SizedBox(height: 14),
            for (final f in fields) ...[
              Text(f.$2, style: nunito(16, w: FontWeight.w700, color: C.forest)), const SizedBox(height: 6),
              TextField(controller: ctrls[f.$1], keyboardType: f.$1.contains('phone') ? TextInputType.phone : TextInputType.text),
              const SizedBox(height: 12),
            ],
            Btn('Save', kind: BtnKind.forest, onTap: () async {
              try { await save({for (final e in ctrls.entries) e.key: e.value.text.trim()}); if (c.mounted) Navigator.pop(c); if (context.mounted) toast(context, 'Saved.'); }
              on ApiError catch (e) { if (context.mounted) toast(context, e.message); }
            }),
          ])));
}

class ThresholdsPage extends StatelessWidget {
  const ThresholdsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final t = st['thresholds'] as J;
    Widget r(String v, String txt) => Container(padding: const EdgeInsets.symmetric(vertical: 14), decoration: const BoxDecoration(border: DashedBottom()),
        child: Row(children: [SizedBox(width: 112, child: Text(v, style: sora(30, w: FontWeight.w800, color: C.forest))),
          const SizedBox(width: 14), Expanded(child: Text(txt, style: nunito(17, w: FontWeight.w600)))]));
    return Scaffold(body: SafeArea(child: Column(children: [
      const Header('What the greenhouse watches'),
      Expanded(child: Pad(children: [
        r('${t['water_pct']} %', 'Below about ${t['water_pct']} % moisture, the greenhouse waters (earlier when it is hot).'),
        r('${t['fan_temp']} °C', 'Above ${t['fan_temp']} °C, it ventilates.'),
        r('90 %', 'Above 90 % air humidity, it ventilates against mould.'),
        r('${t['tank_watch_pct']} %', 'Below ${t['tank_watch_pct']} % of water in the tank, it warns you.'),
        r('0 %', 'Tank empty: the pump never runs dry.'),
        const SizedBox(height: 16),
        Note(Text("These are starting values, learned from an agronomist's rules for ${crop()}. We will adjust them with the greenhouse's experience."),
            color: C.bleSoft),
      ])),
    ])));
  }
}

class HelpPage extends StatelessWidget {
  const HelpPage({super.key, this.open});
  final String? open;
  static const q = [
    ('offline', "I can't see the greenhouse anymore", "Check that this phone is on the greenhouse's Wi-Fi, and that the Raspberry Pi is powered (its green light blinks). The greenhouse keeps working on its own meanwhile."),
    ('valve', "The water doesn't flow", 'Look at the pipe from the tank to the pots: is it bent, or out of the water? Is the pump plugged into its relay? After two faulty waterings the pump locks itself: unlock it in Settings once it is fixed.'),
    ('flame', 'A flame is detected', 'The buzzer sounds and the pump and fan are cut at once. Go and look. If it is a false alarm (strong sunlight on the sensor), the alarm stops by itself when the sensor is clear.'),
    ('sensor', 'A sensor stopped answering', 'Check its wires. Soil probe: on the Arduino, itself plugged into the Pi by USB. Air sensor (DHT22): on the Pi. Until it answers again, the greenhouse does not water: it never waters blind.'),
  ];
  @override
  Widget build(BuildContext context) => Scaffold(body: SafeArea(child: Column(children: [
        const Header('Help'),
        Expanded(child: Pad(children: [
          for (final (k, t, a) in q) Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: Container(decoration: const BoxDecoration(border: DashedBottom()), child: ExpansionTile(
              initiallyExpanded: open == k, tilePadding: EdgeInsets.zero, childrenPadding: const EdgeInsets.only(bottom: 14),
              iconColor: C.ink2, collapsedIconColor: C.ink2, title: Text(t, style: sora(18)),
              expandedAlignment: Alignment.centerLeft,
              children: [Text(a, style: nunito(16, color: C.ink2))])),
          ),
        ])),
      ])));
}

/// The rich dashboard of the Pi (3D greenhouse, statistics, AI, lab), shown inside the app.
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, required this.view, required this.title});
  final String view, title;
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  WebViewController? _c;
  String get _url => '${store.base}/?token=${Uri.encodeComponent(store.token ?? '')}&embed=1#/${widget.view}';

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _c = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(C.kraft)
        ..loadRequest(Uri.parse(_url));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(body: SafeArea(child: Column(children: [
        Header(widget.title),
        Expanded(child: _c != null ? WebViewWidget(controller: _c!) : Pad(children: [
          Text('Open the dashboard in the browser:', style: nunito(17)),
          const SizedBox(height: 12),
          Btn('Open ${widget.title.toLowerCase()}', onTap: () => launchUrl(Uri.parse(_url))),
        ])),
      ])));
}
