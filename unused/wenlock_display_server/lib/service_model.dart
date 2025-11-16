class Service {
  final String id;
  final String department;
  final String vbsPath;
  String projectDir;
  final String? csvPath;
  final String? port;
  String status;

  Service({
    required this.id,
    required this.department,
    required this.vbsPath,
    this.projectDir = '',
    this.csvPath,
    required this.port,
    this.status = 'stopped',
  });

  bool get isRunning => status == 'running';

  Map<String, dynamic> toJson() => {
    'id': id,
    'department': department,
    'vbs_path': vbsPath,
    'project_dir': projectDir,
    'csv_path': csvPath,
    'port': port,
    'status': status,
  };

  factory Service.fromJson(Map<String, dynamic> json) => Service(
    id: json['id'] ?? '',
    department: json['department'] ?? '',
    vbsPath: json['vbs_path'] ?? '',
    projectDir: json['project_dir'] ?? '',
    csvPath: json['csv_path']?.toString(),
    port: json['port'],
    status: json['status'] ?? 'stopped',
  );
}
