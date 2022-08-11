import '../imports.dart';

_Rooms rooms = _Rooms();
_Room room = _Room();
_Game game = _Game();

class _Rooms {
  Map _rooms = {};
  Map get rooms => this._rooms;

  ///
  ///
  ///

  void update(Map lobby) {
    List sortedLobby = lobby.keys.toList();
    sortedLobby.sort(
        (key1, key2) => app.load(lobby, '$key1/timestamp', 0).toInt() - app.load(lobby, '$key2/timestamp', 0).toInt());

    rooms.clear();
    sortedLobby.forEach((key) => rooms.addAll({key: lobby[key]}));
    //app.msg(rooms.keys, prefix: 'Lobby');

    room.update();
  }

  ///
  ///
  ///

  int getIndexOf(String key) => rooms.keys.toList().indexOf(key);
  String getRoomAt(int index) => rooms.keys.toList().elementAt(index);

  String getName(String key) => app.load(rooms, '$key/name', key == room.key ? room.name : '').trim();

  List getPlayers(String key) => app.load(rooms, '$key/players', {}).keys.toList();

  /// If uncomment -> stack overflow
  String getHost(String key) => app.load(rooms, '$key/host', /*key == room.key ? room.host :*/ '').trim();

  List getPlayersPlaying(String key) {
    List players = [];
    app.load(rooms, '$key/players', {}).forEach((key, value) {
      if (app.load(value, 'inGame', 0).abs() == 1 || app.load(users.users, 'users/$key/msgs/enter', false))
        players.add(key);
    });
    players.sort((id1, id2) =>
        app.load(rooms, '$key/players/$id1/token', 0).toInt() - app.load(rooms, '$key/players/$id2/token', 0).toInt());

    return players;
  }

  List getPlayersSpectating(String key) {
    List players = [];
    app.load(rooms, '$key/players', {}).forEach((key, value) {
      if (app.load(value, 'inGame', 0).abs() == 2) players.add(key);
    });
    return players;
  }

  bool isFull(String key) => getPlayers(key).length >= settings.roomLimit && settings.roomLimit >= 2;

  int status(String key) {
    List playersInfo = app.load(rooms, '$key/players', {}).values.toList();
    if (playersInfo.any((value) => app.load(value, 'inGame', 0).toInt() < 0)) return -1;
    if (playersInfo.any((value) => app.load(value, 'inGame', 0).toInt() > 0)) return 1;
    return 0;
  }
}

///
///
///
///
///

class _Room {
  Map get room => app.load(rooms.rooms, '$key', {});

  String _key = '';
  String get key => this._key.trim();

  String _name = '';
  String get name => this._name.trim();

  List get players => rooms.getPlayers(key);
  String get host => rooms.getHost(key);

  List get playersPlaying => rooms.getPlayersPlaying(key);
  List get playersSpectating => rooms.getPlayersSpectating(key);

  int get status => rooms.status(key);

  ///
  ///
  ///

  void init() {
    this._key = '';
    this._name = '';
  }

  void update() {
    if (key.isEmpty) return;

    /// Force room name
    fb.write('lobby/$key/name', name);

    /// Update host
    if (host == users.id || host.isEmpty && players.isNotEmpty && players.first == users.id)
      fb.write('lobby/$key/host', users.id);

    game.update();

    updateInfo();
  }

  Future updateInfo() async {
    await fb.write('lobby/$key/players/${users.id}', {
      'hand': game.hand,
      'inGame': game.inGame,
      'rounds': game.rounds,
      'points': game.points,
      'streaks': game.streaks,
      'token': game.token,
    });
  }

  ///
  ///
  ///

  Future create() async {
    /// Generate name
    String wordPair = generateWordPairs(safeOnly: false, maxSyllables: 2).first.asPascalCase;
    int spaceIndex = wordPair.codeUnits.lastIndexWhere((char) => char < 91);
    this._name = wordPair.substring(0, spaceIndex) + ' ' + wordPair.substring(spaceIndex);

    if (Random().nextDouble() < settings.specialRoomNamesOdd && settings.specialRoomNames.isNotEmpty) {
      settings.specialRoomNames.shuffle();
      this._name = settings.specialRoomNames.first.toUpperCase();
    }

    /// Generate key
    this._key = await fb.push('lobby', {
      'timestamp': await fb.now,
      'name': name,
      'host': users.id,
      'players': {
        users.id: {
          'hand': game.hand,
          'inGame': game.inGame,
          'rounds': game.rounds,
          'points': game.points,
          'streaks': game.streaks,
          'token': game.token,
        }
      },
    });
  }

