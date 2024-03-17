import 'dart:math' as math;

import 'package:flutter_scene/scene.dart';
import 'package:scene_demo/demo/game.dart';
import 'package:scene_demo/demo/math_utils.dart';
import 'package:vector_math/vector_math_64.dart';

class Coin {
  static const kRestingHeight = 1.5;

  Coin(this.gameState, this.position);

  final GameState gameState;

  Vector3 position;
  double rotation = 0;
  bool collected = false;

  double scale = 0;

  Vector3 startCollectionPosition = Vector3.zero();
  double collectAnimation = 0;

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

  /// Returns false when the coin has completed the destruction animation.
  /// Returns true if the coin is still active and should continue being
  /// updated.
  bool update(double deltaSeconds) {
    if (collected && collectAnimation == 1) {
      return false;
    }

    if (!collected) {
      double distance = (gameState.player.position - position).length;
      if (distance < 2.2) {
        collected = true;
        startCollectionPosition = position;
        gameState.coinsCollected++;
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

    return true;
  }
}
