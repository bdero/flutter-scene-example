import 'dart:math';

import 'package:flutter_soloud/flutter_soloud.dart';

class SoundServer {
  static final SoundServer _singleton = SoundServer._internal();

  factory SoundServer() {
    return _singleton;
  }

  SoundServer._internal();

  SoundProps? pickupCoinSound;
  SoundProps? shatterSound;
  SoundProps? jumpSound;

  void initialize() {
    SoloudTools.loadFromAssets("assets/pickupCoin2.wav").then((sound) {
      pickupCoinSound = sound;
    });
    SoloudTools.loadFromAssets("assets/shatter3.ogg").then((sound) {
      shatterSound = sound;
    });
    SoloudTools.loadFromAssets("assets/jump.wav").then((sound) {
      jumpSound = sound;
    });
  }

  void playPickupCoin() {
    if (pickupCoinSound != null) {
      SoLoud().play(pickupCoinSound!, volume: 0.4).then((value) {
        SoLoud()
            .setRelativePlaySpeed(value.newHandle, (Random().nextDouble() - 0.5) * 0.2 + 1.0);
      });
    }
  }

  void playShatter() {
    if (shatterSound != null) {
      SoLoud().play(shatterSound!, volume: 1.0);
    }
  }

  void playJump() {
    if (jumpSound != null) {
      SoLoud().play(jumpSound!, volume: 0.4);
    }
  }
}
