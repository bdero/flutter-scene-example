import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_scene/scene.dart';
import 'package:flutter_scene/camera.dart';
import 'package:scene_demo/demo/camera.dart';
import 'package:scene_demo/demo/coin.dart';
import 'package:scene_demo/demo/player.dart';
import 'package:scene_demo/demo/input_actions.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

class GameWidget extends StatefulWidget {
  const GameWidget({super.key});

  @override
  State<GameWidget> createState() => _GameWidgetState();
}

class CoinController {
  final List<Coin> coins = [
    Coin(vm.Vector3(-1.4 - 0.8 * 0, 1.5, -6 - 2 * 0)),
    Coin(vm.Vector3(-1.4 - 0.8 * 1, 1.5, -6 - 2 * 1)),
    Coin(vm.Vector3(-1.4 - 0.8 * 2, 1.5, -6 - 2 * 2)),
    Coin(vm.Vector3(-1.4 - 0.8 * 3, 1.5, -6 - 2 * 3)),
    //
    Coin(vm.Vector3(-15 + 2 * 0, 1.5, 0.5 - 1.2 * 0)),
    Coin(vm.Vector3(-15 + 2 * 1, 1.5, 0.5 - 1.2 * 1)),
    Coin(vm.Vector3(-15 + 2 * 2, 1.5, 0.5 - 1.2 * 2)),
    Coin(vm.Vector3(-15 + 2 * 3, 1.5, 0.5 - 1.2 * 3)),
    //
    Coin(vm.Vector3(7 + 2 * 0, 1.5, -16 + 1.3 * 0)),
    Coin(vm.Vector3(7 + 2 * 1, 1.5, -16.5 + 1.3 * 1)),
    Coin(vm.Vector3(7 + 2 * 2, 1.5, -16.5 + 1.3 * 2)),
    Coin(vm.Vector3(7 + 2 * 3, 1.5, -16 + 1.3 * 3)),
  ];

  void update(vm.Vector3 playerPosition, double deltaSeconds) {
    for (var coin in coins) {
      coin.update(playerPosition, deltaSeconds);
    }
  }

  Node get node {
    return Node(
      children: coins.map((coin) => coin.node).toList(growable: false),
    );
  }
}

class HUDBox extends StatelessWidget {
  const HUDBox({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          color: Colors.white.withOpacity(0.1),
          child: DefaultTextStyle.merge(
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              shadows: [
                Shadow(
                  blurRadius: 4,
                  color: Colors.black,
                  offset: Offset(2, 2),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class HUDLabelText extends StatelessWidget {
  const HUDLabelText({super.key, required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return RichText(
      softWrap: false,
      overflow: TextOverflow.clip,
      text: TextSpan(
        style: DefaultTextStyle.of(context).style,
        text: label,
        children: [
          TextSpan(
            text: value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: "monospace",
              fontFamilyFallback: ["Courier"],
            ),
          ),
        ],
      ),
    );
  }
}

String secondsToFormattedTime(double seconds) {
  int minutes = (seconds / 60).floor();
  int remainingSeconds = (seconds % 60).floor();
  int remainingHundredths = ((seconds * 100) % 100).floor();
  return "${minutes.toString().padLeft(2, "0")}:${remainingSeconds.toString().padLeft(2, "0")}.${remainingHundredths.toString().padLeft(2, "0")}";
}

class _GameWidgetState extends State<GameWidget> {
  bool playingGame = false;

  Ticker? tick;
  double time = 0;
  double deltaSeconds = 0;

  final InputActions inputActions = InputActions();
  final FollowCamera camera = FollowCamera();
  KinematicPlayer? player;
  CoinController? coins;

  @override
  void initState() {
    startMenu();

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

  void startGame() {
    playingGame = true;
    time = 0;
    player = KinematicPlayer();
    coins = CoinController();
  }

  void startMenu() {
    playingGame = false;
    time = 0;
    player = null;
    coins = null;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (playingGame) {
      inputActions.updatePlayer(player!);
      player!.update(deltaSeconds);
      coins!.update(player!.position, deltaSeconds);
      camera.updateGameplay(
          player!.position,
          vm.Vector3(player!.velocityXZ.x, 0, player!.velocityXZ.y) *
              player!.kMaxSpeed,
          deltaSeconds);
    } else {
      camera.updateOverview(deltaSeconds, time);

      // If any button is pressed, begin the game.
      if (inputActions.keyboardInputState.values.any((value) => value > 0) ||
          inputActions.gamepadInputState.values.any((value) => value > 0) ||
          inputActions.inputDirection.length2 > 0) {
        startGame();
      }
    }

    return Stack(
      children: [
        inputActions.getControlWidget(
          context,
          SceneBox(
            root: Node(children: [
              Node.asset("models/ground.glb"),
              if (player != null) player!.node,
              Node.transform(
                transform:
                    Matrix4.translation(camera.position) * Matrix4.rotationY(3),
                children: [Node.asset("models/sky_sphere.glb")],
              ),
              if (coins != null) coins!.node,
            ]),
            camera: camera.camera,
          ),
        ),
        if (playingGame)
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                child: HUDBox(
                  child: HUDLabelText(
                    label: "Coins: ",
                    value:
                        "${coins!.coins.where((coin) => coin.collected).length}",
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(20),
                child: HUDBox(
                  child: HUDLabelText(
                    label: "Time: ",
                    value: secondsToFormattedTime(time),
                  ),
                ),
              ),
            ],
          ),
        if (!playingGame)
          Center(
            child: ElevatedButton(
              onPressed: startGame,
              child: const Text("Start Game"),
            ),
          ),
      ],
    );
  }
}
