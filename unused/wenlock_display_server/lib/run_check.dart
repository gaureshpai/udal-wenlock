import 'dart:io';
import 'dart:async';

/// Checks if a process with the given PID is still running
Future<bool> isProcessRunning(int pid) async {
  try {
    // Use tasklist to check if the process exists
    final result = await Process.run('tasklist', [
      '/FI',
      'PID eq $pid',
      '/NH',
      '/FO',
      'CSV',
    ], runInShell: true);

    // If the output contains the PID, the process is running
    return result.stdout.toString().contains(pid.toString());
  } catch (e) {
    print('Error checking process: $e');
    return false;
  }
}

/// Reads the PID from the service.pid file in the project directory
Future<int?> readServicePid(String projectDir) async {
  try {
    final pidFile = File('$projectDir\\service.pid');

    if (!await pidFile.exists()) {
      return null;
    }

    final pidString = await pidFile.readAsString();
    return int.tryParse(pidString.trim());
  } catch (e) {
    print('Error reading PID file: $e');
    return null;
  }
}

/// Checks if a service is running by reading its PID file and checking the process
Future<bool> isServiceRunning(String projectDir) async {
  final pid = await readServicePid(projectDir);

  if (pid == null) {
    return false;
  }

  return await isProcessRunning(pid);
}

/// Continuously monitors multiple services and updates their status
/// Returns a stream that emits a map of service IDs to their running status
Stream<Map<String, bool>> monitorServices(
  Map<String, String> serviceProjectDirs, {
  Duration checkInterval = const Duration(seconds: 5),
}) async* {
  while (true) {
    final statusMap = <String, bool>{};

    for (final entry in serviceProjectDirs.entries) {
      final serviceId = entry.key;
      final projectDir = entry.value;
      statusMap[serviceId] = await isServiceRunning(projectDir);
    }

    yield statusMap;
    await Future.delayed(checkInterval);
  }
}
