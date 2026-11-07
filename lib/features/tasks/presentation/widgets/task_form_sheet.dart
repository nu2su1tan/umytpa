import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/category_colors.dart';
import '../../../../core/ui/glass/glass.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../../reminders/domain/reminder_permission_status.dart';
import '../../../reminders/domain/reminder_scheduler.dart';
import '../../domain/entities/reminder_preset.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_category.dart';
import '../../domain/usecases/create_task.dart';
import '../../domain/usecases/delete_task.dart';
import '../../domain/usecases/update_task.dart';
import '../cubit/task_form_cubit.dart';
import '../cubit/task_form_result.dart';
import '../cubit/task_form_state.dart';

abstract final class TaskFormSheet {
  static Future<TaskFormResult?> show(
    BuildContext context, {
    Task? task,
    ReminderPreset defaultReminder = ReminderPreset.defaultPreset,
  }) {
    return showModalBottomSheet<TaskFormResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (BuildContext context) {
        return BlocProvider<TaskFormCubit>(
          create: (_) => TaskFormCubit(
            createTask: getIt<CreateTask>(),
            updateTask: getIt<UpdateTask>(),
            deleteTask: getIt<DeleteTask>(),
            reminderScheduler: getIt<ReminderScheduler>(),
            initialTask: task,
            defaultReminder: defaultReminder,
          ),
          child: const _TaskFormSheetBody(),
        );
      },
    );
  }
}

class _TaskFormSheetBody extends StatefulWidget {
  const _TaskFormSheetBody();

  @override
  State<_TaskFormSheetBody> createState() => _TaskFormSheetBodyState();
}

class _TaskFormSheetBodyState extends State<_TaskFormSheetBody> {
  late final TextEditingController _titleController;
  late final FocusNode _titleFocus;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _titleFocus = FocusNode();
    final TaskFormState state = context.read<TaskFormCubit>().state;
    if (state is TaskFormReady) {
      _titleController.text = state.title;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _titleFocus.dispose();
    super.dispose();
  }

