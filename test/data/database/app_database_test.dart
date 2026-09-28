import 'package:car_tracking_app/data/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('opens, queries, and closes an in-memory SQLite database', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());

    final result = await database.customSelect('SELECT 1 AS value').getSingle();

    expect(result.read<int>('value'), 1);
    await database.close();
  });
}
