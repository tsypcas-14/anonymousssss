// Shared widgets of the design, and the words the app uses for numbers.
import 'package:flutter/material.dart';

import 'art.dart';
import 'store.dart';
import 'theme.dart';

final store = FarmStore.i;
J get st => store.st!;

// ---------------------------------------------------------------- words for numbers
String two(int n) => n.toString().padLeft(2, '0');
DateTime? parse(String? iso) => iso == null || iso.isEmpty ? null : DateTime.tryParse(iso);
String hm(String? iso) { final d = parse(iso); return d == null ? '' : '${two(d.hour)}:${two(d.minute)}'; }
DateTime nowOf() => parse(store.st?['sensors']?['timestamp']) ?? DateTime.now();
String cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
const _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
const _months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
bool sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

String longDate(DateTime d) => '${_days[d.weekday - 1]} ${d.day} ${_months[d.month - 1]}';

String dayPhrase(String? iso, {bool lower = false}) {
  final d = parse(iso);
  if (d == null) return '';
  final now = nowOf(), y = now.subtract(const Duration(days: 1));
  String s;
  if (sameDay(d, now)) { s = d.hour < 12 ? 'this morning' : d.hour < 18 ? 'this afternoon' : 'this evening'; }
  else if (sameDay(d, y)) { s = 'yesterday'; }
  else { s = 'on ${_days[d.weekday - 1]} ${d.day} ${_months[d.month - 1].substring(0, 3)}'; }
  s = '$s at ${hm(iso)}';
  return lower ? s : cap(s);
}

String dayLabel(String? iso) {
  final d = parse(iso);
  if (d == null) return 'Earlier';
  final now = nowOf();
  if (sameDay(d, now)) return 'Today';
  if (sameDay(d, now.subtract(const Duration(days: 1)))) return 'Yesterday';
  return longDate(d);
}

String greeting() {
  final h = nowOf().hour;
  final g = h >= 5 && h < 12 ? 'Good morning' : h >= 12 && h < 18 ? 'Good afternoon' : 'Good evening';
  final n = (store.me?['user']?['name'] as String? ?? '').split(' ').first;
  return n.isEmpty ? g : '$g, $n';
}

String crop() => ((store.me?['greenhouse']?['crop'] as String?) ?? 'tomatoes').toLowerCase();
String house() => (store.me?['greenhouse']?['name'] as String?) ?? 'My greenhouse';

String soilWord(num? raw) => raw == null ? 'No news' : raw <= 450 ? 'Well watered' : raw <= 600 ? 'Moist enough' : raw <= 650 ? 'A bit dry' : 'Dry';
String lightWord(num? lx) => lx == null ? 'no news of the light' : lx < 50 ? 'night sky' : lx < 8000 ? 'dim light' : lx < 25000 ? 'cloudy sky' : 'full sun';
String tankPhrase(num? days, num? pct, bool low) {
  if (low) return 'Empty: the pump is stopped';
  if (days == null) return (pct ?? 0) >= 50 ? 'Plenty of water' : 'Water level is going down';
  if (days < 1) return 'Water for less than a day';
  final whole = days.floor(), frac = days - whole;
  if (frac >= .25 && frac < .75) return 'Water for $whole and a half day${whole >= 1 ? 's' : ''}';
  final n = days.round();
  return 'Water for $n day${n > 1 ? 's' : ''}';
}
String agoText() {
  final s = DateTime.now().difference(store.lastMsg).inSeconds;
  return s < 20 ? 'just now' : s < 90 ? '$s s ago' : '${(s / 60).round()} min ago';
}
String untilText(J m) {
  final now = nowOf().add(Duration(seconds: (m['seconds_left'] as num? ?? 0).toInt()));
  return '${two(now.hour)}:${two(now.minute)}';
}
int pct(num? v) => (v ?? 0).round();

// ---------------------------------------------------------------- widgets
void toast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(msg, style: nunito(15, w: FontWeight.w700, color: Colors.white)),
      backgroundColor: C.forest, behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: leaf(14, 5)), duration: const Duration(seconds: 3)));
}

enum BtnKind { wheat, forest, outline, white, ghost }

