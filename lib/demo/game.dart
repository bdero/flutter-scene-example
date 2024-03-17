import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_scene/scene.dart';
import 'package:scene_demo/demo/camera.dart';
import 'package:scene_demo/demo/coin.dart';
import 'package:scene_demo/demo/leaderboard.dart';
import 'package:scene_demo/demo/player.dart';
import 'package:scene_demo/demo/input_actions.dart';
import 'package:scene_demo/demo/spawn.dart';
import 'package:scene_demo/demo/spike.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

class GameState {
  GameState({
    required this.player,
  });

  static const kTimeLimit = 5; // Seconds.

  final KinematicPlayer player;
  int coinsCollected = 0;

  final List<Coin> coins = [];
  final List<Spike> spikes = [];
}

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

class GameplayHUD extends StatelessWidget {
  const GameplayHUD({super.key, required this.gameState, required this.time});
  final GameState gameState;
  final double time;

  @override
  Widget build(BuildContext context) {
    double secondsRemaining = math.max(0, GameState.kTimeLimit - time);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          child: HUDBox(
            child: HUDLabelText(
              label: "💰 ",
              value: gameState!.coinsCollected.toString().padLeft(3, "0"),
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
    );
  }
}

enum GameMode {
  startMenu,
  playing,
  leaderboardEntry,
}

class _GameWidgetState extends State<GameWidget> {
  GameMode gameMode = GameMode.startMenu;

  Ticker? tick;
  double time = 0;
  double deltaSeconds = 0;

  final InputActions inputActions = InputActions();
  final FollowCamera camera = FollowCamera();
  GameState? gameState;
  SpawnController? spawnController;

  int lastScore = 0;

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
    resetTimer();

    gotoStartMenu();

    super.initState();
  }

  void resetTimer() {
    setState(() {
      tick!.stop();
      time = 0;
      tick!.start();
    });
  }

  void gotoGame() {
    setState(() {
      inputActions.absorbKeyEvents = true;
      gameMode = GameMode.playing;
      resetTimer();
      gameState = GameState(
        player: KinematicPlayer(),
      );
      spawnController = SpawnController(gameState!);
    });
  }

  void gotoStartMenu() {
    setState(() {
      inputActions.absorbKeyEvents = true;
      gameMode = GameMode.startMenu;
      gameState = null;
      spawnController = null;
    });
  }

  void gotoLeaderboardEntry() {
    setState(() {
      inputActions.absorbKeyEvents = false;
      gameMode = GameMode.leaderboardEntry;
      resetTimer();
      lastScore = gameState!.coinsCollected;
      gameState = null;
      spawnController = null;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print(Directory.current.path);
    if (gameMode == GameMode.playing) {
      // If the game is playing, update the player and camera.
      double secondsRemaining = math.max(0, GameState.kTimeLimit - time);
      inputActions.updatePlayer(gameState!.player);
      gameState!.player.update(deltaSeconds);
      spawnController!.update(deltaSeconds);
      camera.updateGameplay(
          gameState!.player.position,
          vm.Vector3(gameState!.player.velocityXZ.x, 0,
                  gameState!.player.velocityXZ.y) *
              gameState!.player.kMaxSpeed,
          deltaSeconds);

      if (secondsRemaining <= 0) {
        gotoLeaderboardEntry();
      }
    } else {
      // If we're in the menus, slowly rotate the camera.
      camera.updateOverview(deltaSeconds, time);
    }
    if (gameMode == GameMode.startMenu) {
      // If any button is pressed, begin the game.
      if (inputActions.keyboardInputState.values.any((value) => value > 0) ||
          inputActions.gamepadInputState.values.any((value) => value > 0)) {
        gotoGame();
      }
    }

    return Stack(
      children: [
        inputActions.getControlWidget(
          context,
          SceneBox(
            root: Node(children: [
              Node.asset("models/ground.glb"),
              Node.transform(
                transform:
                    Matrix4.translation(camera.position) * Matrix4.rotationY(3),
                children: [Node.asset("models/sky_sphere.glb")],
              ),
              if (gameMode == GameMode.playing) gameState!.player.node,
              if (gameMode == GameMode.playing) spawnController!.node,
            ]),
            camera: camera.camera,
          ),
        ),
        if (gameMode == GameMode.playing)
          GameplayHUD(gameState: gameState!, time: time),
        if (gameMode == GameMode.startMenu)
          Animate(
            child: const Center(
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
          )
              .animate()
              .fade()
              .slide(duration: 1.5.seconds, curve: Curves.bounceOut)
              .flip(),
        if (gameMode == GameMode.leaderboardEntry)
          Center(
            child: LeaderboardForm(
                score: lastScore,
                onSubmit: () {
                  gotoStartMenu();
                }),
          ),
      ],
    );
  }
}
