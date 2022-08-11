import '../imports.dart';

class Scores extends StatefulWidget {
  @override
  _ScoresState createState() => _ScoresState();
}

class _ScoresState extends State<Scores> {
  int _processing = 1;

  @override
  void initState() {
    super.initState();

    Timer(Duration(seconds: 1), () => setState(() => _processing = 0));
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future _onBack() async {
    await app.preProcess(() => setState(() => ++_processing));

    await game.leave();
    Navigator.pop(context);
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
        stream: _processing == 0 ? data.stream : null,
        builder: (context, snapshot) {
          return Scaffold(
            body: Column(
              children: [
                Expanded(
                  flex: 1,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(game.quote, style: textTheme.headline5, textAlign: TextAlign.center),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      for (String player in game.scores.keys)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (app.load(game.scores, '$player/points', 0) == game.highscore)
                                  Icon(MdiIcons.hatFedora),
                                Text(
                                  users.getName(player),
                                  style: TextStyle(
                                    fontWeight: player == users.id ? FontWeight.bold : null,
                                    color: room.playersPlaying.contains(player) ? Colors.teal : null,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('${app.load(game.scores, '$player/points', 0)}  '),
                                Icon(MdiIcons.fish),
                              ],
                            ),
                            /*Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('${app.load(game.stats, '$player/streaks', 0)}x  '),
                                Icon(MdiIcons.fire),
                              ],
                            ),*/
                          ],
                        )
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
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
