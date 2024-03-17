import 'dart:math' as math;

import 'package:flutter_scene/scene.dart';
import 'package:scene_demo/demo/math_utils.dart';
import 'package:vector_math/vector_math_64.dart';

class Spike {
  static const kRestingHeight = 1.5;

  Vector3 position;
  double rotation = 0;

  double scale = 0;

  Vector3 startDestroyPosition = Vector3.zero();
  double destroyAnimation = 0;

  Spike(this.position);

  Node get node {
    return Node.transform(
      transform: Matrix4.translation(position) *
          Matrix4.rotationY(rotation) *
          math.min(1.0, 3 - 3 * destroyAnimation) *
          scale,
      children: [
        Node.asset("models/spike.glb"),
      ],
    );
  }

  void update(Vector3 playerPosition, double deltaSeconds) {
    if (destroyAnimation == 1) {
      return;
    }

    double distance = (playerPosition - position).length;
    if (distance < 2.2) {
      startDestroyPosition = position;
    }

    destroyAnimation = math.min(1, destroyAnimation + deltaSeconds * 2);
    position.y = startDestroyPosition.y + math.sin(destroyAnimation * 5) * 0.2;
    rotation += deltaSeconds * 10;

    scale = lerpDeltaTime(scale, 1, 0.1, deltaSeconds);
  }
}
