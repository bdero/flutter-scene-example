import 'package:flutter/widgets.dart';
import 'package:scene_demo/demo/manynodes.dart';
import 'package:flutter_scene/scene.dart';

class DashWidget extends StatelessWidget {
  const DashWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scene(
        node: manyNodes(Node.asset("models/dash.glb", animations: ["Walk"])));
  }
}

// First start with Placeholder()
// Then move to const Image(image: AssetImage("assets/dash.png"));
// Then move to Scene(node: Node.asset("models/dash.glb"));