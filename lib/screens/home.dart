import '../imports.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _processing = 0;
  TextEditingController _controller;
  FocusNode _focusNode;

  String _inputError = '';
  bool _lastKeyboardState = false;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(text: users.name);
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();

    super.dispose();
  }

  Future _onPlay() async {
    await app.preProcess(() => setState(() => ++_processing));

    if (_processing < 2) {
      app.msg(users.name, prefix: 'Name');

      await Navigator.pushNamed(context, 'Lobby');
    }

    if (mounted) await app.postProcess(() => setState(() => _processing = 0));
  }

  @override
  Widget build(BuildContext context) {
    var textTheme = Theme.of(context).textTheme;

    return WillPopScope(
      onWillPop: () async {
        await app.preProcess(() => setState(() => ++_processing));

        SystemNavigator.pop();
        return;
      },
      child: StreamBuilder(
        stream: KeyboardVisibilityController().onChange,
        builder: (context, snapshot) {
          bool keyboardIsVisible = snapshot.data ?? false;
          if (keyboardIsVisible != _lastKeyboardState) {
            _lastKeyboardState = keyboardIsVisible;

            if (_controller.text.length > settings.nameMaxLength)
              _controller.text = _controller.text.substring(0, settings.nameMaxLength);

            _controller.selection = TextSelection.collapsed(offset: _controller.text.length);

            if (!keyboardIsVisible) {
              SystemChrome.restoreSystemUIOverlays();
              _focusNode.unfocus();
              _controller.text = _controller.text.trim();
              _inputError = '';
              users.name = _controller.text;
              fb.write('users/${users.id}/name', _controller.text);
            }
          }
          return StreamBuilder(
              stream: _processing == 0 ? data.stream : null,
              builder: (context, snapshot) {
                if (!KeyboardVisibilityController().isVisible) {
                  _controller.text = users.name;
                }
                return Scaffold(
                  body: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Expanded(
                        flex: 1,
                        child: Center(
                          child: AnimatedOpacity(
                            duration: Duration(milliseconds: settings.delay ~/ 2),
                            opacity: !keyboardIsVisible ? 1 : 0,
                            child: GestureDetector(
                                onLongPress: () => fb.admin ? settings.setDefaults : null,
                                child: Text(settings.title, textAlign: TextAlign.center, style: textTheme.headline3)),
                          ),
                        ),
                      ),
                      if (fb.isOutdated) Text(settings.outdatedMsg, style: textTheme.caption),
                      Expanded(
                        flex: 1,
                        child: Center(
                          child: AnimatedOpacity(
                            opacity: _processing == 0 ? 1 : 0,
                            duration: Duration(milliseconds: settings.delay ~/ 2),
                            child: Container(
                              padding: EdgeInsets.fromLTRB(64, 0, 64, 0),
                              child: TextField(
                                enabled: _processing == 0,
                                controller: _controller,
                                focusNode: _focusNode,
                                textAlign: TextAlign.center,
                                cursorColor: Colors.teal,
                                textInputAction: TextInputAction.done,
                                keyboardType: TextInputType.name,
                                maxLength: settings.nameMaxLength,
                                decoration: InputDecoration(
                                  //labelText: 'Username',
                                  hintText: 'Username',
                                  //prefixIcon: Icon(MdiIcons.accountTie),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  errorText: _inputError.isNotEmpty ? _inputError : null,
                                ),
                                onEditingComplete: _controller.text.isEmpty ? () => null : null,
                                onTap: () {
                                  //_controller.clear();
                                  _inputError = '';
                                  setState(() {});
                                },
                                onChanged: (value) {
                                  if (value.trim().isEmpty)
                                    _controller.clear();
                                  else
                                    _inputError = '';

                                  if (value.length > settings.nameMaxLength) {
                                    _controller.text = value.substring(0, settings.nameMaxLength);
                                    _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
                                  }

                                  setState(() {});
                                },
                                onSubmitted: (value) async {
                                  value = value.trim();
                                  _controller.text = _controller.text.trim();

                                  if (value.isEmpty) _inputError = "Username can't be empty";

                                  setState(() {});
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Center(
                          child: Button(
                            text: 'Play',
                            function: _onPlay,
                            enable: !keyboardIsVisible && _controller.text.isNotEmpty && _processing == 0,
                            duration: Duration(milliseconds: settings.delay ~/ 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              });
        },
      ),
    );
  }
}
