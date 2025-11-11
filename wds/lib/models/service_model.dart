import 'package:flutter/material.dart';

class MicroService {
  final String id;
  final String name;
  final String department;
  final String description;
  final String vbScriptPath;
  final int port;
  ServiceStatus status;
  DateTime? lastChecked;

  MicroService({
    required this.id,
    required this.name,
    required this.department,
    required this.description,
    required this.vbScriptPath,
    required this.port,
    this.status = ServiceStatus.unknown,
    this.lastChecked,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'department': department,
    'description': description,
    'vbScriptPath': vbScriptPath,
    'port': port,
  };

  factory MicroService.fromJson(Map<String, dynamic> json) => MicroService(
    id: json['id'],
    name: json['name'],
    department: json['department'],
    description: json['description'],
    vbScriptPath: json['vbScriptPath'],
    port: json['port'],
  );
}

enum ServiceStatus { running, stopped, unknown, error }

extension ServiceStatusExtension on ServiceStatus {
  String get displayName {
    switch (this) {
      case ServiceStatus.running:
        return 'Running';
      case ServiceStatus.stopped:
        return 'Stopped';
      case ServiceStatus.unknown:
        return 'Unknown';
      case ServiceStatus.error:
        return 'Error';
    }
  }

  Color get color {
    switch (this) {
      case ServiceStatus.running:
        return Colors.green;
      case ServiceStatus.stopped:
        return Colors.red;
      case ServiceStatus.unknown:
        return Colors.grey;
      case ServiceStatus.error:
        return Colors.orange;
    }
  }
}
