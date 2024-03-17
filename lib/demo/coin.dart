import 'dart:math' as math;

import 'package:flutter_scene/scene.dart';
import 'package:scene_demo/demo/math_utils.dart';
import 'package:vector_math/vector_math_64.dart';

class Coin {
  static const kRestingHeight = 1.5;

  Vector3 position;
  double rotation = 0;
  bool collected = false;

  double scale = 0;

  Vector3 startCollectionPosition = Vector3.zero();
  double collectAnimation = 0;

  Coin(this.position);

  Node get node {
    return Node.transform(
      transform: Matrix4.translation(position) *
          Matrix4.rotationY(rotation) *
          math.min(1.0, 3 - 3 * collectAnimation) *
          scale,
      children: [
        Node.asset("models/coin.glb"),
      ],
    );
  }

  void update(Vector3 playerPosition, double deltaSeconds) {
    if (collected && collectAnimation == 1) {
      return;
    }

    if (!collected) {
      double distance = (playerPosition - position).length;
      if (distance < 2.2) {
        collected = true;
        startCollectionPosition = position;
      }
    }
    if (collected) {
      collectAnimation = math.min(1, collectAnimation + deltaSeconds * 2);
      position.y =
          startCollectionPosition.y + math.sin(collectAnimation * 5) * 0.2;
      rotation += deltaSeconds * 10;
    }

    scale = lerpDeltaTime(scale, 1, 0.1, deltaSeconds);

    rotation += deltaSeconds * 2;
  }
}
