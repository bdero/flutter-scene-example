import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_scene/scene.dart';
import 'package:flutter_scene/camera.dart';
import 'package:scene_demo/demo/camera.dart';
import 'package:scene_demo/demo/coin.dart';
import 'package:scene_demo/demo/player.dart';
import 'package:scene_demo/demo/player_controller.dart';
import 'package:vector_math/vector_math_64.dart';

class GameWidget extends StatefulWidget {
  const GameWidget({super.key});

  @override
  State<GameWidget> createState() => _GameWidgetState();
}

class CoinCollection {
  final List<Coin> coins = [
    Coin(Vector3(-1.4 - 0.8 * 0, 1.5, -6 - 2 * 0)),
    Coin(Vector3(-1.4 - 0.8 * 1, 1.5, -6 - 2 * 1)),
    Coin(Vector3(-1.4 - 0.8 * 2, 1.5, -6 - 2 * 2)),
    Coin(Vector3(-1.4 - 0.8 * 3, 1.5, -6 - 2 * 3)),
    //
    Coin(Vector3(-15 + 2 * 0, 1.5, 0.5 - 1.2 * 0)),
    Coin(Vector3(-15 + 2 * 1, 1.5, 0.5 - 1.2 * 1)),
    Coin(Vector3(-15 + 2 * 2, 1.5, 0.5 - 1.2 * 2)),
    Coin(Vector3(-15 + 2 * 3, 1.5, 0.5 - 1.2 * 3)),
    //
    Coin(Vector3(7 + 2 * 0, 1.5, -16 + 1.3 * 0)),
    Coin(Vector3(7 + 2 * 1, 1.5, -16.5 + 1.3 * 1)),
    Coin(Vector3(7 + 2 * 2, 1.5, -16.5 + 1.3 * 2)),
    Coin(Vector3(7 + 2 * 3, 1.5, -16 + 1.3 * 3)),
  ];

  Node update(Vector3 playerPosition, double deltaSeconds) {
    return Node(
      // TODO(bdero): Can this be made more efficient?
      children: coins
          .map((coin) => coin.update(playerPosition, deltaSeconds))
          .whereType<Node>()
          .toList(growable: false),
    );
  }
}

class _GameWidgetState extends State<GameWidget> {
  Ticker? tick;
  double time = 0;
  double deltaSeconds = 0;

  final PlayerController playerController = PlayerController();
  final KinematicPlayer player = KinematicPlayer();
  final FollowCamera camera = FollowCamera();
  final CoinCollection coins = CoinCollection();

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
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    playerController.updatePlayer(player);
    player.update(deltaSeconds);

    return playerController.getControlWidget(
      context,
      SceneBox(
        root: Node(children: [
          Node.asset("models/ground.glb"),
          player.node,
          Node.transform(
            transform:
                Matrix4.translation(camera.position) * Matrix4.rotationY(3),
            children: [Node.asset("models/sky_sphere.glb")],
          ),
          coins.update(player.position, deltaSeconds),
        ]),
        camera: camera.update(
            player.position,
            Vector3(player.velocityXZ.x, 0, player.velocityXZ.y) *
                player.kMaxSpeed,
            deltaSeconds),
      ),
    );
  }
}