class Btn extends StatelessWidget {
  const Btn(this.label, {super.key, this.onTap, this.kind = BtnKind.wheat, this.icon, this.busy = false});
  final String label;
  final VoidCallback? onTap;
  final BtnKind kind;
  final String? icon;
  final bool busy;
  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null && !busy;
    final (bg, fg) = switch (kind) {
      BtnKind.wheat => (C.ble, C.ink),
      BtnKind.forest => (C.forest, Colors.white),
      BtnKind.outline => (Colors.transparent, C.forest),
      BtnKind.white => (Colors.white, C.flame),
      BtnKind.ghost => (C.pousseSoft, C.forest),
    };
    return Material(
      color: enabled ? bg : const Color(0xFFE6DEC9),
      shape: RoundedRectangleBorder(borderRadius: leaf(),
          side: kind == BtnKind.outline ? const BorderSide(color: C.forest, width: 2.5) : BorderSide.none),
      child: InkWell(
        borderRadius: leaf(),
        onTap: enabled ? onTap : null,
        child: Container(
          constraints: const BoxConstraints(minHeight: 58),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          alignment: Alignment.center,
          child: busy
              ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: fg))
              : Row(mainAxisSize: MainAxisSize.min, children: [
                  if (icon != null) ...[Ic(icon!, color: enabled ? fg : const Color(0xFF9A937F)), const SizedBox(width: 10)],
                  Flexible(child: Text(label, textAlign: TextAlign.center,
                      style: sora(18, w: FontWeight.w800, color: enabled ? fg : const Color(0xFF9A937F)))),
                ]),
        ),
      ),
    );
  }
}

class LinkText extends StatelessWidget {
  const LinkText(this.text, {super.key, required this.onTap, this.light = false});
  final String text;
  final VoidCallback onTap;
  final bool light;
  @override
  Widget build(BuildContext context) => Center(
        child: InkWell(onTap: onTap, child: Padding(padding: const EdgeInsets.all(8),
            child: Text(text, style: nunito(16, w: FontWeight.w700, color: light ? Colors.white : C.eau).copyWith(
                decoration: TextDecoration.underline, decorationColor: light ? Colors.white : C.eau, decorationThickness: 1.6)))),
      );
}

/// A title with one word underlined by a hand-drawn wave (the design's "trait qui souligne").
Widget underlined(String before, String word, String after, TextStyle style, {Color line = C.pousse}) => Text.rich(
      TextSpan(style: style, children: [
        TextSpan(text: before),
        TextSpan(text: word, style: TextStyle(decoration: TextDecoration.underline, decorationStyle: TextDecorationStyle.wavy,
            decorationColor: line, decorationThickness: 1.6)),
        TextSpan(text: after),
      ]),
    );

class Header extends StatelessWidget {
  const Header(this.title, {super.key, this.back = true, this.trailing});
  final String title;
  final bool back;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(back ? 10 : 24, 14, 20, 8),
        child: Row(children: [
          if (back) IconButton(onPressed: () => Navigator.of(context).maybePop(), icon: const Ic('back', size: 26, color: C.forest)),
          Expanded(child: Text(title, style: sora(24, color: C.forest))),
          ?trailing,
        ]),
      );
}

class Note extends StatelessWidget {
  const Note(this.child, {super.key, this.color = C.pousseSoft});
  final Widget child;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: color, borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(14), topRight: Radius.circular(14), bottomRight: Radius.circular(14), bottomLeft: Radius.circular(4))),
        child: DefaultTextStyle.merge(style: nunito(15.5), child: child),
      );
}

/// A list line separated by a dashed furrow: icon, title, subtitle, value, chevron.
class LineRow extends StatelessWidget {
  const LineRow({super.key, required this.icon, required this.title, required this.sub, this.value, this.onTap,
      this.iconColor = C.terre, this.warn = false, this.muted = false, this.last = false});
  final String icon, title, sub;
  final String? value;
  final VoidCallback? onTap;
  final Color iconColor;
  final bool warn, muted, last;
  @override
  Widget build(BuildContext context) => Opacity(
        opacity: muted ? .55 : 1,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: last ? null : const BoxDecoration(border: DashedBottom()),
            child: Row(children: [
              Ic(icon, color: iconColor),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: sora(18, color: C.forest)),
                Row(children: [
                  if (warn) ...[const Ic('warn', size: 16, color: C.warn), const SizedBox(width: 5)],
                  Expanded(child: Text(sub, style: nunito(15, color: C.ink2))),
                ]),
              ])),
              if (value != null) Padding(padding: const EdgeInsets.only(left: 8), child: Text(value!, style: sora(18, w: FontWeight.w800))),
              if (onTap != null) const Padding(padding: EdgeInsets.only(left: 6), child: Ic('chevron', size: 20, color: C.ink2)),
            ]),
          ),
        ),
      );
}

