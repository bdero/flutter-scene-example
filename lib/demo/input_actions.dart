import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:gamepads/gamepads.dart';
import 'package:scene_demo/demo/player.dart';
import 'package:vector_math/vector_math_64.dart';

/// Reads and converts raw input data from the mouse/keyboard/gamepad into high
/// level events and state.
///
/// Only one instance of this class should be created.
class InputActions {
  InputActions() {
    ServicesBinding.instance.keyboard.addHandler(_onKeyEvent);

    Gamepads.list().then((gamepads) {
      print("Number of gamepads found: ${gamepads.length}");
      for (var gamepad in gamepads) {
        print(" -> id: ${gamepad.id}, name: '${gamepad.name}'");
      }
    });
    gamepadSubscription =
        Gamepads.events.listen(_onGamepadEvent, onError: (error) {
      print("Gamepad event stream error: $error");
    }, onDone: () {
      print("Gamepad event stream done.");
    }, cancelOnError: false);
  }

  late StreamSubscription<GamepadEvent> gamepadSubscription;

  Map<String, double> keyboardInputState = {
    "W": 0,
    "A": 0,
    "S": 0,
    "D": 0,
    "Arrow Up": 0,
    "Arrow Left": 0,
    "Arrow Down": 0,
    "Arrow Right": 0,
    " ": 0,
  };

  Map<String, double> gamepadInputState = {
    "l.joystick - xAxis": 0,
    "l.joystick - yAxis": 0,
    "r.joystick - xAxis": 0,
    "r.joystick - yAxis": 0,
    "dpad - xAxis": 0,
    "dpad - yAxis": 0,
    "a.circle": 0,
    "b.circle": 0,
    "x.circle": 0,
    "y.circle": 0,
    "minus.circle": 0,
    "plus.circle": 0,
  };

  Vector2 inputDirection = Vector2.zero();

  void updatePlayer(KinematicPlayer player) {
    player.inputDirection = inputDirection;
  }

  bool _onKeyEvent(KeyEvent event) {
    final key = event.logicalKey.keyLabel;

    if (event is KeyDownEvent) {
      if (keyboardInputState.containsKey(key)) {
        keyboardInputState[key] = 1;
      }
      print("Key down: $key, new state: ${keyboardInputState[key]}");
    } else if (event is KeyUpEvent) {
      if (keyboardInputState.containsKey(key)) {
        keyboardInputState[key] = 0;
      }
      print("Key up: $key, new state: ${keyboardInputState[key]}");
    } else if (event is KeyRepeatEvent) {
      print("Key repeat: $key");
    }

    inputDirection = Vector2(
          (keyboardInputState["D"]! - keyboardInputState["A"]!).toDouble(),
          (keyboardInputState["W"]! - keyboardInputState["S"]!).toDouble(),
        ) +
        Vector2(
          (keyboardInputState["Arrow Right"]! -
                  keyboardInputState["Arrow Left"]!)
              .toDouble(),
          (keyboardInputState["Arrow Up"]! - keyboardInputState["Arrow Down"]!)
              .toDouble(),
        );

    return keyboardInputState.containsKey(key);
  }

  void _onGamepadEvent(GamepadEvent event) {
    print("Gamepad data: ${event}");

    if (gamepadInputState.containsKey(event.key)) {
      gamepadInputState[event.key] = event.value;
    }

    inputDirection = Vector2(
          gamepadInputState["l.joystick - xAxis"]! +
              gamepadInputState["dpad - xAxis"]!,
          gamepadInputState["l.joystick - yAxis"]! +
              gamepadInputState["dpad - yAxis"]!,
        ) +
        Vector2(
          gamepadInputState["dpad - xAxis"]!,
          gamepadInputState["dpad - yAxis"]!,
        );
  }

  Widget getControlWidget(BuildContext context, Widget child) {
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
        inputDirection = Vector2(dir.dx, -dir.dy);
      },
      onScaleUpdate: (details) {
        var dir = (details.localFocalPoint - center) * inputMapping;
        inputDirection = Vector2(dir.dx, -dir.dy);
      },
      onScaleEnd: (details) {
        inputDirection = Vector2.zero();
      },
      child: child,
    );
  }
}
