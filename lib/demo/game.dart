import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_scene/scene.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:scene_demo/demo/camera.dart';
import 'package:scene_demo/demo/coin.dart';
import 'package:scene_demo/demo/leaderboard.dart';
import 'package:scene_demo/demo/math_utils.dart';
import 'package:scene_demo/demo/player.dart';
import 'package:scene_demo/demo/input_actions.dart';
import 'package:scene_demo/demo/resource_cache.dart';
import 'package:scene_demo/demo/sound.dart';
import 'package:scene_demo/demo/spawn.dart';
import 'package:scene_demo/demo/spike.dart';
import 'package:vector_math/vector_math.dart' as vm;
import 'package:vector_math/vector_math_64.dart' as vm64;

class ScenePainter extends CustomPainter {
  ScenePainter({required this.scene, required this.camera});
  Scene scene;
  Camera camera;

  @override
  void paint(Canvas canvas, Size size) {
    scene.render(camera, canvas, viewport: Offset.zero & size);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class GameState {
  GameState({
    required this.scene,
    required this.player,
  });

  static const kTimeLimit = 60; // Seconds.

  final Scene scene;
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
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
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
              value: gameState.coinsCollected.toString().padLeft(3, "0"),
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
  const SheenGradientTransform(this.rotation, this.translation, this.scale);

  final double rotation;
  final vm64.Vector3 translation;
  final double scale;

  @override
  vm64.Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    return vm64.Matrix4.translation(translation) *
        vm64.Matrix4.rotationZ(rotation) *
        scale;
  }
}

class ImpellerLogo extends CustomPainter {
  ImpellerLogo(this.time);

  final double time;

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    final Paint paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.scale(size.width / 350);

    Offset armCenter = const Offset(104.15, 246.01);

    canvas.drawCircle(armCenter, 69.37, paint);

