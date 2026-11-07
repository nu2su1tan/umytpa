import 'package:flutter/material.dart';

import '../../features/tasks/domain/entities/task_category.dart';
import 'app_colors.dart';

/// Category accent colors used by chips, dots, and labels.
abstract final class CategoryColors {
  static const Color study = AppColors.study;
  static const Color work = AppColors.work;
  static const Color personal = AppColors.personal;
  static const Color other = AppColors.other;

  static Color of(TaskCategory category) {
    return switch (category) {
      TaskCategory.study => study,
      TaskCategory.work => work,
      TaskCategory.personal => personal,
      TaskCategory.other => other,
    };
  }

  static Color byName(String name) {
    return switch (name) {
      'study' => study,
      'work' => work,
      'personal' => personal,
      'other' => other,
      _ => other,
    };
  }
}
