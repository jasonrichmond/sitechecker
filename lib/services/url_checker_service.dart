// File: url_checker_service.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../utils/url_entry.dart';

Future<void> checkUrlsWithDio(List<UrlEntry> urlEntries) async {
  final dio = Dio(
    BaseOptions(
      headers: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        'Accept':
            'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
        'Connection': 'keep-alive',
      },
    ),
  );

  for (final entry in urlEntries) {
    final url = entry.urlController.text;
    final regexString = entry.regexController.text;
    RegExp? regex;

    entry.isChecking = true;
    entry.regexMatches = false;
    entry.status = 'Checking...';
    entry.statusColor = Colors.blue;

    try {
      if (regexString.isNotEmpty) {
        try {
          regex = RegExp(regexString);
        } catch (e) {
          entry.status = 'Invalid Regex';
          entry.statusColor = Colors.red;
          entry.isChecking = false;
          continue;
        }
      }

      final response = await dio.get(url);

      if (response.statusCode == 200) {
        final content = response.data.toString();

        if (regex != null && regex.hasMatch(content)) {
          entry.regexMatches = true;
          entry.status = 'Matches Regex';
          entry.statusColor = Colors.green;
        } else {
          entry.status = 'No Match';
          entry.statusColor = Colors.orange;
        }
      } else {
        entry.status = 'Error: ${response.statusCode}';
        entry.statusColor = Colors.red;
      }
    } on DioException catch (e) {
      entry.status = 'Error: ${e.message}';
      entry.statusColor = Colors.red;
    } catch (e) {
      entry.status = 'Unexpected Error';
      entry.statusColor = Colors.red;
    } finally {
      entry.isChecking = false;
    }
  }
}
