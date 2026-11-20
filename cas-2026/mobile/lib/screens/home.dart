// "Greenhouse" tab: the home (one title, five lines) and the pages behind its lines.
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../art.dart';
import '../store.dart';
import '../theme.dart';
import '../ui.dart';
import 'settings.dart';
import 'water.dart';

void push(BuildContext c, Widget page) => Navigator.push(c, MaterialPageRoute(builder: (_) => page));

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});
  @override
  Widget build(BuildContext context) {
    final s = st['sensors'] as J, a = st['alarms'] as J, ir = st['irrigation'] as J, th = st['thresholds'] as J;
    final watering = st['actuators']['pump'] == true || ir['phase'] == 'checking';
    final soilRaw = s['soil_raw'] as num?, tankPct = s['water_level_pct'] as num?;
    final dry = soilRaw != null && soilRaw > (th['water_raw'] as num);
    final c = crop();
    var good = false;
    (String, String, String) t;
    if (a['missing'] == true) { t = ('A sensor ', 'stopped', ' answering.'); }
    else if (a['pump_locked'] == true) { t = ('The pump needs a ', 'check', '.'); }
    else if (a['tank_low'] == true) { t = ('The tank is ', 'empty', '.'); }
    else if (watering && dry) { t = ('The $c are ', 'thirsty', ". I'm watering."); }
    else if (watering) { t = ('', 'Watering', ' the $c.'); }
    else if (dry) { t = ('The $c are ', 'thirsty', '.'); }
    else if (tankPct != null && tankPct < (th['tank_watch_pct'] as num)) { t = ('The tank is getting ', 'low', '.'); }
    else { good = true; t = ('Your $c are doing ', 'well', '.'); }
    final fg = good ? Colors.white : C.ink;
    final manual = (st['modes'] as J).entries.where((e) => e.value['mode'] == 'manual').map((e) => e.key == 'fan' ? 'ventilation' : 'watering').toList();
    final alerts = (st['alerts'] as List).isNotEmpty;

    return ListView(padding: EdgeInsets.zero, children: [
      Container(
        color: good ? C.forest : C.ble,
        padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(longDate(nowOf()), style: nunito(15, w: FontWeight.w700, color: fg))),
              IconButton(onPressed: () => push(context, const AlertsPage()), icon: Stack(clipBehavior: Clip.none, children: [
                Ic('bell', color: fg),
                if (alerts) Positioned(right: -3, top: -3, child: Container(width: 10, height: 10,
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: fg, width: 2)))),
              ])),
              IconButton(onPressed: () => push(context, const SettingsPage()), icon: Ic('wheel', color: fg)),
            ]),
            const SizedBox(height: 16),
            Text(greeting(), style: nunito(16, w: FontWeight.w700, color: fg)),
            const SizedBox(height: 4),
            underlined(t.$1, t.$2, t.$3, sora(32, w: FontWeight.w800, color: fg, height: 1.12), line: good ? C.pousse : C.terre),
            const SizedBox(height: 8),
            Text('${house()} · ${watering ? 'watering now' : agoText()}', style: nunito(15, color: fg.withValues(alpha: .9))),
          ])),
          SizedBox(height: 150, width: double.infinity, child: svg(landscape(!good), fit: BoxFit.fill)),
        ]),
      ),
      Padding(padding: const EdgeInsets.fromLTRB(24, 6, 24, 0), child: Column(children: [
        LineRow(icon: 'soil', title: 'The soil', sub: soilRaw == null ? 'No news from the sensor' : soilWord(soilRaw),
            value: s['soil_pct'] == null ? '–' : '${pct(s['soil_pct'])} %', warn: dry, onTap: () => push(context, const SoilPage())),
        LineRow(icon: 'tank', iconColor: C.eau, title: 'The tank', sub: tankPhrase(st['tank_days'], tankPct, a['tank_low'] == true),
            value: tankPct == null ? '–' : '${pct(tankPct)} %', warn: a['tank_low'] == true || (tankPct ?? 100) < (th['tank_watch_pct'] as num),
            onTap: () => store.tabs.value = 1),
        LineRow(icon: 'thermo', iconColor: const Color(0xFFB5731C), title: 'The air and the light',
            sub: s['air_temp'] == null ? 'No news from the sensor' : 'It is ${pct(s['air_temp'])} °C, ${lightWord(s['light'])}',
            onTap: () => push(context, const AirPage())),
        LineRow(icon: 'flame', iconColor: C.flame, title: 'Safety', sub: a['fire'] == true ? 'A flame is detected!' : 'No flame',
            warn: a['fire'] == true, onTap: () => push(context, const SafetyPage())),
        LineRow(icon: 'leafSearch', title: 'Plant health', sub: 'Coming soon', muted: true, onTap: () => push(context, const PlantsPage())),
        LineRow(icon: 'cube', iconColor: C.forest, title: 'The greenhouse in 3D', sub: 'Every sensor, live', last: true,
            onTap: () => push(context, const DashboardPage(view: '3d', title: 'The greenhouse in 3D'))),
      ])),
      Padding(padding: const EdgeInsets.fromLTRB(24, 6, 24, 20), child: Row(children: [
        const Ic('wheel', size: 18, color: C.ink2), const SizedBox(width: 8),
        Expanded(child: Text(manual.isNotEmpty ? 'You are in charge of the ${manual.join(' and the ')} for now.'
            : good ? 'The greenhouse decides on its own. Nothing to do.' : 'The greenhouse decides on its own.', style: nunito(15, color: C.ink2))),
      ])),
    ]);
  }
}

