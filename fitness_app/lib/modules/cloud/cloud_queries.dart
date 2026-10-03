import '../../data/database.dart';

/// Dotazy modulu „cloud“ (automatická záloha).
extension CloudQueries on AppDatabase {
  /// Počet tréninků (stejně jako BackupService – všechny řádky).
  Future<int> cloudWorkoutCount() async {
    final row = await customSelect(
      'SELECT COUNT(*) AS c FROM "${workoutSessions.actualTableName}"',
      readsFrom: {workoutSessions},
    ).getSingle();
    return row.read<int>('c');
  }
}
