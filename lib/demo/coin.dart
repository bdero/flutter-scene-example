import 'dart:math' as math;

import 'package:flutter_scene/scene.dart';
import 'package:scene_demo/demo/game.dart';
import 'package:scene_demo/demo/math_utils.dart';
import 'package:scene_demo/demo/sound.dart';
import 'package:vector_math/vector_math_64.dart';

class Coin {
  static const kRestingHeight = 1.5;

  Coin(this.gameState, this.position, this.velocity);

  final GameState gameState;

  Vector3 position;
  Vector3 velocity;
  double rotation = 0;
  bool collected = false;

  double lifetime = 8;

  double scale = 0;

  Vector3 startCollectionPosition = Vector3.zero();
  double collectAnimation = 0;

  Node get node {
    if (lifetime < 3 && lifetime % 0.2 > 0.12) {
      return Node();
    }
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
    lifetime -= deltaSeconds;
    if (lifetime < 0) {
      return false;
    }

    if (collected && collectAnimation == 1) {
      return false;
    }

    if (!collected) {
      // Deal with gravity and bouncing.
      if (!(position.y == kRestingHeight && velocity.y == 0)) {
        velocity.y -= 9.8 * 4 * deltaSeconds;
        position += velocity * deltaSeconds;

        // Bounce at the resting height.
        if (position.y < kRestingHeight) {
          position.y = kRestingHeight + (kRestingHeight - position.y);
          velocity.y *= -0.5;
          if (velocity.y.abs() < 0.2) {
            position.y = kRestingHeight;
            velocity.y = 0;
          }
        }
        // Once at the resting height, apply friction.
      } else if (velocity.length2 > 0) {
        velocity.xz /= math.pow(8, deltaSeconds).toDouble();
        position.xz += velocity.xz * deltaSeconds;
      }

      double distance = (gameState.player.position - position).length;
      if (distance < 2.2) {
        collected = true;
        startCollectionPosition = position;
        gameState.coinsCollected++;
        SoundServer().playPickupCoin();
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
