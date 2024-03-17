import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
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
        print('Loaded leaderboard from ${file.path}');
        return Leaderboard.fromJson(jsonDecode(json));
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
      print('Leaderboard saved to ${file.path}');
    } catch (e) {
      print('Error saving leaderboard: $e');
    }
  }

  void addEntry(LeaderboardEntry entry) {
    print('Adding entry: ${entry.name} - ${entry.score}');
    entries.add(entry);
    entries.sort((a, b) => b.score.compareTo(a.score));
    if (entries.length > 10) {
      entries.removeRange(10, entries.length);
    }
    saveLocal();
  }
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

  @override
  Widget build(BuildContext context) {
    return HUDBox(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 40),
        width: 440,
        height: 250,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('You collected ${widget.score} coins!'),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name!';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
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
                    child: const Text('Submit'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      widget.onSubmit();
                    },

                    child: const Text('Back to start screen'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
