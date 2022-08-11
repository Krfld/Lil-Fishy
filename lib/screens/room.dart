import '../imports.dart';

class Room extends StatefulWidget {
  @override
  _RoomState createState() => _RoomState();
}

class _RoomState extends State<Room> {
  int _processing = 0;
  ScrollController _scrollController;

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController(initialScrollOffset: 0);

    data.stream.listen((data) async {
      if (mounted && data == 'enter') {
        await app.preProcess(() => setState(() => ++_processing));

        if (_processing < 2 || room.host == users.id && _processing < 3) {
          await game.play();

          await app.delay(times: 4);
          await Navigator.pushNamed(context, 'Game');
        }

        if (mounted) await app.postProcess(() => setState(() => _processing = 0));
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

    room.leave();
    Navigator.pop(context);
  }

  Future _onStart() async {
    await app.preProcess(() => setState(() => ++_processing));

    if (_processing < 2) game.start();
  }

  Future _onSpectate() async {
    await app.preProcess(() => setState(() => ++_processing));

    if (_processing < 2) {
      await game.spectate();
      await Navigator.pushNamed(context, 'Game');
    }

    if (mounted) await app.postProcess(() => setState(() => _processing = 0));
  }

  @override
  Widget build(BuildContext context) {
    var textTheme = Theme.of(context).textTheme;

    return WillPopScope(
      onWillPop: () {
        if (_processing == 0) _onBack();
        return;
      },
      child: StreamBuilder(
        stream: data.stream,
        builder: (context, snapshot) {
          return Scaffold(
            body: Column(
              children: [
                Expanded(
                  flex: 1,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(room.name, style: textTheme.headline5, textAlign: TextAlign.center),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        for (String player in room.players)
                          Text(
                            users.getName(player),
                            style: TextStyle(
                              fontStyle: player == room.host ? FontStyle.italic : null,
                              fontWeight: player == users.id ? FontWeight.bold : null,
                              color: room.playersPlaying.contains(player)
                                  ? Colors.teal
                                  : room.playersSpectating.contains(player)
                                      ? Colors.orange
                                      : null,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Button(
                          text: 'Back',
                          function: _onBack,
                          enable: _processing == 0,
                          duration: Duration(milliseconds: settings.delay ~/ 2),
                        ),
                        if (room.host == users.id && room.players.length > 1 && room.status == 0)
                          Button(
                            text: 'Start',
                            function: _onStart,
                            enable: _processing == 0,
                            duration: Duration(milliseconds: settings.delay ~/ 2),
                          )
                        else if (room.players.length > 1 &&
                            room.status == 1 &&
                            game.totalRemainingCards + game.deck.length > 4 * 2)
                          Button(
                            text: 'Spectate',
                            function: _onSpectate,
                            enable: _processing == 0,
                            duration: Duration(milliseconds: settings.delay ~/ 2),
                          ),
                      ],
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
