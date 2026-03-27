class BackupManifest {
  const BackupManifest({
    required this.id,
    required this.dbPath,
    required this.manifestPath,
    required this.fileName,
    required this.createdAtIso,
    required this.userId,
    required this.appVersion,
    required this.schemaVersion,
    required this.fileSizeBytes,
  });

  final String id;
  final String dbPath;
  final String manifestPath;
  final String fileName;
  final String createdAtIso;
  final String userId;
  final String appVersion;
  final int schemaVersion;
  final int fileSizeBytes;

  DateTime get createdAt => DateTime.tryParse(createdAtIso) ?? DateTime(1970);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dbPath': dbPath,
      'manifestPath': manifestPath,
      'fileName': fileName,
      'createdAtIso': createdAtIso,
      'userId': userId,
      'appVersion': appVersion,
      'schemaVersion': schemaVersion,
      'fileSizeBytes': fileSizeBytes,
    };
  }

  factory BackupManifest.fromMap(Map<String, dynamic> map) {
    return BackupManifest(
      id: map['id']?.toString() ?? '',
      dbPath: map['dbPath']?.toString() ?? '',
      manifestPath: map['manifestPath']?.toString() ?? '',
      fileName: map['fileName']?.toString() ?? '',
      createdAtIso: map['createdAtIso']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
      appVersion: map['appVersion']?.toString() ?? '',
      schemaVersion: int.tryParse(map['schemaVersion']?.toString() ?? '') ?? 1,
      fileSizeBytes: int.tryParse(map['fileSizeBytes']?.toString() ?? '') ?? 0,
    );
  }
}
