import 'dart:math' as math;

import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math_64.dart';

class Coin {
  Vector3 position;
  double rotation = 0;
  bool collected = false;

  Vector3 startAnimPosition = Vector3.zero();
  double collectAnimation = 0;

  Coin(this.position);

  Node get node {
    return Node.transform(
      transform: Matrix4.translation(position) *
          Matrix4.rotationY(rotation) *
          math.min(1.0, 3 - 3 * collectAnimation),
      children: [
        Node.asset("models/coin.glb"),
      ],
    );
  }

  Node? update(Vector3 playerPosition, double deltaSeconds) {
    if (collected && collectAnimation == 1) {
      return null;
    }

    if (!collected) {
      double distance = (playerPosition - position).length;
      if (distance < 2.2) {
        collected = true;
        startAnimPosition = position;
      }
    }
    if (collected) {
      collectAnimation = math.min(1, collectAnimation + deltaSeconds * 2);
      position.y = startAnimPosition.y + math.sin(collectAnimation * 5) * 0.2;
      rotation += deltaSeconds * 10;
    }

    rotation += deltaSeconds * 2;

    return node;
  }
}
