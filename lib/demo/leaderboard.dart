import 'dart:math' as math;
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:scene_demo/demo/game.dart';

part 'leaderboard.g.dart';

@JsonSerializable()
class LeaderboardEntry {
  final String name;
  final int score;

  LeaderboardEntry(this.name, this.score);

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) =>
      _$LeaderboardEntryFromJson(json);

  Map<String, dynamic> toJson() => _$LeaderboardEntryToJson(this);
}

@JsonSerializable()
class Leaderboard {
  List<LeaderboardEntry> entries = [];

  Leaderboard();

  factory Leaderboard.fromJson(Map<String, dynamic> json) =>
      _$LeaderboardFromJson(json);
  Map<String, dynamic> toJson() => _$LeaderboardToJson(this);

  /// Loads the leaderboard from a local JSON file if available. If the file is
  /// not available, then an empty leaderboard is returned.
  factory Leaderboard.loadLocal() {
    try {
      final file = File('leaderboard.json');
      if (file.existsSync()) {
        final json = file.readAsStringSync();
        print('Loaded leaderboard from ${file.absolute.path}');
        return Leaderboard.fromJson(jsonDecode(json));
      } else {
        print('No leaderboard file found at ${file.absolute.path}');
      }
    } catch (e) {
      print('Error loading leaderboard: $e');
    }
    return Leaderboard();
  }

  /// Saves the leaderboard to a local JSON file.
  void saveLocal() {
    try {
      final file = File('leaderboard.json');
      file.writeAsStringSync(jsonEncode(toJson()));
      print('Leaderboard saved to ${file.absolute.path}');
    } catch (e) {
      print('Error saving leaderboard: $e');
    }
  }

  void addEntry(LeaderboardEntry entry) {
    print('Adding entry: ${entry.name} - ${entry.score}');
    entries.add(entry);
    entries.sort((a, b) => b.score.compareTo(a.score));
    //if (entries.length > 10) {
    //  entries.removeRange(10, entries.length);
    //}
    saveLocal();
  }
}

int getLeaderboardPlacement(int score, Leaderboard leaderboard) {
  for (int i = 0; i < leaderboard.entries.length; i++) {
    if (score > leaderboard.entries[i].score) {
      return i + 1;
    }
  }
  return leaderboard.entries.length + 1;
}

/// A widget that displays the leaderboard entry form.
class LeaderboardForm extends StatefulWidget {
  const LeaderboardForm({Key? key, required this.score, required this.onSubmit})
      : super(key: key);

  final int score;
  final Function onSubmit;

  @override
  State<LeaderboardForm> createState() => _LeaderboardFormState();
}

class _LeaderboardFormState extends State<LeaderboardForm> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late FocusNode _focusNode;

  final Leaderboard readOnlyLeaderboard = Leaderboard.loadLocal();

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HUDBox(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 0),
        width: 590,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              RichText(
                text: TextSpan(
                  text:
                      '🏆 ${getPlacementText(getLeaderboardPlacement(widget.score, readOnlyLeaderboard))}',
                  style: const TextStyle(
                    fontSize: 60,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 255, 255, 174),
                    shadows: [
                      Shadow(
                        blurRadius: 6,
                        color: Colors.black,
                        offset: Offset(2, 2),
                      ),
                    ],
                    overflow: TextOverflow.fade,
                  ),
                  children: const [
                    TextSpan(
                      text: ' place 🏆',
                      style: TextStyle(
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              RichText(
                text: TextSpan(
                  text: 'You collected ',
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.normal,
                    shadows: [
                      Shadow(
                        blurRadius: 6,
                        color: Colors.black,
                        offset: Offset(2, 2),
                      ),
                    ],
                    overflow: TextOverflow.fade,
                  ),
                  children: [
                    TextSpan(
                      text: widget.score.toString(),
                      style: const TextStyle(
                        fontSize: 30,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 154, 255, 218),
                      ),
                    ),
                    TextSpan(
                      text: ' coin${widget.score != 1 ? 's' : ''}! 🤑',
                      style: const TextStyle(
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Container(
                width: 380,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(50),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.white.withAlpha(150),
                        blurRadius: 5,
                        offset: Offset.zero,
                        blurStyle: BlurStyle.outer),
                  ],
                ),
                child: TextFormField(
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        blurRadius: 6,
                        color: Colors.black,
                        offset: Offset(1, 1),
                      ),
                    ],
                    fontFamily: 'monospace',
                    fontFamilyFallback: ['Courier'],
                  ),
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Type your name here!',
                    //border: InputBorder.none,
                    border: UnderlineInputBorder(),
                  ),
                  maxLength: 18,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name!';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: 440,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        widget.onSubmit();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink.withAlpha(130),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22)),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          '⏎ Cancel',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                blurRadius: 4,
                                color: Colors.black,
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          final name = _nameController.text;
                          final leaderboard = Leaderboard.loadLocal();
                          leaderboard
                              .addEntry(LeaderboardEntry(name, widget.score));
                          widget.onSubmit();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 57, 155, 60)
                            .withAlpha(150),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22)),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          '😎 Submit',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                blurRadius: 4,
                                color: Colors.black,
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A widget that displays the leaderboard.
class LeaderboardWidget extends StatefulWidget {
  const LeaderboardWidget({Key? key}) : super(key: key);

