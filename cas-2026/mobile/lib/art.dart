// Icons and illustrations of the SmartFarm v2 design (the same drawings as the web app), as SVG.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

String _hex(Color c) => '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

const _icons = {
  'greenhouse': '<path d="M3.5 10.5 12 4l8.5 6.5V20h-17z"/><path d="M12 17v-4.5"/><path d="M12 14c0-2 1.4-3.2 3.3-3.2 0 2-1.4 3.2-3.3 3.2zM12 13.2c0-1.6-1.1-2.6-2.7-2.6 0 1.6 1.1 2.6 2.7 2.6z"/>',
  'drop': '<path d="M12 3.5c3.2 4.1 5.5 7.2 5.5 10.2a5.5 5.5 0 0 1-11 0c0-3 2.3-6.1 5.5-10.2z"/><path d="M9.6 14.2a2.6 2.6 0 0 0 2.4 2.5"/>',
  'fan': '<circle cx="12" cy="12" r="1.6"/><path d="M12 10.4c-.6-3.2.4-6 2.6-6.2 2.3-.2 2.6 3.3-2.6 6.2zM13.4 12.8c2.5 2.1 3.6 4.9 2.1 6.4-1.6 1.6-4.1-.9-2.1-6.4zM10.6 12.4c-3.1 1.1-6 .5-6.5-1.6-.5-2.2 3-3 6.5 1.6z"/>',
  'book': '<rect x="5" y="3.5" width="14" height="17" rx="2"/><path d="M9 3.5v17M12 8h4M12 11.5h4"/>',
  'bell': '<path d="M6.5 16.5V11a5.5 5.5 0 0 1 11 0v5.5l1.5 1.5H5z"/><path d="M10 20.5h4"/>',
  'wheel': '<circle cx="12" cy="12" r="8.5"/><circle cx="12" cy="12" r="2.2"/><path d="M12 3.5v6.3M12 14.2v6.3M3.5 12h6.3M14.2 12h6.3"/>',
  'soil': '<rect x="3.5" y="5" width="17" height="14" rx="3"/><path d="M3.5 10h17"/><circle cx="8" cy="14" r=".6"/><circle cx="12" cy="15.5" r=".6"/><circle cx="16" cy="13.5" r=".6"/>',
  'tank': '<ellipse cx="12" cy="5.5" rx="6.5" ry="2.2"/><path d="M5.5 5.5v13c0 1.2 2.9 2.2 6.5 2.2s6.5-1 6.5-2.2v-13M5.5 12c0 1.2 2.9 2.2 6.5 2.2s6.5-1 6.5-2.2"/>',
  'thermo': '<path d="M10 14.2V5a2 2 0 0 1 4 0v9.2a3.8 3.8 0 1 1-4 0z"/><path d="M12 9v7"/>',
  'flame': '<path d="M12 3.5c.8 3 4.8 5 4.8 9.7a4.8 4.8 0 0 1-9.6 0c0-2.4 1.3-3.8 2.3-5 .3 1.6 1 2.4 1.9 2.8C11.2 9 11 6.3 12 3.5z"/><path d="M12 18.2a1.8 1.8 0 0 1-1.8-1.8c0-1.2 1.1-1.8 1.8-3 .7 1.2 1.8 1.8 1.8 3a1.8 1.8 0 0 1-1.8 1.8z"/>',
  'leafSearch': '<path d="M4 15c0-6 4-10 11-10 0 7-4 11-9.5 11"/><path d="M4 20c2-4 5-7 8-8.5"/><circle cx="17" cy="16.5" r="2.8"/><path d="m19 18.5 2 2"/>',
  'chevron': '<path d="m9.5 6 6 6-6 6"/>',
  'back': '<path d="M15 5.5 8.5 12l6.5 6.5"/>',
  'check': '<path d="m5.5 12.5 4 4 9-9"/>',
  'warn': '<path d="M12 4.5 21 19.5H3z"/><path d="M12 10v4.2M12 16.8v.2"/>',
  'sun': '<circle cx="12" cy="12" r="3.8"/><path d="M12 2.8v2.4M12 18.8v2.4M2.8 12h2.4M18.8 12h2.4M5.5 5.5l1.7 1.7M16.8 16.8l1.7 1.7M5.5 18.5l1.7-1.7M16.8 7.2l1.7-1.7"/>',
  'contact': '<path d="M6 21V4M6 5h11.5l-2 3 2 3H6"/><path d="M4 21h5"/>',
  'cube': '<path d="M12 3.5 20 8v8l-8 4.5L4 16V8z"/><path d="M12 12.5 20 8M12 12.5 4 8M12 12.5v8"/>',
  'chart': '<path d="M4 19.5h16"/><path d="M7 16V11M11 16V6.5M15 16v-6M19 16V9"/>',
  'ai': '<circle cx="12" cy="5" r="2"/><circle cx="6" cy="13" r="2"/><circle cx="18" cy="13" r="2"/><circle cx="12" cy="20" r="1.6"/><path d="M11 6.7 7 11.3M13 6.7l4 4.6M7.2 14.7l3.7 4"/>',
  'help': '<circle cx="12" cy="12" r="8.5"/><path d="M9.6 9.5a2.5 2.5 0 1 1 3.4 2.3c-.6.3-1 .8-1 1.5v.6"/><path d="M12 16.8v.2"/>',
  'user': '<circle cx="12" cy="8.5" r="3.8"/><path d="M4.5 20c1.2-3.6 4-5.5 7.5-5.5s6.3 1.9 7.5 5.5"/>',
  'lock': '<rect x="5.5" y="10.5" width="13" height="10" rx="2"/><path d="M8.5 10.5V8a3.5 3.5 0 0 1 7 0v2.5"/>',
  'lab': '<path d="M9.5 3.5h5M10.5 3.5v6L5 19a1.3 1.3 0 0 0 1.1 2h11.8A1.3 1.3 0 0 0 19 19l-5.5-9.5v-6"/><path d="M7.5 15h9"/>',
  'link': '<path d="M10 14a4 4 0 0 0 5.7 0l3-3a4 4 0 0 0-5.7-5.7l-1 1M14 10a4 4 0 0 0-5.7 0l-3 3a4 4 0 0 0 5.7 5.7l1-1"/>',
};

