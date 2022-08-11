import '../imports.dart';

class Lobby extends StatefulWidget {
  @override
  _LobbyState createState() => _LobbyState();
}

class _LobbyState extends State<Lobby> {
  int _processing = 0;
  ScrollController _scrollController;

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController(initialScrollOffset: 0);
  }

  @override
  void dispose() {
    _scrollController.dispose();

    super.dispose();
  }

  Future _onBack() async {
    await app.preProcess(() => setState(() => ++_processing));

    Navigator.pop(context);
  }

  Future _onCreateRoom() async {
    await app.preProcess(() => setState(() => ++_processing));

    if (_processing < 2) {
      await room.create();
      await Navigator.pushNamed(context, 'Room');
    }

    if (mounted) await app.postProcess(() => setState(() => _processing = 0));
  }

  Future _onJoinRoom(String key) async {
    await app.preProcess(() => setState(() => ++_processing));

    if (_processing < 2 && await room.join(key)) await Navigator.pushNamed(context, 'Room');

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
        stream: _processing == 0 ? data.stream : null,
        builder: (context, snapshot) {
          return Scaffold(
            body: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  flex: 1,
                  child: Center(
                    child: Text('Lobby', style: textTheme.headline4, textAlign: TextAlign.center),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Center(
                    child: rooms.rooms.length == 0
                        ? Text(settings.emptyLobbyMsg, style: textTheme.caption, textAlign: TextAlign.center)
                        : Scrollbar(
                            controller: _scrollController,
                            //isAlwaysShown: true,
                            thickness: 1,
                            child: ListView.builder(
                              /// TODO: Try single child scroll view
                              controller: _scrollController,
                              physics: BouncingScrollPhysics(),
                              padding: EdgeInsets.symmetric(horizontal: 32), // 32..48..64
                              //cacheExtent: 0,
                              //separatorBuilder: (context, index) => Divider(height: 4),
                              itemCount: rooms.rooms.length,
                              itemBuilder: (context, index) {
                                String key = rooms.getRoomAt(index);
                                //if (Lobby.playersFromIndex(index).isEmpty) return null;
                                return Padding(
                                  padding: EdgeInsets.only(bottom: 8),
                                  child: Card(
                                    semanticContainer: false,
                                    elevation: 4,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                    child: ExpansionTile(
                                      tilePadding: EdgeInsets.symmetric(horizontal: 32),
                                      //childrenPadding: EdgeInsets.only(bottom: 16),
                                      title: Text(
                                        rooms.getName(key) + (!rooms.isFull(key) ? '' : ' (Full)'),
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                        //textAlign: TextAlign.center,
                                      ),
                                      subtitle: Text(
                                        //textAlign: TextAlign.center,
                                        '${rooms.getPlayers(key).length}' +
                                            (settings.roomLimit < 2
                                                ? rooms.getPlayers(key).length == 1
                                                    ? ' player'
                                                    : ' players'
                                                : '/${settings.roomLimit} players') +
                                            (rooms.status(key) != 0 ? ' (Started)' : ''),
                                      ),
                                      onExpansionChanged: (value) => null,
                                      children: [
                                        for (String player in rooms.getPlayers(key))
                                          Padding(
                                            padding: EdgeInsets.only(top: 4),
                                            child: Text(
                                              users.getName(player),
                                              style: TextStyle(
                                                fontStyle: player == rooms.getHost(key) ? FontStyle.italic : null,
                                                color: rooms.getPlayersPlaying(key).contains(player)
                                                    ? Colors.teal
                                                    : rooms.getPlayersSpectating(key).contains(player)
                                                        ? Colors.orange
                                                        : null,
                                              ),
                                            ),
                                          ),
                                        Button(
                                          text: !rooms.isFull(key) ? 'Join' : 'Full',
                                          function: !rooms.isFull(key) ? () => _onJoinRoom(key) : null,
                                          enable: _processing == 0,
                                          duration: Duration(milliseconds: settings.delay ~/ 2),
                                          padding: 8,
                                          margin: 16,
                                          border: 0,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
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
                        Button(
                          text: 'Create\nRoom',
                          function: _onCreateRoom,
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
