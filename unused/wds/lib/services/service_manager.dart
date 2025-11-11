import 'dart:io';
import 'package:process_run/shell.dart';
import 'package:http/http.dart' as http;
import '../models/service_model.dart';

class ServiceManager {
  static final ServiceManager _instance = ServiceManager._internal();
  factory ServiceManager() => _instance;
  ServiceManager._internal();

  final shell = Shell();

  // Sample microservices configuration
  List<MicroService> getMicroServices() {
    return [
      MicroService(
        id: 'blood_bank_service',
        name: 'Blood Bank Display Service',
        department: 'Blood Bank',
        description: 'Manages real-time blood inventory display',
        vbScriptPath: 'C:\\HospitalServices\\BloodBank\\service_control.vbs',
        port: 3001,
      ),
      MicroService(
        id: 'pharmacy_service',
        name: 'Pharmacy Display Service',
        department: 'Pharmacy',
        description: 'Manages pharmacy queue and inventory display',
        vbScriptPath: 'C:\\HospitalServices\\Pharmacy\\service_control.vbs',
        port: 3002,
      ),
      // MicroService(
      //   id: 'ot_service',
      //   name: 'Operation Theatre Display Service',
      //   department: 'Operation Theatre',
      //   description: 'Manages OT schedule and status display',
      //   vbScriptPath: 'C:\\HospitalServices\\OT\\service_control.vbs',
      //   port: 3003,
      // ),
      // MicroService(
      //   id: 'icu_service',
      //   name: 'ICU Display Service',
      //   department: 'ICU',
      //   description: 'Manages ICU bed status and patient monitoring display',
      //   vbScriptPath: 'C:\\HospitalServices\\ICU\\service_control.vbs',
      //   port: 3004,
      // ),
      // MicroService(
      //   id: 'emergency_service',
      //   name: 'Emergency Display Service',
      //   department: 'Emergency',
      //   description: 'Manages emergency department queue display',
      //   vbScriptPath: 'C:\\HospitalServices\\Emergency\\service_control.vbs',
      //   port: 3005,
      // ),
      // MicroService(
      //   id: 'lab_service',
      //   name: 'Laboratory Display Service',
      //   department: 'Laboratory',
      //   description: 'Manages lab test status and results display',
      //   vbScriptPath: 'C:\\HospitalServices\\Lab\\service_control.vbs',
      //   port: 3006,
      // ),
    ];
  }

  /// Check if a service is running by attempting to connect to its port
  Future<ServiceStatus> checkServiceStatus(MicroService service) async {
    try {
      final response = await http
          .get(Uri.parse('http://localhost:${service.port}/health'))
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        return ServiceStatus.running;
      }
      return ServiceStatus.stopped;
    } catch (e) {
      // If we can't connect, service is likely stopped
      return ServiceStatus.stopped;
    }
  }

  /// Start a service using its VBScript
  Future<bool> startService(MicroService service) async {
    try {
      // Check if VBScript file exists
      final vbFile = File(service.vbScriptPath);
      if (!await vbFile.exists()) {
        print('VBScript file not found: ${service.vbScriptPath}');
        return false;
      }

      // Execute VBScript with "start" parameter
      await shell.run('cscript //nologo "${service.vbScriptPath}" start');

      // Wait a moment for service to start
      await Future.delayed(const Duration(seconds: 2));

      // Verify service started
      final status = await checkServiceStatus(service);
      return status == ServiceStatus.running;
    } catch (e) {
      print('Error starting service: $e');
      return false;
    }
  }

  /// Stop a service using its VBScript
  Future<bool> stopService(MicroService service) async {
    try {
      // Check if VBScript file exists
      final vbFile = File(service.vbScriptPath);
      if (!await vbFile.exists()) {
        print('VBScript file not found: ${service.vbScriptPath}');
        return false;
      }

      // Execute VBScript with "stop" parameter
      await shell.run('cscript //nologo "${service.vbScriptPath}" stop');

      // Wait a moment for service to stop
      await Future.delayed(const Duration(seconds: 2));

      // Verify service stopped
      final status = await checkServiceStatus(service);
      return status == ServiceStatus.stopped;
    } catch (e) {
      print('Error stopping service: $e');
      return false;
    }
  }

  /// Restart a service
  Future<bool> restartService(MicroService service) async {
    final stopped = await stopService(service);
    if (!stopped) return false;

    await Future.delayed(const Duration(seconds: 1));
    return await startService(service);
  }
}
