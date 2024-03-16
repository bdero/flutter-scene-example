import 'dart:math' as math;

import 'package:vector_math/vector_math_64.dart';

T lerp<T>(T a, T b, double t) {
  if (a is double && b is double) {
    return a + (b - a) * t as T;
  } else if (a is Vector3 && b is Vector3) {
    return a + (b - a) * t as T;
  } else {
    throw "Unsupported type for lerp: ${a.runtimeType}";
  }
}

T lerpDeltaTime<T>(T a, T b, double t, double deltaTime) {
  return lerp(a, b, math.min(1, 1 - math.pow(t, deltaTime).toDouble()));
}

Vector3 vector3Lerp(Vector3 a, Vector3 b, double t) {
  return a + (b - a) * t;
}

Vector3 vector3LerpDeltaTime(Vector3 a, Vector3 b, double t, double deltaTime) {
  return vector3Lerp(a, b, math.min(1, 1 - math.pow(t, deltaTime).toDouble()));
}
