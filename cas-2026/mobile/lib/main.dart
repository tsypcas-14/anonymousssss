// SmartFarm mobile app: the SmartFarm Interface v2 design, connected to the Raspberry Pi of the greenhouse.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'art.dart';
import 'screens/fan.dart';
import 'screens/home.dart';
import 'screens/log.dart';
import 'screens/special.dart';
import 'screens/start.dart';
import 'screens/water.dart';
import 'store.dart';
import 'theme.dart';
import 'ui.dart';

final navKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FarmStore.i.boot();
  runApp(const SmartFarmApp());
}

class SmartFarmApp extends StatelessWidget {
  const SmartFarmApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'SmartFarm',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        navigatorKey: navKey,
        home: const Root(),
        builder: (context, child) => _Overlays(child: child!),   // above every page: flame alert, offline
      );
}

/// Decides what to show: loading, first launch, or the app (with the flame alert and offline screen above it).
class Root extends StatelessWidget {
  const Root({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: store, builder: (context, _) {
        if (store.booting) return const LoadingScreen();
        if (!store.signedIn) return const WelcomeScreen();
        if (store.st == null) return const _Waiting();
        return const Shell();
      });
}

/// Signed in, but no news yet: loading for a few seconds, then the offline screen.
class _Waiting extends StatefulWidget {
  const _Waiting();
  @override
  State<_Waiting> createState() => _WaitingState();
}

class _WaitingState extends State<_Waiting> {
  bool late = false;
  Timer? _t;
  @override
  void initState() { super.initState(); _t = Timer(const Duration(seconds: 8), () => setState(() => late = true)); }
  @override
  void dispose() { _t?.cancel(); super.dispose(); }
  @override
  Widget build(BuildContext context) => late ? const OfflineScreen() : const LoadingScreen();
}

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    // A watering we asked for has finished: show its result, wherever we are.
    _sub = store.results.listen((c) {
      final nav = navKey.currentState;
      if (nav == null) return;
      if (c['kind'] == 'water') {
        nav.popUntil((r) => r.isFirst);
        store.tabs.value = 1;
        nav.push(MaterialPageRoute(builder: (_) => ResultPage(command: c)));
      } else if (c['message'] is String && (c['message'] as String).isNotEmpty && mounted) {
        toast(context, c['message']);
      }
    });
  }

  @override
  void dispose() { _sub?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: Listenable.merge([store, store.tabs]), builder: (context, _) {
        final fire = st['alarms']['fire'] == true && !store.fireAck;
        final good = store.tabs.value == 0 && (st['alerts'] as List).where((a) => a['id'] != 'fire').isEmpty && st['alarms']['fire'] != true;
        SystemChrome.setSystemUIOverlayStyle(fire || (store.tabs.value == 0 && good)
            ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark);
        return Scaffold(
          body: IndexedStack(index: store.tabs.value, children: const [
            HomeTab(), WaterTab(), FanTab(), SafeArea(bottom: false, child: LogView()),
          ]),
          bottomNavigationBar: _Bar(index: store.tabs.value, onTap: (i) => store.tabs.value = i),
        );
      });
}

/// Drawn above every page: the flame alert (until "I saw it") and "I can't see the greenhouse".
class _Overlays extends StatelessWidget {
  const _Overlays({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: store, builder: (context, _) {
        final live = store.signedIn && store.st != null;
        final fire = live && st['alarms']['fire'] == true && !store.fireAck;
        final offline = live && !store.online;
        return Stack(children: [
          child,
          if (offline) const Positioned.fill(child: OfflineScreen()),
          if (fire) Positioned.fill(child: FireScreen(onAck: () {
            store.ackFire();
            navKey.currentState?.push(MaterialPageRoute(builder: (_) => const SafetyPage()));
          })),
        ]);
      });
}

class _Bar extends StatelessWidget {
  const _Bar({required this.index, required this.onTap});
  final int index;
  final ValueChanged<int> onTap;
  static const items = [('greenhouse', 'Greenhouse'), ('drop', 'Watering'), ('fan', 'Ventilation'), ('book', 'Log')];
  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(color: C.paper, border: Border(top: BorderSide(color: Color(0xFFE5DCC6)))),
        padding: EdgeInsets.fromLTRB(6, 8, 6, 8 + MediaQuery.paddingOf(context).bottom),
        child: Row(children: [
          for (var i = 0; i < items.length; i++) Expanded(child: InkWell(
            onTap: () => onTap(i),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              AnimatedContainer(duration: const Duration(milliseconds: 180), width: 56, height: 32,
                  decoration: BoxDecoration(color: i == index ? C.pousse : Colors.transparent, borderRadius: leaf(14, 6)),
                  child: Center(child: Ic(items[i].$1, color: i == index ? C.forest : C.ink2))),
              const SizedBox(height: 2),
              Text(items[i].$2, style: nunito(13, w: FontWeight.w600, color: i == index ? C.forest : C.ink2)),
            ]),
          )),
        ]),
      );
}
