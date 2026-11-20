// "Ventilation" tab, and "Who decides?" (automatic or by hand, per equipment).
import 'package:flutter/material.dart';

import '../art.dart';
import '../store.dart';
import '../theme.dart';
import '../ui.dart';
import 'home.dart';
import 'water.dart';

class FanTab extends StatelessWidget {
  const FanTab({super.key});
  @override
  Widget build(BuildContext context) {
    final on = st['actuators']['fan'] == true;
    final runs = List<J>.from(st['fan_runs_today']);
    String run(J r) => r['end'] == null ? 'since ${hm(r['start'])}' : 'from ${hm(r['start'])} to ${hm(r['end'])}';
    final maxT = runs.isEmpty ? 0 : runs.map((r) => (r['max_temp'] as num?) ?? 0).reduce((a, b) => a > b ? a : b);
    final shown = runs.length > 2 ? runs.sublist(runs.length - 2) : runs;
    return SafeArea(bottom: false, child: Column(children: [
      Header('Ventilation', back: false, trailing: modePill(context, 'fan')),
      Expanded(child: Pad(scroll: false, children: [
        Row(children: [
          FanArt(on: on),
          const SizedBox(width: 18),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(on ? 'Fan running' : 'Fan stopped', style: sora(25, height: 1.15)),
            const SizedBox(height: 4),
            Text('It starts above ${st['thresholds']['fan_temp']} °C, or when the air is too damp.', style: nunito(16, color: C.ink2)),
          ])),
        ]),
        const SizedBox(height: 18),
        Note(Text(runs.isEmpty ? 'It has not run today.'
            : 'Today it ran ${shown.map(run).join(', then ')}. The air reached ${maxT.toStringAsFixed(1)} °C.')),
        const Spacer(),
        Btn(on ? 'Stop the fan' : 'Ventilate now', icon: 'fan', onTap: st['alarms']['fire'] == true ? null : () async {
          try {
            await store.fan(!on);
            if (context.mounted) toast(context, on ? 'The fan stops. Automatic again in 1 hour.' : 'The fan starts. Automatic again in 1 hour.');
          } on ApiError catch (e) { if (context.mounted) toast(context, e.message); }
        }),
        LinkText('Who decides: the greenhouse or me?', onTap: () => push(context, const WhoPage())),
      ])),
    ]));
  }
}

class WhoPage extends StatelessWidget {
  const WhoPage({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: store, builder: (context, _) {
        Widget block(String eq, String icon, String title, String autoText) {
          final m = st['modes'][eq] as J, manual = m['mode'] == 'manual';
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Ic(icon, color: C.eau), const SizedBox(width: 10), Text(title, style: sora(22))]),
            const SizedBox(height: 10),
            Seg2(left: 'The greenhouse decides', right: 'I decide', rightOn: manual, onChanged: (v) async {
              try {
                await store.mode(eq, v ? 'manual' : 'auto');
                if (context.mounted) toast(context, v ? 'You decide for the next hour.' : 'The greenhouse decides again.');
              } on ApiError catch (e) { if (context.mounted) toast(context, e.message); }
            }),
            const SizedBox(height: 10),
            Text(manual ? '${m['by'] ?? 'You'} took over at ${hm(m['since'])}. Back to auto at ${untilText(m)} if nobody touches it.' : autoText,
                style: nunito(16, color: C.ink2)),
          ]);
        }
        return Scaffold(body: SafeArea(child: Column(children: [
          const Header('Who decides?'),
          Expanded(child: Pad(scroll: false, children: [
            Text('For each piece of equipment, you choose.', style: nunito(18, color: C.ink2)),
            const SizedBox(height: 20),
            block('irrigation', 'drop', 'Watering', 'It waters when the soil is dry.'),
            Container(margin: const EdgeInsets.symmetric(vertical: 16), height: 2, decoration: const BoxDecoration(border: DashedBottom())),
            block('fan', 'fan', 'Ventilation', 'It ventilates above ${st['thresholds']['fan_temp']} °C or in damp air.'),
            const Spacer(),
            Row(children: [const Ic('flame', size: 18, color: C.flame), const SizedBox(width: 6),
              Expanded(child: Text('The flame alert stays active in every case.', style: nunito(14, color: C.ink2)))]),
          ])),
        ])));
      });
}
