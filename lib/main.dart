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
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scene Demo'),
      ),
      extendBodyBehindAppBar: false,
      body: GestureSceneBox(
        root: //Node(children: [
            //for (double x = -5; x <= 10; x++)
            //  for (double y = -5; y <= 10; y++)
            //    for (double z = -5; z <= 10; z++)
            //      Node(position: m64.Vector3(x * 2, y * 2, z * 2), children: [
            Node.asset('models/dash.glb'),
        //      ]),
        //]),
      ),
    );
  }
}
