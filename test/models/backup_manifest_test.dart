import 'package:flutter_test/flutter_test.dart';
import 'package:oficina_app/models/backup_manifest.dart';

void main() {
  test('BackupManifest serializa e desserializa preservando os campos', () {
    const manifest = BackupManifest(
      id: 'backup_1',
      dbPath: 'C:/dados/backup_1.db',
      manifestPath: 'C:/dados/backup_1.json',
      fileName: 'backup_1.db',
      createdAtIso: '2026-03-26T12:00:00.000',
      userId: 'user_123',
      appVersion: '1.0.3+10',
      schemaVersion: 2,
      fileSizeBytes: 4096,
    );

    final restored = BackupManifest.fromMap(manifest.toMap());

    expect(restored.id, manifest.id);
    expect(restored.dbPath, manifest.dbPath);
    expect(restored.manifestPath, manifest.manifestPath);
    expect(restored.fileName, manifest.fileName);
    expect(restored.createdAtIso, manifest.createdAtIso);
    expect(restored.userId, manifest.userId);
    expect(restored.appVersion, manifest.appVersion);
    expect(restored.schemaVersion, manifest.schemaVersion);
    expect(restored.fileSizeBytes, manifest.fileSizeBytes);
  });
}
