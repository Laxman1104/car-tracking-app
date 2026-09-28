import 'package:drift/drift.dart';

import '../database/app_database.dart';

class AttachmentRepository {
  AttachmentRepository(this._database);

  final AppDatabase _database;

  Future<int> create(AttachmentsCompanion attachment) {
    return _database.into(_database.attachments).insert(attachment);
  }

  Future<Attachment?> findById(int id) {
    return (_database.select(
      _database.attachments,
    )..where((attachment) => attachment.id.equals(id))).getSingleOrNull();
  }

  Future<List<Attachment>> findForRecord(int recordId) {
    return (_database.select(_database.attachments)
          ..where(
            (attachment) => attachment.maintenanceRecordId.equals(recordId),
          )
          ..orderBy([
            (attachment) => OrderingTerm.asc(attachment.position),
            (attachment) => OrderingTerm.asc(attachment.id),
          ]))
        .get();
  }

  Future<bool> update(Attachment attachment) {
    return _database.update(_database.attachments).replace(attachment);
  }

  Future<int> deleteById(int id) {
    return (_database.delete(
      _database.attachments,
    )..where((attachment) => attachment.id.equals(id))).go();
  }
}
