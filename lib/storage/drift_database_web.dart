import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

QueryExecutor openDicomDatabaseExecutor() {
  return DatabaseConnection.delayed(
    Future(() async {
      final result = await WasmDatabase.open(
        databaseName: 'dicom_viewer_db',
        sqlite3Uri: Uri.parse('sqlite3.wasm'),
        driftWorkerUri: Uri.parse('drift_worker.js'),
      );
      return result.resolvedExecutor;
    }),
  );
}
