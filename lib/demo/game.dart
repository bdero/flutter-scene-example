import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_scene/scene.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
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

  static const kTimeLimit = 60; // Seconds.

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

class SpringCurve extends Curve {
  @override
  double transformInternal(double t) {
    const a = 0.09;
    const w = 20;
    return -(math.pow(math.e, -t / a) * math.cos(t * w)) + 1.0;
  }
}

class SheenGradientTransform extends GradientTransform {
  SheenGradientTransform(this.rotation, this.translation, this.scale);

  double rotation;
  vm.Vector3 translation;
  double scale;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translation(translation) *
        Matrix4.rotationZ(rotation) *
        scale;
  }
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

  SoundProps? frontendMusic;
  SoundProps? gameplayMusic;
  int? currentMusicHandle;

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

    SoloudTools.loadFromAssets("assets/potion.ogg").then((sound) {
      frontendMusic = sound;
      playMusic(frontendMusic, true, true);
    });
    SoloudTools.loadFromAssets("assets/machine.ogg").then((sound) {
      gameplayMusic = sound;
      print("got sound");
    });

    super.initState();
  }

  void playMusic(SoundProps? music, bool loop, bool fadeIn) {
    if (currentMusicHandle != null) {
      SoLoud().stop(currentMusicHandle!);
    }
    if (music != null) {
      SoLoud().play(music, volume: 0.0).then((value) {
        if (value.error != PlayerErrors.noError) {
          debugPrint('SoLoud error: ${value.error}');
        }
        currentMusicHandle = value.newHandle;
        if (loop) {
          final loopingResult = SoLoud().setLooping(value.newHandle, true);
          if (loopingResult != PlayerErrors.noError) {
            debugPrint('SoLoud error: $value');
          }
        }
        if (fadeIn) {
          final fadeVolumeResult =
              SoLoud().fadeVolume(value.newHandle, 0.5, 0.5);
          if (fadeVolumeResult != PlayerErrors.noError) {
            debugPrint('SoLoud error: $value');
          }
        }
      });
    }
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
      playMusic(gameplayMusic, false, true);
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
      playMusic(frontendMusic, true, true);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          GameplayHUD(gameState: gameState!, time: time)
              .animate(key: const ValueKey('gameplayHUD'))
              .slideY(
                curve: Curves.easeOutCubic,
                duration: 1.5.seconds,
                begin: -3,
                end: 0,
              ),
        if (gameMode == GameMode.startMenu)
          Center(
              child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: [
                  HUDBox(
                    child: ShaderMask(
                      shaderCallback: (bounds) {
                        return LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: const [
                              Color.fromARGB(255, 153, 221, 255),
                              Color.fromARGB(255, 255, 158, 126),
                              Color.fromARGB(255, 230, 229, 255),
                              Color.fromARGB(255, 15, 234, 48),
                              Colors.white,
                            ],
                            stops: const [0, 0.1, 0.5, 0.9, 1],
                            tileMode: TileMode.repeated,
                            transform: SheenGradientTransform(
                              -math.pi / 4,
                              vm.Vector3(time * 150, 0, 0),
                              10,
                            )).createShader(bounds);
                      },
                      child: const Text(
                        "PRESS 🅰️ TO PLAY!",
                        style: TextStyle(
                          fontSize: 80,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const HUDBox(
                    child: Text(
                      "🕹️ Left stick to move, 🅰️ to jump",
                      style: TextStyle(
                        fontSize: 34,
                      ),
                    ),
                  )
                ],
              )
                  .animate(key: const ValueKey("startMenu"))
                  .fade(duration: 0.2.seconds)
                  .slide(duration: 1.5.seconds, curve: SpringCurve())
                  .flip(),
              const SizedBox(height: 50),
              LeaderboardWidget()
            ],
          )),
        if (gameMode == GameMode.leaderboardEntry)
          Center(
            child: LeaderboardForm(
              score: lastScore,
              onSubmit: () {
                gotoStartMenu();
              },
            ),
          )
              .animate(key: const ValueKey("leaderboard"))
              .fade(duration: 0.2.seconds)
              .slide(duration: 1.5.seconds, curve: SpringCurve())
              .flip(),
      ],
    );
  }
}
