# Impeller Scene 3D Demo

## ⚠️ Experimental! ⚠️

* This demo requires Impeller, which currently only supports iOS/iOS simulators.
* The [flutter_scene](https://pub.dev/packages/flutter_scene) package does not work out of the box and currently requires a special custom build of Flutter Engine to use (gn arg `--enable-impeller-3d`).
* The underlying Flutter API used to build and render Scene nodes is _not_ supported and _will_ break repeatedly. Eventually, the API will be removed/replaced altogether.

![Demo video](impeller_scene.mov)