  Future<bool> _confirmDiscardIfNeeded(TaskFormReady state) async {
    if (!state.isDirty) {
      return true;
    }
    final bool? discard = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Discard',
      barrierColor: Colors.black.withValues(alpha: 0.35),
      transitionDuration: const Duration(milliseconds: 250),
      transitionBuilder: (
        BuildContext context,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
        Widget child,
      ) {
        final double curvedValue =
            Curves.easeOutBack.transform(animation.value);
        return Transform.scale(
          scale: curvedValue,
          child: Opacity(
            opacity: animation.value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      pageBuilder: (
        BuildContext context,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
      ) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: AppGlass(
                radius: 24,
                child: Material(
                  color: Colors.transparent,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Text(
                          'Discard changes?',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'You have unsaved changes.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: Text(
                                'Keep editing',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Discard'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    return discard ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return BlocConsumer<TaskFormCubit, TaskFormState>(
      listenWhen: (TaskFormState previous, TaskFormState current) {
        return current is TaskFormEffect ||
            (current is TaskFormReady &&
                previous is TaskFormLoading &&
                _titleController.text != current.title) ||
            (previous is TaskFormReady &&
                current is TaskFormReady &&
                previous.pendingRationale != current.pendingRationale &&
                current.pendingRationale != null);
      },
      listener: (BuildContext context, TaskFormState state) {
        switch (state) {
          case TaskFormReady(:final title, :final pendingRationale)
              when pendingRationale != null:
            if (_titleController.text != title) {
              _titleController.value = TextEditingValue(
                text: title,
                selection: TextSelection.collapsed(offset: title.length),
              );
            }
            _showPermissionRationaleDialog(context, pendingRationale);
          case TaskFormReady(:final title)
              when _titleController.text != title:
            _titleController.value = TextEditingValue(
              text: title,
              selection: TextSelection.collapsed(offset: title.length),
            );
          case TaskFormSaveSuccess():
            Navigator.of(context).pop(const TaskFormSaved());
          case TaskFormDeleteSuccess(:final task):
            Navigator.of(context).pop(TaskFormDeleted(task));
          default:
            break;
        }
      },
      builder: (BuildContext context, TaskFormState state) {
        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: AppGlass(
              radius: 28,
              child: Material(
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    // Drag handle
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 10, bottom: 6),
                        width: 36,
                        height: 5,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      ),
                    ),
                    Flexible(
                      child: switch (state) {
                        TaskFormLoading() ||
                        TaskFormSaveSuccess() ||
                        TaskFormDeleteSuccess() =>
                          const SizedBox(
                            height: 240,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        TaskFormLoadFailure(:final message) => Padding(
                            padding: const EdgeInsets.all(AppTheme.screenPadding),
                            child: Text(message),
                          ),
                        TaskFormReady() => PopScope(
                            canPop: !state.isDirty,
                            onPopInvokedWithResult:
                                (bool didPop, Object? result) async {
                              if (didPop) {
                                return;
                              }
                              final bool discard =
                                  await _confirmDiscardIfNeeded(state);
                              if (discard && context.mounted) {
                                Navigator.of(context).pop();
                              }
                            },
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(
                                AppTheme.screenPadding,
                                8,
                                AppTheme.screenPadding,
                                24,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: <Widget>[
                                  // Title field on solid light fill
                                  Container(
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.surface,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: theme.dividerColor,
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 4,
                                    ),
                                    child: TextField(
                                      controller: _titleController,
                                      focusNode: _titleFocus,
                                      autofocus: !state.isEdit,
                                      maxLength: 120,
                                      style: theme.textTheme.headlineLarge
                                          ?.copyWith(
                                        fontSize: 22,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'What needs to be done?',
                                        counterText: '',
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        errorText: state.validation.titleError,
                                      ),
                                      textInputAction: TextInputAction.done,
                                      onChanged: context
                                          .read<TaskFormCubit>()
                                          .titleChanged,
                                    ),
                                  ),
                                  if (state.validation.dueAtError != null) ...<Widget>[
                                    const SizedBox(height: 8),
                                    Text(
                                      state.validation.dueAtError!,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.error,
                                      ),
                                    ),
                                  ],
                                  if (state.validation.reminderWarning !=
                                      null) ...<Widget>[
                                    const SizedBox(height: 8),
                                    Text(
                                      state.validation.reminderWarning!,
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: theme.brightness ==
                                                Brightness.dark
                                            ? AppColors.darkPrimary
                                            : AppColors.lightOrangeText,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                  if (state.showPermissionHelp) ...<Widget>[
                                    const SizedBox(height: 12),
                                    _PermissionHelpBanner(
                                      onOpenSettings: () {
                                        context
                                            .read<TaskFormCubit>()
                                            .openSystemSettings();
                                      },
                                    ),
                                  ],
                                  if (state.submitError != null) ...<Widget>[
                                    const SizedBox(height: 8),
                                    Text(
                                      state.submitError!,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.error,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 20),
                                  _CategoryChips(
                                    selected: state.category,
                                    onSelected: context
                                        .read<TaskFormCubit>()
                                        .categoryChanged,
                                  ),
                                  const SizedBox(height: 16),
                                  _DateTimeRow(
                                    dueAt: state.dueAt,
                                    onPickDate: () => _pickDate(context, state),
                                    onPickTime: () => _pickTime(context, state),
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    children: <Widget>[
                                      Icon(
                                        Icons.notifications_none_rounded,
                                        size: 18,
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Remind me',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  _ReminderChips(
                                    selected: state.reminder,
                                    onSelected: (ReminderPreset preset) {
                                      context
                                          .read<TaskFormCubit>()
                                          .reminderChanged(preset);
                                    },
                                  ),
                                  const SizedBox(height: 24),
                                  FilledButton(
                                    onPressed: state.canSave
                                        ? () => context
                                            .read<TaskFormCubit>()
                                            .save()
                                        : null,
                                    child: Text(
                                      state.isEdit ? 'Save changes' : 'Save',
                                    ),
                                  ),
                                  if (state.isEdit) ...<Widget>[
                                    const SizedBox(height: 8),
                                    TextButton(
                                      onPressed: state.isSubmitting
                                          ? null
                                          : () => context
                                              .read<TaskFormCubit>()
                                              .delete(),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showPermissionRationaleDialog(
    BuildContext context,
    ReminderPermissionRationale rationale,
  ) async {
    final String title;
    final String message;
    switch (rationale) {
      case ReminderPermissionRationale.exactAlarms:
        title = 'Exact alarms permission';
        message =
            'Umytpa needs permission to schedule exact alarms so your reminders ring right on time. Tap Continue to open settings.';
      case ReminderPermissionRationale.fullScreenIntent:
        title = 'Full-screen reminder permission';
        message =
            'Umytpa can display reminders over locked screens like an alarm clock. Tap Continue to enable full-screen alerts in settings.';
    }

    final bool? proceed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (!context.mounted) {
      return;
    }
    final TaskFormCubit cubit = context.read<TaskFormCubit>();
    if (proceed == true) {
      await cubit.confirmPermissionRationale(rationale);
    } else {
      cubit.dismissPermissionRationale();
    }
  }

  Future<void> _pickDate(BuildContext context, TaskFormReady state) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: state.dueAt,
      firstDate: state.isEdit
          ? DateTime(now.year - 1)
          : DateTimeUtils.startOfDay(now),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null && context.mounted) {
      context.read<TaskFormCubit>().dueDateChanged(picked);
    }
  }

  Future<void> _pickTime(BuildContext context, TaskFormReady state) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: state.dueAt.hour,
        minute: state.dueAt.minute,
      ),
    );
    if (picked != null && context.mounted) {
      context.read<TaskFormCubit>().dueTimeChanged(
            TimeOfDayLike(hour: picked.hour, minute: picked.minute),
          );
    }
  }
}

class _PermissionHelpBanner extends StatelessWidget {
  const _PermissionHelpBanner({required this.onOpenSettings});

  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Notifications are off. The task can still be saved, but reminders will not fire.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onOpenSettings,
                child: Text(
                  'Open settings',
                  style: TextStyle(color: theme.colorScheme.primary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.selected,
    required this.onSelected,
  });

  final TaskCategory selected;
  final ValueChanged<TaskCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: <Widget>[
          for (final TaskCategory category in TaskCategory.values) ...<Widget>[
            _SelectableChip(
              label: category.label,
              selected: selected == category,
              color: CategoryColors.of(category),
              showDot: true,
              onTap: () => onSelected(category),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _ReminderChips extends StatelessWidget {
  const _ReminderChips({
    required this.selected,
    required this.onSelected,
  });

  final ReminderPreset selected;
  final ValueChanged<ReminderPreset> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (final ReminderPreset preset in ReminderPreset.values)
          _SelectableChip(
            label: preset.label,
            selected: selected == preset,
            onTap: () => onSelected(preset),
          ),
      ],
    );
  }
}

class _DateTimeRow extends StatelessWidget {
  const _DateTimeRow({
    required this.dueAt,
    required this.onPickDate,
    required this.onPickTime,
  });

  final DateTime dueAt;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _PillButton(
            icon: Icons.calendar_today_outlined,
            label: _dateLabel(dueAt),
            onTap: onPickDate,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _PillButton(
            icon: Icons.schedule,
            label: DateFormat.Hm().format(dueAt),
            onTap: onPickTime,
          ),
        ),
      ],
    );
  }

  String _dateLabel(DateTime dueAt) {
    final DateTime now = DateTime.now();
    if (DateTimeUtils.isSameCalendarDay(dueAt, now)) {
      return 'Today';
    }
    if (DateTimeUtils.isSameCalendarDay(
      dueAt,
      DateTimeUtils.startOfTomorrow(now),
    )) {
      return 'Tomorrow';
    }
    return DateFormat('d MMM').format(dueAt);
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      shape: StadiumBorder(side: BorderSide(color: theme.dividerColor)),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: <Widget>[
                Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    style: theme.textTheme.titleMedium?.copyWith(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectableChip extends StatelessWidget {
  const _SelectableChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
    this.showDot = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color border = selected
        ? (color ?? theme.colorScheme.primary)
        : theme.dividerColor;

    return Material(
      color: theme.colorScheme.surface,
      shape: StadiumBorder(
        side: BorderSide(
          color: border,
          width: selected ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 40, minWidth: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (showDot && color != null) ...<Widget>[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
