// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:scene_demo/demo/demo.dart';

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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scene Demo'),
      ),
      extendBodyBehindAppBar: false,
      body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ConstrainedBox(
              constraints:
                  BoxConstraints(maxHeight: MediaQuery.of(context).size.height),
              child: DashWidget(),
            ),
          ]),
    );
  }
}

//class _MyHomePageState extends State<MyHomePage> {
//  @override
//  void initState() {
//    super.initState();
//  }
//
//  @override
//  Widget build(BuildContext context) {
//    return Scaffold(
//      appBar: AppBar(
//        title: const Text('Scene Demo'),
//      ),
//      extendBodyBehindAppBar: false,
//      body: GestureSceneBox(
//        root: Node(position: vm.Vector3(0, -1.5, 0), children: [
//          for (double x = -4; x <= 3; x++)
//            for (double y = -4; y <= 3; y++)
//              for (double z = -4; z <= 3; z++)
//                Node(position: vm.Vector3(x * 4, y * 4, z * 4), children: [
//                  Node.asset('models/dash.glb', animations: ['Walk']),
//                ]),
//        ]),
//      ),
//    );
//  }
//}

//class _MyHomePageState extends State<MyHomePage> {
//  _MyHomePageState() {
//    dash = Node.asset('models/dash.glb');
//  }
//
//  late Node dash;
//
//  @override
//  void initState() {
//    super.initState();
//  }
//
//  @override
//  Widget build(BuildContext context) {
//    return Scaffold(
//      appBar: AppBar(
//        title: const Text('Scene Demo'),
//      ),
//      extendBodyBehindAppBar: false,
//      body: GestureSceneBox(
//        root: Node(
//          position: vm.Vector3(0, -1.5, 0),
//          children: [
//            for (double x = -4; x <= 4; x++)
//              for (double y = -4; y <= 4; y++)
//                for (double z = -4; z <= 4; z++)
//                  Node(
//                    position: vm.Vector3(x * 3.5, y * 3.5, z * 3.5),
//                    children: [dash],
//                  ),
//          ],
//        ),
//      ),
//    );
//  }
//}

