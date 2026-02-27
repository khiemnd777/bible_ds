class DailyScheduler {
  const DailyScheduler();

  String todayKey() {
    final now = DateTime.now();
    return _dateKey(now);
  }

  String assignSceneIdForDate(List<String> sceneIds, DateTime date) {
    if (sceneIds.isEmpty) return '';
    final seed = int.parse(_dateKey(date).replaceAll('-', ''));
    final index = seed % sceneIds.length;
    return sceneIds[index];
  }

  String _dateKey(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final yyyy = normalized.year.toString().padLeft(4, '0');
    final mm = normalized.month.toString().padLeft(2, '0');
    final dd = normalized.day.toString().padLeft(2, '0');
    return '$yyyy-$mm-$dd';
  }
}
