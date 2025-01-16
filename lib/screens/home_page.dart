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
  final List<TextEditingController> _controllers = [];
  final List<UrlEntry> _urlEntries = [];

  @override
  void initState() {
    super.initState();
    _loadUrls();
    _checkUrls();
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

        entry.titleController.addListener(_saveUrls);
        entry.urlController.addListener(_saveUrls);
        entry.regexController.addListener(_saveUrls);

        _urlEntries.add(entry);
      }
    });
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

  void _deleteURL(int index) {
    setState(() {
      _urlEntries.removeAt(index);
    });
    _saveUrls();
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

  Future<void> _checkUrls() async {
    for (final entry in _urlEntries) {
      setState(() {
        entry.isChecking = true;
      });

      await checkUrlsWithDio([entry]);

      setState(() {
        entry.isChecking = false;
      });
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
                                Row(
                                  children: const [
                                    SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Checking...',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              const SizedBox(width: 8),
                              if (entry.status != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: entry.statusColor.withAlpha(26),
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

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }
}