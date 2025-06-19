import 'package:flutter/material.dart';
import 'log_service.dart';

// log_page.dart
// 日志模块页面，展示全局异常日志
class LogPage extends StatelessWidget {
  const LogPage({super.key});

  @override
  Widget build(BuildContext context) {
    final logs = LogService.errors.reversed.toList(); // 获取所有异常日志，倒序显示
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