  Future join(String key) async {
    String name = rooms.getName(key);
    if (name.isEmpty) return false;

    bool isFull = true;
    await fb.databaseReference.child('lobby/$key/players').runTransaction((mutableData) async {
      Map players = mutableData.value ?? {};
      isFull = true;

      if (settings.roomLimit >= 2 && players.keys.length >= settings.roomLimit) return mutableData;

      isFull = false;
      players.addAll({
        users.id: {
          'hand': game.hand,
          'inGame': game.inGame,
          'rounds': game.rounds,
          'points': game.points,
          'streaks': game.streaks,
          'token': game.token,
        }
      });

      mutableData.value = players;
      return mutableData;
    });

    if (isFull) return false;

    this._key = key;
    this._name = name;
    return true;
  }

  Future leave() async {
    String key = this.key;
    this._key = '';
    this._name = '';

    if (rooms.getPlayers(key).length > 1) {
      await fb.delete('lobby/$key/players/${users.id}');
      if (rooms.getHost(key) == users.id) await fb.delete('lobby/$key/host');
    } else {
      await fb.delete('lobby/$key');
    }
  }
}

///
///
///
///
///

class _Game {
  List _hand = [];
  List get hand => this._hand;

  int _token = 0;
  int get token => this._token;

  int _inGame = 0;
  int get inGame => this._inGame;

  int _rounds = 0;
  int get rounds => this._rounds;

  int points = 0;

  int _streaks = 0;
  int get streaks => this._streaks;

  int _currentStreak = 0;
  int get currentStreak => this._currentStreak;

  ///
  ///
  ///

  Timer signalPointTimer;
  bool signalPoint = false;

  bool ready = false;

  int get remainingCards => hand.length - points * 4;

  int get totalRemainingCards {
    int totalRemainingCards = 0;
    room.playersPlaying.forEach((player) => totalRemainingCards += getPlayerRemainingCards(player));
    return totalRemainingCards;
  }

  Map get lastPlay => app.load(room.room, 'lastPlay', {});

  String get quote => app.load(room.room, 'quote', '').trim();

  Map get scores {
    Map unsortedScores = app.load(room.room, 'scores', {});

    List sortedScores = unsortedScores.keys.toList();
    sortedScores.sort((id1, id2) =>
        -(app.load(unsortedScores, '$id1/points', 0).toInt() - app.load(unsortedScores, '$id2/points', 0).toInt()));

    Map scores = {};
    sortedScores.forEach((id) => scores.addAll({id: unsortedScores[id]}));

    return scores;
  }

  int get highscore => app.load(scores.values.first, 'points', 0).toInt();

  ///
  ///
  ///

  List get deck {
    /// Get cards from all players
    List drawnCards = [];
    for (String player in room.players) if (player != users.id) drawnCards.addAll(getPlayerHand(player));
    drawnCards.addAll(hand);

    /// Get cards in deck
    List deck = cards.setup();
    drawnCards.forEach((card) {
      int index = deck.lastIndexOf(card);
      if (index != -1) deck.removeAt(index);
    });
    return deck;
  }

  String get playerTurn {
    if (!ready) return '';
    return room.playersPlaying.firstWhere(
      (player) => getPlayerRounds(player) < getPlayerRounds(room.playersPlaying.first),
      orElse: () => room.playersPlaying.first,
    );
  }

  ///
  ///
  ///

  void init() {
    hand.clear();
    this._token = 0;
    this._inGame = 0;
    this._rounds = 0;
    points = 0;
    this._streaks = 0;
    this._currentStreak = 0;

    ready = false;
    signalPoint = false;
  }

  void update() {
    if (inGame <= 0 || !ready) return;

    /// Update points
    int currentPoints = 0;
    cards.toMap(hand).values.forEach((value) => currentPoints += value.length ~/ 4);
    points = currentPoints;

    /// Check if needs cards
    if (remainingCards == 0 && playerTurn == users.id) {
      List deckCards = cards.getCards(deck, 1);
      if (deckCards.isNotEmpty)
        hand.addAll(deckCards);
      else
        this._rounds = getPlayerRounds(users.id) + 1;
    }

    /// Check if game is over
    if (totalRemainingCards == 0 && deck.length == 0) {
      this._inGame *= -1;
      data.streamController.sink.add('scores');
    }

    /// Leave if player is alone
    if (room.playersPlaying.length == 1) {
      this._inGame = 0;
      data.streamController.sink.add('leave');
    }

    if ((signalPointTimer == null || !signalPointTimer.isActive) && signalPoint)
      signalPointTimer = Timer(Duration(seconds: 1), () {
        signalPoint = false;
        data.streamController.sink.add(null);
      });
  }

  ///
  ///
  ///

  List getPlayerHand(String player) {
    List playerHand = app.load(room.room, 'players/$player/hand', player == users.id ? hand : []).toList();
    /*app.load(users.users, '$player/msgs/giveCards', []).forEach((card) {
      int index = playerHand.lastIndexOf(card);
      if (index != -1) playerHand.removeAt(index);
    });*/
    return playerHand;
  }

