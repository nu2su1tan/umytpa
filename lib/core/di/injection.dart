import 'package:get_it/get_it.dart';

import '../l10n/locale_controller.dart';
import '../../features/reminders/data/local_reminder_scheduler.dart';
import '../../features/reminders/data/notification_details_factory.dart';
import '../../features/reminders/domain/reminder_scheduler.dart';
import '../../features/reminders/domain/usecases/reschedule_all_reminders.dart';
import '../../features/tasks/data/datasources/app_database.dart';
import '../../features/tasks/data/datasources/tasks_dao.dart';
import '../../features/tasks/data/repositories/task_repository_impl.dart';
import '../../features/tasks/domain/repositories/task_repository.dart';
import '../../features/tasks/domain/usecases/create_task.dart';
import '../../features/tasks/domain/usecases/delete_task.dart';
import '../../features/tasks/domain/usecases/get_task.dart';
import '../../features/tasks/domain/usecases/group_tasks_by_date.dart';
import '../../features/tasks/domain/usecases/toggle_task_done.dart';
import '../../features/tasks/domain/usecases/update_task.dart';
import '../../features/tasks/domain/usecases/watch_tasks.dart';

/// Global service locator. Resolve dependencies only in the composition root
/// and in `BlocProvider(create: ...)`.
final GetIt getIt = GetIt.instance;

/// Registers application dependencies.
Future<void> configureDependencies() async {
  final LocaleController localeController = await LocaleController.load();
  final AppDatabase database = AppDatabase();
  const NotificationDetailsFactory detailsFactory = NotificationDetailsFactory();
  final LocalReminderScheduler scheduler = LocalReminderScheduler(
    detailsFactory: detailsFactory,
    languageCode: () => localeController.locale?.languageCode,
  );
  await scheduler.initialize();

  getIt
    ..registerSingleton<LocaleController>(localeController)
    ..registerSingleton<AppDatabase>(database)
    ..registerSingleton<TasksDao>(database.tasksDao)
    ..registerSingleton<NotificationDetailsFactory>(detailsFactory)
    ..registerSingleton<LocalReminderScheduler>(scheduler)
    ..registerSingleton<ReminderScheduler>(scheduler)
    ..registerLazySingleton<TaskRepository>(
      () => TaskRepositoryImpl(getIt<TasksDao>()),
    )
    ..registerLazySingleton<WatchTasks>(
      () => WatchTasks(getIt<TaskRepository>()),
    )
    ..registerLazySingleton<GetTask>(
      () => GetTask(getIt<TaskRepository>()),
    )
    ..registerLazySingleton<GroupTasksByDate>(() => const GroupTasksByDate())
    ..registerLazySingleton<CreateTask>(
      () => CreateTask(
        repository: getIt<TaskRepository>(),
        reminderScheduler: getIt<ReminderScheduler>(),
      ),
    )
    ..registerLazySingleton<UpdateTask>(
      () => UpdateTask(
        repository: getIt<TaskRepository>(),
        reminderScheduler: getIt<ReminderScheduler>(),
      ),
    )
    ..registerLazySingleton<DeleteTask>(
      () => DeleteTask(
        repository: getIt<TaskRepository>(),
        reminderScheduler: getIt<ReminderScheduler>(),
      ),
    )
    ..registerLazySingleton<ToggleTaskDone>(
      () => ToggleTaskDone(
        repository: getIt<TaskRepository>(),
        reminderScheduler: getIt<ReminderScheduler>(),
      ),
    )
    ..registerLazySingleton<RescheduleAllReminders>(
      () => RescheduleAllReminders(
        repository: getIt<TaskRepository>(),
        reminderScheduler: getIt<ReminderScheduler>(),
      ),
    );
}
