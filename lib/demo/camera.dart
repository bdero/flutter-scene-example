import 'dart:math' as math;

import 'package:flutter_scene/camera.dart';
import 'package:vector_math/vector_math_64.dart';

Vector3 vector3Lerp(Vector3 a, Vector3 b, double t) {
  return a + (b - a) * t;
}

Vector3 vector3LerpDeltaTime(Vector3 a, Vector3 b, double t, double deltaTime) {
  return vector3Lerp(a, b, math.min(1, 1 - math.pow(t, deltaTime).toDouble()));
}

class FollowCamera {
  static final Vector3 kFollowOffset = Vector3(0, 10, -12);

  static final Vector3 kLogoArea = Vector3(0, 5, 15);
  static const double kLogoRadius = 11;
  static final Vector3 kLogoFollowOffset = Vector3(0, -2, -25) * 1;

  static final Vector3 kOverviewArea = Vector3(-20, 0, 24);
  static const double kOverviewRadius = 10;
  static final Vector3 kOverviewCameraPosition = Vector3(5, 50, -70);

  Vector3 position = Vector3(0, 3, -5);
  Vector3 target = Vector3.zero();

  Camera get camera => Camera(position: position, target: target);

  void updateGameplay(
      Vector3 cameraTarget, Vector3 movementDirection, double deltaSeconds) {
    Vector3 destinationPosition =
        target + kFollowOffset * (1 + movementDirection.length / 15);

    Vector3 destinationTarget =
        cameraTarget + Vector3(0, 2, 0) + movementDirection * 0.6;

    if ((cameraTarget - kLogoArea).length < kLogoRadius) {
      destinationPosition = kLogoArea + kLogoFollowOffset;
      destinationTarget = vector3Lerp(destinationTarget, kLogoArea, 0.6);
    }

    if ((cameraTarget - kOverviewArea).length < kOverviewRadius) {
      destinationPosition = kOverviewCameraPosition;
      destinationTarget =
          Vector3.zero(); //vector3Lerp(destinationTarget, Vector3.zero(), 0.8);

      position = vector3LerpDeltaTime(
          position, destinationPosition, 0.4, deltaSeconds);
      target =
          vector3LerpDeltaTime(target, destinationTarget, 0.4, deltaSeconds);
    } else {
      position = vector3LerpDeltaTime(
          position, destinationPosition, 0.1, deltaSeconds);
      target =
          vector3LerpDeltaTime(target, destinationTarget, 0.1, deltaSeconds);
    }
  }

  void updateOverview(double deltaSeconds, double timeElapsed) {
    position = vector3LerpDeltaTime(
        position,
        Vector3(math.sin(timeElapsed/5) * 7, 5, -math.cos(timeElapsed/5) * 7) * 6,
        0.6,
        deltaSeconds);
    target = vector3LerpDeltaTime(target, Vector3.zero(), 0.4, deltaSeconds);
  }
}
