// repair.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:printing/printing.dart';
import '../main.dart'; // Import for AppState, RepairJob, pickImageAndSave, generateInvoicePdf

class RepairTrackingPage extends StatefulWidget {
  const RepairTrackingPage({Key? key}) : super(key: key);
  @override
  State<RepairTrackingPage> createState() => _RepairTrackingPageState();
}

class _RepairTrackingPageState extends State<RepairTrackingPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _cname = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _model = TextEditingController();
  final TextEditingController _imei = TextEditingController();
  final TextEditingController _problem = TextEditingController();
  String? _imagePath;
  @override
  Widget build(BuildContext context) {
    final st = Provider.of<AppState>(context);
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _cname,
                  decoration: const InputDecoration(labelText: 'Customer Name'),
                ),
                TextFormField(
                  controller: _phone,
                  decoration: const InputDecoration(labelText: 'Phone'),
                  keyboardType: TextInputType.phone,
                ),
                TextFormField(
                  controller: _model,
                  decoration: const InputDecoration(labelText: 'Model'),
                ),
                TextFormField(
                  controller: _imei,
                  decoration: const InputDecoration(labelText: 'IMEI'),
                ),
                TextFormField(
                  controller: _problem,
                  decoration: const InputDecoration(labelText: 'Problem'),
                ),
                const SizedBox(height: 8),
                if (_imagePath != null)
                  Image.file(File(_imagePath!), height: 120),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        final p = await pickImageAndSave();
                        if (p != null) setState(() => _imagePath = p);
                      },
                      icon: const Icon(Icons.camera_alt),
                      label: const Text("Add Photo"),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () async {
                        if (_cname.text.trim().isEmpty ||
                            _phone.text.trim().isEmpty)
                          return;
                        final job = RepairJob(
                          customerName: _cname.text.trim(),
                          phone: _phone.text.trim(),
                          model: _model.text.trim(),
                          imei: _imei.text.trim(),
                          problem: _problem.text.trim(),
                          imagePath: _imagePath,
                        );
                        await st.addRepair(job);
                        _cname.clear();
                        _phone.clear();
                        _model.clear();
                        _imei.clear();
                        _problem.clear();
                        setState(() => _imagePath = null);
                      },
                      icon: const Icon(Icons.save),
                      label: const Text("Save Repair"),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: st.repairs.length,
              itemBuilder: (_, idx) {
                final r = st.repairs[idx];
                return Card(
                  child: ListTile(
                    leading: r.imagePath != null
                        ? Image.file(
                            File(r.imagePath!),
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                          )
                        : const Icon(Icons.phone_android),
                    title: Text("${r.customerName} • ${r.model}"),
                    subtitle: Text("${r.problem}\nStatus: ${r.status}"),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) async {
                        if (v == 'Complete') {
                          r.status = 'Completed';
                          await st.db.db.update(
                            'repairs',
                            r.toMap(),
                            where: 'id=?',
                            whereArgs: [r.id],
                          );
                          st.repairs = await st.db.getRepairs();
                          st.notifyListeners();
                        } else if (v == 'Invoice') {
                          final cust = Customer(
                            name: r.customerName,
                            phone: r.phone,
                          );
                          final bytes = await generateInvoicePdf(r, cust);
                          await Printing.layoutPdf(onLayout: (_) => bytes);
                        } else if (v == 'Call') {
                          final uri = Uri.parse('tel:${r.phone}');
                          if (await canLaunchUrl(uri)) await launchUrl(uri);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'Complete',
                          child: Text('Mark Complete'),
                        ),
                        PopupMenuItem(
                          value: 'Invoice',
                          child: Text('Generate Invoice'),
                        ),
                        PopupMenuItem(
                          value: 'Call',
                          child: Text('Call Customer'),
                        ),
                      ],
                    ),
                  ),
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
    _cname.dispose();
    _phone.dispose();
    _model.dispose();
    _imei.dispose();
    _problem.dispose();
    super.dispose();
  }
}
