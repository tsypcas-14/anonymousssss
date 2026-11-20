// First launch: loading, welcome, connect my greenhouse (address + account), sign in.
import 'package:flutter/material.dart';

import '../art.dart';
import '../store.dart';
import '../theme.dart';
import '../ui.dart';

const _sprout = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 40 40"><path d="M20 40V16" stroke="#1f4a2c" stroke-width="3"/>'
    '<path d="M20 18c0-8 6-12 13-12 0 8-6 12-13 12z" fill="#8cc94f"/><path d="M20 20c0-7-5-10-11-10 0 7 5 10 11 10z" fill="#6fae3f"/></svg>';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});
  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat(reverse: true);
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(width: 170, child: Stack(alignment: Alignment.bottomCenter, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, crossAxisAlignment: CrossAxisAlignment.end, children: [
              for (final (i, s) in [(0, 26.0), (1, 34.0), (2, 42.0)])
                AnimatedBuilder(animation: _c, builder: (_, _) => Transform.scale(alignment: Alignment.bottomCenter,
                    scaleY: .6 + .4 * ((_c.value + i * .2) % 1), child: Padding(padding: const EdgeInsets.only(bottom: 3),
                        child: svg(_sprout, width: s, height: s)))),
            ]),
            Container(height: 3, color: C.terre),
          ])),
          const SizedBox(height: 22),
          Text('Looking for the greenhouse…', style: sora(26, w: FontWeight.w800), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('It takes a few seconds.', style: nunito(17, color: C.ink2)),
        ])),
      );
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: C.forest,
        body: SafeArea(bottom: false, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(padding: const EdgeInsets.fromLTRB(26, 30, 26, 0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(padding: const EdgeInsets.all(3), decoration: BoxDecoration(color: C.kraft, borderRadius: leaf(10, 4)),
                  child: svg(logoSvg, width: 34, height: 34)),
              const SizedBox(width: 12),
              Text('SmartFarm', style: sora(22, color: Colors.white)),
            ]),
            const SizedBox(height: 40),
            underlined('Hello.\nI watch over your ', 'greenhouse', '.', sora(36, w: FontWeight.w800, color: Colors.white, height: 1.12)),
            const SizedBox(height: 18),
            Text('I tell you when everything is fine, and I warn you when there is something to do.',
                style: nunito(18, color: Colors.white.withValues(alpha: .92))),
          ])),
          const Spacer(),
          SizedBox(height: 190, child: svg(landscape(false, h: 190), fit: BoxFit.fill)),
          Container(color: const Color(0xFF4C9A2F), padding: EdgeInsets.fromLTRB(26, 0, 26, 26 + MediaQuery.paddingOf(context).bottom),
              child: Column(children: [
                Btn('Connect my greenhouse', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ConnectScreen()))),
                const SizedBox(height: 6),
                LinkText('I already have an account', light: true,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignInScreen()))),
              ])),
        ])),
      );
}

/// Where is the greenhouse? Remembers the Pi's address once it answers.
class AddressField extends StatefulWidget {
  const AddressField({super.key, required this.onFound});
  final VoidCallback onFound;
  @override
  State<AddressField> createState() => _AddressFieldState();
}

