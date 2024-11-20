// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:scene_demo/demo/game.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final soloud = SoLoud.instance;

  soloud.init().then((_) {
    debugPrint("SoLoud initialized.");
  }).catchError((error) {
    debugPrint("SoLoud initialization failed: $error");
  });

  runApp(const SceneExample());
}

class SceneExample extends StatelessWidget {
  const SceneExample({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scene Demo',
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF3a3a3a),
      ),
      home: const DemoPage(),
    );
  }
}

class DemoPage extends StatefulWidget {
  const DemoPage({super.key});

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: GameWidget());
  }
}
