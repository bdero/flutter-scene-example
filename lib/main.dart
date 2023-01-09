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

class Node {
  static Node asset(String assetUri) {
    Future<ui.SceneNode> node =
        ui.SceneNode.fromAsset('models/flutter_logo_baked.glb');
    node.onError((Object error, StackTrace stackTrace) {
      FlutterError.reportError(
          FlutterErrorDetails(exception: error, stack: stackTrace));
    });
    return Node(node);
  }

  static Node transform(Matrix4 transform, {List<Node>? children}) {
    Future<ui.SceneNode> node =
        Future<ui.SceneNode>(ui.SceneNode.fromTransform(transform.storage));
    return Node(node, children: children);
  }

  Node(node, {resolved, List<Node>? children})
      : _node = node,
        _children = children ?? [] {
    _node.then((ui.SceneNode result) => _resolvedNode = result);
  }

  Future<ui.SceneNode> _node;
  List<Node> _children;

  ui.SceneNode? _resolvedNode;
  bool _connected = false;

  void connectChildren() {
    if (_resolvedNode == null || _connected) return;
    _connected = true;

    for (var child in _children) {
      if (child._resolvedNode == null) {
        continue;
      }
      _resolvedNode.addChild(child._resolvedNode);
    }
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  ui.SceneNode? ipscene;
  Camera camera = Camera();
  Ticker? ticker;

  @override
  void initState() {
    super.initState();
    ui.SceneNode.fromAsset('models/flutter_logo_baked.glb').then(
        (ui.SceneNode scene) {
      if (!mounted) {
        return;
      }
      setState(() {
        ipscene = scene;
      });

      // Start a ticker to update the camera every frame.
      ticker = Ticker((time) {
        setState(() {
          double t = time.inMilliseconds / Duration.millisecondsPerSecond;
          camera.position = m64.Vector3(10 * sin(t), 10 * cos(t), -5);
        });
      });
      ticker!.start();
    }, onError: (Object error, StackTrace stackTrace) {
      FlutterError.reportError(
          FlutterErrorDetails(exception: error, stack: stackTrace));
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget child = SceneBox(
      root: ipscene,
      camera: camera,
      alwaysRepaint: true,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Scene Demo'),
      ),
      body: Container(child: child),
    );
  }
}
