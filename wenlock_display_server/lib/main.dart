import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';

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
      backgroundColor: widget.role == 'Admin'
          ? Colors.black
          : Colors.blueGrey[900],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${widget.role} Login',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _controller,
                obscureText: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white10,
                  hintText: 'Enter Password',
                  hintStyle: const TextStyle(color: Colors.white54),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _verifyPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Login',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _message,
                style: TextStyle(
                  color: _message.contains('✅')
                      ? Colors.greenAccent
                      : Colors.redAccent,
                  fontSize: 16,
                ),
              ),
            ],
          ),
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

      // Expect top-level key "services"
      if (data is Map<String, dynamic> && data.containsKey('services')) {
        final list = data['services'] as List;
        setState(() {
          services = list
              .map((e) => Service.fromJson(e as Map<String, dynamic>))
              .toList();
        });
      }
    } else {
      // Create example default file if none exists
      services = [];
      await _saveServices();
    }
  }

  Future<void> _saveServices() async {
    final file = File('services.json');
    final data = {
      'services': services.map((s) {
        return {
          'id': s.id.toLowerCase().replaceAll(' ', '_'),
          'department': s.department,
          'vbs_path': s.vbsPath,
          'project_dir': s.projectDir,
          'port': s.port,
          'node_exe': s.nodeExe,
          'entry_file': s.entryFile,
          'status': s.status,
          'pid': s.pid,
          'last_started': s.lastStarted,
          'last_stopped': s.lastStopped,
          'log_file': s.logFile,
        };
      }).toList(),
    };
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
  }

  Future<void> _toggleService(Service s) async {
    try {
      // Determine which action to perform
      final action = s.isRunning ? 'stop' : 'start';

      // Run the .vbs script with the correct argument
      await Process.start('wscript', [s.vbsPath, action]);

      // Update the UI and status
      setState(() {
        s.status = s.isRunning ? 'stopped' : 'running';
      });

      await _saveServices();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showServiceForm({Service? service}) {
    final departmentController = TextEditingController(
      text: service?.department ?? '',
    );
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

                // Validation
                if (department.isEmpty) {
                  setDialogState(
                    () => errorMessage = 'Department name is required',
                  );
                  return;
                }
                if (vbsPath.isEmpty) {
                  setDialogState(
                    () => errorMessage = 'VBS file path is required',
                  );
                  return;
                }
                if (!await File(vbsPath).exists()) {
                  setDialogState(
                    () => errorMessage = 'VBS file does not exist: $vbsPath',
                  );
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
      appBar: AppBar(
        title: Text('${widget.role} Control Panel'),
        actions: [
          if (widget.role == 'Admin')
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add Service'),
                    onPressed: () => _showServiceForm(),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reload Services'),
                    onPressed: _loadServices,
                  ),
                ],
              ),
            ),
        ],
        backgroundColor: widget.role == 'Admin'
            ? Colors.black
            : Colors.blueGrey[800],
      ),
      backgroundColor: widget.role == 'Admin'
          ? Colors.black
          : Colors.blueGrey[900],
      body: ListView.builder(
        itemCount: services.length,
        itemBuilder: (context, i) {
          final s = services[i];
          return Card(
            color: Colors.white10,
            margin: const EdgeInsets.all(10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              title: Text(
                s.department,
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
              subtitle: Text(
                s.vbsPath,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: s.isRunning
                          ? Colors.redAccent
                          : Colors.green,
                    ),
                    onPressed: () => _toggleService(s),
                    child: Text(s.isRunning ? 'Stop' : 'Start'),
                  ),
                  if (widget.role == 'Admin')
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () {
                        setState(() {
                          services.remove(s);
                        });
                        _saveServices();
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
