# Impeller Scene 3D Demo

This demo was featured as part of Flutter Forward 2023! Watch the keynote here:
[![Flutter Forward Thumbnail](https://img.youtube.com/vi/zKQYGKAe5W8/0.jpg)](https://www.youtube.com/watch?v=zKQYGKAe5W8&t=7074s "Flutter Forward 2023")

## ⚠️ Experimental! ⚠️

* This demo requires Impeller, which currently only supports iOS/iOS simulators.
* The [flutter_scene](https://pub.dev/packages/flutter_scene) package does not work out of the box and currently requires a special custom build of Flutter Engine to use (gn arg `--enable-impeller-3d`).
* The underlying Flutter API used to build and render Scene nodes is _not_ supported and _will_ break repeatedly. Eventually, the API will be removed/replaced altogether.

https://user-images.githubusercontent.com/919017/215621872-ef3dac49-22a0-476e-8fb9-d560121a3c17.mov
