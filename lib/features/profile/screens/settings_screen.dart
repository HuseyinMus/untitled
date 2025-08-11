import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  ThemeMode _mode = ThemeMode.system;
  TimeOfDay? _notificationTime;
  String _language = 'TR';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListView(
        children: [
          const ListTile(title: Text('Tema')),
          RadioListTile<ThemeMode>(
            value: ThemeMode.light,
            groupValue: _mode,
            onChanged: (v) => setState(() => _mode = v!),
            title: const Text('Açık'),
          ),
          RadioListTile<ThemeMode>(
            value: ThemeMode.dark,
            groupValue: _mode,
            onChanged: (v) => setState(() => _mode = v!),
            title: const Text('Koyu'),
          ),
          RadioListTile<ThemeMode>(
            value: ThemeMode.system,
            groupValue: _mode,
            onChanged: (v) => setState(() => _mode = v!),
            title: const Text('Sistem'),
          ),
          const Divider(),
          ListTile(
            title: const Text('Dil'),
            trailing: DropdownButton<String>(
              value: _language,
              items: const [DropdownMenuItem(value: 'TR', child: Text('Türkçe')), DropdownMenuItem(value: 'EN', child: Text('English'))],
              onChanged: (v) => setState(() => _language = v ?? 'TR'),
            ),
          ),
          const Divider(),
          ListTile(
            title: const Text('Bildirim Saati'),
            subtitle: Text(_notificationTime == null ? 'Seçili değil' : _notificationTime!.format(context)),
            trailing: IconButton(
              icon: const Icon(Icons.schedule),
              onPressed: () async {
                final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                if (time != null) setState(() => _notificationTime = time);
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_forever_outlined),
            title: const Text('Hesabı Sil'),
            onTap: () => _confirm(context, 'Hesabı silmek istediğinize emin misiniz?'),
          ),
        ],
      ),
    );
  }

  void _confirm(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Onay'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Evet')),
        ],
      ),
    );
  }
}


