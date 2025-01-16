// File: main.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'utils/http_overrides.dart';
import 'screens/home_page.dart';
import 'services/callback_dispatcher.dart';

void main() {
  HttpOverrides.global = MyHttpOverrides();
  runApp(const MyApp());
  Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: true
  );
  Workmanager().registerPeriodicTask("check-url-tasks", "simpleTask",
      frequency: const Duration(minutes: 15));
  
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
