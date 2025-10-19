import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter/foundation.dart';

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

class LoginScreen extends StatefulWidget {
  final String role;
  const LoginScreen({super.key, required this.role});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _controller = TextEditingController();
  String _message = '';

  // Pre-hashed passwords (SHA-256 of “admin123” and “staff123” for demo)
  static const adminHash =
      '240be518fabd2724ddb6f04eeb1da5967448d7e831c08c8fa822809f74c720a9';
  static const staffHash =
      '10176e7b7b24d317acfcf8d2064cfd2f24e154f7b5a96603077d5ef813d6a6b6';

  Future<void> _verifyPassword() async {
    final input = _controller.text.trim();
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes).toString();

    final correctHash = widget.role == 'Admin' ? adminHash : staffHash;

    setState(() {
      if (digest == correctHash) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ServiceControlScreen(role: widget.role),
          ),
        );
      } else {
        _message = '❌ Incorrect Password';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100.0),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          flexibleSpace: Center(
            child: SizedBox(
              height: 80,
              child: Image.asset('assets/wenlock_logo.png', fit: BoxFit.contain),
            ),
          ),
          centerTitle: true,
        ),
      ),
      body: Center(
        child: SizedBox(
          width: 500,
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${widget.role} Login',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _controller,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _verifyPassword,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Login'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _message,
                    style: TextStyle(
                      color: _message.contains('✅')
                          ? Colors.green
                          : Colors.red,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        height: 30,
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${DateTime.now().year}@ UDAL DC Fellowship',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class Service {
  final String id;
  final String department;
  final String vbsPath;
  final String projectDir;
  final int port;
  final String nodeExe;
  final String entryFile;
  String status;
  int? pid;
  String? lastStarted;
  String? lastStopped;
  String? logFile;

  Service({
    required this.id,
    required this.department,
    required this.vbsPath,
    this.projectDir = '',
    this.port = 4000,
    this.nodeExe = r'C:\Program Files\nodejs\node.exe',
    this.entryFile = 'server.js',
    this.status = 'stopped',
    this.pid,
    this.lastStarted,
    this.lastStopped,
    this.logFile,
  });

  bool get isRunning => status == 'running';

  Map<String, dynamic> toJson() => {
    'id': id,
    'department': department,
    'vbs_path': vbsPath,
    'project_dir': projectDir,
    'port': port,
    'node_exe': nodeExe,
    'entry_file': entryFile,
    'status': status,
    'pid': pid,
    'last_started': lastStarted,
    'last_stopped': lastStopped,
    'log_file': logFile,
  };

  static Service fromJson(Map<String, dynamic> json) => Service(
    id: json['id'] ?? '',
    department: json['department'] ?? '',
    vbsPath: json['vbs_path'] ?? '',
    projectDir: json['project_dir'] ?? '',
    port: (json['port'] ?? 0).toInt(),
    nodeExe: json['node_exe'] ?? '',
    entryFile: json['entry_file'] ?? '',
    status: json['status'] ?? 'stopped',
    pid: json['pid'],
    lastStarted: json['last_started'],
    lastStopped: json['last_stopped'],
    logFile: json['log_file'],
  );
}

class ServiceControlScreen extends StatefulWidget {
  final String role;
  const ServiceControlScreen({super.key, required this.role});

  @override
  State<ServiceControlScreen> createState() => _ServiceControlScreenState();
}

class _ServiceControlScreenState extends State<ServiceControlScreen> {
  List<Service> services = [];

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    final file = File('services.json');
    if (await file.exists()) {
      final content = await file.readAsString();
      final data = json.decode(content);

      if (data is Map<String, dynamic> && data.containsKey('services')) {
        final list = data['services'] as List;
        setState(() {
          services = list
              .map((e) => Service.fromJson(e as Map<String, dynamic>))
              .toList();
        });
      }
    } else {
      services = [];
      await _saveServices();
    }
  }

  Future<void> _saveServices() async {
    final file = File('services.json');
    final data = {
      'services': services.map((s) => s.toJson()).toList(),
    };
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
  }

  Future<void> _toggleService(Service s) async {
    try {
      final action = s.isRunning ? 'stop' : 'start';
      await Process.start('wscript', [s.vbsPath, action]);
      setState(() {
        s.status = s.isRunning ? 'stopped' : 'running';
      });
      await _saveServices();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showServiceForm({Service? service}) {
    final departmentController =
        TextEditingController(text: service?.department ?? '');
    final vbsController = TextEditingController(text: service?.vbsPath ?? '');
    String errorMessage = '';

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(service == null ? 'Add Service' : 'Edit Service'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField('Department *', departmentController),
                _buildTextField('VBS File Path *', vbsController),
                if (errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      errorMessage,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                const Padding(
                  padding: EdgeInsets.only(top: 12.0),
                  child: Text(
                    'Note: Ensure your VBS file is configured with correct project settings.',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final department = departmentController.text.trim();
                final vbsPath = vbsController.text.trim();

                if (department.isEmpty) {
                  setDialogState(
                      () => errorMessage = 'Department name is required');
                  return;
                }
                if (vbsPath.isEmpty) {
                  setDialogState(
                      () => errorMessage = 'VBS file path is required');
                  return;
                }
                if (!await File(vbsPath).exists()) {
                  setDialogState(
                      () => errorMessage = 'VBS file does not exist: $vbsPath');
                  return;
                }

                final newService = Service(
                  id: department.toLowerCase().replaceAll(' ', '_'),
                  department: department,
                  vbsPath: vbsPath,
                  projectDir: service?.projectDir ?? '',
                  port: service?.port ?? 4000,
                  nodeExe:
                      service?.nodeExe ?? r'C:\Program Files\nodejs\node.exe',
                  entryFile: service?.entryFile ?? 'server.js',
                );

                setState(() {
                  if (service == null) {
                    services.add(newService);
                  } else {
                    final index = services.indexOf(service);
                    services[index] = newService;
                  }
                });
                _saveServices();
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool isNumber = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: SizedBox(
          height: 50,
          child: Image.asset('assets/wenlock_logo.png', fit: BoxFit.contain),
        ),
        centerTitle: true,
        actions: [
          if (widget.role == 'Admin')
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showServiceForm(),
              tooltip: 'Add Service',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadServices,
            tooltip: 'Reload Services',
          ),
        ],
      ),
      body: services.isEmpty
          ? const Center(
              child: Text(
                'No services configured.',
                style: TextStyle(color: Colors.grey, fontSize: 18),
              ),
            )
          : ListView.builder(
              itemCount: services.length,
              itemBuilder: (context, i) {
                final s = services[i];
                return Container(
                  color: i.isEven ? const Color(0xFFF3F4F6) : Colors.white,
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    title: Text(
                      s.department.toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 120,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: s.isRunning
                                  ? const Color(0xFF16A34A)
                                  : Colors.grey,
                            ),
                            onPressed: () => _toggleService(s),
                            child: Text(
                              s.isRunning ? 'RUNNING' : 'STOPPED',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        if (widget.role == 'Admin')
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () {
                              setState(() => services.remove(s));
                              _saveServices();
                            },
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: Container(
        height: 30,
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${services.length} services',
              style: const TextStyle(color: Colors.grey),
            ),
            Text(
              '${widget.role} Access',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}