/// A 2px line icon of the design, in one colour.
class Ic extends StatelessWidget {
  const Ic(this.name, {super.key, this.size = 24, this.color});
  final String name;
  final double size;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    final c = _hex(color ?? DefaultTextStyle.of(context).style.color ?? Colors.black);
    return SvgPicture.string(
      '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg" fill="none" stroke="$c" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">${_icons[name] ?? ''}</svg>',
      width: size, height: size);
  }
}

Widget svg(String body, {double? width, double? height, BoxFit fit = BoxFit.contain}) =>
    SvgPicture.string(body, width: width, height: height, fit: fit);

/// The home landscape: tunnel greenhouse, olive tree, rows. watch = yellow, earth and big sun.
String landscape(bool watch, {double h = 150}) {
  final sky = watch ? '#e8b746' : '#1f4a2c', hill = watch ? '#d3a03a' : '#2b6a35', field = watch ? '#8b4a2b' : '#4c9a2f';
  final row = watch ? '#e7b44a' : '#b9e06a', sun = watch ? '#fff3c9' : '#e8b746', tree = watch ? '#3f6b34' : '#6aa84f';
  String f(double k) => (h * k).toStringAsFixed(1);
  return '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 360 $h" preserveAspectRatio="none">
  <rect width="360" height="$h" fill="$sky"/><circle cx="322" cy="${f(.12)}" r="11" fill="$sun"/>
  <path d="M0 ${f(.42)} C70 ${f(.3)} 140 ${f(.36)} 210 ${f(.4)} S330 ${f(.3)} 360 ${f(.36)} V$h H0z" fill="$hill"/>
  <g transform="translate(36 ${f(.3)})"><path d="M0 18 C0 4 30 4 30 18z" fill="#f6f1e4"/><path d="M8 18V8M15 18V5M22 18V8" stroke="$hill" stroke-width="1.6"/></g>
  <g transform="translate(296 ${f(.2)})"><rect x="-1.5" y="10" width="3" height="14" fill="#6b4a2b"/><ellipse cx="0" cy="8" rx="14" ry="10" fill="$tree"/></g>
  <path d="M0 ${f(.62)} C90 ${f(.5)} 270 ${f(.5)} 360 ${f(.62)} V$h H0z" fill="$field"/>
  <g fill="none" stroke="$row" stroke-width="2" stroke-linecap="round">
  <path d="M180 ${f(.55)} C130 ${f(.7)} 80 ${f(.85)} 30 $h"/><path d="M180 ${f(.55)} C160 ${f(.72)} 140 ${f(.86)} 120 $h"/>
  <path d="M180 ${f(.55)} C200 ${f(.72)} 220 ${f(.86)} 240 $h"/><path d="M180 ${f(.55)} C230 ${f(.7)} 280 ${f(.85)} 330 $h"/>
  <path d="M180 ${f(.55)} C110 ${f(.62)} 40 ${f(.72)} 0 ${f(.8)}"/><path d="M180 ${f(.55)} C250 ${f(.62)} 320 ${f(.72)} 360 ${f(.8)}"/></g></svg>''';
}

/// The tank drawn big: water level, wave, ticks and the red dashed reserve line.
String tankSvg(double? pct) {
  final p = (pct ?? 0).clamp(0, 100), y = 150 - 128 * p / 100;
  return '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 120 170">
  <defs><clipPath id="tk"><path d="M16 20 V148 a44 12 0 0 0 88 0 V20z"/></clipPath></defs>
  <g clip-path="url(#tk)"><rect x="0" y="$y" width="120" height="170" fill="#7fb6d5"/>
  <path d="M0 $y q15 -6 30 0 t30 0 t30 0 t30 0 V${y + 8} H0z" fill="#5a9cc4"/><rect x="0" y="${y + 6}" width="120" height="170" fill="#5a9cc4"/></g>
  <path d="M16 20 V148 a44 12 0 0 0 88 0 V20" fill="none" stroke="#24648f" stroke-width="4"/>
  <ellipse cx="60" cy="20" rx="44" ry="10" fill="#fbf8f1" stroke="#24648f" stroke-width="4"/>
  <path d="M18 141 H102" stroke="#c0392b" stroke-width="2.5" stroke-dasharray="5 4"/>
  <path d="M108 60h8M108 90h8M108 120h8" stroke="#24648f" stroke-width="3" stroke-linecap="round"/></svg>''';
}

