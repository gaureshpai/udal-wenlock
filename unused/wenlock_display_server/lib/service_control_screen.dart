import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
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
          color: Colors.grey,
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
    final data = {'services': services.map((s) => s.toJson()).toList()};
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
  }

  Future<void> _startService(Service s) async {
    try {
      final action = 'start';
      await Process.start('wscript', [s.vbsPath, action]);
      setState(() {
        s.status = 'running';
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

  void _showServiceForm({Service? service}) {
    final departmentController = TextEditingController(
      text: service?.department ?? '',
    );
    final vbsController = TextEditingController(text: service?.vbsPath ?? '');
    final csvController = TextEditingController(text: service?.csvPath ?? '');
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
                  csvPath: csvPath.isEmpty ? null : csvPath,
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
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 24,
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            s.department.toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        BlinkingDot(active: s.isRunning),
                        const SizedBox(width: 10),
                        Text(
                          s.isRunning ? 'RUNNING' : 'STOPPED',
                          style: TextStyle(
                            color: s.isRunning
                                ? Colors.green
                                : Colors.redAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!s.isRunning)
                          SizedBox(
                            width: 120,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                              ),
                              onPressed: () => _startService(s),
                              child: const Text(
                                'START',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        if (s.csvPath != null &&
                            s.csvPath!.isNotEmpty &&
                            (widget.role == 'Staff' || widget.role == 'Admin'))
                          IconButton(
                            icon: const Icon(
                              Icons.edit,
                              color: Colors.blueAccent,
                            ),
                            tooltip: 'Edit CSV',
                            onPressed: () => _editCsv(s),
                          ),
                        if (widget.role == 'Admin')
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
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
