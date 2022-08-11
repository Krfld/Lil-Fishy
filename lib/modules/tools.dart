import '../imports.dart';

final _App app = _App();

class _App {
  Future delay({double times = 1}) async =>
      await Future.delayed(Duration(milliseconds: (settings.delay * times).toInt()));

  Future preProcess(Function function) async {
    await function();
    await app.delay();
  }

  Future postProcess(Function function) async {
    await app.delay();
    await function();
  }

  dynamic load(Map source, String path, var defaultValue) {
    path = path.substring(path.startsWith('/') ? 1 : 0, path.endsWith('/') ? path.length - 1 : path.length);

    List paths = path.split('/');

    dynamic out = source;

    try {
      for (int i = 0; i < paths.length - 1; i++) out = out[paths[i]] ?? {};
      out = out[paths.last];
    } catch (e) {
      out = defaultValue;
    }

    if (out is num != defaultValue is num ||
        out is String != defaultValue is String ||
        out is bool != defaultValue is bool ||
        out is List != defaultValue is List ||
        out is Map != defaultValue is Map) out = defaultValue;

    return out;
  }

  int _debugID = 1; // if 0, debug won't work
  dynamic msg(var msg, {BuildContext context, String prefix = 'DEBUG'}) {
    context == null && _debugID > 0
        ? print('+[${prefix.toUpperCase()} (${this._debugID++})] $msg')
        : print('+{${context.widget}} $msg');
    return msg;
  }
}

class Loading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: SpinKitPulse(color: Colors.teal, size: 64)));
  }
}

class Button extends StatelessWidget {
  final String text;
  final Function function;
  final bool enable;
  final Duration duration;
  final double padding;
  final double margin;
  final double border;

  Button({
    @required this.text,
    @required this.function,
    this.enable = true,
    this.duration,
    this.padding = 16,
    this.margin = 0,
    this.border = 32,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: this.duration ?? Duration(seconds: 0),
      opacity: this.enable ? 1 : 0,
      child: Padding(
        padding: EdgeInsets.all(this.margin),
        child: OutlineButton(
          //splashColor: Colors.teal,

          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(this.border)),
          padding: EdgeInsets.all(this.padding),
          onPressed: this.enable ? this.function : null,
          child: Text(this.text, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}

class PlayingCard extends StatelessWidget {
  //final double card;
  final int value;
  final List suits;
  final Function onPressed;
  final bool selected;
  final bool horizontal;
  final Color borderColor;
  final bool fishIcon;
  final int amount;

  PlayingCard(
    this.value,
    this.suits, {
    @required this.onPressed,
    this.selected = false,
    this.horizontal = false,
    this.borderColor,
    this.fishIcon = false,
    this.amount = 0,
  });

  @override
  Widget build(BuildContext context) {
    double bigSide = 64; // 64
    double smallSide = 44; // 44

    return Container(
      //margin: EdgeInsets.all(4),
      height: !this.horizontal ? bigSide : smallSide,
      width: !this.horizontal ? smallSide : bigSide,
      child: OutlineButton(
        borderSide: BorderSide(
          color: this.borderColor == null
              ? this.selected
                  ? Colors.teal
                  : Colors.grey
              : this.borderColor,
        ),
        textColor: this.selected ? Colors.teal : null,
        highlightElevation: 4,
        //splashColor: Colors.teal,
        //highlightColor: Colors.teal,
        padding: EdgeInsets.all(0), // Interesting
        onPressed: this.onPressed,
        child: this.value > 0
            ? this.value == 15
                ? //Icon(MdiIcons.starFourPoints, color: cards.colors[0])
                Icon(MdiIcons.fleurDeLis, color: cards.colors[0])
                : Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(cards.getRank(this.value.toDouble()), style: TextStyle(fontSize: 16)),
                      if (this.fishIcon)
                        Icon(MdiIcons.fish, size: 16)
                      else if (this.amount > 1)
                        Text('x${this.amount}', style: TextStyle(fontSize: 12))
                      else if (this.suits.isNotEmpty)
                        Wrap(
                          alignment: WrapAlignment.spaceEvenly,
                          //runAlignment: WrapAlignment.spaceEvenly,
                          children: [
                            for (var suit in this.suits) Icon(cards.suits[suit], color: cards.colors[suit], size: 16)
                          ],
                        ),
                    ],
                  )
            : Icon(MdiIcons.judaism, color: Colors.teal),
      ),
    );
  }
}