  int getPlayerRounds(String player) =>
      app.load(room.room, 'players/$player/rounds', player == users.id ? rounds : 0).toInt();
  int getPlayerPoints(String player) =>
      app.load(room.room, 'players/$player/points', player == users.id ? points : 0).toInt();
  int getPlayerToken(String player) =>
      app.load(room.room, 'players/$player/token', player == users.id ? token : 0).toInt();
  /*int getPlayerStreaks(String player) =>
      app.load(room.room, 'players/$player/streaks', player == users.id ? streaks : 0).toInt();*/

  int getPlayerRemainingCards(String player) => getPlayerHand(player).length - getPlayerPoints(player) * 4;

  String get lastPlayPlayerTurn => app.load(lastPlay, 'playerTurn', '');
  int get lastPlayCardValue => app.load(lastPlay, 'cardValue', 0);
  String get lastPlayPlayerTarget => app.load(lastPlay, 'playerTarget', '');
  int get lastPlayGotCards => app.load(lastPlay, 'gotCards', 0).toInt();
  bool get lastPlayPoint => app.load(lastPlay, 'point', false);
  int get lastPlayStreak => app.load(lastPlay, 'streak', 0).toInt();

  ///
  ///
  ///

  void start() {
    /// Deal cards
    List deal = cards.getCards(deck, room.players.length * 4);
    for (String player in room.players) {
      users.msg(player, {'enter': true, 'takeCards': deal.take(4).toList()});
      deal.removeRange(0, 4);
    }

    /// FIXME: Testing
    /*List deal = cards.getCards(deck, deck.length);
    for (String player in room.players) {
      users.msg(player, {'enter': true, 'takeCards': deal.take(deck.length ~/ room.players.length).toList()});
      //fb.write('lobby/${room.key}/players/$player/hand', deal.take(deck.length ~/ room.players.length).toList());
      deal.removeRange(0, deck.length ~/ room.players.length);
    }*/

    String quote = 'Scores';
    if (Random().nextDouble() < settings.scoresQuotesOdd && settings.scoresQuotes.isNotEmpty) {
      settings.scoresQuotes.shuffle();
      quote = settings.scoresQuotes.first.toUpperCase();
    }
    fb.write('lobby/${room.key}/quote', quote);

    /// Clear last play
    fb.delete('lobby/${room.key}/lastPlay');

    /// Clear scores
    fb.delete('lobby/${room.key}/scores');
  }

  Future play() async {
    this._token = Random().nextInt(settings.roomLimit) + 1;
    this._inGame = 1;

    await room.updateInfo();
  }

  Future spectate() async {
    this._inGame = 2;

    await room.updateInfo();
  }

  Future leave() async {
    hand.clear();
    this._token = 0;
    this._inGame = 0;
    this._rounds = 0;
    points = 0;
    this._streaks = 0;
    this._currentStreak = 0;

    ready = false;
    signalPoint = false;

    await room.updateInfo();
  }

  Future saveScores() async {
    if (inGame.abs() == 1)
      await fb.write('lobby/${room.key}/scores/${users.id}', {'points': points, 'streaks': streaks});
  }

  ///
  ///
  ///

  Future ask(int value, String player) async {
    if (app.load(users.users, '$player/msgs/giveCards', []).isNotEmpty) return false;

    List values = cards.toMap(getPlayerHand(player))[value] ?? [];
    List remainingValues = values.getRange(values.length - values.length % 4, values.length).toList();

    List takeCards = [];
    remainingValues.forEach((remainingValue) => takeCards.add(value + remainingValue * 0.1));

    int gotCards = takeCards.length;

    if (takeCards.isEmpty) {
      takeCards = cards.getCards(deck, 1);

      if (takeCards.isNotEmpty && cards.getValue(takeCards.single) == value)
        gotCards = -1;
      else
        this._rounds++;
    } else
      await users.msg(player, {'giveCards': takeCards});

    if (gotCards == 0)
      this._currentStreak = 0;
    else if (++this._currentStreak > streaks) this._streaks = currentStreak;

    hand.addAll(takeCards);

    int currentPoints = 0;
    cards.toMap(hand).values.forEach((value) => currentPoints += value.length ~/ 4);
    points = currentPoints;

    if (gotCards == 0 && cards.toMap(hand)[cards.getValue(takeCards.single)].length % 4 == 0 ||
        cards.toMap(hand)[value].length % 4 == 0) signalPoint = true;

    await fb.write('lobby/${room.key}/lastPlay', {
      'playerTurn': users.id,
      'cardValue': value,
      'playerTarget': player,
      'gotCards': gotCards,
      'point': cards.toMap(hand)[value].length % 4 == 0,
      'streak': currentStreak,
    });
    await room.updateInfo();

    return true;
  }
}