const fanStand = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 120 130"><path d="M60 70 V112 M44 114 H76" stroke="#55705a" stroke-width="5" stroke-linecap="round" fill="none"/></svg>';
const fanBlades = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 120 112"><g fill="none" stroke="#55705a" stroke-width="5" stroke-linejoin="round">
  <path d="M60 56 C52 36 56 14 70 14 C82 16 78 38 60 56z"/><path d="M60 56 C80 50 100 58 98 72 C94 84 74 74 60 56z"/>
  <path d="M60 56 C46 72 26 80 20 68 C16 56 38 50 60 56z"/></g><circle cx="60" cy="56" r="6" fill="#55705a"/></svg>''';

/// The fan of the Ventilation screen: the blades turn while it runs.
class FanArt extends StatefulWidget {
  const FanArt({super.key, required this.on, this.size = 130});
  final bool on;
  final double size;
  @override
  State<FanArt> createState() => _FanArtState();
}

class _FanArtState extends State<FanArt> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
  @override
  void initState() { super.initState(); if (widget.on) _c.repeat(); }
  @override
  void didUpdateWidget(FanArt old) { super.didUpdateWidget(old); widget.on ? _c.repeat() : _c.stop(); }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return SizedBox(width: s, height: s * 130 / 120, child: Stack(children: [
      Positioned.fill(child: svg(fanStand)),
      Positioned(left: 0, right: 0, top: 0, height: s * 112 / 120,
          child: RotationTransition(turns: _c, alignment: const Alignment(0, .0), child: svg(fanBlades))),
    ]));
  }
}

/// Soil cross-section with the probe planted; the blue dots follow the soil moisture.
String soilSvg(double? pct) {
  final n = (3 + (pct ?? 0) / 100 * 9).round();
  final dots = List.generate(n, (i) => '<circle cx="${20 + (i * 53) % 330}" cy="${70 + (i * 37) % 80}" r="3.2" fill="#4f9fd0"/>').join();
  return '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 360 170" preserveAspectRatio="none">
  <rect width="360" height="170" fill="#efe3c8"/>
  <path d="M0 52 C60 46 120 58 180 52 S300 46 360 52 V170 H0z" fill="#b98a5e"/>
  <path d="M0 82 C80 76 160 90 240 82 S330 76 360 82 V170 H0z" fill="#8d5a36"/>
  <path d="M0 122 C80 116 170 128 250 120 S330 118 360 122 V170 H0z" fill="#6b3f24"/>
  <path d="M0 50 C60 44 120 56 180 50 S300 44 360 50" stroke="#3f8f33" stroke-width="5" fill="none"/>
  $dots<rect x="172" y="22" width="16" height="118" rx="3" fill="#f6f1e4"/>
  <rect x="166" y="10" width="28" height="22" rx="6" fill="#1f4a2c"/><circle cx="180" cy="140" r="5" fill="#e8b746"/></svg>''';
}

