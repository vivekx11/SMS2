// ps.dart
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PasswordStorePage extends StatefulWidget {
  const PasswordStorePage({Key? key}) : super(key: key);
  @override
  State<PasswordStorePage> createState() => _PasswordStorePageState();
}

class _PasswordStorePageState extends State<PasswordStorePage> {
  final _keyCtrl = TextEditingController();
  final _valueCtrl = TextEditingController();
  final secureStorage = FlutterSecureStorage();
  List<MapEntry<String, String>> entries = [];
  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final all = await secureStorage.readAll();
    setState(
      () => entries = all.entries
          .map((e) => MapEntry(e.key, e.value ?? ''))
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Password Store')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: _keyCtrl,
              decoration: const InputDecoration(
                labelText: 'Label (eg: Google account)',
              ),
            ),
            TextField(
              controller: _valueCtrl,
              decoration: const InputDecoration(labelText: 'Password / PIN'),
              obscureText: true,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                if (_keyCtrl.text.trim().isEmpty ||
                    _valueCtrl.text.trim().isEmpty)
                  return;
                await secureStorage.write(
                  key: _keyCtrl.text.trim(),
                  value: _valueCtrl.text.trim(),
                );
                _keyCtrl.clear();
                _valueCtrl.clear();
                await _loadAll();
              },
              child: const Text('Save'),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: entries.length,
                itemBuilder: (_, idx) {
                  final e = entries[idx];
                  return ListTile(
                    title: Text(e.key),
                    subtitle: Text(e.value),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () async {
                        await secureStorage.delete(key: e.key);
                        await _loadAll();
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _keyCtrl.dispose();
    _valueCtrl.dispose();
    super.dispose();
  }
}
