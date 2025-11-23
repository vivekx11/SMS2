// sms.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telephony/telephony.dart';
import '../main.dart'; // Import for AppState, SmsLog, telephony

class SmsSenderPage extends StatefulWidget {
  const SmsSenderPage({Key? key}) : super(key: key);
  @override
  State<SmsSenderPage> createState() => _SmsSenderPageState();
}

class _SmsSenderPageState extends State<SmsSenderPage> {
  final _to = TextEditingController();
  final _msg = TextEditingController();
  bool _sending = false;
  Future<void> _sendSms(AppState st) async {
    final to = _to.text.trim();
    final message = _msg.text.trim();
    if (to.isEmpty || message.isEmpty) return;
    setState(() => _sending = true);
    // request permissions
    final permissionsGranted = await telephony.requestPhoneAndSmsPermissions;
    if (permissionsGranted != true) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("SMS permission denied")));
      setState(() => _sending = false);
      return;
    }
    try {
      await telephony.sendSms(to: to, message: message);
      final log = SmsLog(toNumber: to, message: message, status: 'sent');
      await st.addSmsLog(log);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("SMS sent")));
      _to.clear();
      _msg.clear();
    } catch (e) {
      final log = SmsLog(toNumber: to, message: message, status: 'failed');
      await st.addSmsLog(log);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to send: $e")));
    } finally {
      setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final st = Provider.of<AppState>(context);
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          TextField(
            controller: _to,
            decoration: const InputDecoration(labelText: 'Recipient (+91...)'),
            keyboardType: TextInputType.phone,
          ),
          TextField(
            controller: _msg,
            decoration: const InputDecoration(labelText: 'Message'),
            maxLines: 4,
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _sending ? null : () => _sendSms(st),
            icon: const Icon(Icons.send),
            label: const Text('Send SMS'),
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          const Text(
            "SMS History",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: st.smsLogs.length,
              itemBuilder: (_, idx) {
                final s = st.smsLogs[idx];
                return ListTile(
                  title: Text(s.toNumber),
                  subtitle: Text(
                    "${s.message}\n${DateTime.fromMillisecondsSinceEpoch(s.sentAt)}",
                  ),
                  trailing: Text(s.status),
                  isThreeLine: true,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _to.dispose();
    _msg.dispose();
    super.dispose();
  }
}
