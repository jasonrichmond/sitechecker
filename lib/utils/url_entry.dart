// File: url_entry.dart
import 'package:flutter/material.dart';

class UrlEntry {
  final TextEditingController titleController;
  final TextEditingController urlController;
  final TextEditingController regexController;
  String status;
  Color statusColor;
  bool regexMatches;
  bool isChecking;

  UrlEntry({
    required this.titleController,
    required this.urlController,
    required this.regexController,
    this.status = 'Unchanged',
    this.statusColor = Colors.grey,
    this.regexMatches = false,
    this.isChecking = false,
  });
}
