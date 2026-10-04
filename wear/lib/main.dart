// Aplikace pro hodinky s Wear OS: zápis sérií během tréninku.
//
// Doplněk k aplikaci v telefonu (stejné applicationId, stejný podpisový
// klíč – jinak spolu přes Data Layer nemluví). Stav tréninku drží telefon,
// hodinky ho jen zobrazují a posílají příkazy. Návod: docs/wear_os.md.

import 'package:flutter/material.dart';
import 'package:wear_plus/wear_plus.dart';

import 'ui/ambient_view.dart';
import 'ui/home.dart';
import 'watch_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FitnessWearApp());
}

/// Barva aplikace v telefonu (seed motivu).
const kSeedColor = Color(0xFF2E7D6B);

class FitnessWearApp extends StatefulWidget {
  const FitnessWearApp({super.key});

  @override
  State<FitnessWearApp> createState() => _FitnessWearAppState();
}

class _FitnessWearAppState extends State<FitnessWearApp> {
  late final WatchController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WatchController()..start();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: kSeedColor,
      brightness: Brightness.dark,
    ).copyWith(surface: Colors.black);
    return MaterialApp(
      title: _controller.strings.appTitle,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: Colors.black,
        visualDensity: VisualDensity.compact,
      ),
      home: Scaffold(
        body: WatchShape(
          builder: (context, shape, child) => AmbientMode(
            builder: (context, mode, child) => mode == WearMode.ambient
                ? AmbientView(controller: _controller)
                : WatchHome(
                    controller: _controller,
                    round: shape == WearShape.round,
                  ),
          ),
        ),
      ),
    );
  }
}
