import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:wenlock_display_server/login_screen.dart';

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PrivilegeCheckApp(),
    ),
  );
}

class PrivilegeCheckApp extends StatefulWidget {
  const PrivilegeCheckApp({super.key});

  @override
  State<PrivilegeCheckApp> createState() => _PrivilegeCheckAppState();
}

class _PrivilegeCheckAppState extends State<PrivilegeCheckApp> {
  bool? isAdmin;

  @override
  void initState() {
    super.initState();
    _checkAdminPrivilege();
  }

  Future<void> _checkAdminPrivilege() async {
    if (kIsWeb) {
      if (kDebugMode) {
        // Allow admin mode in debug web builds for testing
        setState(() => isAdmin = true);
      } else {
        setState(() => isAdmin = false);
      }
      return;
    }
    try {
      // Try running a command that only works under admin privileges.
      final result = await Process.run('net', ['session']);
      setState(() => isAdmin = result.exitCode == 0);
    } catch (_) {
      setState(() => isAdmin = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isAdmin == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return isAdmin!
        ? const LoginScreen(role: 'Admin')
        : const LoginScreen(role: 'Staff');
  }
}
