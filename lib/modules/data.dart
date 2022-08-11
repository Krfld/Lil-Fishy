import '../imports.dart';

Users users;
final _Data data = _Data();
final _Settings settings = _Settings();

///
///
///
///
///

class _Data {
  Map _data = {};
  Map get data => this._data;

  // ignore: close_sinks
  final StreamController streamController = StreamController.broadcast();
  Stream get stream => this.streamController.stream;

  Map _timestamps = {};
  Map get timestamps => this._timestamps;

  int lastTimestamp = 0;

  ///
  ///
  ///

  void init() {
    room.init();
    game.init();
  }

  void update(Map data) async {
    this._data = data;
    //app.msg(database, prefix: 'Database');

    /// Update classes
    users.update(app.load(data, 'users', {}));
    rooms.update(app.load(data, 'lobby', {}));
    settings.update(app.load(data, '|settings', {}));

    this._timestamps = app.load(data, '|timestamps', {});

    this.streamController.sink.add(null);
  }
}

///
///
///
///
///

class Users {
  bool _processing = false;
  Users(this._id);

  ///
  ///
  ///

  Map _users = {};
  Map get users => this._users;

  /// ID
  final String _id;
  String get id => this._id.trim();

  /// Name
  String name = '';

  ///
  ///
  ///

  void update(Map users) {
    this._users = users;
    //app.msg(users, prefix: 'Users');

    /// Update name
    fb.write('users/$id/name', name);

    readMessages();
  }

  Future readMessages() async {
    if (_processing) return;

    Map msgs = app.load(users, '$id/msgs', {});

    if (msgs.isNotEmpty) {
      _processing = true;

      if (app.load(msgs, 'enter', false)) {
        data.streamController.sink.add('enter');
        await fb.delete('users/$id/msgs/enter');
      }

      List takeCards = app.load(msgs, 'takeCards', []);
      if (takeCards.isNotEmpty) {
        game.hand.addAll(takeCards);

        if (cards.toMap(game.hand)[cards.getValue(takeCards.first)].length % 4 == 0) game.signalPoint = true;

        int currentPoints = 0;
        cards.toMap(game.hand).values.forEach((value) => currentPoints += value.length ~/ 4);
        game.points = currentPoints;

        await fb.delete('users/$id/msgs/takeCards');
      }

      List giveCards = app.load(msgs, 'giveCards', []);
      if (giveCards.isNotEmpty) {
        giveCards.forEach((card) {
          int index = game.hand.lastIndexOf(card);
          if (index != -1) game.hand.removeAt(index);
        });

        await fb.delete('users/$id/msgs/giveCards');
      }

      await room.updateInfo();

      _processing = false;
    }
  }

  ///
  ///
  ///

  String getName(String id) => app.load(users, '$id/name', id == this.id ? name : '').trim();

  Future msg(String id, Map msg) async {
    if (id.isEmpty || msg.isEmpty) return;
    await fb.write('users/$id/msgs', msg);
  }
}

///
///
///
///
///

class _Settings {
  Map _settings;
  Map get settings => this._settings;

  List _roomNames = [
    'BIA É BOA',
    'BORDÃO É GAY',
    'BRAÇO NA MESA\nMÃO NA TERESA',
    'CALA A BOCA SAC',
    'CARLA',
    'CARLITOS TRAZ A PIZA',
    'CARLOS É MERDA',
    'KOETISTA',
    'MARCELO PRETO DE LIXO',
    'NELSON É LINDU',
    'SAC É GAGO',
    'SOUSA É TOURO\nTOURO É GAY',
    'TUA MÃE SEM MEL\nAIA',
  ];

  List _quotes = [
    'Eu sou burro\nEu não sou gago',
    'Cólon não é no cólon?',
    'Não tem bué mas tem',
    'Tenho a coisa na boca',
    'Não levo com pneus',
    'Eu não falho',
    'Quando eu era puto eu era autista\nMas agora já não sou',
    'O Sousa às vezes de vez em quando do nada parece que chupa piça de preto',
    'Oh ohhh Tone...\nJá foste às putas?',
    'O Marcelo é peso',
    'Os fones do Sousa captam ondas não visíveis a olho humano',
    'Vou comprar umaz carcaça',
    'Quando eu estou com a buba mando todos embora',
    'Beethoven toca bué martelo',
    'Fui beber um copo de água e já fiquei sem casa',
    'Só existe fanta de laranja e homens brancos\nO resto é merda',
    'I\'m a boss\n I\'m a bitch',
    'Manteiga vegan é feita a partir de teta de planta',
    'Môlhos de mólhos',
    'Quando morrer vou-me atirar ao mar',
    'Se matares de ronda nesta faca...',
    'Eu só vooouuu pró caralho',
    'Já babei o meu ecrã e tudo',
    'Bem-vindo ao clube de autistas',
    'Call of Daty',
    'Tá a Sousa soro',
    'Preciso duMamala',
    'Os braços parecem que estão nos ombros',
    'O meu pai tá aberto',
    'Isa boa carla anal no anólio',
    'São 4 ou 5 da manhã na Turquia'
  ];

  String get title => app.load(settings, 'title', 'Lil Fishy').trim();
  String get outdatedMsg => app.load(settings, 'outdatedMsg', 'New version available');
  int get nameMaxLength => app.load(settings, 'nameMaxLength', 12).toInt();
  String get emptyLobbyMsg => app.load(settings, 'emptyLobbyMsg', 'No rooms').trim();
  int get roomLimit => app.load(settings, 'roomLimit', 10).toInt();
  List get specialRoomNames => app.load(settings, 'specialRoomNames', this._roomNames);
  double get specialRoomNamesOdd => app.load(settings, 'specialRoomNamesOdd', 1 / 1000).toDouble();
  List get scoresQuotes => app.load(settings, 'scoresQuotes', this._quotes);
  double get scoresQuotesOdd => app.load(settings, 'scoresQuotesOdd', 1 / 100).toDouble();
  int get delay => app.load(settings, 'delay', 250).toInt();
  int get timestampPeriod => app.load(settings, 'timestampPeriod', 5).toInt();
  int get onlineThreshold => app.load(settings, 'onlineThreshold', 20).toInt();

  ///
  ///
  ///

  void update(Map settings) => this._settings = settings;

  Future get setDefaults async {
    this._roomNames.sort();
    this._quotes.sort();
    await fb.write('|settings', {
      'title': 'Lil Fishy',
      'outdatedMsg': 'New version available',
      'nameMaxLength': 12,
      'emptyLobbyMsg': 'No rooms',
      'roomLimit': 10,
      'specialRoomNames': this._roomNames,
      'specialRoomNamesOdd': 1 / 1000,
      'scoresQuotes': this._quotes,
      'scoresQuotesOdd': 1 / 100,
      'delay': 250,
      'timestampPeriod': 5,
      'onlineThreshold': 20,
    });
  }
}
