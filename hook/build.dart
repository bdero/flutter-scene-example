import 'package:hooks/hooks.dart';
import 'package:flutter_scene_importer/build_hooks.dart';

void main(List<String> args) {
  build(args, (config, output) async {
    buildModels(
      buildInput: config,
      inputFilePaths: [
        'models/coin.glb',
        'models/dash.glb',
        'models/ground.glb',
        'models/sky_sphere.glb',
        'models/spike.glb',
      ],
    );
  });
}
