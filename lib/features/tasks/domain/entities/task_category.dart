enum TaskCategory {
  study,
  work,
  personal,
  other;

  String get label => switch (this) {
        TaskCategory.study => 'Study',
        TaskCategory.work => 'Work',
        TaskCategory.personal => 'Personal',
        TaskCategory.other => 'Other',
      };
}
