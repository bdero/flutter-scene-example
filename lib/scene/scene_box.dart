// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';

import 'camera.dart';

/// Responsible for rendering a given SceneNode using a camera transform.
class SceneRenderBox extends RenderBox {
  SceneRenderBox(
      {ui.SceneNode? node, Camera? camera, bool alwaysRepaint = false})
      : camera_ = camera {
    this.node = node;
    this.alwaysRepaint = alwaysRepaint;
  }

  ui.SceneShader? _shader;
  ui.SceneNode? _node;

  set node(ui.SceneNode? node) {
    _shader = node?.sceneShader();
    _node = node;

    markNeedsPaint();
  }

  Camera? camera_;
  set camera(Camera? camera) {
    camera_ = camera;

    markNeedsPaint();
  }

  Ticker? _ticker;
  Size _size = Size.zero;

  set alwaysRepaint(bool alwaysRepaint) {
    if (alwaysRepaint) {
      _ticker = Ticker((_) => markNeedsPaint());
      markNeedsPaint();
    } else {
      _ticker = null;
    }
  }

  @override
  void attach(covariant PipelineOwner owner) {
    super.attach(owner);
    _ticker?.start();
  }

  @override
  void detach() {
    super.detach();
    _ticker?.stop();
  }

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    // Expand to take up as much space as allowed.
    _size = constraints.biggest;
    return constraints.biggest;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_shader == null) {
      return;
    }

    Camera camera = camera_ ?? Camera();
    _shader!
        .setCameraTransform(camera.computeTransform(size.aspectRatio).storage);

    context.canvas.drawRect(Rect.fromLTWH(0, 0, _size.width, _size.height),
        Paint()..shader = _shader);
  }
}

/// Draws a given ui.SceneNode using a given camera.
/// This is the lowest level widget for drawing an 3D scene.
class SceneBoxUI extends LeafRenderObjectWidget {
  const SceneBoxUI(
      {Key? key, this.root, this.camera, this.alwaysRepaint = false})
      : super(key: key);
  final ui.SceneNode? root;
  final Camera? camera;
  final bool alwaysRepaint;

  @override
  RenderBox createRenderObject(BuildContext context) {
    return SceneRenderBox(
        node: root, camera: camera, alwaysRepaint: alwaysRepaint);
  }

  @override
  void updateRenderObject(BuildContext context, SceneRenderBox renderObject) {
    renderObject.node = root;
    renderObject.camera = camera;
    renderObject.alwaysRepaint = alwaysRepaint;
    super.updateRenderObject(context, renderObject);
  }
}

/// An immutable Scene node for conveniently building during widget tree construction.
class Node {
  static Node asset(String assetUri) {
    Future<ui.SceneNode> node = ui.SceneNode.fromAsset(assetUri);
    return Node._(node);
  }

  static Node transform({Matrix4? transform, List<Node>? children}) {
    Matrix4 t = transform ?? Matrix4.identity();
    Future<ui.SceneNode> node =
        Future<ui.SceneNode>.value(ui.SceneNode.fromTransform(t.storage));
    return Node._(node, children: children);
  }

  factory Node({Vector3? position, List<Node>? children}) {
    Matrix4 transform = Matrix4.identity();
    if (position != null) {
      transform *= Matrix4.translation(position);
    }
    return Node.transform(transform: transform, children: children);
  }

  Node._(node, {List<Node>? children})
      : _node = node,
        _children = children ?? [] {
    _node.then((ui.SceneNode result) => _resolvedNode = result);
  }

  late final Future<ui.SceneNode> _node;
  final List<Node> _children;

  ui.SceneNode? _resolvedNode;
  bool _connected = false;

  /// Walk the immutable tree and form the internal scene graph by parenting the
  /// ui.SceneNodes to eachother.
  void connectChildren() {
    if (_resolvedNode == null || _connected) return;
    _connected = true;

    for (var child in _children) {
      if (child._resolvedNode == null) {
        child._node.then((value) {
          _resolvedNode!.addChild(child._resolvedNode!);
          child.connectChildren();
        });
        continue;
      }
      _resolvedNode!.addChild(child._resolvedNode!);
      child.connectChildren();
    }
  }

  void onLoadingComplete(Function(ui.SceneNode node) callback) {
    if (_resolvedNode != null) {
      callback(_resolvedNode!);
      return;
    }

    _node.whenComplete(() {
      if (_resolvedNode != null) callback(_resolvedNode!);
    });
  }
}

class SceneBox extends StatefulWidget {
  const SceneBox(
      {super.key, required this.root, this.camera, this.alwaysRepaint = false});

  final Node root;
  final Camera? camera;
  final bool alwaysRepaint;

  @override
  State<StatefulWidget> createState() => _SceneBox();
}

class _SceneBox extends State<SceneBox> {
  @override
  Widget build(BuildContext context) {
    if (widget.root._resolvedNode == null) {
      widget.root.onLoadingComplete((node) {
        // Kick the state to trigger a rebuild of the widget tree as soon as the
        // node is ready.
        if (mounted) setState(() {});
      });
      return const SizedBox.expand();
    }

    widget.root.connectChildren();

    return SceneBoxUI(
        root: widget.root._resolvedNode,
        camera: widget.camera,
        alwaysRepaint: widget.alwaysRepaint);
  }
}

class GestureSceneBox extends StatefulWidget {
  const GestureSceneBox({super.key, required this.root});

  final Node root;

  @override
  State<GestureSceneBox> createState() => _GestureSceneBoxState();
}

class _GestureSceneBoxState extends State<GestureSceneBox> {
  Vector3 _direction = Vector3(0, 0, -1);
  double _distance = 5;

  double _startScaleDistance = 1;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onScaleStart: (details) {
        _startScaleDistance = _distance;
      },
      onScaleEnd: (details) {},
      onScaleUpdate: (details) {
        setState(() {
          _distance = _startScaleDistance / details.scale;

          double panDistance = details.focalPointDelta.distance;
          if (panDistance < 1e-3) {
            return;
          }

          // TODO(bdero): Compute this transform more efficiently.
          Matrix4 viewToWorldTransform = Matrix4.inverted(
              matrix4LookAt(Vector3.zero(), -_direction, Vector3(0, 1, 0)));

          Vector3 screenSpacePanDirection = Vector3(
                  details.focalPointDelta.dx, -details.focalPointDelta.dy, 0)
              .normalized();
          Vector3 screenSpacePanAxis =
              screenSpacePanDirection.cross(Vector3(0, 0, 1)).normalized();
          Vector3 panAxis = viewToWorldTransform * screenSpacePanAxis;
          Vector3 newDirection =
              Quaternion.axisAngle(panAxis, panDistance / 100)
                  .rotate(_direction)
                  .normalized();
          if (newDirection.length > 1e-1) {
            _direction = newDirection;
          }
        });
      },
      behavior: HitTestBehavior.translucent,
      child: SceneBox(
        root: widget.root,
        camera: Camera(position: _direction * _distance),
      ),
    );
  }
}
