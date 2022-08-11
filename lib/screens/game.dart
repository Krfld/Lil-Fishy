import '../imports.dart';

class Game extends StatefulWidget {
  @override
  _GameState createState() => _GameState();
}

class _GameState extends State<Game> {
  int _processing = 0;
  ScrollController _scrollController;

  int _cardSelected = 0;
  String _playerSelected = '';

  Map _online = {};

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController(initialScrollOffset: 0);

    game.ready = true;

    data.stream.listen((data) async {
      if (mounted) {
        if (data == 'scores') {
          await app.preProcess(() => setState(() => ++_processing));

          if (_processing < 2 || game.lastPlayPlayerTurn == users.id && _processing < 3) {
            await game.saveScores();

            await app.delay(times: 4);
            Navigator.pushReplacementNamed(context, 'Scores');
          }
        } else if (data == 'leave') await _onBack();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();

    super.dispose();
  }

  Future _onBack() async {
    await app.preProcess(() => setState(() => ++_processing));

    await game.leave();
    Navigator.pop(context);
  }

  Future _onSelection() async {
    await app.preProcess(() => setState(() => ++_processing));

    int card = _cardSelected;
    String player = room.playersPlaying.length == 2
        ? room.playersPlaying.where((player) => player != users.id).single
        : _playerSelected;

    _cardSelected = 0;
    _playerSelected = '';

    if (_processing < 2) _online.addAll({player: await game.ask(card, player)});

    if (mounted) await app.postProcess(() => setState(() => _processing = 0));
  }

  @override
  Widget build(BuildContext context) {
    if (_cardSelected != 0 && (_playerSelected.isNotEmpty || room.playersPlaying.length == 2)) _onSelection();

    return WillPopScope(
      onWillPop: () {
        // No back
        return;
      },
      child: StreamBuilder(
        stream: data.stream,
        builder: (context, snapshot) {
          return Scaffold(
            body: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  flex: 3,
                  child: Scrollbar(
                    controller: _scrollController,
                    thickness: 1,
                    child: Center(
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        padding: EdgeInsets.all(32),
                        physics: BouncingScrollPhysics(),
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          //runAlignment: WrapAlignment.center,
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            for (String player in room.playersPlaying)
                              if (player != users.id)
                                OutlineButton(
                                  borderSide: BorderSide(color: player == _playerSelected ? Colors.teal : Colors.grey),
                                  textColor: player == _playerSelected ? Colors.teal : null,
                                  highlightElevation: 4,
                                  //splashColor: Colors.teal,
                                  padding: EdgeInsets.all(16),
                                  disabledBorderColor:
                                      game.playerTurn == player && game.inGame > 0 ? Colors.teal : null,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  onPressed: game.playerTurn == users.id && game.remainingCards > 0 && _processing == 0
                                      ? () {
                                          _playerSelected != player && room.playersPlaying.length > 2
                                              ? _playerSelected = player
                                              : _playerSelected = '';
                                          setState(() {});
                                        }
                                      : null,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.only(bottom: 8),
                                        child: Text(users.getName(player), textAlign: TextAlign.center),
                                      ),
                                      if ((app.load(users.users, '$player/msgs/giveCards', []).isEmpty ||
                                              app.load(_online, '$player', true)) &&
                                          !app.load(users.users, 'users/$player/msgs/enter', false)) ...{
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text('${game.getPlayerRemainingCards(player)}  '),
                                            Icon(MdiIcons.cardsPlayingOutline),
                                          ],
                                        ),
                                        if (game.getPlayerPoints(player) != 0)
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text('${game.getPlayerPoints(player)}  '),
                                              Icon(MdiIcons.fish),
                                            ],
                                          ),
                                      } else
                                        Icon(MdiIcons.wifiOff),
                                    ],
                                  ),
                                ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (game.lastPlayPlayerTurn.isNotEmpty)
                  Expanded(
                    flex: 1,
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Text(users.getName(game.lastPlayPlayerTurn)),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(MdiIcons.arrowRight),
                                if (game.lastPlayStreak > 1) Text('x${game.lastPlayStreak}'),
                                /*Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('${game.lastPlayStreak}x  '),
                                      Icon(MdiIcons.fire),
                                    ],
                                  ),*/
                              ],
                            ),
                            Text(users.getName(game.lastPlayPlayerTarget)),
                            PlayingCard(
                              game.lastPlayCardValue,
                              [],
                              onPressed: () => null,
                              borderColor: game.lastPlayGotCards == 0
                                  ? Colors.red
                                  : game.lastPlayGotCards == -1
                                      ? Colors.orange
                                      : Colors.green,
                              fishIcon: game.lastPlayPoint,
                              amount: game.lastPlayGotCards,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (game.inGame.abs() == 1) ...{
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('${game.points}  ', style: TextStyle(color: game.signalPoint ? Colors.teal : null)),
                            Icon(MdiIcons.fish, color: game.signalPoint ? Colors.teal : null),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('${game.remainingCards}  '),
                            Icon(MdiIcons.cardsPlayingOutline),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    flex: 2,
                    child: Scrollbar(
                      controller: _scrollController,
                      thickness: 1,
                      child: Center(
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          padding: EdgeInsets.all(16),
                          physics: BouncingScrollPhysics(),
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            runAlignment: WrapAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (int value in cards.toMap(game.hand).keys)
                                if (cards.toMap(game.hand)[value].length % 4 != 0)
                                  PlayingCard(
                                    value,
                                    cards
                                        .toMap(game.hand)[value]
                                        .getRange(
                                            cards.toMap(game.hand)[value].length -
                                                cards.toMap(game.hand)[value].length % 4,
                                            cards.toMap(game.hand)[value].length)
                                        .toList(),
                                    selected: _cardSelected == value,
                                    onPressed: game.playerTurn == users.id && _processing == 0
                                        ? () {
                                            _cardSelected != value ? _cardSelected = value : _cardSelected = 0;
                                            setState(() {});
                                          }
                                        : null,
                                  ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                } else
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: Button(
                        text: 'Back',
                        function: _onBack,
                        enable: _processing == 0,
                        duration: Duration(milliseconds: settings.delay ~/ 2),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