  @override
  State<LeaderboardWidget> createState() => _LeaderboardWidgetState();
}

String getPlacementText(int index) {
  final int ones = index % 10;
  final int tens = (index ~/ 10) % 10;
  if (tens != 1) {
    switch (ones) {
      case 1:
        return '${index}st';
      case 2:
        return '${index}nd';
      case 3:
        return '${index}rd';
    }
  }
  return '${index}th';
}

enum LeaderboardState {
  waitingAtTop,
  scrolling,
  waitingAtBottom,
  returning,
}

class _LeaderboardWidgetState extends State<LeaderboardWidget> {
  final Leaderboard _leaderboard = Leaderboard.loadLocal();
  Ticker? _ticker;
  double timeElapsed = 0;
  final ScrollController _scrollController = ScrollController();
  LeaderboardState _state = LeaderboardState.waitingAtTop;

  void resetTicker() {
    _ticker?.stop();
    _ticker?.start();
    timeElapsed = 0;
  }

  @override
  void initState() {
    super.initState();
    _ticker = Ticker((elapsed) {
      setState(() {
        timeElapsed = elapsed.inSeconds.toDouble();

        if (_leaderboard.entries.length < 5) {
          return;
        }

        switch (_state) {
          case LeaderboardState.waitingAtTop:
            if (timeElapsed > 5) {
              _state = LeaderboardState.scrolling;
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: (_leaderboard.entries.length - 5).seconds,
                curve: Curves.linear,
              );
              resetTicker();
            }
            break;
          case LeaderboardState.scrolling:
            if (timeElapsed > _leaderboard.entries.length - 5) {
              _state = LeaderboardState.waitingAtBottom;
              resetTicker();
            }
            break;
          case LeaderboardState.waitingAtBottom:
            if (timeElapsed > 5) {
              _state = LeaderboardState.returning;
              _scrollController.animateTo(
                0,
                duration: 1.seconds,
                curve: Curves.easeInOutCubic,
              );
              resetTicker();
            }
            break;
          case LeaderboardState.returning:
            if (timeElapsed > 1) {
              _state = LeaderboardState.waitingAtTop;
              resetTicker();
            }
            break;
        }
      });
    });
    _ticker?.start();
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      width: 540,
      child: HUDBox(
        child: ShaderMask(
          shaderCallback: (bounds) {
            return const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.purple,
                Colors.transparent,
                Colors.transparent,
                Colors.purple
              ],
              stops: [0.0, 0.1, 0.9, 1.0],
            ).createShader(bounds);
          },
          blendMode: BlendMode.dstOut,
          child: ListView.builder(
            controller: _scrollController,
            itemCount: _leaderboard.entries.length,
            itemBuilder: (context, index) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                      child: Text(
                    getPlacementText(index + 1),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontFamilyFallback: ['Courier'],
                    ),
                    overflow: TextOverflow.fade,
                    softWrap: false,
                  )),
                  Expanded(
                    flex: 3,
                    child: Center(
                      child: Text(
                        '${index == 0 ? '👑 ' : ''}${_leaderboard.entries[index].name}',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontFamilyFallback: ['Courier'],
                        ),
                        overflow: TextOverflow.fade,
                        softWrap: false,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '💰${_leaderboard.entries[index].score.toString()}',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontFamilyFallback: ['Courier'],
                        ),
                        overflow: TextOverflow.fade,
                        softWrap: false,
                      ),
                    ),
                  ),
                ],
              ).animate(key: ValueKey('leaderboardrows$index')).slideY(
                    delay: index < 5
                        ? (math.min(5, index) * 0.2).seconds
                        : 0.seconds,
                    curve: Curves.easeOutCubic,
                    duration: 0.8.seconds,
                    begin: index < 5 ? 10 : 0,
                    end: 0,
                  );
            },
          ),
        ),
      ),
    );
  }
}
