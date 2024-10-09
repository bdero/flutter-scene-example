import 'package:flutter_scene/material/physically_based_material.dart';
import 'package:flutter_scene/material/unlit_material.dart';
import 'package:flutter_scene/node.dart';
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
  static final Map<String, SoundProps?> _sounds = {};

  static Future<void> preloadAll() async {
    await Future.wait([
      Node.fromAsset("build/models/dash.model").then((node) {
        _models["dash"] = convertToUnlit(node);
      }),
      Node.fromAsset("build/models/ground.model").then((node) {
        _models["ground"] = convertToUnlit(node);
      }),
      Node.fromAsset("build/models/sky_sphere.model").then((node) {
        _models["sky_sphere"] = convertToUnlit(node);
      }),
      Node.fromAsset("build/models/coin.model").then((node) {
        _models["coin"] = convertToUnlit(node);
      }),
      Node.fromAsset("build/models/spike.model").then((node) {
        _models["spike"] = convertToUnlit(node);
      }),
      SoloudTools.loadFromAssets("assets/potion.ogg").then((sound) {
        _sounds["frontendMusic"] = sound;
      }),
      SoloudTools.loadFromAssets("assets/machine.ogg").then((sound) {
        _sounds["gameplayMusic"] = sound;
      }),
    ]);
  }

  static Node getModel(String name) {
    return _models[name]!;
  }

  static SoundProps? getSound(String name) {
    return _sounds[name];
  }
}
