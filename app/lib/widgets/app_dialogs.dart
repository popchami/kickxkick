import 'package:flutter/material.dart';

Future<void> showAppMessage(
  BuildContext context, {
  required String title,
  String? message,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: message == null ? null : Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('閉じる')),
      ],
    ),
  );
}
