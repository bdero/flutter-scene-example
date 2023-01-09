// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/scheduler.dart';
import 'package:vector_math/vector_math_64.dart' as m64;
import 'package:flutter/material.dart';

import 'scene/camera.dart';
import 'scene/scene_box.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scene Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  //ui.SceneNode? ipscene;
  //Camera camera = Camera();
  //Ticker? ticker;

  @override
  void initState() {
    super.initState();
    //ui.SceneNode.fromAsset('models/flutter_logo_baked.glb')
    //    .then((ui.SceneNode scene) {
    //  if (!mounted) {
    //    return;
    //  }
    //  setState(() {
    //    ipscene = scene;
    //  });
    //
    //  // Start a ticker to update the camera every frame.
    //  ticker = Ticker((time) {
    //    setState(() {
    //      double t = time.inMilliseconds / Duration.millisecondsPerSecond;
    //      camera.position = m64.Vector3(10 * sin(t), 10 * cos(t), -5);
    //    });
    //  });
    //  ticker!.start();
    //});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scene Demo'),
      ),
      body: Container(
        child: GestureSceneBox(
          root: SceneNode.asset('models/flutter_logo_baked.glb'),
        ),
      ),
    );
  }
}
