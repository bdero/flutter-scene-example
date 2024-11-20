import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

class SoundServer {
  static final SoundServer _singleton = SoundServer._internal();

  factory SoundServer() {
    return _singleton;
  }

  SoundServer._internal();

  AudioSource? pickupCoinSound;
  AudioSource? shatterSound;
  AudioSource? jumpSound;

  void initialize() {
    SoLoud.instance.loadFile("assets/pickupCoin2.wav").then((sound) {
      pickupCoinSound = sound;
    }).catchError((error) {
      debugPrint("Error loading pickupCoin2.wav: $error");
    });

    SoLoud.instance.loadFile("assets/shatter3.ogg").then((sound) {
      shatterSound = sound;
    }).catchError((error) {
      debugPrint("Error loading shatter3.ogg: $error");
    });

    SoLoud.instance.loadFile("assets/jump.wav").then((sound) {
      jumpSound = sound;
    }).catchError((error) {
      debugPrint("Error loading jump.wav: $error");
    });
  }

  Future<void> playPickupCoin() async {
    if (pickupCoinSound != null) {
      final handle = await SoLoud.instance.play(pickupCoinSound!, volume: 0.4);
      SoLoud.instance.setRelativePlaySpeed(
        handle,
        (Random().nextDouble() - 0.5) * 0.2 + 1.0,
      );
    }
  }

  Future<void> playShatter() async {
    if (shatterSound != null) {
      await SoLoud.instance.play(shatterSound!, volume: 1.0);
    }
  }

  Future<void> playJump() async {
    if (jumpSound != null) {
      await SoLoud.instance.play(jumpSound!, volume: 0.4);
    }
  }
}