const sproutSvg = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 320 220"><circle cx="262" cy="34" r="16" fill="#e8b746"/>
  <path d="M0 170 C90 140 230 140 320 168 V220 H0z" fill="#cfe3b4"/><path d="M0 190 C110 165 220 168 320 186 V220 H0z" fill="#a6d65a"/>
  <path d="M160 175 V110" stroke="#1f4a2c" stroke-width="6" stroke-linecap="round"/>
  <path d="M160 118 c-6-26-30-34-48-28 6 22 26 32 48 28z" fill="#6fae3f"/><path d="M160 112 c8-26 34-34 52-26-6 22-28 32-52 26z" fill="#8cc94f"/>
  <g fill="#4f9fd0"><path d="M84 54c5 7 8 11 8 15a8 8 0 0 1-16 0c0-4 3-8 8-15z"/><path d="M238 72c4 6 7 9 7 12a7 7 0 0 1-14 0c0-3 3-6 7-12z"/>
  <path d="M60 104c3 5 5 7 5 9a5 5 0 0 1-10 0c0-2 2-4 5-9z"/><path d="M214 128c3 5 5 7 5 9a5 5 0 0 1-10 0c0-2 2-4 5-9z"/></g></svg>''';

const valveSvg = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 120 120" fill="none" stroke="#8b4a2b" stroke-width="6" stroke-linecap="round" stroke-linejoin="round">
  <rect x="44" y="10" width="32" height="20" rx="8"/><path d="M60 30v22"/><path d="M14 72h22M84 72h22"/><path d="M36 54 60 72 36 90zM84 54 60 72 84 90z"/></svg>''';

const offlineSvg = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 320 120"><path d="M0 70 C80 50 200 54 320 64 V120 H0z" fill="#ddd4bf"/>
  <rect x="14" y="56" width="20" height="34" rx="5" fill="none" stroke="#4a4537" stroke-width="5"/>
  <path d="M42 54 C80 20 120 14 156 16" stroke="#6d6757" stroke-width="3" stroke-dasharray="2 7" stroke-linecap="round" fill="none"/>
  <path d="M190 22 h40" stroke="#6d6757" stroke-width="3" stroke-dasharray="2 7" stroke-linecap="round"/>
  <path d="M250 64 c0-16 32-16 32 0z" fill="#c9bfa8"/></svg>''';

const logoSvg = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><path d="M4 14 16 5l12 9v12a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2z" fill="#1f4a2c"/>
  <path d="M16 25v-7" stroke="#f4eee0" stroke-width="2" stroke-linecap="round"/><path d="M16 19.5c0-3 2-4.8 5-4.8 0 3-2 4.8-5 4.8z" fill="#a6d65a"/>
  <path d="M16 18.5c0-2.4-1.6-3.8-4-3.8 0 2.4 1.6 3.8 4 3.8z" fill="#a6d65a"/><path d="M9 26h14" stroke="#e8b746" stroke-width="2" stroke-linecap="round"/></svg>''';

/// One-series line chart with an optional dashed threshold or a comfort band.
String sparkSvg(List<double?> values, {double? min, double? max, double? threshold, List<num>? band, String color = '#8b4a2b'}) {
  final v = values.whereType<double>().toList();
  if (v.length < 2) return '';
  double lo = min ?? v.reduce(math.min), hi = max ?? v.reduce(math.max);
  if (threshold != null) { lo = math.min(lo, threshold); hi = math.max(hi, threshold); }
  if (band != null) { lo = math.min(lo, band[0].toDouble()); hi = math.max(hi, band[1].toDouble()); }
  final pad = (hi - lo) * .12 == 0 ? 1 : (hi - lo) * .12;
  lo -= pad; hi += pad;
  const w = 320.0, h = 70.0;
  double x(int i) => i / (values.length - 1) * w;
  double y(double val) => h - 4 - (val - lo) / (hi - lo) * (h - 8);
  final b = StringBuffer();
  var pen = false;
  for (var i = 0; i < values.length; i++) {
    final val = values[i];
    if (val == null) { pen = false; continue; }
    b.write('${pen ? 'L' : 'M'}${x(i).toStringAsFixed(1)} ${y(val).toStringAsFixed(1)} ');
    pen = true;
  }
  var li = values.length - 1;
  while (values[li] == null) { li--; }
  return '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 $w $h" preserveAspectRatio="none">
  ${band != null ? '<rect x="0" y="${y(band[1].toDouble())}" width="$w" height="${y(band[0].toDouble()) - y(band[1].toDouble())}" fill="#e3efd6"/>' : ''}
  ${threshold != null ? '<path d="M0 ${y(threshold)} H$w" stroke="#c0392b" stroke-width="1.6" stroke-dasharray="6 5"/>' : ''}
  <path d="$b" fill="none" stroke="$color" stroke-width="2.6" stroke-linejoin="round" stroke-linecap="round"/>
  <circle cx="${x(li)}" cy="${y(values[li]!)}" r="4.5" fill="$color"/></svg>''';
}
