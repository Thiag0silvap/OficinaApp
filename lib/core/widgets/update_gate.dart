import 'package:flutter/material.dart';

import '../../services/update_service.dart';
import '../constants/app_version.dart';

class UpdateGate extends StatefulWidget {
  const UpdateGate({super.key, required this.child});

  final Widget child;

  @override
  State<UpdateGate> createState() => _UpdateGateState();
}

class _UpdateGateState extends State<UpdateGate> {
  bool _checked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_checked) return;
    _checked = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final info = await UpdateService.checkForUpdate();
      if (!mounted || info == null) return;

      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Atualização disponível'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Versão instalada: ${AppVersion.current}'),
                Text('Nova versão: ${info.latestVersion}'),
                if ((info.notes ?? '').isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(info.notes!),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Agora não'),
              ),
              FilledButton(
                onPressed: () async {
                  await UpdateService.openDownloadUrl(info.downloadUrl);
                  if (context.mounted) Navigator.of(context).pop();
                },
                child: const Text('Baixar atualização'),
              ),
            ],
          );
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
