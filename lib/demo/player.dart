import 'dart:math' as math;

import 'package:flutter_scene/scene.dart';
import 'package:scene_demo/demo/math_utils.dart';
import 'package:vector_math/vector_math_64.dart';

enum JumpAnimationState {
  none,
  jumping,
  falling,
  landing,
}

class KinematicPlayer {
  /// 1/n seconds from zero velocity to full velocity.
  final double kAccelerationRate = 8;

  /// 1/n seconds from full velocity to zero velocity.
  /// This isn't a friction coefficient, it's an inverse acceleration rate.
  final double kFrictionRate = 4;

  /// Meters per second (Dash's body is exactly 2 meters wide).
  final double kMaxSpeed = 12;

  final double kJumpSpeed = 10;

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

  double _velocityY = 0;

  Vector2 _inputDirection = Vector2.zero();

  set inputDirection(Vector2 inputDirection) {
    _inputDirection = inputDirection;
    if (_inputDirection.length > 1) {
      _inputDirection.normalize();
    }
  }

  double damageCooldown = 0;

  double jumpCooldown = 0;
  bool requestJump = false;
  JumpAnimationState _jumpState = JumpAnimationState.none;
  double landingAnimationCooldown = 0;

  double groundedWeight = 1;
  double jumpStartWeight = 0;
  double landingWeight = 0;

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
    characterModel.setAnimationState(
        "Idle", true, true, (1 - speed) * groundedWeight, 1.2);
    characterModel.setAnimationState(
        "Run", true, true, speed * groundedWeight, 1.2);

    characterModel.setAnimationState(
        "JumpStart",
        _jumpState == JumpAnimationState.jumping ||
            _jumpState == JumpAnimationState.falling,
        false,
        jumpStartWeight,
        1.0);
    characterModel.setAnimationState("JumpLand",
        _jumpState == JumpAnimationState.landing, false, landingWeight, 1.0);

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

  get onGround {
    return _position.y == 0 && _velocityY == 0;
  }

  void update(double deltaSeconds) {
    if (damageCooldown > 0) {
      damageCooldown = math.max(0, damageCooldown - deltaSeconds);
    }

    // The user can hold the jump button for multiple frames to increase height.
    if (jumpCooldown > 0) {
      jumpCooldown = math.max(0, jumpCooldown - deltaSeconds);
      if (!requestJump || jumpCooldown == 0) {
        jumpCooldown = 0;
      } else {
        _velocityY = kJumpSpeed;
      }
    }

    // Begin jumping
    if (requestJump && onGround && jumpCooldown == 0) {
      _velocityY = kJumpSpeed;
      jumpCooldown = 0.2;
      _jumpState = JumpAnimationState.jumping;
    }

    // Jump animation state.
    switch (_jumpState) {
      case JumpAnimationState.jumping:
        if (_velocityY < 0) {
          _jumpState = JumpAnimationState.falling;
        } else if (onGround) {
          _jumpState = JumpAnimationState.landing;
          landingAnimationCooldown = 0.4;
        }
        break;
      case JumpAnimationState.falling:
        if (onGround) {
          _jumpState = JumpAnimationState.landing;
          landingAnimationCooldown = 0.4;
        }
        break;
      case JumpAnimationState.landing:
        if (landingAnimationCooldown > 0) {
          landingAnimationCooldown =
              math.max(0, landingAnimationCooldown - deltaSeconds);
        } else {
          _jumpState = JumpAnimationState.none;
        }
        break;
      case JumpAnimationState.none:
        break;
    }

    double groundedWeightDest = (_jumpState == JumpAnimationState.none ? 1 : 0);
    double jumpStartWeightDest = (_jumpState == JumpAnimationState.jumping ||
            _jumpState == JumpAnimationState.falling)
        ? 1
        : 0;
    double landingWeightDest = (_jumpState == JumpAnimationState.landing) ? 1 : 0;

    groundedWeight = math.max(groundedWeightDest,  math.min(1, 1 - landingAnimationCooldown * 6));
    jumpStartWeight = jumpStartWeightDest;
    landingWeight = landingWeightDest * math.min(1, landingAnimationCooldown * 4);
    print ("groundedWeight: $groundedWeight, jumpStartWeight: $jumpStartWeight, landingWeight: $landingWeight");

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

    // Apply gravity to velocity.
    _velocityY -= 9.8 * 4 * deltaSeconds;

    Vector3 velocity = Vector3(
        _velocityXZ.x * kMaxSpeed, _velocityY, _velocityXZ.y * kMaxSpeed);

    // Displace.
    _position += velocity * deltaSeconds;

    // Don't allow the player to walk though the back wall.
    if (_position.z > 14) {
      _position.z = 14;
      _velocityXZ.y = math.min(12, _velocityXZ.y);
    }

    // Don't allow the player to fall though the floor.
    if (_position.y < 0 && _position.y > -1 && _position.xz.length < 31) {
      _position.y = 0;
      _velocityY = 0;
    }

    // If the player falls off the stage, reset their position.
    if (_position.y < -10) {
      _position = Vector3(_position.x, 0, _position.z).normalized() * 25;
      _velocityXZ = Vector2.zero();
      _velocityY = 0;
      takeDamage();
    }

    // Rotate towards the direction of movement.
    if (_velocityXZ.length2 > 1e-3) {
      // TODO(bdero): Is `Quaternion.fromTwoVectors` busted? Also, there's no slerp operation.
      Quaternion rotation = Quaternion.axisAngle(
          Vector3(0, 1, 0),
          _direction.angleToSigned(
                  Vector3(velocity.x, 0, velocity.z).normalized(),
                  Vector3(0, -1, 0)) *
              0.2);
      rotation.rotate(_direction);
    }
  }
}
