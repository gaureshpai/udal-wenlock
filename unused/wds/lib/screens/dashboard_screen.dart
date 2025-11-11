import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../models/service_model.dart';
import '../services/service_manager.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ServiceManager _serviceManager = ServiceManager();
  List<MicroService> _services = [];
  bool _isLoading = true;
  String _username = '';
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadServices();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _refreshServiceStatuses();
    });
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('logged_in_user') ?? 'Staff';
    });
  }

  Future<void> _loadServices() async {
    setState(() => _isLoading = true);
    
    _services = _serviceManager.getMicroServices();
    
    // Check status of all services
    for (var service in _services) {
      final status = await _serviceManager.checkServiceStatus(service);
      service.status = status;
      service.lastChecked = DateTime.now();
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _refreshServiceStatuses() async {
    for (var service in _services) {
      final status = await _serviceManager.checkServiceStatus(service);
      if (mounted) {
        setState(() {
          service.status = status;
          service.lastChecked = DateTime.now();
        });
      }
    }
  }

  Future<void> _startService(MicroService service) async {
    final messenger = ScaffoldMessenger.of(context);
    
    setState(() {
      service.status = ServiceStatus.unknown;
    });

    final success = await _serviceManager.startService(service);
    
    if (success) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('${service.name} started successfully'),
          backgroundColor: Colors.green,
        ),
      );
      await _refreshServiceStatuses();
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to start ${service.name}'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        service.status = ServiceStatus.error;
      });
    }
  }

  Future<void> _stopService(MicroService service) async {
    final messenger = ScaffoldMessenger.of(context);
    
    setState(() {
      service.status = ServiceStatus.unknown;
    });

    final success = await _serviceManager.stopService(service);
    
    if (success) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('${service.name} stopped successfully'),
          backgroundColor: Colors.orange,
        ),
      );
      await _refreshServiceStatuses();
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to stop ${service.name}'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        service.status = ServiceStatus.error;
      });
    }
  }

  Future<void> _restartService(MicroService service) async {
    final messenger = ScaffoldMessenger.of(context);
    
    setState(() {
      service.status = ServiceStatus.unknown;
    });

    final success = await _serviceManager.restartService(service);
    
    if (success) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('${service.name} restarted successfully'),
          backgroundColor: Colors.blue,
        ),
      );
      await _refreshServiceStatuses();
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to restart ${service.name}'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        service.status = ServiceStatus.error;
      });
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hospital Microservices Dashboard'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadServices,
            tooltip: 'Refresh All',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                'Welcome, $_username',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _services.isEmpty
              ? const Center(child: Text('No services configured'))
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummaryCards(),
                      const SizedBox(height: 24),
                      Text(
                        'Services',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _services.length,
                          itemBuilder: (context, index) {
                            return _buildServiceCard(_services[index]);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSummaryCards() {
    final running = _services.where((s) => s.status == ServiceStatus.running).length;
    final stopped = _services.where((s) => s.status == ServiceStatus.stopped).length;
    final total = _services.length;

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Total Services',
            total.toString(),
            Colors.blue,
            Icons.dashboard,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            'Running',
            running.toString(),
            Colors.green,
            Icons.check_circle,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            'Stopped',
            stopped.toString(),
            Colors.red,
            Icons.stop_circle,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String label, String value, Color color, IconData icon) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(MicroService service) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.circle,
                  size: 16,
                  color: service.status.color,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    service.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(
                  label: Text(
                    service.status.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                  backgroundColor: service.status.color,
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Department: ${service.department}',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
              ),
            ),
            Text(
              service.description,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Port: ${service.port}',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
              ),
            ),
            if (service.lastChecked != null)
              Text(
                'Last checked: ${DateFormat('HH:mm:ss').format(service.lastChecked!)}',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
              ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (service.status == ServiceStatus.stopped)
                  ElevatedButton.icon(
                    onPressed: () => _startService(service),
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: const Text('Start'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                if (service.status == ServiceStatus.running) ...[
                  ElevatedButton.icon(
                    onPressed: () => _stopService(service),
                    icon: const Icon(Icons.stop, size: 18),
                    label: const Text('Stop'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _restartService(service),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Restart'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
                if (service.status == ServiceStatus.unknown)
                  const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}