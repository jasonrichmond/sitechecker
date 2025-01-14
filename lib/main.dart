import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';

int notificationid = 0;
final List<UrlEntry> _urlEntries = [];

class UrlEntry {
  final TextEditingController titleController;
  final TextEditingController urlController;
  final TextEditingController regexController;
  String status;
  Color statusColor;

  UrlEntry({
    required this.titleController,
    required this.urlController,
    required this.regexController,
    this.status = 'Unchanged',
    this.statusColor = Colors.grey,
  });
}

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
        final response = await http.get(Uri.parse(url));
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

void main() {
  runApp(const MyApp());
  Workmanager().initialize(
      callbackDispatcher, // The top level function, aka callbackDispatcher
      isInDebugMode:
          true // If enabled it will post a notification whenever the task is running. Handy for debugging tasks
      );
  Workmanager().registerPeriodicTask("check-url-tasks", "simpleTask",
      frequency: const Duration(minutes: 15)); // Register the task
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Website Checker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Website Checker'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final List<TextEditingController> _controllers = [];
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  // ignore: unused_field
  bool _notificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    _notificationsEnabled = false;
    _isAndroidPermissionGranted();
    _requestPermissions();
    _initializeNotifications();
    _loadUrls();
  }

  Future<void> _isAndroidPermissionGranted() async {
    if (Platform.isAndroid) {
      final bool granted = await _notificationsPlugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>()
              ?.areNotificationsEnabled() ??
          false;

      setState(() {
        _notificationsEnabled = granted;
      });
    }
  }

  Future<void> _requestPermissions() async {
    if (Platform.isIOS || Platform.isMacOS) {
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    } else if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      final bool? grantedNotificationPermission =
          await androidImplementation?.requestNotificationsPermission();
      setState(() {
        _notificationsEnabled = grantedNotificationPermission ?? false;
      });
    }
  }

  void _initializeNotifications() async {
    debugPrint('initializing notifications');
    final AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings(
            '@mipmap/ic_launcher'); // Replace with your app icon

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );
    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle when a notification is tapped
        debugPrint("Notification tapped with payload: ${response.payload}");
      },
    );
  }

  Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'url_changes_channel', 'URL Changes', // Channel name
      channelDescription: 'Notifications for URL content changes',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );
    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);
    await _notificationsPlugin.show(
        notificationid++, // Unique notification ID
        title,
        body,
        notificationDetails,
        payload: 'test');
  }

  void _saveUrls() async {
    final prefs = await SharedPreferences.getInstance();

    final titles =
        _urlEntries.map((entry) => entry.titleController.text).toList();
    final urls = _urlEntries.map((entry) => entry.urlController.text).toList();
    final regexes =
        _urlEntries.map((entry) => entry.regexController.text).toList();

    await prefs.setStringList('titles', titles);
    await prefs.setStringList('urls', urls);
    await prefs.setStringList('regexes', regexes);
  }

  void _loadUrls() async {
    final prefs = await SharedPreferences.getInstance();
    final titles = prefs.getStringList('titles') ?? [];
    final urls = prefs.getStringList('urls') ?? [];
    final regexes = prefs.getStringList('regexes') ?? [];

    setState(() {
      for (int i = 0; i < urls.length; i++) {
        final entry = UrlEntry(
          titleController:
              TextEditingController(text: titles.length > i ? titles[i] : ''),
          urlController: TextEditingController(text: urls[i]),
          regexController:
              TextEditingController(text: regexes.length > i ? regexes[i] : ''),
        );

        entry.titleController.addListener(() => _saveUrls());
        entry.urlController.addListener(() => _saveUrls());
        entry.regexController.addListener(() => _saveUrls());

        _urlEntries.add(entry);
      }
    });
  }

  Future<void> _checkUrls() async {
    final prefs = await SharedPreferences.getInstance();

    for (final entry in _urlEntries) {
      final url = entry.urlController.text;
      final regexString = entry.regexController.text;
      RegExp? regex;

      if (regexString.isNotEmpty) {
        try {
          regex = RegExp(regexString);
        } catch (e) {
          setState(() {
            entry.status = 'Invalid Regex';
            entry.statusColor = Colors.red;
          });
          continue;
        }
      }

      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final savedContent = prefs.getString(url);
          final newContent = response.body;

          if (savedContent == null) {
            await prefs.setString(url, newContent);
            setState(() {
              entry.status = 'First Check';
              entry.statusColor = Colors.blue;
            });
          } else if (savedContent != newContent) {
            if (regex == null || regex.hasMatch(newContent)) {
              await prefs.setString(url, newContent);
              setState(() {
                entry.status = 'Changed';
                entry.statusColor = Colors.green;
              });
            } else {
              setState(() {
                entry.status = 'No Match';
                entry.statusColor = Colors.orange;
              });
            }
          } else {
            setState(() {
              entry.status = 'Unchanged';
              entry.statusColor = Colors.grey;
            });
          }
        }
      } catch (e) {
        setState(() {
          entry.status = 'Error';
          entry.statusColor = Colors.red;
        });
      }
    }
  }

  void _addNewUrlField() {
    setState(() {
      final entry = UrlEntry(
        titleController: TextEditingController(),
        urlController: TextEditingController(),
        regexController: TextEditingController(),
      );

      entry.titleController.addListener(() => _saveUrls());
      entry.urlController.addListener(() => _saveUrls());
      entry.regexController.addListener(() => _saveUrls());

      _urlEntries.add(entry);
    });
  }
Future<void> _launchUrl(String url) async {
  final Uri uri = Uri.parse(url);

  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Could not launch $url'),
        backgroundColor: Colors.red,
      ),
    );
  }
}


  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _deleteURL(int index) async {
    setState(() {
      _urlEntries.removeAt(index);
    });
    _saveUrls();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('Enter URLs to check:'),
            Expanded(
              child: ListView.builder(
                itemCount: _urlEntries.length,
                itemBuilder: (context, index) {
                  final entry = _urlEntries[index];

                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: entry.titleController,
                          decoration: InputDecoration(
                            labelText: 'Title ${index + 1}',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: entry.urlController,
                          decoration: InputDecoration(
                            labelText: 'URL ${index + 1}',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: entry.regexController,
                          decoration: InputDecoration(
                            labelText: 'Regular Expression ${index + 1}',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: entry.statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                entry.status,
                                style: TextStyle(
                                    color: entry.statusColor,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.open_in_browser),
                              onPressed: () =>
                                  _launchUrl(entry.urlController.text),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteURL(index),
                            ),
                          ],
                        ),
                        const Divider(),
                      ],
                    ),
                  );
                },
              ),
            ),

            ElevatedButton(
              onPressed: _checkUrls,
              child: const Text('Check URLs'),
            ),
            // Add the new button for "Hello World" notification
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewUrlField,
        tooltip: 'Add URL',
        child: const Icon(Icons.add),
      ),
    );
  }
}
