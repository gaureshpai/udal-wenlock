import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wenlock_display_server/run_check.dart';
import 'package:wenlock_display_server/service_model.dart';

class ServiceControlScreen extends StatefulWidget {
  final String role;
  const ServiceControlScreen({super.key, required this.role});

  @override
  State<ServiceControlScreen> createState() => _ServiceControlScreenState();
}

class BlinkingDot extends StatefulWidget {
  final bool active;
  const BlinkingDot({super.key, required this.active});

  @override
  State<BlinkingDot> createState() => _BlinkingDotState();
}

class _BlinkingDotState extends State<BlinkingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    if (widget.active) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant BlinkingDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.active && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) {
      return Container(
        width: 12,
        height: 12,
        decoration: const BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
      );
    }

    return FadeTransition(
      opacity: _controller.drive(Tween(begin: 0.2, end: 1.0)),
      child: Container(
        width: 12,
        height: 12,
        decoration: const BoxDecoration(
          color: Color(0xFF16A34A),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _ServiceControlScreenState extends State<ServiceControlScreen> {
  List<Service> services = [];
  Timer? _statusCheckTimer;

  @override
  void initState() {
    super.initState();
    _loadServices();
    _startStatusMonitoring();
  }

  void _startStatusMonitoring() {
    _statusCheckTimer?.cancel();
    _statusCheckTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _checkAllServiceStatuses(),
    );
  }

  Future<void> _checkAllServiceStatuses() async {
    bool hasChanges = false;
    for (var service in services) {
      if (service.projectDir.isNotEmpty) {
        final isRunning = await isServiceRunning(service.projectDir);
        final newStatus = isRunning ? 'running' : 'stopped';
        if (service.status != newStatus) {
          service.status = newStatus;
          hasChanges = true;
        }
      }
    }
    if (hasChanges && mounted) {
      setState(() {});
      await _saveServices();
    }
  }

  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    super.dispose();
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

          // Extract projectDir from vbsPath if empty
          for (var service in services) {
            if (service.projectDir.isEmpty && service.vbsPath.isNotEmpty) {
              final vbsFile = File(service.vbsPath);
              service.projectDir = vbsFile.parent.path;
            }
          }
        });
        await _checkAllServiceStatuses();
      }
    } else {
      services = [];
      await _saveServices();
    }
  }

  Future<void> _saveServices() async {
    final file = File('services.json');
    final data = {'services': services.map((s) => s.toJson()).toList()};
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
  }

  Future<void> _startService(Service s) async {
    try {
      final action = 'start';
      await Process.start('wscript', [s.vbsPath, action]);
      setState(() {
        // s.status = 'running';
      });
      await _saveServices();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error starting service: $e')));
      }
    }
  }

  Future<void> _stopService(Service s) async {
    try {
      final action = 'stop';
      await Process.run('wscript', [s.vbsPath, action]);
      setState(() {
        s.status = 'stopped';
      });
      await _saveServices();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${s.department} stopped successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error stopping service: $e')));
      }
    }
  }

  void _showServiceForm({Service? service}) {
    final departmentController = TextEditingController(
      text: service?.department ?? '',
    );
    final vbsController = TextEditingController(text: service?.vbsPath ?? '');
    final csvController = TextEditingController(text: service?.csvPath ?? '');
    final portController = TextEditingController(text: service?.port ?? '');
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
                _buildTextField('CSV File Path (optional)', csvController),
                _buildTextField('Port No.', portController),
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
                final csvPath = csvController.text.trim();
                final port = portController.text.trim();

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
                if (port.isEmpty) {
                  setDialogState(() => errorMessage = 'Port is required');
                  return;
                }
                if (!await File(vbsPath).exists()) {
                  setDialogState(
                    () => errorMessage = 'VBS file does not exist: $vbsPath',
                  );
                  return;
                }

                // Extract projectDir from vbsPath
                final vbsFile = File(vbsPath);
                final projectDir = vbsFile.parent.path;

                final newService = Service(
                  id: department.toLowerCase().replaceAll(' ', '_'),
                  department: department,
                  vbsPath: vbsPath,
                  csvPath: csvPath.isEmpty ? null : csvPath,
                  port: port,
                  projectDir: projectDir,
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
        toolbarHeight: 120,
        title: Image.asset('assets/wenlock_logo.png', fit: BoxFit.fitWidth),
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
            onPressed: () async {
              await _loadServices();
              await _checkAllServiceStatuses();
            },
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
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 24,
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(width: 10),
                        Expanded(
                          child: Row(
                            children: [
                              Text(
                                s.department.toUpperCase(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                ),
                              ),
                              const SizedBox(width: 20),
                              if (s.csvPath != null &&
                                  s.csvPath!.isNotEmpty &&
                                  (widget.role == 'Staff' ||
                                      widget.role == 'Admin'))
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    side: const BorderSide(
                                      color: Colors.greenAccent,
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.green,
                                  ),
                                  label: const Text(
                                    'Edit CSV',
                                    style: TextStyle(color: Colors.green),
                                  ),
                                  onPressed: () => _editCsv(s),
                                ),
                              SizedBox(width: 10),
                              IconButton(
                                onPressed: () => launchUrl(
                                  Uri.parse('http://localhost:${s.port}'),
                                ),
                                icon: Icon(Icons.launch_rounded),
                              ),
                            ],
                          ),
                        ),
                        BlinkingDot(active: s.isRunning),
                        const SizedBox(width: 10),
                        Text(
                          s.isRunning ? 'RUNNING' : 'STOPPED',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w600,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!s.isRunning)
                          ElevatedButton.icon(
                            onPressed: () => _startService(s),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            icon: const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'START',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        if (s.isRunning)
                          ElevatedButton.icon(
                            onPressed: () => _stopService(s),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            icon: const Icon(
                              Icons.stop_rounded,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'STOP',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        if (widget.role == 'Admin')
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              size: 48,
                              color: Colors.redAccent,
                            ),
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

  Future<void> _editCsv(Service s) async {
    final path = s.csvPath;
    if (path == null || path.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No CSV path configured for this service.'),
          ),
        );
      }
      return;
    }

    final file = File(path);
    String content = '';
    if (await file.exists()) {
      content = await file.readAsString();
    }

    final controller = TextEditingController(text: content);

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Edit CSV - ${s.department}'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: TextField(
              controller: controller,
              maxLines: 20,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'CSV content',
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // Ensure parent directory exists
                final parent = file.parent;
                if (!await parent.exists()) {
                  await parent.create(recursive: true);
                }
                await file.writeAsString(controller.text);
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('CSV saved')));
                }
                Navigator.pop(context);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error saving CSV: $e')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
