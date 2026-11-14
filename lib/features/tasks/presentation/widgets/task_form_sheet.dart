import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/time_format.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/category_colors.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../../reminders/domain/reminder_permission_status.dart';
import '../../../week_counter/ui/kit/pressable.dart';
import '../../../week_counter/ui/theme/tokens.dart';
import '../../../reminders/domain/reminder_scheduler.dart';
import '../../data/task_defaults.dart';
import '../../domain/entities/reminder_preset.dart';
import '../../domain/entities/repeat_rule.dart';
import '../../domain/entities/subtask.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_category.dart';
import '../../domain/usecases/parse_smart_input.dart';
import '../../domain/usecases/create_task.dart';
import '../../domain/usecases/delete_task.dart';
import '../../domain/usecases/update_task.dart';
import '../cubit/task_form_cubit.dart';
import '../cubit/task_form_result.dart';
import '../cubit/task_form_state.dart';
import '../../../../l10n/app_localizations.dart';
import '../utils/task_l10n.dart';
import 'custom_reminder_dialog.dart';

abstract final class TaskFormSheet {
  static Future<TaskFormResult?> show(
    BuildContext context, {
    Task? task,
    ReminderPreset defaultReminder = ReminderPreset.defaultPreset,
    String? initialTitle,
  }) async {
    // A new task starts with what was picked last time.
    final TaskDefaults defaults = task == null
        ? await TaskDefaults.load()
        : const TaskDefaults();
    if (!context.mounted) {
      return null;
    }
    final bool remembered = task == null;
    return showModalBottomSheet<TaskFormResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: context.tokens.scrim,
      elevation: 0,
      builder: (BuildContext context) {
        return BlocProvider<TaskFormCubit>(
          create: (_) => TaskFormCubit(
            createTask: getIt<CreateTask>(),
            updateTask: getIt<UpdateTask>(),
            deleteTask: getIt<DeleteTask>(),
            reminderScheduler: getIt<ReminderScheduler>(),
            initialTask: task,
            defaultReminder: remembered ? defaults.reminder : defaultReminder,
            defaultCustomBefore: defaults.customBefore,
            defaultCategory: defaults.category,
          )..prefill(initialTitle),
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
      barrierLabel: context.l10n.discard,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      transitionDuration: const Duration(milliseconds: 250),
      transitionBuilder:
          (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) {
            final double curvedValue = Curves.easeOutBack.transform(
              animation.value,
            );
            return Transform.scale(
              scale: curvedValue,
              child: Opacity(
                opacity: animation.value.clamp(0.0, 1.0),
                child: child,
              ),
            );
          },
      pageBuilder:
          (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 340),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: context.tokens.sheet,
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Text(
                              context.l10n.discardTitle,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              context.l10n.discardBody,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: <Widget>[
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: Text(
                                    context.l10n.keepEditing,
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  style: TextButton.styleFrom(
                                    foregroundColor: context.tokens.danger,
                                  ),
                                  child: Text(context.l10n.discard),
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
    final Tokens t = context.tokens;
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
          case TaskFormReady(:final title) when _titleController.text != title:
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
          padding: EdgeInsets.fromLTRB(8, 0, 8, 8 + bottomInset),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: t.sheet,
              borderRadius: BorderRadius.circular(38),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x1F000000),
                  blurRadius: 40,
                  offset: Offset(0, -10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(38),
              child: Material(
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    // Drag handle
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 6, bottom: 6),
                        width: 36,
                        height: 5,
                        decoration: BoxDecoration(
                          color: t.surface3,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    Flexible(
                      child: switch (state) {
                        TaskFormLoading() ||
                        TaskFormSaveSuccess() ||
                        TaskFormDeleteSuccess() => const SizedBox(
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
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Flexible(
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.fromLTRB(
                                    AppTheme.screenPadding,
                                    8,
                                    AppTheme.screenPadding,
                                    8,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: <Widget>[
                                      // Title field on solid light fill
                                      Container(
                                        decoration: BoxDecoration(
                                          color: t.sheetCard,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 4,
                                        ),
                                        child: TextField(
                                          controller: _titleController,
                                          focusNode: _titleFocus,

                                          maxLength: 120,
                                          style: t.sectionTitle,
                                          decoration: InputDecoration(
                                            hintText: state.isEdit
                                                ? context.l10n.taskHint
                                                : context.l10n.smartHint,
                                            counterText: '',
                                            border: InputBorder.none,
                                            enabledBorder: InputBorder.none,
                                            focusedBorder: InputBorder.none,
                                            errorText:
                                                state.validation.titleError ==
                                                        null ||
                                                    !state.isDirty
                                                ? null
                                                : context.l10n.domainMessage(
                                                    state
                                                        .validation
                                                        .titleError!,
                                                  ),
                                          ),
                                          textInputAction: TextInputAction.done,
                                          onChanged: context
                                              .read<TaskFormCubit>()
                                              .titleChanged,
                                        ),
                                      ),
                                      if (state.smart != null) ...<Widget>[
                                        const SizedBox(height: 8),
                                        _SmartSuggestion(
                                          smart: state.smart!,
                                          onApply: () {
                                            final TaskFormCubit cubit =
                                                context.read<TaskFormCubit>()
                                                  ..applySmartInput();
                                            final TaskFormState next =
                                                cubit.state;
                                            if (next is TaskFormReady) {
                                              _titleController
                                                  .value = TextEditingValue(
                                                text: next.title,
                                                selection:
                                                    TextSelection.collapsed(
                                                      offset: next.title.length,
                                                    ),
                                              );
                                            }
                                          },
                                        ),
                                      ],
                                      if (state.validation.dueAtError !=
                                          null) ...<Widget>[
                                        const SizedBox(height: 8),
                                        Text(
                                          context.l10n.domainMessage(
                                            state.validation.dueAtError!,
                                          ),
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: theme.colorScheme.error,
                                              ),
                                        ),
                                      ],
                                      if (state.validation.reminderWarning !=
                                          null) ...<Widget>[
                                        const SizedBox(height: 8),
                                        Text(
                                          context.l10n.domainMessage(
                                            state.validation.reminderWarning!,
                                          ),
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: t.danger,
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
                                      if (state.submitError !=
                                          null) ...<Widget>[
                                        const SizedBox(height: 8),
                                        Text(
                                          context.l10n.domainMessage(
                                            state.submitError!,
                                          ),
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
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
                                        onPickDate: () =>
                                            _pickDate(context, state),
                                        onPickTime: () =>
                                            _pickTime(context, state),
                                      ),
                                      const SizedBox(height: 20),
                                      Row(
                                        children: <Widget>[
                                          Icon(
                                            Icons.notifications_none_rounded,
                                            size: 18,
                                            color: t.ink2,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            context.l10n.remindMe,
                                            style: t.footnote.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      _ReminderChips(
                                        selected: state.reminder,
                                        customBefore: state.customBefore,
                                        onSelected: (ReminderPreset preset) {
                                          context
                                              .read<TaskFormCubit>()
                                              .reminderChanged(preset);
                                        },
                                        onCustom: () async {
                                          final TaskFormCubit cubit = context
                                              .read<TaskFormCubit>();
                                          final Duration? picked =
                                              await showCustomReminderDialog(
                                                context,
                                                state.customBefore,
                                              );
                                          if (picked != null) {
                                            unawaited(
                                              cubit.reminderChanged(
                                                ReminderPreset.custom,
                                                custom: picked,
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                      const SizedBox(height: 12),
                                      const SizedBox(height: 16),
                                      _SectionLabel(
                                        icon: Icons.repeat_rounded,
                                        text: context.l10n.repeatLabel,
                                      ),
                                      const SizedBox(height: 10),
                                      SizedBox(
                                        height: 44,
                                        child: ListView(
                                          scrollDirection: Axis.horizontal,
                                          children: <Widget>[
                                            for (final RepeatRule rule
                                                in RepeatRule
                                                    .values) ...<Widget>[
                                              _SelectableChip(
                                                label: context.l10n.repeatName(
                                                  rule,
                                                ),
                                                selected: state.repeat == rule,
                                                onTap: () => context
                                                    .read<TaskFormCubit>()
                                                    .repeatChanged(rule),
                                              ),
                                              const SizedBox(width: 8),
                                            ],
                                          ],
                                        ),
                                      ),
                                      if (state.isEdit) ...<Widget>[
                                        const SizedBox(height: 16),
                                        _SectionLabel(
                                          icon: Icons.checklist_rounded,
                                          text: context.l10n.subtasksLabel,
                                        ),
                                        const SizedBox(height: 10),
                                        _SubtasksEditor(items: state.subtasks),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  AppTheme.screenPadding,
                                  4,
                                  AppTheme.screenPadding,
                                  16,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: <Widget>[
                                    FilledButton(
                                      onPressed: state.canSave
                                          ? () => context
                                                .read<TaskFormCubit>()
                                                .save()
                                          : null,
                                      child: Text(
                                        state.isEdit
                                            ? context.l10n.saveChanges
                                            : context.l10n.save,
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
                                        style: TextButton.styleFrom(
                                          foregroundColor: t.danger,
                                        ),
                                        child: Text(context.l10n.delete),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
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
        title = context.l10n.permExactTitle;
        message = context.l10n.permExactBody;
      case ReminderPermissionRationale.fullScreenIntent:
        title = context.l10n.permFullScreenTitle;
        message = context.l10n.permFullScreenBody;
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
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.l10n.continueLabel),
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
      initialEntryMode: TimePickerEntryMode.input,
      builder: (BuildContext ctx, Widget? child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(
          alwaysUse24HourFormat: !uses12HourClock(context.l10n.localeName),
        ),
        child: child!,
      ),
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
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              context.l10n.notificationsOffBanner,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onOpenSettings,
                child: Text(
                  context.l10n.openSettingsAction,
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
  const _CategoryChips({required this.selected, required this.onSelected});

  final TaskCategory selected;
  final ValueChanged<TaskCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: <Widget>[
          for (final TaskCategory category in TaskCategory.values) ...<Widget>[
            _SelectableChip(
              label: context.l10n.categoryLabel(category),
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
    required this.onCustom,
    this.customBefore,
  });

  final ReminderPreset selected;
  final Duration? customBefore;
  final ValueChanged<ReminderPreset> onSelected;
  final VoidCallback onCustom;

  static const Set<ReminderPreset> _shown = <ReminderPreset>{
    ReminderPreset.fiveMinutes,
    ReminderPreset.thirtyMinutes,
    ReminderPreset.oneHour,
  };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (final ReminderPreset preset in ReminderPreset.values)
          if (preset != ReminderPreset.custom &&
              (_shown.contains(preset) || preset == selected))
            _SelectableChip(
              label: context.l10n.presetLabel(preset),
              selected: selected == preset,
              // Tapping the chosen one again turns the reminder off.
              onTap: () =>
                  onSelected(selected == preset ? ReminderPreset.none : preset),
            ),
        _SelectableChip(
          label: selected == ReminderPreset.custom && customBefore != null
              ? context.l10n.reminderBefore(customBefore) ??
                    context.l10n.reminderCustom
              : context.l10n.reminderCustom,
          selected: selected == ReminderPreset.custom,
          onTap: onCustom,
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
            label: _dateLabel(context, dueAt),
            onTap: onPickDate,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _PillButton(
            icon: Icons.schedule,
            label: timeFormatFor(context.l10n.localeName).format(dueAt),
            onTap: onPickTime,
          ),
        ),
      ],
    );
  }

  String _dateLabel(BuildContext context, DateTime dueAt) {
    final DateTime now = DateTime.now();
    if (DateTimeUtils.isSameCalendarDay(dueAt, now)) {
      return context.l10n.dateToday;
    }
    if (DateTimeUtils.isSameCalendarDay(
      dueAt,
      DateTimeUtils.startOfTomorrow(now),
    )) {
      return context.l10n.dateTomorrow;
    }
    return DateFormat('d MMM', context.l10n.localeName).format(dueAt);
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
    final Tokens t = context.tokens;
    return Pressable(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 50),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: ShapeDecoration(
          color: t.sheetCard,
          shape: const StadiumBorder(),
        ),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 18, color: t.violetInk),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: t.body.copyWith(
                  fontWeight: FontWeight.w600,
                  fontFeatures: Fonts.tabular,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
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
    final Tokens t = context.tokens;

    return Semantics(
      selected: selected,
      child: Pressable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: Motion.fast,
          curve: Motion.out,
          constraints: const BoxConstraints(minHeight: 44, minWidth: 48),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: ShapeDecoration(
            color: selected ? t.violetSoft : t.sheetCard,
            shape: const StadiumBorder(),
          ),
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
                style: t.callout.copyWith(
                  color: selected ? t.violetInk : t.ink,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final Tokens t = context.tokens;
    return Row(
      children: <Widget>[
        Icon(icon, size: 18, color: t.ink2),
        const SizedBox(width: 6),
        Text(text, style: t.footnote.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

/// Checklist editor: tick, remove, and add steps.
class _SubtasksEditor extends StatefulWidget {
  const _SubtasksEditor({required this.items});

  final List<Subtask> items;

  @override
  State<_SubtasksEditor> createState() => _SubtasksEditorState();
}

class _SubtasksEditorState extends State<_SubtasksEditor> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    context.read<TaskFormCubit>().subtaskAdded(_controller.text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final Tokens t = context.tokens;
    final TaskFormCubit cubit = context.read<TaskFormCubit>();
    return Container(
      decoration: BoxDecoration(
        color: t.sheetCard,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Column(
        children: <Widget>[
          for (final (int i, Subtask item) in widget.items.indexed)
            Row(
              children: <Widget>[
                IconButton(
                  onPressed: () => cubit.subtaskToggled(i),
                  icon: Icon(
                    item.isDone
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: item.isDone ? t.limeInk : t.ink3,
                  ),
                ),
                Expanded(
                  child: Text(
                    item.title,
                    style: t.body.copyWith(
                      color: item.isDone ? t.ink3 : t.ink,
                      decoration: item.isDone
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => cubit.subtaskRemoved(i),
                  icon: Icon(Icons.close_rounded, size: 18, color: t.ink3),
                ),
              ],
            ),
          Row(
            children: <Widget>[
              const SizedBox(width: 12),
              Icon(Icons.add_rounded, color: t.violetInk),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _controller,
                  maxLength: 80,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _add(),
                  style: t.body,
                  decoration: InputDecoration(
                    hintText: context.l10n.subtaskHint,
                    counterText: '',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "Apply: tomorrow 18:00 · Study" chip shown under the title field.
class _SmartSuggestion extends StatelessWidget {
  const _SmartSuggestion({required this.smart, required this.onApply});

  final SmartInput smart;
  final VoidCallback onApply;

  String _summary(BuildContext context) {
    final String locale = context.l10n.localeName;
    final List<String> parts = <String>[];
    if (smart.date != null) {
      final DateTime d = smart.date!;
      final DateTime now = DateTime.now();
      if (DateTimeUtils.isSameCalendarDay(d, now)) {
        parts.add(context.l10n.dateToday);
      } else if (DateTimeUtils.isSameCalendarDay(
        d,
        DateTimeUtils.startOfTomorrow(now),
      )) {
        parts.add(context.l10n.dateTomorrow);
      } else {
        parts.add(DateFormat('EEE, d MMM', locale).format(d));
      }
    }
    if (smart.hasTime) {
      final String h = smart.hour.toString().padLeft(2, '0');
      final String m = (smart.minute ?? 0).toString().padLeft(2, '0');
      parts.add('$h:$m');
    }
    if (smart.category != null) {
      parts.add(context.l10n.categoryLabel(smart.category!));
    }
    if (smart.repeat != null) {
      parts.add(context.l10n.repeatName(smart.repeat!));
    }
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final Tokens t = context.tokens;
    return Align(
      alignment: Alignment.centerLeft,
      child: Pressable(
        onTap: onApply,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: ShapeDecoration(
            color: t.violetSoft,
            shape: const StadiumBorder(),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.auto_awesome_rounded, size: 16, color: t.violetInk),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  context.l10n.smartApply(_summary(context)),
                  style: t.callout.copyWith(
                    color: t.violetInk,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
