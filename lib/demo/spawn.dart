import 'dart:math' as math;

import 'package:flutter_scene/scene.dart';
import 'package:scene_demo/demo/coin.dart';
import 'package:scene_demo/demo/game.dart';
import 'package:scene_demo/demo/spike.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

enum SpawnType {
  eCoin,
  eSpike,
}

abstract class SpawnPattern {
  /// Called when the pattern should update.
  ///
  /// `update` should return false when the spawn pattern has completed.
  /// If `update` returns true, then the pattern will continue receiving update
  /// calls.
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
  SpawnController(this.gameState);

  final GameState gameState;

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
      spawnType: SpawnType.eSpike,
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
      spawnType: SpawnType.eSpike,
    ),
  ];
  final List<SpawnPattern> activePatterns = [];

  int nextRuleIndex = 0;
  double timeElapsed = 0;

  void update(double deltaSeconds) {
    timeElapsed += deltaSeconds;

    while (nextRuleIndex < rules.length &&
        timeElapsed > rules[nextRuleIndex].spawnTime) {
      SpawnRule rule = rules[nextRuleIndex];
      activePatterns.add(rule.pattern);
      nextRuleIndex++;
    }

    for (int i = activePatterns.length - 1; i >= 0; i--) {
      SpawnPattern pattern = activePatterns[i];
      final updateResult = pattern.update(
          gameState.player.position, deltaSeconds, (vm.Vector3 position) {
        if (rules[i].spawnType == SpawnType.eCoin) {
          gameState.coins.add(Coin(gameState, position, vm.Vector3(0, 12, 0)));
        } else if (rules[i].spawnType == SpawnType.eSpike) {
          gameState.spikes.add(Spike(gameState, position));
        }
      });
      if (!updateResult) {
        activePatterns.removeAt(i);
      }
    }

    for (int i = gameState.coins.length - 1; i >= 0; i--) {
      Coin coin = gameState.coins[i];
      if (!coin.update(deltaSeconds)) {
        gameState.coins.removeAt(i);
      }
    }
    for (int i = gameState.spikes.length - 1; i >= 0; i--) {
      Spike spike = gameState.spikes[i];
      if (!spike.update(deltaSeconds)) {
        gameState.spikes.removeAt(i);
      }
    }
  }

  Node get node {
    return Node(
      children: [
        for (var coin in gameState.coins) coin.node,
        for (var spike in gameState.spikes) spike.node,
      ],
    );
  }
}