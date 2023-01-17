import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:scene_demo/scene/camera.dart';
import 'package:scene_demo/scene/scene_box.dart';
import 'package:vector_math/vector_math_64.dart';

class GameWidget extends StatefulWidget {
  const GameWidget({super.key});

  @override
  State<GameWidget> createState() => _GameWidgetState();
}

class KinematicPlayer {
  /// 1/n seconds from zero veclocity to full velocity.
  final double kAccelerationRate = 8;

  /// 1/n seconds from full velocity to zero velocity.
  /// This isn't a friction coefficient, it's an inverse acceleration rate.
  final double kFrictionRate = 4;

  /// Meters per second (Dash's body is exactly 2 meters wide).
  final double kMaxSpeed = 8;

  Vector3 _position = Vector3.zero();
  Vector3 get position {
    return _position;
  }

  Vector3 _direction = Vector3(0, 0, -1);

  /// Magnitude range: 0 -> 1. Multiplied by kMaxSpeed.
  Vector2 _velocityXZ = Vector2.zero();

  Vector2 _inputDirection = Vector2.zero();

  set inputDirection(Vector2 inputDirection) {
    _inputDirection = inputDirection;
    if (_inputDirection.length > 1) {
      _inputDirection.normalize();
    }
  }

  Node get node {
    Matrix4 transform = Matrix4.translation(_position) *
        Matrix4.rotationY(
            Vector3(0, 0, -1).angleToSigned(_direction, Vector3(0, 1, 0)));

    double speed = _velocityXZ.length;

    Node characterModel = Node.asset("models/dash.glb");
    characterModel.setAnimationState("Walk", true, true, 0.0, 1.0);
    characterModel.setAnimationState("Run", true, true, speed, 1.0);

    return Node.transform(
      transform: transform,
      children: [characterModel],
    );
  }

  Node update(double deltaSeconds) {
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

    return node;
  }
}

Vector3 vector3Lerp(Vector3 a, Vector3 b, double t) {
  return a + (b - a) * t;
}

Vector3 vector3LerpDeltaTime(Vector3 a, Vector3 b, double t, double deltaTime) {
  return vector3Lerp(a, b, math.min(1, 1 - math.pow(t, deltaTime).toDouble()));
}

class FollowCamera {
  final Vector3 kFollowOffset = Vector3(0, 10, -12);
  Vector3 position = Vector3(0, 3, -5);

  Camera update(Vector3 target, double deltaSeconds) {
    Vector3 destinationPosition = target + kFollowOffset;
    position =
        vector3LerpDeltaTime(position, destinationPosition, 0.1, deltaSeconds);
    return Camera(position: position, target: target + Vector3(0, 2, 0));
  }
}

class _GameWidgetState extends State<GameWidget> {
  Ticker? tick;
  double time = 0;
  double deltaSeconds = 0;

  final KinematicPlayer player = KinematicPlayer();
  final FollowCamera camera = FollowCamera();

  @override
  void initState() {
    tick = Ticker(
      (elapsed) {
        setState(() {
          double previousTime = time;
          time = elapsed.inMilliseconds / 1000.0;
          deltaSeconds = previousTime > 0 ? time - previousTime : 0;
        });
      },
    );
    tick!.start();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final Offset center = Offset(
            MediaQuery.of(context).size.width,
            MediaQuery.of(context).size.height -
                (Scaffold.of(context).appBarMaxHeight ?? 0)) /
        2;
    final double inputMapping = 1 / math.min(center.dx, center.dy);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onScaleStart: (details) {
        var dir = (details.localFocalPoint - center) * inputMapping;
        player.inputDirection = Vector2(dir.dx, -dir.dy);
      },
      onScaleUpdate: (details) {
        var dir = (details.localFocalPoint - center) * inputMapping;
        player.inputDirection = Vector2(dir.dx, -dir.dy);
      },
      onScaleEnd: (details) {
        player.inputDirection = Vector2.zero();
      },
      child: SceneBox(
        root: Node(children: [
          Node.asset("models/ground.glb"),
          player.update(deltaSeconds),
          Node.transform(
            transform:
                Matrix4.translation(camera.position) * Matrix4.rotationY(time),
            children: [Node.asset("models/sky_sphere.glb")],
          ),
        ]),
        camera: camera.update(player.position, deltaSeconds),
      ),
    );
  }
}
