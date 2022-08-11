import '../imports.dart';

import 'package:flutter/foundation.dart';

final _Firebase fb = _Firebase();

class _Firebase {
  bool _restarting = false;
  BuildContext _context;
  Timer _timer;
  StreamSubscription _streamSubscription;

  final bool _admin = false;
  bool get admin => this._admin;

  final double _version = 1.01;
  String get version => 'v' + this._version.toString().replaceRange(1, 2, '_');

  List _versions = [];
  List get versions => this._versions;

  bool get isOutdated {
    versions.retainWhere((version) => version.startsWith('v'));

    return versions
        .any((version) => double.parse(version.substring(1).replaceFirst(RegExp(r'_'), '.')) > this._version);
  }

  DatabaseReference get databaseReference =>
      FirebaseDatabase.instance.reference().child(kReleaseMode ? version : 'debug');

  Future setup(BuildContext context) async {
    this._context = context;

    await Firebase.initializeApp();

    //await signOut();
    await signIn();

    this._versions = (await databaseReference.parent().once()).value.keys.toList();

    _streamSubscription = databaseReference.onValue.listen((database) => data.update(database.snapshot.value ?? {}));

    await delete('|timestamps/users/${users.id}');
    clean();

    _timer = Timer.periodic(Duration(seconds: settings.timestampPeriod), (timer) async {
      await write('|timestamps/users/${users.id}', await now);
      clean();
    });

    await write('|timestamps/users/${users.id}', await now);
    //await app.delay(times: 2);
    _restarting = false;
  }

  Future restart() async {
    if (_restarting) return;
    _restarting = true;

    if (!(_streamSubscription?.isPaused ?? true)) {
      _streamSubscription.pause();
      await _streamSubscription.cancel();
    }
    if (_timer?.isActive ?? false) _timer.cancel();

    data.init();
    Phoenix.rebirth(this._context);
  }

  Future get now async {
    await write('|timestamps/now', ServerValue.timestamp);
    return app.load(data.timestamps, 'now', 0);
  }

  Future write(String path, var value) async {
    try {
      await databaseReference.update({path: value});
    } catch (e) {
      app.msg(e, prefix: 'Write Error');
      await restart();
    }
  }

  Future push(String path, var value) async {
    try {
      DatabaseReference reference = databaseReference.child(path).push();
      await reference.set(value);
      return reference.key;
    } catch (e) {
      app.msg(e, prefix: 'Push Error');
      await restart();
    }
  }

  Future delete(String path) async {
    try {
      await databaseReference.child(path).remove();
    } catch (e) {
      app.msg(e, prefix: 'Delete Error');
      await restart();
    }
  }

  Future read(String path) async {
    try {
      return (await databaseReference.child(path).once()).value;
    } catch (e) {
      app.msg(e, prefix: 'Read Error');
      await restart();
    }
  }

  void clean() {
    /// Check online
    List online = [];
    app.load(data.timestamps, 'users', {}).forEach((id, timestamp) {
      if (app.load(data.timestamps, 'now', 0) - timestamp < settings.onlineThreshold * 1000)
        online.add(id);
      else
        delete('|timestamps/users/$id');
    });

    rooms.rooms.keys.forEach((room) {
      List players = rooms.getPlayers(room);
      int removed = 0;

      /// Check players
      players.forEach((player) {
        if (!online.contains(player)) {
          removed++;
          delete('lobby/$room/players/$player');
        }
      });

      /// Check host
      if (!online.contains(app.load(rooms.rooms, '$room/host', ''))) delete('lobby/$room/host');

      /// Check room
      if (removed == players.length) delete('lobby/$room');
    });
  }

  User get user => FirebaseAuth.instance.currentUser;

  Future signIn() async {
    await FirebaseAuth.instance.signInAnonymously();

    users = Users(user.uid);

    data.update(await read('') ?? {});
    users.name = users.getName(users.id);
    await delete('users/${users.id}/msgs');
    await write('users/${users.id}/lastOnline', DateTime.now().toString());

    databaseReference.child('|timestamps/users/${users.id}').onDisconnect().remove();

    app.msg('${settings.title} v${this._version} ADMIN | ID: ${users.id} | Name: ${users.name}', prefix: 'Setup');
  }

  ///
  /*Future signOut() async {
    app.msg('Signing Out: $user');
    await FirebaseAuth.instance.signOut();
  }*/

  ///
  /*Future<void> signInWithGoogle() async {
    final GoogleSignInAccount googleUser = await GoogleSignIn().signIn();
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final GoogleAuthCredential googleAuthCredential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    await _firebaseAuth.signInWithCredential(googleAuthCredential);
    app.msg('Signed In Google: ${_firebaseAuth.currentuser}');
  }*/
}
