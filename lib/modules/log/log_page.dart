import 'package:flutter/material.dart';
import 'log_service.dart';

class LogPage extends StatelessWidget {
  const LogPage({super.key});

  @override
  Widget build(BuildContext context) {
    final logs = LogService.errors.reversed.toList();
    return Scaffold(
      appBar: AppBar(title: const Text('日志')), 
      body: logs.isEmpty
          ? const Center(child: Text('暂无错误日志'))
          : ListView.builder(
              itemCount: logs.length,
              itemBuilder: (context, index) => ListTile(
                title: Text(logs[index], style: const TextStyle(fontSize: 13)),
              ),
            ),
    );
  }
} 