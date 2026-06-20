import 'package:flutter/material.dart';

class AppFab extends StatelessWidget {
  const AppFab({Key? key}) : super(key: key);

  void _showSprintMessage(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label はSprint2以降で実装予定です')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          builder: (context) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.add),
                      title: const Text('靴を登録'),
                      onTap: () {
                        Navigator.of(context).pop();
                        _showSprintMessage(context, '靴を登録');
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.today_outlined),
                      title: const Text('今日履いた'),
                      onTap: () {
                        Navigator.of(context).pop();
                        _showSprintMessage(context, '今日履いた');
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.ios_share_outlined),
                      title: const Text('コレクション共有'),
                      onTap: () {
                        Navigator.of(context).pop();
                        _showSprintMessage(context, 'コレクション共有');
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      child: const Icon(Icons.add),
    );
  }
}
