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
class SceneBox extends LeafRenderObjectWidget {
  const SceneBox({Key? key, this.root, this.camera, this.alwaysRepaint = false})
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
