import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const HospitalServicesApp());
}

class HospitalServicesApp extends StatelessWidget {
  const HospitalServicesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hospital Services Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
      ),
      home: const LoginScreen(),
    );
  }
}