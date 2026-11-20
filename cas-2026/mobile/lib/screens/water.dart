// "Watering" tab: see the water left, water by hand (confirm sheet), follow the order, then success or error.
import 'package:flutter/material.dart';

import '../art.dart';
import '../store.dart';
import '../theme.dart';
import '../ui.dart';
import 'fan.dart';
import 'home.dart';
import 'log.dart';
import 'settings.dart';

Widget modePill(BuildContext context, String eq) {
  final m = st['modes'][eq] as J;
  final manual = m['mode'] == 'manual';
  return InkWell(
    onTap: () => push(context, const WhoPage()),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: manual ? C.bleSoft : C.pousseSoft, borderRadius: leaf(12, 4)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Ic(manual ? 'user' : 'wheel', size: 16, color: manual ? const Color(0xFF6B4A00) : C.forest),
        const SizedBox(width: 6),
        Text(manual ? 'Manual · until ${untilText(m)}' : 'Auto', style: nunito(14, w: FontWeight.w700, color: manual ? const Color(0xFF6B4A00) : C.forest)),
      ]),
    ),
  );
}

class WaterTab extends StatelessWidget {
  const WaterTab({super.key});
  @override
  Widget build(BuildContext context) {
    final s = st['sensors'] as J, a = st['alarms'] as J, ld = st['last_diagnosis'] as J?;
    final busy = st['actuators']['pump'] == true || st['irrigation']['phase'] == 'checking';
    final locked = st['irrigation']['locked'] == true;
    return SafeArea(bottom: false, child: Column(children: [
      Header('Watering', back: false, trailing: modePill(context, 'irrigation')),
      Expanded(child: Pad(scroll: false, children: [
        Row(children: [
          SizedBox(width: 130, child: svg(tankSvg((s['water_level_pct'] as num?)?.toDouble()))),
          const SizedBox(width: 18),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(tankPhrase(st['tank_days'], s['water_level_pct'], a['tank_low'] == true), style: sora(25, height: 1.15)),
            const SizedBox(height: 4),
            Text(s['water_level_pct'] == null ? 'No news from the level sensor' : '${pct(s['water_level_pct'])} % in the tank',
                style: nunito(16, color: C.ink2)),
          ])),
        ]),
        const SizedBox(height: 18),
        Note(ld == null ? const Text('No watering yet.') : Text.rich(TextSpan(children: [
          TextSpan(text: '${dayPhrase(ld['time'])}, '),
          TextSpan(text: '${ld['seconds']} seconds', style: const TextStyle(fontWeight: FontWeight.w800)),
          TextSpan(text: '${ld['manual'] == true ? ' by hand' : ''}: the soil was at ${pct(ld['soil_before_pct'])} %.'),
        ]))),
        if (locked) ...[const SizedBox(height: 12), Note(Text.rich(TextSpan(children: [
          const TextSpan(text: 'The pump is locked after two faulty waterings. Check it, then unlock it in '),
          WidgetSpan(child: GestureDetector(onTap: () => push(context, const SettingsPage()),
              child: Text('Settings', style: nunito(15.5, w: FontWeight.w700, color: C.eau).copyWith(decoration: TextDecoration.underline)))),
          const TextSpan(text: '.'),
        ])), color: C.bleSoft)],
        const Spacer(),
        busy
            ? Btn('Watering in progress…', kind: BtnKind.ghost, icon: 'drop', onTap: () => push(context, const RunPage()))
            : Btn('Water now', icon: 'drop', onTap: a['tank_low'] == true || locked || a['fire'] == true ? null : () => waterSheet(context)),
        LinkText("See this week's waterings", onTap: () => push(context, const Scaffold(body: SafeArea(child: LogView(filter: 'irrigation', back: true))))),
      ])),
    ]));
  }
}

/// "How long?": the durations live here, in a sheet that comes up from the bottom.
Future<void> waterSheet(BuildContext context) async {
  final opts = List<int>.from(st['thresholds']['manual_seconds']);
  var pick = opts.contains(5) ? 5 : opts.first;
  final go = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: C.paper,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
    builder: (c) => StatefulBuilder(builder: (c, set) => Padding(
      padding: EdgeInsets.fromLTRB(24, 12, 24, 22 + MediaQuery.paddingOf(c).bottom),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Center(child: Container(width: 46, height: 5, decoration: BoxDecoration(color: const Color(0xFFD6CCB6), borderRadius: BorderRadius.circular(3)))),
        const SizedBox(height: 16),
        Text('How long?', style: sora(24)),
        const SizedBox(height: 16),
        Row(children: [
          for (final o in opts) Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 5), child: GestureDetector(
            onTap: () => set(() => pick = o),
            child: Container(height: 56, alignment: Alignment.center,
                decoration: BoxDecoration(color: o == pick ? C.pousse : C.chip, borderRadius: leaf(14, 5)),
                child: Text('$o s', style: sora(18, color: o == pick ? C.forest : C.ink2)))))),
        ]),
        const SizedBox(height: 16),
        Btn('Water $pick seconds', icon: 'drop', onTap: () => Navigator.pop(c, true)),
        const SizedBox(height: 10),
        Text('You take over. Back to auto in 1 h.', textAlign: TextAlign.center, style: nunito(14, color: C.ink2)),
        LinkText('Cancel', onTap: () => Navigator.pop(c, false)),
      ]),
    )),
  );
  if (go != true || !context.mounted) return;
  try {
    await store.water(pick);
    if (context.mounted) push(context, const RunPage());
  } on ApiError catch (e) {
    if (context.mounted) toast(context, e.message);
  }
}

