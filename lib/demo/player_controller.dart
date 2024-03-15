import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:scene_demo/demo/player.dart';
import 'package:vector_math/vector_math_64.dart';

class PlayerController {
  PlayerController() {
    ServicesBinding.instance.keyboard.addHandler(_onKey);
  }

  Map<String, double> rawInputState = {
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

  Vector2 inputDirection = Vector2.zero();

  void updatePlayer(KinematicPlayer player) {
    player.inputDirection = inputDirection;
  }

  bool _onKey(KeyEvent event) {
    final key = event.logicalKey.keyLabel;

    if (event is KeyDownEvent) {
      if (rawInputState.containsKey(key)) {
        rawInputState[key] = 1;
      }
      print("Key down: $key, new state: ${rawInputState[key]}");
    } else if (event is KeyUpEvent) {
      if (rawInputState.containsKey(key)) {
        rawInputState[key] = 0;
      }
      print("Key up: $key, new state: ${rawInputState[key]}");
    } else if (event is KeyRepeatEvent) {
      print("Key repeat: $key");
    }

    inputDirection = Vector2(
          (rawInputState["D"]! - rawInputState["A"]!).toDouble(),
          (rawInputState["W"]! - rawInputState["S"]!).toDouble(),
        ) +
        Vector2(
          (rawInputState["Arrow Right"]! - rawInputState["Arrow Left"]!)
              .toDouble(),
          (rawInputState["Arrow Up"]! - rawInputState["Arrow Down"]!)
              .toDouble(),
        );

    return rawInputState.containsKey(key);
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
