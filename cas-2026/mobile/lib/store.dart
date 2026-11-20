// Everything the app knows about the greenhouse, and every call to the Raspberry Pi (local network only, no cloud).
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ApiError implements Exception {
  ApiError(this.message, [this.status = 0]);
  final String message;
  final int status;
  @override
  String toString() => message;
}

typedef J = Map<String, dynamic>;

class FarmStore extends ChangeNotifier {
  FarmStore._();
  static final FarmStore i = FarmStore._();

  String base = '';                 // e.g. http://192.168.1.20:8000
  String? token;
  J? info;                          // /api/info: name, crop, mode
  J? me;                            // /api/me: user, greenhouse, code
  J? st;                            // live state from the WebSocket
  List<J> events = [];
  List<J> history = [];
  bool booting = true;
  DateTime lastMsg = DateTime.fromMillisecondsSinceEpoch(0);
  bool fireAck = false;
  int seenCmd = 0;
  final tabs = ValueNotifier<int>(0);           // bottom bar: 0 greenhouse, 1 watering, 2 ventilation, 3 log
  final _results = StreamController<J>.broadcast();
  Stream<J> get results => _results.stream;   // finished commands (success / error / refused / stopped)

  WebSocketChannel? _ws;
  StreamSubscription? _sub;
  Timer? _tick, _retry;
  bool get signedIn => me != null;
  bool get online => DateTime.now().difference(lastMsg).inSeconds < 8;

  // ---------------------------------------------------------------- start
  Future<void> boot() async {
    final p = await SharedPreferences.getInstance();
    base = p.getString('base') ?? '';
    token = p.getString('token');
    if (base.isNotEmpty) {
      try {
        info = await _get('/api/info');
        if (token != null) { me = await _get('/api/me'); _connect(); }
      } on ApiError catch (e) {
        if (e.status == 401) await _forget();
      } catch (_) { /* the greenhouse is not reachable now: show welcome, the user can retry */ }
    }
    booting = false;
    _tick = Timer.periodic(const Duration(seconds: 4), (_) => notifyListeners());   // refresh "x min ago" and offline
    notifyListeners();
  }

  /// Checks that a SmartFarm answers at this address, and remembers it.
  Future<J> findGreenhouse(String address) async {
    var a = address.trim();
    if (!a.startsWith('http')) a = 'http://$a';
    if (!RegExp(r':\d+$').hasMatch(Uri.parse(a).authority)) a = '$a:8000';
    a = a.replaceAll(RegExp(r'/+$'), '');
    final old = base;
    base = a;
    try {
      final r = await _get('/api/info');
      if (r['app'] != 'smartfarm') throw ApiError('Something answered, but it is not a SmartFarm greenhouse.');
      info = r;
      (await SharedPreferences.getInstance()).setString('base', base);
      notifyListeners();
      return r;
    } catch (e) {
      base = old;
      if (e is ApiError) rethrow;
      throw ApiError('No greenhouse at this address. Is this phone on the greenhouse Wi-Fi?');
    }
  }

  // ---------------------------------------------------------------- accounts
  Future<void> signup(String name, String email, String password, String code) =>
      _signedIn(_post('/api/auth/signup', {'name': name, 'email': email, 'password': password, 'code': code}));
  Future<void> signin(String email, String password) =>
      _signedIn(_post('/api/auth/login', {'email': email, 'password': password}));

  Future<void> _signedIn(Future<J> call) async {
    final r = await call;
    token = r['token'];
    (await SharedPreferences.getInstance()).setString('token', token!);
    me = await _get('/api/me');
    _connect();
    notifyListeners();
  }

  Future<void> signout() async {
    try { await _post('/api/auth/logout', {}); } catch (_) {}
    await _forget();
  }

  Future<void> _forget() async {
    token = null; me = null; st = null; events = []; history = [];
    _close();
    (await SharedPreferences.getInstance()).remove('token');
    notifyListeners();
  }

  Future<void> saveMe({String? name, String? notify}) async {
    final r = await _send('PATCH', '/api/me', {'name': ?name, 'notify': ?notify});
    me = {...?me, 'user': r['user']};
    notifyListeners();
  }

