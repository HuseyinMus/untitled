import 'package:flutter/material.dart';

class AvatarPicker extends StatelessWidget {
  const AvatarPicker({super.key});

  static const List<String> _emojis = [
    '😀','😎','🧠','📚','🎓','🚀','🧩','💡','📝','🔤','🗣️','🎯','🌟','🧭','🧪','🧬'
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Avatar seç', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _emojis.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemBuilder: (_, i) {
                final emoji = _emojis[i];
                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => Navigator.pop(context, emoji),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Theme.of(context).colorScheme.secondaryContainer,
                    ),
                    child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}


