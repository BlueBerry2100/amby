import 'package:flutter/material.dart';

import 'app_state.dart';
import 'audio_engine.dart';
import 'look/look.dart';
import 'ui/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(AmbyApp(state: AppState(AudioEngine())));
}

class AmbyApp extends StatefulWidget {
  const AmbyApp({super.key, required this.state});

  final AppState state;

  @override
  State<AmbyApp> createState() => _AmbyAppState();
}

class _AmbyAppState extends State<AmbyApp> {
  late final Future<void> _loading = widget.state.load();

  @override
  Widget build(BuildContext context) {
    // тема зависит от выбранного оформления и акцента
    return ListenableBuilder(
      listenable: widget.state,
      builder: (context, _) => MaterialApp(
        title: 'Amby',
        debugShowCheckedModeBanner: false,
        theme: widget.state.theme,
        home: FutureBuilder(
          future: _loading,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Scaffold(
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Не удалось запустить:\n${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            }
            if (snapshot.connectionState != ConnectionState.done) {
              return Scaffold(
                body: Center(child: Text('AMBY', style: Look.of(context).display(46))),
              );
            }
            return HomeScreen(state: widget.state);
          },
        ),
      ),
    );
  }
}
