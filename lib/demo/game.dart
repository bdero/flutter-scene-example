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

enum SpawnType {
  eCoin,
  eSpike,
}

abstract class SpawnPattern {
  /// Called when the pattern should update.
  ///
  /// `update` should return false when it is done spawning.
  /// If `update` returns true, then the pattern will continue receiving update calls.
  bool update(vm.Vector3 playerPosition, double deltaSeconds,
      Function(vm.Vector3 spawnPosition) spawnCallback);
}

class PlayerCircleSpawnPattern extends SpawnPattern {
  PlayerCircleSpawnPattern({required this.radius, required this.count});
  final double radius;
  final int count;

  @override
  bool update(vm.Vector3 playerPosition, double deltaSeconds,
      Function(vm.Vector3 spawnPosition) spawnCallback) {
    for (int i = 0; i < count; i++) {
      double angle = i * math.pi * 2 / count;
      vm.Vector3 spawnPosition = vm.Vector3(
              playerPosition.x, 0, playerPosition.z) +
          vm.Vector3(math.cos(angle) * radius, 1.5, math.sin(angle) * radius);
      spawnCallback(spawnPosition);
    }
    return false;
  }
}

class RandomNearPlayerSpawnPattern extends SpawnPattern {
  RandomNearPlayerSpawnPattern(
      {required this.lifetime,
      required this.minDistance,
      required this.maxDistance,
      required this.minSpawnRate,
      required this.maxSpawnRate});
  final double lifetime;
  final double minDistance;
  final double maxDistance;
  final double minSpawnRate;
  final double maxSpawnRate;

  double timeElapsed = 0;
  double nextSpawnTime = 0;

  @override
  bool update(vm.Vector3 playerPosition, double deltaSeconds,
      Function(vm.Vector3 spawnPosition) spawnCallback) {
    timeElapsed += deltaSeconds;
    if (timeElapsed > lifetime) {
      return false;
    }

    nextSpawnTime -= deltaSeconds;
    final random = math.Random();
    while (nextSpawnTime <= 0) {
      nextSpawnTime += math.max(
          minSpawnRate,
          maxSpawnRate -
              (timeElapsed / lifetime) * (maxSpawnRate - minSpawnRate));
      double distance =
          minDistance + (maxDistance - minDistance) * random.nextDouble();
      double angle = random.nextDouble() * math.pi * 2;
      vm.Vector3 spawnPosition = playerPosition +
          vm.Vector3(
              math.cos(angle) * distance, 1.5, math.sin(angle) * distance);
      spawnCallback(spawnPosition);
    }

    return true;
  }
}

class HardcodedSpawnPattern extends SpawnPattern {
  HardcodedSpawnPattern({required this.positions});
  final List<vm.Vector3> positions;

  @override
  bool update(vm.Vector3 playerPosition, double deltaSeconds,
      Function(vm.Vector3 spawnPosition) spawnCallback) {
    for (var position in positions) {
      spawnCallback(position);
    }
    return false;
  }
}

class SpawnRule {
  SpawnRule(
      {required this.spawnTime,
      required this.pattern,
      required this.spawnType});

  final double spawnTime;
  final SpawnPattern pattern;
  final SpawnType spawnType;
}

class SpawnController {
  final List<SpawnRule> rules = [
    SpawnRule(
      spawnTime: 0,
      pattern: HardcodedSpawnPattern(positions: [
        vm.Vector3(-1.4 - 0.8 * 0, 1.5, -6 - 2 * 0),
        vm.Vector3(-1.4 - 0.8 * 1, 1.5, -6 - 2 * 1),
        vm.Vector3(-1.4 - 0.8 * 2, 1.5, -6 - 2 * 2),
        vm.Vector3(-1.4 - 0.8 * 3, 1.5, -6 - 2 * 3),
        //
        vm.Vector3(-15 + 2 * 0, 1.5, 0.5 - 1.2 * 0),
        vm.Vector3(-15 + 2 * 1, 1.5, 0.5 - 1.2 * 1),
        vm.Vector3(-15 + 2 * 2, 1.5, 0.5 - 1.2 * 2),
        vm.Vector3(-15 + 2 * 3, 1.5, 0.5 - 1.2 * 3),
        //
        vm.Vector3(7 + 2 * 0, 1.5, -16 + 1.3 * 0),
        vm.Vector3(7 + 2 * 1, 1.5, -16.5 + 1.3 * 1),
        vm.Vector3(7 + 2 * 2, 1.5, -16.5 + 1.3 * 2),
        vm.Vector3(7 + 2 * 3, 1.5, -16 + 1.3 * 3),
      ]),
      spawnType: SpawnType.eCoin,
    ),
    SpawnRule(
      spawnTime: 5,
      pattern: PlayerCircleSpawnPattern(
        radius: 3,
        count: 8,
      ),
      spawnType: SpawnType.eCoin,
    ),
    SpawnRule(
      spawnTime: 5,
      pattern: PlayerCircleSpawnPattern(
        radius: 5,
        count: 10,
      ),
      spawnType: SpawnType.eCoin,
    ),
    SpawnRule(
      spawnTime: 5,
      pattern: PlayerCircleSpawnPattern(
        radius: 7,
        count: 12,
      ),
      spawnType: SpawnType.eCoin,
    ),
    SpawnRule(
      spawnTime: 5,
      pattern: RandomNearPlayerSpawnPattern(
        lifetime: 10,
        minDistance: 3,
        maxDistance: 8,
        minSpawnRate: 0.2,
        maxSpawnRate: 1.5,
      ),
      spawnType: SpawnType.eCoin,
    ),
  ];
  final List<SpawnPattern> activePatterns = [];
  final List<Coin> coins = [];

  int nextRuleIndex = 0;
  double timeElapsed = 0;

  void update(vm.Vector3 playerPosition, double deltaSeconds) {
    timeElapsed += deltaSeconds;

    while (nextRuleIndex < rules.length &&
        timeElapsed > rules[nextRuleIndex].spawnTime) {
      SpawnRule rule = rules[nextRuleIndex];
      activePatterns.add(rule.pattern);
      nextRuleIndex++;
    }

    for (int i = activePatterns.length - 1; i >= 0; i--) {
      SpawnPattern pattern = activePatterns[i];
      final updateResult =
          pattern.update(playerPosition, deltaSeconds, (vm.Vector3 position) {
        if (rules[i].spawnType == SpawnType.eCoin) {
          coins.add(Coin(position));
        }
      });
      if (!updateResult) {
        activePatterns.removeAt(i);
      }
    }

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