class _AddressFieldState extends State<AddressField> {
  late final _c = TextEditingController(text: store.base.isEmpty ? '' : store.base);
  String? _err;
  bool _busy = false;
  Future<void> _find() async {
    setState(() { _busy = true; _err = null; });
    try { await store.findGreenhouse(_c.text); widget.onFound(); }
    on ApiError catch (e) { _err = e.message; }
    if (mounted) setState(() => _busy = false);
  }
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Address of the greenhouse', style: nunito(16, w: FontWeight.w700, color: C.forest)),
        const SizedBox(height: 6),
        TextField(controller: _c, keyboardType: TextInputType.url, autocorrect: false, onSubmitted: (_) => _find(),
            decoration: InputDecoration(hintText: '192.168.1.20', errorText: _err, errorMaxLines: 3)),
        const SizedBox(height: 6),
        Text('The address of the Raspberry Pi on the Wi-Fi (shown by the installer). On an Android emulator, 10.0.2.2 is this computer.',
            style: nunito(13.5, color: C.ink2)),
        const SizedBox(height: 12),
        Btn('Find the greenhouse', kind: BtnKind.forest, busy: _busy, onTap: _find),
      ]);
}

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});
  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(), _email = TextEditingController(), _pw = TextEditingController(), _code = TextEditingController();
  String? _err;
  bool _busy = false;

  Future<void> _go() async {
    if (!_form.currentState!.validate()) return;
    setState(() { _busy = true; _err = null; });
    try {
      await store.signup(_name.text.trim(), _email.text.trim(), _pw.text, _code.text.trim());
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } on ApiError catch (e) { setState(() => _err = e.message); }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final found = store.info != null && store.base.isNotEmpty;
    return Scaffold(body: SafeArea(child: Column(children: [
      const Header('Connect my greenhouse'),
      Expanded(child: Pad(children: [
        Text('Three little things, only once.', style: nunito(18, color: C.ink2)),
        const SizedBox(height: 14),
        Steps([
          ('On the greenhouse network', found ? 'This phone reaches the Raspberry Pi' : 'Join the greenhouse Wi-Fi', found ? 2 : 1),
          (found ? '${store.info!['name']} found' : 'Find the greenhouse', found ? 'It answers, everything is fine' : 'Type its address below', found ? 2 : 0),
          ('Your account', 'With the code written on the greenhouse', found ? 1 : 0),
        ]),
        if (!found) AddressField(onFound: () => setState(() {}))
        else Form(key: _form, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _field('First name', _name, (v) => v!.trim().isEmpty ? 'Please enter your first name.' : null),
          _field('Email', _email, (v) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v!.trim()) ? null : 'This email does not look right.',
              type: TextInputType.emailAddress),
          _field('Password', _pw, (v) => v!.length < 8 ? 'At least 8 characters.' : null, obscure: true),
          _field('Greenhouse code', _code, (v) => RegExp(r'^\d{6}$').hasMatch(v!.trim()) ? null : '6 digits.',
              type: TextInputType.number, hint: 'Shown on the Pi: greenhouse_code.txt or its logs'),
          if (_err != null) Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(_err!, style: nunito(15, w: FontWeight.w700, color: C.flame))),
          Btn("Let's go", kind: BtnKind.forest, busy: _busy, onTap: _go),
          LinkText('Another address', onTap: () => setState(() => store.info = null)),
        ])),
        LinkText('I already have an account', onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SignInScreen()))),
      ])),
    ])));
  }
}

Widget _field(String label, TextEditingController c, FormFieldValidator<String> v,
        {bool obscure = false, TextInputType? type, String? hint}) =>
    Padding(padding: const EdgeInsets.only(bottom: 14), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(label, style: nunito(16, w: FontWeight.w700, color: C.forest)),
      const SizedBox(height: 6),
      TextFormField(controller: c, validator: v, obscureText: obscure, keyboardType: type, autocorrect: false,
          decoration: InputDecoration(helperText: hint, helperMaxLines: 2)),
    ]));

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});
  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController(), _pw = TextEditingController();
  String? _err;
  bool _busy = false;
  Future<void> _go() async {
    if (!_form.currentState!.validate()) return;
    setState(() { _busy = true; _err = null; });
    try {
      await store.signin(_email.text.trim(), _pw.text);
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } on ApiError catch (e) { setState(() => _err = e.message); }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final found = store.info != null && store.base.isNotEmpty;
    return Scaffold(body: SafeArea(child: Column(children: [
      const Header('Sign in'),
      Expanded(child: Pad(children: [
        Text('Welcome back.', style: nunito(18, color: C.ink2)),
        const SizedBox(height: 14),
        if (!found) AddressField(onFound: () => setState(() {}))
        else Form(key: _form, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('${store.info!['name']} · ${store.base.replaceFirst(RegExp(r'^https?://'), '')}', style: nunito(14, color: C.ink2)),
          const SizedBox(height: 12),
          _field('Email', _email, (v) => v!.trim().isEmpty ? 'Please enter your email.' : null, type: TextInputType.emailAddress),
          _field('Password', _pw, (v) => v!.isEmpty ? 'Please enter your password.' : null, obscure: true),
          if (_err != null) Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(_err!, style: nunito(15, w: FontWeight.w700, color: C.flame))),
          Btn('Sign in', kind: BtnKind.forest, busy: _busy, onTap: _go),
        ])),
        LinkText('Create an account', onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ConnectScreen()))),
      ])),
    ])));
  }
}