/// Dashed separator ("sillon") drawn as a box border.
class DashedBottom extends BoxBorder {
  const DashedBottom();
  @override
  BorderSide get top => BorderSide.none;
  @override
  BorderSide get bottom => const BorderSide(color: C.furrow, width: 2);
  @override
  bool get isUniform => false;
  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.only(bottom: 2);
  @override
  ShapeBorder scale(double t) => this;
  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection, BoxShape shape = BoxShape.rectangle, BorderRadius? borderRadius}) {
    final p = Paint()..color = C.furrow..strokeWidth = 2;
    for (double x = rect.left; x < rect.right; x += 10) {
      canvas.drawLine(Offset(x, rect.bottom - 1), Offset((x + 5).clamp(0, rect.right), rect.bottom - 1), p);
    }
  }
}

class Caps extends StatelessWidget {
  const Caps(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(top: 14, bottom: 4),
      child: Text(text.toUpperCase(), style: nunito(13, w: FontWeight.w800, color: C.ink2).copyWith(letterSpacing: 1.1)));
}

class Stamp extends StatelessWidget {
  const Stamp(this.text, {super.key, this.tilt = -.07});
  final String text;
  final double tilt;
  @override
  Widget build(BuildContext context) => Transform.rotate(angle: tilt, child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        decoration: BoxDecoration(border: Border.all(color: const Color(0xFFB9AD92), width: 2), borderRadius: BorderRadius.circular(10)),
        child: Text(text, style: sora(14, w: FontWeight.w800, color: C.ink2))));
}

/// Vertical steps with a line between them: done (green check), now (dashed ring), later (grey ring).
class Steps extends StatelessWidget {
  const Steps(this.items, {super.key});
  final List<(String title, String sub, int state)> items;   // state: 2 done, 1 now, 0 later
  @override
  Widget build(BuildContext context) => Column(children: [
        for (var i = 0; i < items.length; i++)
          IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SizedBox(width: 34, child: Column(children: [
              Container(width: 32, height: 32, decoration: BoxDecoration(shape: BoxShape.circle,
                  color: items[i].$3 == 2 ? const Color(0xFF3F8F33) : C.kraft,
                  border: Border.all(color: items[i].$3 == 2 ? const Color(0xFF3F8F33) : items[i].$3 == 1 ? C.eau : const Color(0xFFCFC6AF), width: 2.5)),
                  child: items[i].$3 == 2 ? const Center(child: Ic('check', size: 20, color: Colors.white)) : null),
              if (i < items.length - 1) Expanded(child: Container(width: 2.5, color: items[i].$3 == 2 ? const Color(0xFF3F8F33) : const Color(0xFFCFC6AF))),
            ])),
            const SizedBox(width: 14),
            Expanded(child: Padding(padding: const EdgeInsets.only(bottom: 22), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(items[i].$1, style: sora(18, color: items[i].$3 == 0 ? C.ink2 : C.ink)),
              Text(items[i].$2, style: nunito(15, color: C.ink2)),
            ]))),
          ])),
      ]);
}

/// Segmented "The greenhouse decides | I decide".
class Seg2 extends StatelessWidget {
  const Seg2({super.key, required this.left, required this.right, required this.rightOn, required this.onChanged});
  final String left, right;
  final bool rightOn;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) {
    Widget part(String t, bool on, bool value) => Expanded(child: GestureDetector(
          onTap: () => onChanged(value),
          child: AnimatedContainer(duration: const Duration(milliseconds: 180), constraints: const BoxConstraints(minHeight: 50),
              alignment: Alignment.center,
              decoration: BoxDecoration(color: on ? C.forest : Colors.transparent, borderRadius: leaf(13, 4)),
              child: Text(t, textAlign: TextAlign.center, style: sora(15, color: on ? Colors.white : C.ink2)))));
    return Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: C.chip, borderRadius: leaf(16, 6)),
        child: Row(children: [part(left, !rightOn, false), part(right, rightOn, true)]));
  }
}

class Pad extends StatelessWidget {
  const Pad({super.key, required this.children, this.scroll = true});
  final List<Widget> children;
  final bool scroll;
  @override
  Widget build(BuildContext context) {
    final col = Padding(padding: const EdgeInsets.fromLTRB(24, 6, 24, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children));
    return scroll ? SingleChildScrollView(child: col) : col;
  }
}
