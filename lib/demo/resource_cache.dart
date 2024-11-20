import 'package:flutter_scene/scene.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

Node convertToUnlit(Node node) {
  // Search for all mesh primitives and convert them to unlit.
  if (node.mesh != null) {
    for (final primitive in node.mesh!.primitives) {
      if (primitive.material is PhysicallyBasedMaterial) {
        final pbr = primitive.material as PhysicallyBasedMaterial;
        primitive.material = UnlitMaterial(colorTexture: pbr.baseColorTexture);
      }
    }
  }
  for (final child in node.children) {
    convertToUnlit(child);
  }

  return node;
}

class ResourceCache {
  static final Map<String, Node> _models = {};
  static final Map<String, AudioSource?> _sounds = {};

  static Future<void> preloadAll() async {
    await Future.wait([
      Node.fromAsset("models/dash.glb").then((node) {
        _models["dash"] = convertToUnlit(node);
      }),
      Node.fromAsset("models/ground.glb").then((node) {
        _models["ground"] = convertToUnlit(node);
      }),
      Node.fromAsset("models/sky_sphere.glb").then((node) {
        _models["sky_sphere"] = convertToUnlit(node);
      }),
      Node.fromAsset("models/coin.glb").then((node) {
        _models["coin"] = convertToUnlit(node);
      }),
      Node.fromAsset("models/spike.glb").then((node) {
        _models["spike"] = convertToUnlit(node);
      }),
      SoLoud.instance.loadFile("assets/potion.ogg").then((sound) {
        _sounds["frontendMusic"] = sound;
      }),
      SoLoud.instance.loadFile("assets/machine.ogg").then((sound) {
        _sounds["gameplayMusic"] = sound;
      }),
    ]);
  }

  static Node getModel(String name) {
    return _models[name]!;
  }

  static AudioSource? getSound(String name) {
    return _sounds[name];
  }
}
