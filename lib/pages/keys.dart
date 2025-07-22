import 'package:flutter/material.dart';

class KeysPage extends StatefulWidget {
  const KeysPage({super.key});

  @override
  State<KeysPage> createState() => _KeysPageState();
}

class _KeysPageState extends State<KeysPage> {
  final List<Map<String, String>> _keys = [
    {'name': 'MacBook Pro TouchID', 'created': '2024-11-01', 'id': '1'},
    {'name': 'iPhone FaceID', 'created': '2025-01-15', 'id': '2'},
    {'name': 'YubiKey 5 NFC', 'created': '2025-03-22', 'id': '3'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WebAuthn 密钥')),
      body: ListView.separated(
        itemCount: _keys.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final key = _keys[index];
          return ListTile(
            leading: const Icon(Icons.vpn_key),
            title: Text(key['name'] ?? ''),
            subtitle: Text('注册时间:  ${key['created']}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  tooltip: '详情',
                  onPressed: () {
                    // 仅 UI 演示，无实际功能
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('密钥详情'),
                        content: Text(
                          '名称: ${key['name']}\n注册时间: ${key['created']}',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('关闭'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: '删除',
                  onPressed: () {
                    // 仅 UI 演示，无实际删除
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('演示：未实现删除功能')));
                  },
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 仅 UI 演示，无实际添加功能
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('演示：未实现添加功能')));
        },
        tooltip: '添加密钥',
        child: const Icon(Icons.add),
      ),
    );
  }
}