  Future<void> saveGreenhouse(J changes) async {
    final r = await _send('PATCH', '/api/settings', changes);
    me = {...?me, 'greenhouse': r};
    notifyListeners();
  }

  /// "I saw it, I'm checking": hides the full-screen flame alert (it comes back with the next flame).
  void ackFire() { fireAck = true; notifyListeners(); }

  // ---------------------------------------------------------------- commands
  Future<J> water(int seconds) => _post('/api/water', {'seconds': seconds});
  Future<J> stopWater() => _post('/api/water/stop', {});
  Future<J> fan(bool on) => _post('/api/fan', {'on': on});
  Future<J> mode(String equipment, String mode) => _post('/api/mode', {'equipment': equipment, 'mode': mode});
  Future<J> unlock() => _post('/api/pump/unlock', {});
  Future<J> sim(J body) => _post('/api/sim', body);

  Future<void> refresh() async {
    if (!signedIn) return;
    try {
      final ev = await _getList('/api/events?limit=300');
      final h = await _get('/api/history?hours=24');
      events = ev;
      history = List<J>.from(h['points']);
      notifyListeners();
    } catch (_) {}
  }

  // ---------------------------------------------------------------- live state
  void reconnect() => _connect();

  void _connect() {
    _close();
    if (token == null || base.isEmpty) return;
    final ws = Uri.parse(base).replace(scheme: base.startsWith('https') ? 'wss' : 'ws', path: '/ws', queryParameters: {'token': token});
    try {
      _ws = WebSocketChannel.connect(ws);
      _sub = _ws!.stream.listen((m) => _onState(jsonDecode(m as String) as J),
          onDone: _later, onError: (_) => _later(), cancelOnError: true);
    } catch (_) { _later(); }
    refresh();
  }

  void _later() {
    if (_ws?.closeCode == 4401) { _forget(); return; }
    _retry?.cancel();
    _retry = Timer(const Duration(seconds: 3), () { if (token != null) _connect(); });
    notifyListeners();
  }

  void _close() {
    _retry?.cancel();
    _sub?.cancel();
    _ws?.sink.close();
    _ws = null;
  }

  void _onState(J s) {
    final first = st == null;
    final prevMinute = (st?['sensors']?['timestamp'] as String?)?.substring(0, 15);
    st = s;
    lastMsg = DateTime.now();
    if (s['alarms']['fire'] != true) fireAck = false;
    final c = s['command'] as J?;
    if (first) {
      seenCmd = c?['id'] ?? 0;                                   // a result from before the app opened is old news
    } else if (c != null && c['id'] != seenCmd && ['success', 'error', 'refused', 'stopped'].contains(c['status'])) {
      seenCmd = c['id'];
      _results.add(c);
    }
    if (prevMinute != (s['sensors']['timestamp'] as String).substring(0, 15)) refresh();
    notifyListeners();
  }

  // ---------------------------------------------------------------- http
  Map<String, String> get _headers => {'Content-Type': 'application/json', if (token != null) 'Authorization': 'Bearer $token'};

  Future<J> _get(String path) async => await _send('GET', path, null) as J;
  Future<List<J>> _getList(String path) async => List<J>.from(await _send('GET', path, null) as List);
  Future<J> _post(String path, J body) async => await _send('POST', path, body) as J;

  Future<dynamic> _send(String method, String path, J? body) async {
    final uri = Uri.parse('$base$path');
    late http.Response r;
    try {
      final req = http.Request(method, uri)..headers.addAll(_headers);
      if (body != null) req.body = jsonEncode(body);
      r = await http.Response.fromStream(await http.Client().send(req).timeout(const Duration(seconds: 8)));
    } catch (_) {
      throw ApiError("I can't reach the greenhouse. Is this phone on its Wi-Fi?");
    }
    final data = r.body.isEmpty ? null : jsonDecode(utf8.decode(r.bodyBytes));
    if (r.statusCode >= 400) {
      final d = data is Map ? data['detail'] : null;
      if (r.statusCode == 401 && !path.startsWith('/api/auth/')) unawaited(_forget());
      throw ApiError(d is String ? d : 'Please fill every field.', r.statusCode);
    }
    return data;
  }

  @override
  void dispose() { _tick?.cancel(); _close(); _results.close(); super.dispose(); }
}
