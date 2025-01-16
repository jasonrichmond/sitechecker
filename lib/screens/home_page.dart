// File: home_page.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/url_entry.dart';
import '../services/url_checker_service.dart';
import 'package:url_launcher/url_launcher.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final List<UrlEntry> _urlEntries = [];

  @override
  void initState() {
    super.initState();
    _loadUrls();

    // Call _checkUrls after the widget is rendered
    Future.delayed(Duration.zero, () {
      debugPrint("Automatically calling _checkUrls on page initialization...");
      _checkUrls();
    });
  }

  Future<void> _loadUrls() async {
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

        entry.titleController.addListener(_saveUrls);
        entry.urlController.addListener(_saveUrls);
        entry.regexController.addListener(_saveUrls);

        _urlEntries.add(entry);
      }
    });
  }

  Future<void> _saveUrls() async {
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

  Future<void> _checkUrls() async {
    for (final entry in _urlEntries) {
      if (!mounted) return;

      setState(() {
        entry.status = 'Checking...';
        entry.statusColor = Colors.blue;
        entry.isChecking = true;
      });

      try {
        await checkUrlsWithDio([entry]);
      } catch (e) {
        debugPrint("Error checking URL: ${entry.urlController.text}, Error: $e");
      } finally {
        if (mounted) {
          setState(() {
            entry.isChecking = false;
          });
        }
      }
    }
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
                    child: Container(
                      decoration: BoxDecoration(
                        color: entry.isChecking
                            ? Colors.grey.withAlpha(26)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
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
                              if (entry.isChecking)
                                const CircularProgressIndicator(),
                              const SizedBox(width: 10),
                              Text(entry.status),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: _checkUrls,
              child: const Text('Check URLs'),
            ),
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

  void _addNewUrlField() {
    setState(() {
      final entry = UrlEntry(
        titleController: TextEditingController(),
        urlController: TextEditingController(),
        regexController: TextEditingController(),
      );

      entry.titleController.addListener(_saveUrls);
      entry.urlController.addListener(_saveUrls);
      entry.regexController.addListener(_saveUrls);

      _urlEntries.add(entry);
    });
  }
}
