import 'package:native_assets_cli/native_assets_cli.dart';
import 'package:flutter_scene_importer/build_hooks.dart';

void main(List<String> args) {
  build(args, (config, output) async {
    buildModels(buildConfig: config, inputFilePaths: [
      'models/coin.glb',
      'models/dash.glb',
      'models/ground.glb',
      'models/sky_sphere.glb',
      'models/spike.glb',
    ]);
  });
}