    Path rrectClip = Path()
      ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(34.78, 34.19, 281.19, 281.19),
          const Radius.circular(36.46)));
    Path circleCutout = Path()
      ..addOval(Rect.fromCircle(center: armCenter, radius: 100.84));
    canvas.clipPath(
        Path.combine(PathOperation.difference, rrectClip, circleCutout));

    canvas.drawCircle(armCenter, 139.45, paint);

    Path arm = Path()
      ..moveTo(150.88, 105.35)
      ..relativeCubicTo(-1.63, 1.45, -1.72, 2.97, -1.72, 2.97)
      ..relativeCubicTo(0, 0.72, 0.12, 2.33, 4.2, 5.64)
      ..relativeCubicTo(1.72, 1.4, 4.35, 3.27, 8, 4.94)
      ..relativeCubicTo(-21.95, -3.93, -43.9, -7.86, -65.85, -11.8)
      ..cubicTo(111.02, 27.16, 137.87, -5.41, 160.41, -20.1)
      ..relativeCubicTo(17.78, -11.58, 42.97, -26.12, 75.18, -45.69)
      ..relativeCubicTo(7.69, -4.67, 14.65, -8.91, 23.33, -14.18)
      ..relativeCubicTo(13.11, -7.97, 29.48, -8.35, 43.01, -1.1)
      ..relativeCubicTo(15.36, 8.22, 32.35, 18.96, 49.61, 33)
      ..relativeCubicTo(18.14, 14.76, 32.35, 29.74, 43.25, 42.92)
      ..relativeCubicTo(0, 0, -0.03, -0.03, -0.05, -0.05)
      ..relativeCubicTo(-1.26, -1.74, -6.43, -8.49, -15.83, -10.35)
      ..relativeCubicTo(-5.59, -1.11, -10.23, -0.01, -12.61, 0.75)
      ..relativeCubicTo(-57.43, 31.39, -208.79, 114.29, -215.41, 120.16)
      ..close()
      ..moveTo(278.05, 84.08)
      ..relativeCubicTo(-6.37, 3.13, -23.48, 11.51, -46.81, 23.15)
      ..relativeCubicTo(-18.21, 9.08, -38.87, 19.48, -61.57, 31.04)
      ..relativeCubicTo(-11.36, -13.56, -22.71, -27.12, -34.07, -40.68)
      ..relativeCubicTo(15.25, -12.77, 32.04, -25.81, 50.43, -38.76)
      ..relativeCubicTo(10.19, -7.17, 20.22, -13.86, 30.03, -20.1)
      ..relativeCubicTo(0, 0, 115.78, -74.91, 156.43, -60.62)
      ..relativeCubicTo(13.59, 4.78, 22.03, 16.4, 22.03, 16.4)
      ..relativeCubicTo(8.27, 8.76, 12.84, 17.66, 15.32, 23.52)
      ..relativeCubicTo(-64.09, 32.56, -105.31, 53.04, -131.78, 66.03)
      ..close();

    canvas.translate(armCenter.dx, armCenter.dy);
    canvas.rotate(-time * 2);
    canvas.translate(-armCenter.dx, -armCenter.dy);

    for (int i = 0; i < 7; i++) {
      canvas.drawPath(arm, paint);
      canvas.translate(armCenter.dx, armCenter.dy);
      canvas.rotate(math.pi * 2 / 7);
      canvas.translate(-armCenter.dx, -armCenter.dy);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class VignettePainter extends CustomPainter {
  VignettePainter({this.color = Colors.white});

  ui.Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..shader = RadialGradient(
        radius: 1.0,
        colors: [Colors.transparent, color],
        stops: const [0.2, 1.0],
      ).createShader(
        Rect.fromLTRB(0, 0, size.width, size.height),
      )
      ..blendMode = BlendMode.srcOver;

    canvas.drawRect(Rect.fromLTRB(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class _GameWidgetState extends State<GameWidget> {
  Scene scene = Scene();
  GameMode gameMode = GameMode.startMenu;
  Node skySphere = Node();

  Ticker? tick;
  double time = 0;
  double logoAnimation = 0;
  double deltaSeconds = 0;
  double rainbowVignette = 1;

  final InputActions inputActions = InputActions();
  final FollowCamera camera = FollowCamera();
  GameState? gameState;
  SpawnController? spawnController;

  int lastScore = 0;

  SoundHandle? currentMusicHandle;

  @override
  void initState() {
    tick = Ticker(
      (elapsed) {
        setState(() {
          double previousTime = time;
          time = elapsed.inMilliseconds / 1000.0;
          deltaSeconds = previousTime > 0 ? time - previousTime : 0;
          logoAnimation += deltaSeconds;
        });
      },
    );
    resetTimer();

    ResourceCache.preloadAll().then((_) {
      gotoStartMenu();

      skySphere = ResourceCache.getModel("sky_sphere");
      scene.add(skySphere);
      scene.add(ResourceCache.getModel("ground"));

      playMusic(ResourceCache.getSound("frontendMusic"), true, true);
    });
    SoundServer().initialize();

    super.initState();
  }

  Future<void> playMusic(AudioSource? music, bool loop, bool fadeIn) async {
    if (currentMusicHandle != null) {
      SoLoud.instance.stop(currentMusicHandle!);
      currentMusicHandle = null;
    }
    if (music != null) {
      try {
        final handle = await SoLoud.instance.play(music, volume: 0.0);
        currentMusicHandle = handle;

        if (loop) {
          SoLoud.instance.setLooping(handle, true);
        }

        if (fadeIn) {
          SoLoud.instance
              .fadeVolume(handle, 1.0, const Duration(milliseconds: 500));
        }
      } catch (error) {
        debugPrint('Error playing music: $error');
      }
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
        scene: scene,
        player: KinematicPlayer(),
      );
      scene.add(gameState!.player.node);
      spawnController = SpawnController(gameState!);
      scene.add(spawnController!.node);
      playMusic(ResourceCache.getSound("gameplayMusic"), false, true);
    });
  }

  void gotoStartMenu() {
    setState(() {
      inputActions.absorbKeyEvents = true;
      gameMode = GameMode.startMenu;
      if (gameState != null) {
        scene.remove(gameState!.player.node);
        gameState = null;
        scene.remove(spawnController!.node);
        spawnController = null;
      }
    });
  }

  void gotoLeaderboardEntry() {
    setState(() {
      inputActions.absorbKeyEvents = false;
      gameMode = GameMode.leaderboardEntry;
      resetTimer();
      lastScore = gameState!.coinsCollected;
      scene.remove(gameState!.player.node);
      gameState = null;
      scene.remove(spawnController!.node);
      spawnController = null;
      playMusic(ResourceCache.getSound("frontendMusic"), true, true);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double rainbowVignetteDest = gameMode == GameMode.playing ? 0 : 1;
    rainbowVignette =
        lerpDeltaTime(rainbowVignette, rainbowVignetteDest, 0.8, deltaSeconds);

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

      if (secondsRemaining <= 0 || inputActions.skipToEnd) {
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

    skySphere.localTransform = vm.Matrix4.translation(camera.position) *
        vm.Matrix4.rotationY(time * 0.1);

    return Stack(
      children: [
        inputActions.getControlWidget(
          context,
          SizedBox.expand(
            child: CustomPaint(
              painter: ScenePainter(scene: scene, camera: camera.camera),
            ),
          ),
        ),
        if (gameMode == GameMode.playing)
          IgnorePointer(
            child: CustomPaint(
              painter: VignettePainter(
                  color: Color.lerp(
                          Colors.white.withAlpha(100),
                          Colors.red,
                          math.max(
                              0.0, gameState!.player.damageCooldown - 1)) ??
                      Colors.transparent),
              child: Container(),
            ),
          ),
        IgnorePointer(
          child: Opacity(
            opacity: rainbowVignette,
            child: ShaderMask(
              shaderCallback: (bounds) {
                return LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: const [
                      Color.fromARGB(255, 153, 221, 255),
                      Color.fromARGB(255, 255, 158, 126),
                      Color.fromARGB(255, 230, 229, 255),
                      ui.Color.fromARGB(255, 114, 207, 131),
                      Colors.white,
                      Color.fromARGB(255, 153, 221, 255),
                    ],
                    stops: const [0, 0.1, 0.5, 0.8, 0.9, 1],
                    tileMode: TileMode.repeated,
                    transform: SheenGradientTransform(
                      math.pi / 4,
                      vm64.Vector3(-time * 150, 0, 0),
                      5,
                    )).createShader(bounds);
              },
              child: CustomPaint(
                painter: VignettePainter(),
                child: Container(),
              ),
            ),
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
        if (gameMode == GameMode.startMenu && logoAnimation > 1)
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
                              vm64.Vector3(time * 150, 0, 0),
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
              const LeaderboardWidget()
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
        if (logoAnimation < 2)
          IgnorePointer(
            child: Opacity(
              opacity: math.max(0, math.min(1, 2 - logoAnimation)),
              child: Container(
                color: Colors.black.withOpacity(1.0),
                child: Center(
                  child: ImageFiltered(
                    imageFilter: ui.ImageFilter.blur(
                        sigmaX: lerp(0.0, 100.0, 1 / (1 + logoAnimation * 70))
                                .toDouble() +
                            math
                                .max(0.0, (-1.0 + logoAnimation) * 40)
                                .toDouble(),
                        sigmaY: lerp(0.0, 100.0, 1 / (1 + logoAnimation * 70))
                                .toDouble() +
                            math
                                .max(0.0, (-1.0 + logoAnimation) * 40)
                                .toDouble(),
                        tileMode: TileMode.decal),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ColorFiltered(
                          colorFilter: const ui.ColorFilter.mode(
                              Colors.white, BlendMode.srcATop),
                          child: FlutterLogo(
                            duration: Duration.zero,
                            size: lerp(200, 600, 1 / (1 + logoAnimation * 10)),
                          ),
                        ),
                        CustomPaint(
                          size: Size(
                              lerp(200, 600, 1 / (1 + logoAnimation * 10)),
                              lerp(200, 600, 1 / (1 + logoAnimation * 10))),
                          painter: ImpellerLogo(time),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
