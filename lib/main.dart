import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:arkit_plugin/arkit_plugin.dart';
import 'package:flutter/scheduler.dart';
import 'package:scene_demo/demo/game.dart';
import 'package:vector_math/vector_math_64.dart';

void main() => runApp(MaterialApp(home: MyApp()));

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Ticker? tick;

  ARKitController? arkitController;
  String anchorId = '';

  Matrix4 projectionMatrix = Matrix4.identity();
  Matrix4 viewMatrix = Matrix4.identity();
  Matrix4? anchorTransform;

  @override
  void initState() {
    tick = Ticker(
      (elapsed) {
        if (arkitController == null) {
          return;
        }
        arkitController?.cameraProjectionMatrix().then((value) => setState(() {
              if (value != null) {
                projectionMatrix = value;
              }
            }));
        arkitController?.pointOfViewTransform().then((value) => setState(() {
              if (value != null) {
                viewMatrix = value;
              }
            }));
      },
    );
    tick!.start();
    super.initState();
  }

  void onARKitViewCreated(ARKitController arkitController) {
    this.arkitController = arkitController;
    arkitController.addCoachingOverlay(CoachingOverlayGoal.horizontalPlane);
    arkitController.onAddNodeForAnchor = _handleAddAnchor;
    arkitController.onUpdateNodeForAnchor = _handleUpdateAnchor;
  }

  void _handleAddAnchor(ARKitAnchor anchor) {
    if (anchorId == '' && anchor is ARKitPlaneAnchor) {
      debugPrint('Added plane anchor ${anchor.identifier}');
      setState(() {
        anchorTransform = anchor.transform * Matrix4.translation(anchor.center);
      });
    }
  }

  void _handleUpdateAnchor(ARKitAnchor anchor) {
    if (anchor.identifier == anchorId && anchor is ARKitPlaneAnchor) {
      debugPrint('Anchor center: ${anchor.center}');
      debugPrint('Anchor transform: ${anchor.transform}');
      debugPrint(
          'Camera transform: ${arkitController?.pointOfViewTransform()}');
      setState(() {
        anchorTransform = anchor.transform * Matrix4.translation(anchor.center);
      });
    }
  }

  @override
  void dispose() {
    arkitController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //debugPrint('      view:\n${viewMatrix.toString()}');
    //debugPrint('    anchor:\n${anchorTransform?.toString()}');
    return Scaffold(
      body: Stack(
        children: [
          ARKitSceneView(
            showFeaturePoints: true,
            planeDetection: ARPlaneDetection.horizontal,
            onARKitViewCreated: onARKitViewCreated,
          ),
          if (anchorTransform != null)
            GameWidgetAR(projectionMatrix, viewMatrix, anchorTransform!),
        ],
      ),
    );
  }

  //void onARKitViewCreated(ARKitController arkitController) {
  //  this.arkitController = arkitController;
  //  final node = ARKitNode(
  //      geometry: ARKitSphere(radius: 0.1), position: Vector3(0, 0, -0.5));
  //  this.arkitController.add(node);
  //}
}