/// "I'm starting the watering.": sent, received, the pump starts, the water flows, the soil is checked.
class RunPage extends StatelessWidget {
  const RunPage({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: store, builder: (context, _) {
        final c = st['command'] as J?;
        if (c == null || c['kind'] != 'water') {
          return Scaffold(body: SafeArea(child: Column(children: [const Header('Watering'),
            Pad(children: [Text('No watering in progress.', style: nunito(17, color: C.ink2))])])));
        }
        final s = c['steps'] as J;
        final list = [
          ('sent', 'Order sent', hm(s['sent'])), ('received', 'The greenhouse got it', hm(s['received'])),
          ('running', 'The pump starts…', s['running'] != null ? hm(s['running']) : 'A few seconds'),
          ('checking', 'The water flows', s['checking'] != null ? hm(s['checking']) : 'For ${c['seconds']} seconds'),
          ('done', 'Checking the soil', s['done'] != null ? hm(s['done']) : 'One minute later, tree 3 checks it worked'),
        ];
        final first = list.indexWhere((e) => s[e.$1] == null);
        return Scaffold(body: SafeArea(child: Column(children: [
          const Header('Watering'),
          Expanded(child: Pad(scroll: false, children: [
            Text("I'm starting the watering.", style: sora(30, w: FontWeight.w800, height: 1.12)),
            const SizedBox(height: 6),
            Text('${c['seconds']} seconds, by hand.', style: nunito(17, color: C.ink2)),
            const SizedBox(height: 22),
            Steps([for (var i = 0; i < list.length; i++) (list[i].$2, list[i].$3, s[list[i].$1] != null ? 2 : i == first ? 1 : 0)]),
            const Spacer(),
            if (['sent', 'received', 'running'].contains(c['status']))
              Btn('Stop', kind: BtnKind.outline, onTap: () async {
                try { await store.stopWater(); } on ApiError catch (e) { if (context.mounted) toast(context, e.message); }
              }),
          ])),
        ])));
      });
}

class ResultPage extends StatelessWidget {
  const ResultPage({super.key, required this.command});
  final J command;
  @override
  Widget build(BuildContext context) {
    final c = command, r = c['result'] as J?;
    if (c['status'] == 'success') {
      return Scaffold(backgroundColor: C.pousseSoft, body: SafeArea(child: Pad(scroll: false, children: [
        const SizedBox(height: 20),
        svg(sproutSvg, height: 220),
        const SizedBox(height: 10),
        Text('Watering done.', style: sora(32, w: FontWeight.w800)),
        const SizedBox(height: 10),
        Text('${r!['seconds']} seconds. The soil went up to ${pct(r['soil_after_pct'])} %. The ${crop()} say thank you.', style: nunito(18, color: C.ink2)),
        const Spacer(),
        Btn('Thanks', kind: BtnKind.forest, onTap: () => Navigator.pop(context)),
      ])));
    }
    final title = c['status'] == 'refused' ? 'Not now.' : c['status'] == 'stopped' ? 'Watering stopped.'
        : r?['label'] == 'FUITE' ? 'The water went somewhere else.' : r?['label'] == 'CAPTEUR_DEFAILLANT' ? 'The soil probe is confused.' : "The water didn't flow.";
    return Scaffold(body: SafeArea(child: Pad(scroll: false, children: [
      const SizedBox(height: 20),
      Align(alignment: Alignment.centerLeft, child: svg(valveSvg, width: 120)),
      const SizedBox(height: 16),
      Text(title, style: sora(32, w: FontWeight.w800, height: 1.1)),
      const SizedBox(height: 10),
      Text((c['message'] as String?) ?? '', style: nunito(18, color: C.ink2)),
      const Spacer(),
      if (c['status'] != 'stopped') Btn('Try again', onTap: () async {
        try { await store.water(c['seconds']); if (context.mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RunPage())); }
        on ApiError catch (e) { if (context.mounted) toast(context, e.message); }
      }) else Btn('OK', kind: BtnKind.forest, onTap: () => Navigator.pop(context)),
      LinkText('What else can I do?', onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HelpPage(open: 'valve')))),
    ])));
  }
}
