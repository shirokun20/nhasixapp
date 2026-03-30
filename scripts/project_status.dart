// ignore_for_file: avoid_print

import 'dart:io';

void main() {
  print('🔄 Updating Project Dashboards...');

  // 1. Update Individual Dashboards
  final data = <String, List<String>>{};

  data['🔮 Future Plans'] = _updateDirectoryReadme('projects/future-plan');
  data['📋 Analysis Phase'] = _updateDirectoryReadme('projects/analysis-plan');
  data['🚧 On Progress'] = _updateDirectoryReadme('projects/onprogress-plan');
  data['✅ Success'] = _updateDirectoryReadme('projects/success-plan');

  // Issues are special case
  data['🐛 Active Issues'] = _updateIssuesReadme('projects/issues');

  // 2. Update Master Dashboard
  _updateMasterDashboard(data);

  print('✅ All dashboards updated.');
}

// Returns a list of markdown rows for the master dashboard
List<String> _updateDirectoryReadme(String dirPath) {
  final directory = Directory(dirPath);
  final rows = <String>[];

  if (!directory.existsSync()) return rows;

  final projects = directory.listSync().whereType<Directory>().toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  final buffer = StringBuffer();
  buffer.writeln('# 📊 Dashboard: ${dirPath.split('/').last}\n');

  if (projects.isEmpty) {
    buffer.writeln('*No projects found in this category.*');
  } else {
    buffer.writeln('| Project Name | Progress | % | Status |');
    buffer.writeln('|---|---|---|---|');

    for (var project in projects) {
      final projectName = project.path.split(Platform.pathSeparator).last;
      final progressFile = File('${project.path}/progress.md');

      // Default values
      int percentage = 0;
      String status = 'Pending';
      String bar = '..........';

      if (progressFile.existsSync()) {
        final content = progressFile.readAsStringSync();
        final lines = content.split('\n');
        int totalTasks = 0;
        int completedTasks = 0;

        for (var line in lines) {
          final trimmed = line.trim();
          if (trimmed.startsWith('- [ ]')) totalTasks++;
          if (trimmed.startsWith('- [x]')) {
            totalTasks++;
            completedTasks++;
          }
        }

        if (totalTasks > 0) {
          percentage = (completedTasks / totalTasks * 100).toInt();
          final filled = (percentage / 10).round();
          bar = '█' * filled + '░' * (10 - filled);

          if (percentage == 100) {
            status = '✅ Ready';
          } else if (percentage > 50) {
            status = '🔥 Hot';
          } else {
            status = '🚧 Building';
          }
        }
      } else {
        if (dirPath.contains('success-plan')) {
          percentage = 100;
          bar = '██████████';
          status = '✅ Merged';
        } else if (dirPath.contains('future-plan')) {
          status = '🧊 Backlog';
        }
      }

      final row = '| **$projectName** | `$bar` | $percentage% | $status |';
      buffer.writeln(row);
      rows.add(row);
    }
  }

  buffer
      .writeln('\n_Last updated: ${DateTime.now().toString().split('.')[0]}_');
  File('$dirPath/README.md').writeAsStringSync(buffer.toString());
  return rows;
}

List<String> _updateIssuesReadme(String dirPath) {
  final directory = Directory(dirPath);
  final rows = <String>[];

  if (!directory.existsSync()) return rows;

  final files = directory
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.md') && !f.path.endsWith('README.md'))
      .toList();

  final buffer = StringBuffer();
  buffer.writeln('# 🐛 Issue Tracker\n');
  buffer.writeln('| Issue | Date | Status |');
  buffer.writeln('|---|---|---|');

  if (files.isEmpty) {
    buffer.writeln('*No active issues.*');
  } else {
    for (var file in files) {
      final name =
          file.path.split(Platform.pathSeparator).last.replaceAll('.md', '');
      String date = 'Unknown';
      String display = name;
      if (name.length > 10 && name[4] == '-' && name[7] == '-') {
        date = name.substring(0, 10);
        display = name.substring(11).replaceAll('_', ' ');
      }
      final row = '| $display | $date | 🔴 Open |';
      buffer.writeln(row);
      rows.add(row);
    }
  }

  buffer
      .writeln('\n_Last updated: ${DateTime.now().toString().split('.')[0]}_');
  File('$dirPath/README.md').writeAsStringSync(buffer.toString());
  return rows;
}

void _updateMasterDashboard(Map<String, List<String>> data) {
  final buffer = StringBuffer();
  buffer.writeln('# 🚀 Master Project Dashboard');
  buffer.writeln('**Role**: Senior Principal Flutter Engineer & Architect');
  buffer.writeln(
      '**Mission**: Build scalable, clean, and robust mobile applications.\n');

  buffer.writeln('## 📌 Workflow Overview');
  buffer.writeln('1. **Analysis** → **On Progress** → **Success**');
  buffer.writeln('2. **Issue** → **On Progress** → **Success**');
  buffer.writeln('3. **Future** → **On Progress** → **Success**\n');

  data.forEach((section, rows) {
    buffer.writeln('## $section');
    if (rows.isEmpty) {
      buffer.writeln('_No items in this stage._\n');
    } else {
      if (section.contains('Issues')) {
        buffer.writeln('| Issue | Date | Status |');
        buffer.writeln('|---|---|---|');
      } else {
        buffer.writeln('| Project Name | Progress | % | Status |');
        buffer.writeln('|---|---|---|---|');
      }
      rows.forEach(buffer.writeln);
      buffer.writeln('');
    }
  });

  buffer.writeln(
      '---\n_Generated automatically by Advanced Engineering Project Manager_');
  File('projects/README.md').writeAsStringSync(buffer.toString());
}
