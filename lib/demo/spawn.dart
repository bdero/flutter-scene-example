import 'dart:math' as math;

import 'package:flutter_scene/scene.dart';
import 'package:scene_demo/demo/coin.dart';
import 'package:scene_demo/demo/game.dart';
import 'package:scene_demo/demo/spike.dart';
import 'package:vector_math/vector_math.dart' as vm;

enum SpawnType {
  coin,
  spike,
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
      vm.Vector3 spawnPosition =
          vm.Vector3(playerPosition.x, 0, playerPosition.z) +
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
  final Node node = Node();

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
      spawnType: SpawnType.coin,
    ),
    SpawnRule(
      spawnTime: 5,
      pattern: PlayerCircleSpawnPattern(
        radius: 3,
        count: 8,
      ),
      spawnType: SpawnType.coin,
    ),
    SpawnRule(
      spawnTime: 5,
      pattern: PlayerCircleSpawnPattern(
        radius: 5,
        count: 10,
      ),
      spawnType: SpawnType.coin,
    ),
    SpawnRule(
      spawnTime: 5,
      pattern: RandomNearPlayerSpawnPattern(
        lifetime: 60,
        minDistance: 3,
        maxDistance: 8,
        minSpawnRate: 0.2,
        maxSpawnRate: 1.0,
      ),
      spawnType: SpawnType.coin,
    ),
    SpawnRule(
      spawnTime: 8,
      pattern: RandomNearPlayerSpawnPattern(
        lifetime: 60,
        minDistance: 5,
        maxDistance: 10,
        minSpawnRate: 0.5,
        maxSpawnRate: 1.5,
      ),
      spawnType: SpawnType.spike,
    ),
    SpawnRule(
      spawnTime: 10,
      pattern: PlayerCircleSpawnPattern(
        radius: 3,
        count: 8,
      ),
      spawnType: SpawnType.coin,
    ),
    SpawnRule(
      spawnTime: 20,
      pattern: PlayerCircleSpawnPattern(
        radius: 3,
        count: 8,
      ),
      spawnType: SpawnType.coin,
    ),
    SpawnRule(
      spawnTime: 30,
      pattern: PlayerCircleSpawnPattern(
        radius: 3,
        count: 8,
      ),
      spawnType: SpawnType.coin,
    ),

    // Cluster
    SpawnRule(
      spawnTime: 31,
      pattern: PlayerCircleSpawnPattern(
        radius: 8,
        count: 8,
      ),
      spawnType: SpawnType.coin,
    ),
    SpawnRule(
      spawnTime: 31.5,
      pattern: PlayerCircleSpawnPattern(
        radius: 7,
        count: 8,
      ),
      spawnType: SpawnType.coin,
    ),
    SpawnRule(
      spawnTime: 32,
      pattern: PlayerCircleSpawnPattern(
        radius: 6,
        count: 8,
      ),
      spawnType: SpawnType.coin,
    ),
    SpawnRule(
      spawnTime: 32.5,
      pattern: PlayerCircleSpawnPattern(
        radius: 6,
        count: 8,
      ),
      spawnType: SpawnType.coin,
    ),
    SpawnRule(
      spawnTime: 33,
      pattern: PlayerCircleSpawnPattern(
        radius: 5,
        count: 8,
      ),
      spawnType: SpawnType.coin,
    ),
    SpawnRule(
      spawnTime: 33.5,
      pattern: PlayerCircleSpawnPattern(
        radius: 4,
        count: 8,
      ),
      spawnType: SpawnType.coin,
    ),
    SpawnRule(
      spawnTime: 34,
      pattern: PlayerCircleSpawnPattern(
        radius: 3,
        count: 8,
      ),
      spawnType: SpawnType.spike,
    ),

    SpawnRule(
      spawnTime: 40,
      pattern: PlayerCircleSpawnPattern(
        radius: 3,
        count: 8,
      ),
      spawnType: SpawnType.coin,
    ),
    SpawnRule(
      spawnTime: 50,
      pattern: PlayerCircleSpawnPattern(
        radius: 3,
        count: 8,
      ),
      spawnType: SpawnType.coin,
    ),
    SpawnRule(
      spawnTime: 60,
      pattern: PlayerCircleSpawnPattern(
        radius: 3,
        count: 8,
      ),
      spawnType: SpawnType.coin,
    ),
    SpawnRule(
      spawnTime: 70,
      pattern: PlayerCircleSpawnPattern(
        radius: 3,
        count: 8,
      ),
      spawnType: SpawnType.coin,
    ),
    SpawnRule(
      spawnTime: 80,
      pattern: PlayerCircleSpawnPattern(
        radius: 3,
        count: 8,
      ),
      spawnType: SpawnType.coin,
    ),
    SpawnRule(
      spawnTime: 90,
      pattern: PlayerCircleSpawnPattern(
        radius: 3,
        count: 8,
      ),
      spawnType: SpawnType.coin,
    ),
    SpawnRule(
      spawnTime: 100,
      pattern: PlayerCircleSpawnPattern(
        radius: 3,
        count: 8,
      ),
      spawnType: SpawnType.coin,
    ),
    SpawnRule(
      spawnTime: 110,
      pattern: PlayerCircleSpawnPattern(
        radius: 3,
        count: 8,
      ),
      spawnType: SpawnType.coin,
    ),
    SpawnRule(
      spawnTime: 120,
      pattern: PlayerCircleSpawnPattern(
        radius: 3,
        count: 8,
      ),
      spawnType: SpawnType.coin,
    ),
    SpawnRule(
      spawnTime: 130,
      pattern: PlayerCircleSpawnPattern(
        radius: 3,
        count: 8,
      ),
      spawnType: SpawnType.coin,
    ),
    SpawnRule(
      spawnTime: 140,
      pattern: PlayerCircleSpawnPattern(
        radius: 3,
        count: 8,
      ),
      spawnType: SpawnType.coin,
    ),
    SpawnRule(
      spawnTime: 145,
      pattern: PlayerCircleSpawnPattern(
        radius: 3,
        count: 8,
      ),
      spawnType: SpawnType.coin,
    ),
  ];
  final List<SpawnRule> activeRules = [];

  int nextRuleIndex = 0;
  double timeElapsed = 0;

  void update(double deltaSeconds) {
    timeElapsed += deltaSeconds;

    while (nextRuleIndex < rules.length &&
        timeElapsed > rules[nextRuleIndex].spawnTime) {
      SpawnRule rule = rules[nextRuleIndex];
      activeRules.add(rule);
      nextRuleIndex++;
    }

    for (int i = activeRules.length - 1; i >= 0; i--) {
      SpawnRule rule = activeRules[i];
      final updateResult = rule.pattern.update(
          gameState.player.position, deltaSeconds, (vm.Vector3 position) {
        if (rule.spawnType == SpawnType.coin) {
          gameState.coins.add(Coin(gameState, position, vm.Vector3(0, 12, 0)));
          node.add(gameState.coins.last.node);
        } else if (rule.spawnType == SpawnType.spike) {
          gameState.spikes.add(Spike(gameState, position));
          node.add(gameState.spikes.last.node);
        }
      });
      if (!updateResult) {
        activeRules.removeAt(i);
      }
    }

    for (int i = gameState.coins.length - 1; i >= 0; i--) {
      Coin coin = gameState.coins[i];
      if (!coin.update(deltaSeconds)) {
        gameState.coins.removeAt(i);
        try {
          node.remove(coin.node);
        } catch (_) {}
      }
    }
    for (int i = gameState.spikes.length - 1; i >= 0; i--) {
      Spike spike = gameState.spikes[i];
      if (!spike.update(deltaSeconds)) {
        gameState.spikes.removeAt(i);
        try {
          node.remove(spike.node);
        } catch (_) {}
      }
    }
  }
}
