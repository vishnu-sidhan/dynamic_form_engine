import 'form_enums.dart';

/// Transactional outbox mutation record for offline-first replication.
class OutboxMutation {
  final String id;
  final String entityType;
  final String entityId;
  final SyncOperationType operation;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final DateTime? syncedAt;

  const OutboxMutation({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.payload,
    required this.createdAt,
    this.syncedAt,
  });

  bool get isSynced => syncedAt != null;

  OutboxMutation copyWith({
    String? id,
    String? entityType,
    String? entityId,
    SyncOperationType? operation,
    Map<String, dynamic>? payload,
    DateTime? createdAt,
    DateTime? syncedAt,
  }) {
    return OutboxMutation(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      operation: operation ?? this.operation,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'entityType': entityType,
      'entityId': entityId,
      'operation': operation.name,
      'payload': payload,
      'createdAt': createdAt.toIso8601String(),
      'syncedAt': syncedAt?.toIso8601String(),
    };
  }

  factory OutboxMutation.fromMap(Map<String, dynamic> map) {
    SyncOperationType op = SyncOperationType.insert;
    final opStr = map['operation']?.toString().toLowerCase();
    if (opStr == 'update') op = SyncOperationType.update;
    if (opStr == 'delete') op = SyncOperationType.delete;

    DateTime created = DateTime.now();
    if (map['createdAt'] != null) {
      if (map['createdAt'] is DateTime) {
        created = map['createdAt'] as DateTime;
      } else {
        created = DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now();
      }
    }

    DateTime? synced;
    if (map['syncedAt'] != null) {
      if (map['syncedAt'] is DateTime) {
        synced = map['syncedAt'] as DateTime;
      } else {
        synced = DateTime.tryParse(map['syncedAt'].toString());
      }
    }

    return OutboxMutation(
      id: map['id']?.toString() ?? '',
      entityType: map['entityType']?.toString() ?? '',
      entityId: map['entityId']?.toString() ?? '',
      operation: op,
      payload: map['payload'] is Map
          ? Map<String, dynamic>.from(map['payload'] as Map)
          : const {},
      createdAt: created,
      syncedAt: synced,
    );
  }
}
