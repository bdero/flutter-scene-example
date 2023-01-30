// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:scene_demo/demo/demo.dart';
import 'package:scene_demo/demo/game.dart';

void main() {
  runApp(const DemoApp());
}

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scene Demo',
      theme: ThemeData(
          useMaterial3: true,
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: const Color(0xFF3a3a3a)),
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
  int widgetIndex = 0;

  @override
  Widget build(BuildContext context) {
    final widgets = [const DashWidget(), const GameWidget()];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            AnimatedOpacity(
              opacity: widgetIndex > 0 ? 1 : 0,
              duration: const Duration(milliseconds: 300),
              child: IconButton(
                onPressed: () => setState(() {
                  widgetIndex = max(0, widgetIndex - 1);
                }),
                icon: const Icon(Icons.arrow_back_ios),
              ),
            ),
            const Expanded(
                child: Text(
              'Scene Demo',
              textAlign: TextAlign.center,
            )),
            AnimatedOpacity(
              opacity: widgetIndex < widgets.length - 1 ? 1 : 0,
              duration: const Duration(milliseconds: 300),
              child: IconButton(
                onPressed: () => setState(() {
                  widgetIndex = min(widgets.length - 1, widgetIndex + 1);
                }),
                icon: const Icon(Icons.arrow_forward_ios),
              ),
            ),
          ],
        ),
      ),
      extendBodyBehindAppBar: false,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: widgets[widgetIndex]
              //child: IndexedStack(
              //  index: widgetIndex,
              //  children: widgets,
              //),
              ),
        ],
      ),
    );
  }
}
