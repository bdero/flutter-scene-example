import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_scene/scene.dart';
import 'package:scene_demo/demo/camera.dart';
import 'package:scene_demo/demo/player.dart';
import 'package:scene_demo/demo/input_actions.dart';
import 'package:scene_demo/demo/spawn.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

class GameWidget extends StatefulWidget {
  const GameWidget({super.key});

  @override
  State<GameWidget> createState() => _GameWidgetState();
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
    final style = DefaultTextStyle.of(context).style;
    final valueStyle = style.copyWith(
      fontWeight: FontWeight.bold,
      fontFamily: "monospace",
      fontFamilyFallback: ["Courier"],
    );

    return RichText(
      softWrap: false,
      overflow: TextOverflow.clip,
      text: TextSpan(
        style: style,
        text: label,
        children: [
          TextSpan(
            style: valueStyle,
            text: value,
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

  static const kTimeLimit = 30; // Seconds.

  final InputActions inputActions = InputActions();
  final FollowCamera camera = FollowCamera();
  KinematicPlayer? player;
  SpawnController? spawnController;

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

    startMenu();

    super.initState();
  }

  void resetTimer() {
    setState(() {
      tick!.stop();
      time = 0;
      tick!.start();
    });
  }

  void startGame() {
    setState(() {
      playingGame = true;
      resetTimer();
      player = KinematicPlayer();
      spawnController = SpawnController();
    });
  }

  void startMenu() {
    setState(() {
      playingGame = false;
      resetTimer();
      player = null;
      spawnController = null;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double secondsRemaining = math.max(0, kTimeLimit - time);
    if (playingGame) {
      inputActions.updatePlayer(player!);
      player!.update(deltaSeconds);
      spawnController!.update(player!.position, deltaSeconds);
      camera.updateGameplay(
          player!.position,
          vm.Vector3(player!.velocityXZ.x, 0, player!.velocityXZ.y) *
              player!.kMaxSpeed,
          deltaSeconds);

      if (secondsRemaining <= 0) {
        startMenu();
      }
    } else {
      camera.updateOverview(deltaSeconds, time);

      // If any button is pressed, begin the game.
      if (inputActions.keyboardInputState.values.any((value) => value > 0) ||
          inputActions.gamepadInputState.values.any((value) => value > 0)) {
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
              if (spawnController != null) spawnController!.node,
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
                    label: "💰 ",
                    value:
                        "${spawnController!.coins.where((coin) => coin.collected).length}",
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(20),
                child: HUDBox(
                  child: HUDLabelText(
                    label: "⏱ ",
                    value: secondsToFormattedTime(secondsRemaining),
                  ),
                ),
              ),
            ],
          ),
        if (!playingGame)
          const Center(
            child: HUDBox(
              child: Text(
                "Press any button to start",
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
