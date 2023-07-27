import 'package:flutter/material.dart';

class SwitchRowWidget extends StatelessWidget {
  final bool value;
  final String text;
  final ValueChanged<bool?> onChanged;

  SwitchRowWidget({
    required this.value,
    required this.text,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(text, style: const TextStyle(fontSize: 16, color: Colors.white)),
        Checkbox(
          value: value,
          onChanged: onChanged,
          activeColor: const Color.fromARGB(255, 106, 200, 255),
        ),
      ],
    );
  }
}
