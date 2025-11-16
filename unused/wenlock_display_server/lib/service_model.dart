class Service {
  final String id;
  final String department;
  final String vbsPath;
  final String projectDir;
  final int port;
  final String nodeExe;
  final String entryFile;
  final String? csvPath;
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
    this.csvPath,
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
    'csv_path': csvPath,
    'status': status,
    'pid': pid,
    'last_started': lastStarted,
    'last_stopped': lastStopped,
    'log_file': logFile,
  };

  factory Service.fromJson(Map<String, dynamic> json) => Service(
    id: json['id'] ?? '',
    department: json['department'] ?? '',
    vbsPath: json['vbs_path'] ?? '',
    projectDir: json['project_dir'] ?? '',
    port:
        int.tryParse(json['port']?.toString() ?? '') ??
        (json['port'] is int ? json['port'] as int : 0),
    nodeExe: json['node_exe'] ?? '',
    entryFile: json['entry_file'] ?? '',
    csvPath: json['csv_path']?.toString(),
    status: json['status'] ?? 'stopped',
    pid: json['pid'],
    lastStarted: json['last_started'],
    lastStopped: json['last_stopped'],
    logFile: json['log_file'],
  );
}
