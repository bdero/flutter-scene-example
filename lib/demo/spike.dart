import 'dart:math' as math;

import 'package:flutter_scene/scene.dart';
import 'package:scene_demo/demo/coin.dart';
import 'package:scene_demo/demo/game.dart';
import 'package:scene_demo/demo/math_utils.dart';
import 'package:scene_demo/demo/resource_cache.dart';
import 'package:scene_demo/demo/sound.dart';
import 'package:vector_math/vector_math.dart';

class Spike {
  static const kRestingHeight = 1.5;

  Spike(this.gameState, this.position) {
    node = ResourceCache.getModel('spike').clone();
  }

  final GameState gameState;
  late Node node;

  Vector3 position;
  double rotation = 0;

  double scale = 0;

  Vector3 startDestroyPosition = Vector3.zero();
  double destroyAnimation = 0;

  bool destroyed = false;

  double lifetime = 4;

  void updateNode() {
    node.globalTransform = Matrix4.translation(position) *
        Matrix4.rotationY(rotation) *
        math.min(1.0, 3 - 3 * destroyAnimation) *
        scale;
  }

  /// Returns false when the spike has completed the destruction animation.
  /// Returns true if the spike is still active and should continue being
  /// updated.
  bool update(double deltaSeconds) {
    lifetime -= deltaSeconds;
    if (lifetime < 0) {
      destroyed = true;
      startDestroyPosition = position;
    }
    if (destroyAnimation == 1) {
      return false;
    }

    if (!destroyed) {
      double distance =
          (gameState.player.position + Vector3(0, 1, 0) - position).length;
      if (distance < 1.6) {
        destroyed = true;
        startDestroyPosition = position;
        if (gameState.player.takeDamage()) {
          final coinsLost = math.min(10, gameState.coinsCollected);
          gameState.coinsCollected -= coinsLost;

          SoundServer().playShatter();

          // Coin shower.
          for (int i = 0; i < coinsLost; i++) {
            final xzAngle = i * math.pi * 2 / coinsLost;
            final direction = Vector3(
                    math.cos(xzAngle), //
                    5, //
                    math.sin(xzAngle))
                .normalized();
            gameState.coins.add(Coin(
              gameState,
              gameState.player.position + direction * 2.3,
              direction * 15,
            ));
          }
        }
      }
    }

    if (destroyed) {
      destroyAnimation = math.min(1, destroyAnimation + deltaSeconds * 2);
      position.y =
          startDestroyPosition.y + math.sin(destroyAnimation * 5) * 0.2;
      rotation += deltaSeconds * 10;
    }

    scale = lerpDeltaTime(scale, 1, 0.02, deltaSeconds);
    rotation += deltaSeconds * 2;

    updateNode();

    return true;
  }
}