/// A sensor that stopped answering: its last value is dated, never shown as today's.
class MutePage extends StatelessWidget {
  const MutePage({super.key, required this.title, required this.keyName, required this.unit, required this.advice});
  final String title, keyName, unit, advice;
  @override
  Widget build(BuildContext context) {
    final lv = (st['last_valid'] as J)[keyName] as J?;
    return Scaffold(body: SafeArea(child: Column(children: [
      Header(title),
      Expanded(child: Pad(scroll: false, children: [
        const SizedBox(height: 20),
        Align(alignment: Alignment.centerLeft, child: Container(width: 30, height: 6, decoration: BoxDecoration(color: const Color(0xFFB9AD92), borderRadius: BorderRadius.circular(3)))),
        const SizedBox(height: 16),
        Text('No news from the sensor.', style: sora(30, w: FontWeight.w800, height: 1.12)),
        const SizedBox(height: 12),
        Text(lv == null ? 'No valid reading yet.' : "Last valid reading: ${pct(lv['v'])} $unit at ${hm(lv['t'])}. I don't show it as if it were today's.",
            style: nunito(17, color: C.ink2)),
        const SizedBox(height: 16),
        Note(Text(advice), color: C.bleSoft),
        const Spacer(),
        Btn('What to check?', onTap: () => push(context, const HelpPage(open: 'sensor'))),
      ])),
    ])));
  }
}

class SoilPage extends StatelessWidget {
  const SoilPage({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: store, builder: (context, _) {
        final s = st['sensors'] as J;
        if (s['soil_raw'] == null) {
          return const MutePage(title: 'The soil', keyName: 'soil_raw', unit: 'raw',
              advice: 'Check that the soil probe is well in the soil and that the Arduino is plugged into the Pi. Watering is paused meanwhile.');
        }
        final h = store.history, ld = st['last_diagnosis'] as J?;
        return Scaffold(body: ListView(padding: EdgeInsets.zero, children: [
          Stack(children: [
            SizedBox(height: 190 + MediaQuery.paddingOf(context).top, width: double.infinity, child: svg(soilSvg((s['soil_pct'] as num).toDouble()), fit: BoxFit.fill)),
            Positioned(left: 14, top: MediaQuery.paddingOf(context).top + 8, child: CircleAvatar(backgroundColor: C.paper.withValues(alpha: .8),
                child: IconButton(onPressed: () => Navigator.pop(context), icon: const Ic('back', color: C.forest)))),
            Positioned(left: 22, bottom: 12, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: C.paper, borderRadius: BorderRadius.circular(10)),
                child: Text('10 cm deep', style: nunito(15, w: FontWeight.w700)))),
          ]),
          Pad(scroll: false, children: [
            Text('The soil is', style: nunito(16, color: C.ink2)),
            Text.rich(TextSpan(style: sora(30, w: FontWeight.w800), children: [
              TextSpan(text: '${soilWord(s['soil_raw']).toLowerCase()} '),
              TextSpan(text: '${pct(s['soil_pct'])} %', style: const TextStyle(color: C.terre)),
            ])),
            Caps('Since ${h.isEmpty ? 'yesterday' : dayPhrase(h.first['t'], lower: true)}'),
            SizedBox(height: 76, child: svg(sparkSvg([for (final p in h) (p['soil'] as num?)?.toDouble()], min: 0, max: 100,
                threshold: (st['thresholds']['water_pct'] as num).toDouble()), fit: BoxFit.fill)),
            const SizedBox(height: 10),
            Text('The red line: below it, the greenhouse waters.${ld != null ? ' It did ${dayPhrase(ld['time'], lower: true)}.' : ''}',
                style: nunito(16, color: C.ink2)),
            const SizedBox(height: 8),
            Text('Raw probe value: ${pct(s['soil_raw'])} (higher = drier).', style: nunito(13.5, color: C.ink2)),
          ]),
        ]));
      });
}

