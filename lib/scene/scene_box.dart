// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/material.dart';

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
class SceneNode {
  static SceneNode asset(String assetUri) {
    Future<ui.SceneNode> node =
        ui.SceneNode.fromAsset('models/flutter_logo_baked.glb');
    //node.onError((Object error, StackTrace stackTrace) {
    //  FlutterError.reportError(
    //      FlutterErrorDetails(exception: error, stack: stackTrace));
    //});
    return SceneNode(node);
  }

  static SceneNode transform(Matrix4 transform, {List<SceneNode>? children}) {
    Future<ui.SceneNode> node = Future<ui.SceneNode>.value(
        ui.SceneNode.fromTransform(transform.storage));
    return SceneNode(node, children: children);
  }

  SceneNode(node, {resolved, List<SceneNode>? children})
      : _node = node,
        _children = children ?? [] {
    _node.then((ui.SceneNode result) => _resolvedNode = result);
  }

  final Future<ui.SceneNode> _node;
  final List<SceneNode> _children;

  ui.SceneNode? _resolvedNode;
  bool _connected = false;

  /// Walk the immutable tree and form the internal scene graph by parenting the
  /// ui.SceneNodes to eachother.
  void connectChildren() {
    if (_resolvedNode == null || _connected) return;
    _connected = true;

    for (var child in _children) {
      if (child._resolvedNode == null) {
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

  final SceneNode root;
  final Camera? camera;
  final bool alwaysRepaint;

  @override
  State<StatefulWidget> createState() {
    return _SceneBox();
  }
}

class _SceneBox extends State<SceneBox> {
  @override
  void initState() {
    widget.root.onLoadingComplete((node) {
      // Kick the state to trigger a rebuild of the widget tree as soon as the
      // node is ready.
      if (mounted) setState(() {});
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.root._resolvedNode == null) {
      return const SizedBox.expand();
    }

    widget.root.connectChildren();
    return SceneBoxUI(
        root: widget.root._resolvedNode,
        camera: widget.camera,
        alwaysRepaint: widget.alwaysRepaint);
  }
}
