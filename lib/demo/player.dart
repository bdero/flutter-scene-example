import 'dart:math' as math;

import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math_64.dart';

class KinematicPlayer {
  /// 1/n seconds from zero velocity to full velocity.
  final double kAccelerationRate = 8;

  /// 1/n seconds from full velocity to zero velocity.
  /// This isn't a friction coefficient, it's an inverse acceleration rate.
  final double kFrictionRate = 4;

  /// Meters per second (Dash's body is exactly 2 meters wide).
  final double kMaxSpeed = 12;

  Vector3 _position = Vector3.zero();
  Vector3 get position {
    return _position;
  }

  Vector3 _direction = Vector3(0, 0, -1);

  /// Magnitude range: 0 -> 1. Multiplied by kMaxSpeed.
  Vector2 _velocityXZ = Vector2.zero();
  Vector2 get velocityXZ {
    return _velocityXZ;
  }

  Vector2 _inputDirection = Vector2.zero();

  set inputDirection(Vector2 inputDirection) {
    _inputDirection = inputDirection;
    if (_inputDirection.length > 1) {
      _inputDirection.normalize();
    }
  }

  double damageCooldown = 0;

  Node get node {
    if (damageCooldown % 0.2 > 0.12) {
      return Node();
    }

    Matrix4 transform = Matrix4.translation(_position) *
        Matrix4.rotationY(
            Vector3(0, 0, -1).angleToSigned(_direction, Vector3(0, 1, 0)));

    double speed = _velocityXZ.length;

    Node characterModel = Node.asset("models/dash.glb");
    characterModel.setAnimationState("Walk", false, true, 0.0, 1.0);
    characterModel.setAnimationState("Idle", true, true, 1 - speed, 1.2);
    characterModel.setAnimationState("Run", true, true, speed, 1.2);
    //characterModel.setAnimationState("Blink", true, true, 1.0, 1.0);

    return Node.transform(
      transform: transform,
      children: [characterModel],
    );
  }

  /// Returns true if the player took damage.
  bool takeDamage() {
    if (damageCooldown > 0) {
      return false;
    }
    damageCooldown = 2;
    _velocityXZ = Vector2.zero();
    return true;
  }

  void update(double deltaSeconds) {
    if (damageCooldown > 0) {
      damageCooldown = math.max(0, damageCooldown - deltaSeconds);
    }

    // Speed up when there's input.
    if (_inputDirection.length2 > 1e-3) {
      _velocityXZ += _inputDirection * kAccelerationRate * deltaSeconds;
      if (_velocityXZ.length > 1) {
        _velocityXZ.normalize();
      }
    }
    // Slow down when there's no input.
    else if (_velocityXZ.length2 > 0) {
      double speed =
          math.max(0, _velocityXZ.length - kFrictionRate * deltaSeconds);
      _velocityXZ = _velocityXZ.normalized() * speed;
    }

    Vector3 velocity = Vector3(_velocityXZ.x, 0, _velocityXZ.y);

    // Apply velocity.
    _position += velocity * kMaxSpeed * deltaSeconds;

    // Rotate towards the direction of movement.
    if (_velocityXZ.length2 > 1e-3) {
      // TODO(bdero): Is `Quaternion.fromTwoVectors` busted? Also, there's no slerp operation.
      Quaternion rotation = Quaternion.axisAngle(
          Vector3(0, 1, 0),
          _direction.angleToSigned(velocity.normalized(), Vector3(0, -1, 0)) *
              0.2);
      rotation.rotate(_direction);
    }
  }
}
