import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math_64.dart';

Node manyNodes(Node input) {
  return Node(children: [
    for (double x = -3; x <= 3; x++)
      for (double y = -3; y <= 3; y++)
        for (double z = -3; z <= 3; z++)
          Node(position: Vector3(x * 4, y * 4, z * 4), children: [input])
  ]);
}
