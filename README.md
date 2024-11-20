# [Flutter Scene](https://github.com/bdero/flutter_scene) Example

<p align="center">
  <img alt="Flutter Scene" width="600px" src="https://raw.githubusercontent.com/gist/bdero/4f34a4dfe78a4a83d54788bc4f5bcf07/raw/ff137e3fdd0b1bb8808d5ff08f5c1c94e8a30665/dashgameported2.gif">
</p>

## Prerequisites

1. You must have [CMake](https://cmake.org/download/) installed.
   - On macOS, install CMake via [Homebrew](https://brew.sh/) using the following command:
     ```bash
     brew install cmake
     ```

## How to run

1. Switch to Flutter's [main channel](https://docs.flutter.dev/release/upgrade#other-channels).
   ```bash
   flutter channel main
   ```
2. Enable the native assets feature.
   ```bash
   flutter config --enable-native-assets
   ```
3. Clone this repository.
   ```bash
   git clone https://github.com/bdero/flutter-scene-example.git
   cd flutter-scene-example
   ```
4. Run the app on macOS, Windows, Linux, iOS, or Android with Impeller enabled.
   ```bash
   flutter run -d macos --enable-impeller
   ```

## History

This repository started life as a 3D demo shown off at [Flutter Forward 2023](https://www.youtube.com/watch?v=zKQYGKAe5W8&t=7074s)!

[![Flutter Forward Thumbnail](https://img.youtube.com/vi/zKQYGKAe5W8/0.jpg)](https://www.youtube.com/watch?v=zKQYGKAe5W8&t=7074s "Flutter Forward 2023")

The 3D renderer was originally built as a C++ component in Impeller. At the time, this required a custom build of Flutter Engine in order to use it.

Since then, we've built and shipped [Flutter GPU](https://github.com/flutter/engine/blob/main/docs/impeller/Flutter-GPU.md) as a preview API in the Flutter SDK, and rewrote the [Flutter Scene](https://github.com/bdero/flutter_scene) renderer in Dart.

We showed this demo off at Flutter's booth during GDC 2024. A few extra features were thrown in for this, including a leaderboard, collisions, music, spikes, fall damage, and jumping.

## Licenses

### Source code

The source code in this repository is MIT licensed.

### Assets

All 3D models, textures, music, and sound effects present in this repository are licensed under a
[Creative Commons Attribution-ShareAlike 4.0 International License][cc-by-sa].

[![CC BY-SA 4.0][cc-by-sa-image]][cc-by-sa]

[cc-by-sa]: http://creativecommons.org/licenses/by-sa/4.0/
[cc-by-sa-image]: https://licensebuttons.net/l/by-sa/4.0/88x31.png
[cc-by-sa-shield]: https://img.shields.io/badge/License-CC%20BY--SA%204.0-lightgrey.svg