class AirPage extends StatelessWidget {
  const AirPage({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: store, builder: (context, _) {
        final s = st['sensors'] as J;
        if (s['air_temp'] == null) {
          return const MutePage(title: 'The air and the light', keyName: 'air_temp', unit: '°C',
              advice: 'Check that the air sensor (DHT22) is plugged in. Ventilation keeps working with the other readings, watering is paused.');
        }
        final h = store.history, today = nowOf();
        final todays = h.where((p) => p['temp'] != null && sameDay(parse(p['t'])!, today)).toList();
        final max = todays.isEmpty ? (s['air_temp'] as num) : todays.map((p) => p['temp'] as num).reduce((a, b) => a > b ? a : b);
        final comfort = List<num>.from(st['thresholds']['comfort']);
        final ran = (st['fan_runs_today'] as List).isNotEmpty;
        final lx = s['light'] as num;
        return Scaffold(body: SafeArea(child: Column(children: [
          const Header('The air and the light'),
          Expanded(child: Pad(children: [
            Text.rich(TextSpan(children: [
              TextSpan(text: '${pct(s['air_temp'])}', style: sora(76, w: FontWeight.w800, color: C.forest, height: 1)),
              TextSpan(text: ' °C', style: sora(26, w: FontWeight.w800, color: C.forest)),
            ])),
            const SizedBox(height: 8),
            Text('It reached ${max.toStringAsFixed(1)} °C today.${ran ? ' The greenhouse ventilated.' : ''} Humidity ${pct(s['air_hum'])} %.',
                style: nunito(17, color: C.ink2)),
            Caps('Since ${h.isEmpty ? 'yesterday' : dayPhrase(h.first['t'], lower: true)}'),
            SizedBox(height: 76, child: svg(sparkSvg([for (final p in h) (p['temp'] as num?)?.toDouble()], band: comfort, color: '#b5731c'), fit: BoxFit.fill)),
            const SizedBox(height: 10),
            Text('The green band: where the ${crop()} are fine, from ${comfort[0]} to ${comfort[1]} °C.', style: nunito(16, color: C.ink2)),
            const SizedBox(height: 12),
            LineRow(icon: 'sun', iconColor: const Color(0xFFC98B12), title: 'Light', last: true,
                sub: '${cap(lightWord(lx))}, ${lx >= 8000 ? 'enough for the day' : lx >= 50 ? 'the plants grow slowly' : 'the plants rest'} · ${lx.round()} lx'),
          ])),
        ])));
      });
}

class SafetyPage extends StatelessWidget {
  const SafetyPage({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: store, builder: (context, _) {
        final fire = st['alarms']['fire'] == true;
        final g = (store.me?['greenhouse'] as J?) ?? {};
        final name = (g['contact_name'] as String?) ?? '', phone = (g['contact_phone'] as String?) ?? '';
        final last = store.events.where((e) => e['kind'] == 'safety' && e['level'] == 'alarm').firstOrNull;
        final masked = phone.length > 5 ? '${phone.substring(0, phone.length > 7 ? 7 : 3)} ••• ${phone.substring(phone.length - 3)}' : phone;
        return Scaffold(body: SafeArea(child: Column(children: [
          const Header('Safety'),
          Expanded(child: Pad(children: [
            Row(children: [
              Transform.rotate(angle: -.07, child: Container(width: 82, height: 82, alignment: Alignment.center,
                  decoration: BoxDecoration(color: fire ? C.flameSoft : C.pousseSoft, borderRadius: leaf(26, 8)),
                  child: Ic('flame', size: 38, color: fire ? C.flame : const Color(0xFF2F6B2F)))),
              const SizedBox(width: 16),
              Expanded(child: Text(fire ? 'A flame in the greenhouse!' : 'No flame in the greenhouse.', style: sora(25, w: FontWeight.w800))),
            ]),
            const SizedBox(height: 16),
            Text('If a flame appears, the alarm sounds on site and the pump and fan are cut at once, even if the app is closed.',
                style: nunito(17, color: C.ink2)),
            const SizedBox(height: 10),
            LineRow(icon: 'contact', title: name.isEmpty ? 'Contact in case of flame' : '$name, contact of the greenhouse',
                sub: name.isEmpty ? 'Not set yet: add one in Settings' : masked,
                onTap: () => phone.isNotEmpty ? launchUrl(Uri(scheme: 'tel', path: phone.replaceAll(' ', ''))) : push(context, const SettingsPage())),
            LineRow(icon: 'book', title: 'Last alert', sub: last == null ? 'None in the last 7 days' : dayPhrase(last['time']), last: true),
          ])),
        ])));
      });
}

class PlantsPage extends StatelessWidget {
  const PlantsPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(body: SafeArea(child: Column(children: [
        const Header('Plant health'),
        SizedBox(height: 120, width: double.infinity, child: svg(landscape(false, h: 120).replaceAll('#1f4a2c', '#f4eee0'), fit: BoxFit.fill)),
        Expanded(child: Pad(children: [
          const SizedBox(height: 10),
          Text('Soon, the greenhouse will look at your plants.', style: sora(26, w: FontWeight.w800, height: 1.15)),
          const SizedBox(height: 12),
          Text('A camera will spot diseases and tell you what it sees. Not installed yet.', style: nunito(17, color: C.ink2)),
          const SizedBox(height: 16),
          const Note(Text('When it is ready, each result will be marked "to confirm". A photo is not a diagnosis.'), color: Color(0xFFEBE2CC)),
        ])),
      ])));
}

class AlertsPage extends StatelessWidget {
  const AlertsPage({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: store, builder: (context, _) {
        final alerts = List<J>.from(st['alerts']);
        final today = nowOf();
        final handled = store.events.where((e) => e['level'] == 'auto' && sameDay(parse(e['time']) ?? DateTime(2000), today)).take(6).toList();
        const ic = {'fire': 'flame', 'locked': 'lock', 'missing': 'thermo', 'tank': 'tank', 'dry': 'soil'};
        void open(String id) {
          switch (id) {
            case 'fire': push(context, const SafetyPage());
            case 'locked': push(context, const SettingsPage());
            case 'missing': push(context, const AirPage());
            case 'dry': push(context, const SoilPage());
            default: Navigator.pop(context); store.tabs.value = 1;
          }
        }
        return Scaffold(body: SafeArea(child: Column(children: [
          const Header('Alerts'),
          Expanded(child: Pad(children: [
            const Caps('To look at'),
            if (alerts.isEmpty) Text('Nothing to look at. Everything is fine.', style: nunito(16, color: C.ink2)),
            for (final a in alerts)
              LineRow(icon: ic[a['id']] ?? 'warn', iconColor: a['level'] == 'critical' ? C.flame : C.warn, title: a['title'],
                  sub: '${a['detail']} Since ${hm(a['since'])}.', onTap: () => open(a['id'])),
            const Caps('Already handled today'),
            if (handled.isEmpty) Text('Nothing yet today.', style: nunito(16, color: C.ink2)),
            for (final e in handled)
              LineRow(icon: e['kind'] == 'fan' ? 'fan' : 'drop', iconColor: C.forest, title: e['title'], sub: '${hm(e['time'])} · ${e['detail']}', last: true),
            const SizedBox(height: 20),
            if (!alerts.any((a) => a['level'] == 'critical')) const Center(child: Stamp('nothing in red', tilt: .05)),
          ])),
        ])));
      });
}

/// Opens the result of a watering command (success, error, refused, stopped).
void showResult(BuildContext context, J command) => push(context, ResultPage(command: command));
