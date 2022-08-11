import './imports.dart';

void main() => runApp(Phoenix(child: LilFishy()));

class LilFishy extends StatefulWidget {
  @override
  _LilFishyState createState() => _LilFishyState();
}

class _LilFishyState extends State<LilFishy> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.inactive) data.lastTimestamp = DateTime.now().millisecondsSinceEpoch;

    if (state == AppLifecycleState.resumed &&
        data.lastTimestamp != 0 &&
        DateTime.now().millisecondsSinceEpoch - data.lastTimestamp >
            (settings.onlineThreshold - settings.timestampPeriod) * 1000) fb.restart();
  }

  Future _setup() async {
    await SystemChrome.setEnabledSystemUIOverlays([]);
    await fb.setup(context);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lil Fishy',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        brightness: Brightness.dark,
      ),
      routes: {
        'Home': (context) => Home(),
        'Lobby': (context) => Lobby(),
        'Room': (context) => Room(),
        'Game': (context) => Game(),
        'Scores': (context) => Scores(),
      },
      home: KeyboardDismissOnTap(
        child: FutureBuilder(
          future: _setup(),
          builder: (context, setup) {
            if (setup.connectionState == ConnectionState.waiting) return Loading();
            return Home();
          },
        ),
      ),
    );
  }
}
