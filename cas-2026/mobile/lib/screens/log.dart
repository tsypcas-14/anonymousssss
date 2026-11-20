// "Log" tab: a timeline with the hour on the left, a line, one sentence, and "Why?" opening the reason.
import 'package:flutter/material.dart';

import '../store.dart';
import '../theme.dart';
import '../ui.dart';

class LogView extends StatefulWidget {
  const LogView({super.key, this.filter = '', this.back = false});
  final String filter;
  final bool back;
  @override
  State<LogView> createState() => _LogViewState();
}

class _LogViewState extends State<LogView> {
  late String f = widget.filter;
  final open = <int>{};

  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: store, builder: (context, _) {
        var ev = store.events;
        if (f == 'important') { ev = ev.where((e) => e['level'] == 'warn' || e['level'] == 'alarm').toList(); }
        else if (f.isNotEmpty) { ev = ev.where((e) => e['kind'] == f).toList(); }
        final rows = <Widget>[];
        String? group;
        for (final e in ev.take(120)) {
          final g = dayLabel(e['time']);
          if (g != group) { rows.add(Caps(g)); group = g; }
          rows.add(_entry(e));
        }
        const filters = [('', 'All'), ('irrigation', 'Watering'), ('fan', 'Ventilation'), ('important', 'Alerts')];
        return Column(children: [
          Header('The log', back: widget.back),
          SizedBox(height: 40, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 20), children: [
            for (final (k, t) in filters) Padding(padding: const EdgeInsets.only(right: 6), child: GestureDetector(
              onTap: () => setState(() => f = k),
              child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: f == k ? C.pousseSoft : Colors.transparent, borderRadius: BorderRadius.circular(10)),
                  child: Text(t, style: nunito(15, w: FontWeight.w700, color: f == k ? C.forest : C.ink2))))),
          ])),
          Expanded(child: RefreshIndicator(onRefresh: store.refresh, child: ListView(padding: const EdgeInsets.fromLTRB(24, 0, 24, 24), children: [
            if (rows.isEmpty) Padding(padding: const EdgeInsets.only(top: 20), child: Text('Nothing yet.', style: nunito(16, color: C.ink2))),
            ...rows,
            const SizedBox(height: 10),
            const Align(alignment: Alignment.centerRight, child: Stamp('7 days kept')),
          ]))),
        ]);
      });

  Widget _entry(J e) {
    final color = switch (e['level']) { 'warn' => C.warn, 'alarm' => C.flame, 'user' => const Color(0xFFA39B84), _ => const Color(0xFF6AA84F) };
    final why = (e['why'] as String?) ?? '';
    final id = e['id'] as int;
    return IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SizedBox(width: 50, child: Text(hm(e['time']), style: sora(15))),
      SizedBox(width: 22, child: Column(children: [
        Container(margin: const EdgeInsets.only(top: 3), width: 18, height: 18,
            decoration: BoxDecoration(shape: BoxShape.circle, color: C.kraft, border: Border.all(color: color, width: 3))),
        Expanded(child: Container(width: 2, color: C.pousseSoft)),
      ])),
      const SizedBox(width: 10),
      Expanded(child: Padding(padding: const EdgeInsets.only(bottom: 18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(e['title'], style: sora(17)),
        Text(e['detail'] ?? '', style: nunito(15, color: C.ink2)),
        if (why.isNotEmpty) GestureDetector(
          onTap: () => setState(() => open.contains(id) ? open.remove(id) : open.add(id)),
          child: Padding(padding: const EdgeInsets.only(top: 4), child: Text('Why?', style: nunito(14.5, w: FontWeight.w700, color: C.eau)
              .copyWith(decoration: TextDecoration.underline, decorationColor: C.eau)))),
        if (open.contains(id)) Padding(padding: const EdgeInsets.only(top: 6), child: Note(Text(why, style: nunito(14)))),
      ]))),
    ]));
  }
}
