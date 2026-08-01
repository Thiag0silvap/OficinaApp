enum AttachmentType { image, signature, other }

class Attachment {
  final String id;
  final String filename;
  final String path;
  final AttachmentType type;
  final DateTime createdAt;
  final String? mime;
  final String? note;
  final String? parentId;
  final String? parentType;

  Attachment({
    required this.id,
    required this.filename,
    required this.path,
    required this.type,
    DateTime? createdAt,
    this.mime,
    this.note,
    this.parentId,
    this.parentType,
  }) : createdAt = createdAt ?? DateTime.now();

  Attachment copyWith({
    String? id,
    String? filename,
    String? path,
    AttachmentType? type,
    DateTime? createdAt,
    String? mime,
    String? note,
    String? parentId,
    String? parentType,
  }) {
    return Attachment(
      id: id ?? this.id,
      filename: filename ?? this.filename,
      path: path ?? this.path,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      mime: mime ?? this.mime,
      note: note ?? this.note,
      parentId: parentId ?? this.parentId,
      parentType: parentType ?? this.parentType,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'filename': filename,
      'path': path,
      'type': type.name,
      'createdAt': createdAt.toIso8601String(),
      'mime': mime,
      'note': note,
      'parentId': parentId,
      'parentType': parentType,
    };
  }

  factory Attachment.fromMap(Map<String, dynamic> map) {
    return Attachment(
      id: map['id'] as String,
      filename: map['filename'] as String,
      path: map['path'] as String,
      type: AttachmentType.values.firstWhere(
        (e) => e.name == (map['type'] ?? 'other'),
        orElse: () => AttachmentType.other,
      ),
      createdAt: DateTime.parse(map['createdAt'] as String),
      mime: map['mime'] as String?,
      note: map['note'] as String?,
      parentId: map['parentId'] as String?,
      parentType: map['parentType'] as String?,
    );
  }
}
