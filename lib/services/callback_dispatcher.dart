import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

int notificationid = 0;
@pragma('vm:entry-point') // Mandatory for obfuscated apps or Flutter 3.1+
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final prefs = await SharedPreferences.getInstance();
    final FlutterLocalNotificationsPlugin notificationsPlugin =
        FlutterLocalNotificationsPlugin();

    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'url_changes_channel',
      'URL Changes',
      channelDescription: 'Notifications for URL content changes',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );
    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);

    // Load stored URLs
    final urls = prefs.getStringList('urls') ?? [];
    for (final url in urls) {
      try {
        final dio = Dio(
          BaseOptions(
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
            },
          ),
        );

        try {
          final response = await dio.get(url);
          if (response.statusCode == 200) {
            // Handle response
            debugPrint(response.data);
          }
        } on DioException catch (e) {
          debugPrint('Error: ${e.message}');
        }

        final response = await http.get(
          Uri.parse(url),
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
            'Accept':
                'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
            'Connection': 'keep-alive',
          },
        );

        if (response.statusCode == 200) {
          final savedContent = prefs.getString(url);
          if (savedContent == null) {
            // First time fetching the URL
            await prefs.setString(url, response.body);
          } else if (savedContent != response.body) {
            // Content has changed
            await prefs.setString(url, response.body);
            await notificationsPlugin.show(
              notificationid++, // Unique notification ID
              'Content Changed',
              'The content of $url has changed.',
              notificationDetails,
            );
          }
        }
      } catch (e) {
        // Handle any errors while fetching URLs
        debugPrint('Error checking URL $url: $e');
      }
    }

    return Future.value(true);
  });
}