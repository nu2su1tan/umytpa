import AppIntents
import Foundation

/// Where an intent leaves a task for Flutter to pick up when the app opens.
enum PendingEntry {
  static let kindKey = "umytpa.pending_entry_kind"
  static let textKey = "umytpa.pending_entry_text"

  static func store(kind: String, text: String?) {
    let defaults = UserDefaults.standard
    defaults.set(kind, forKey: kindKey)
    defaults.set(text, forKey: textKey)
  }

  /// Returns and clears what is waiting.
  static func take() -> [String: String]? {
    let defaults = UserDefaults.standard
    guard let kind = defaults.string(forKey: kindKey) else { return nil }
    var entry = ["kind": kind]
    if let text = defaults.string(forKey: textKey) { entry["text"] = text }
    defaults.removeObject(forKey: kindKey)
    defaults.removeObject(forKey: textKey)
    return entry
  }
}

/// "Hey Siri, add a task in Umytpa": Siri asks what to add, the app opens and
/// creates the task (dates and times in the sentence are understood).
@available(iOS 16.0, *)
struct AddTaskIntent: AppIntent {
  static var title: LocalizedStringResource = "Add task"
  static var description = IntentDescription("Adds a task to Umytpa.")
  static var openAppWhenRun: Bool = true

  @Parameter(title: "Task", requestValueDialog: "What should I add?")
  var text: String

  func perform() async throws -> some IntentResult {
    PendingEntry.store(kind: "add", text: text)
    return .result()
  }
}

@available(iOS 16.0, *)
struct NewTaskIntent: AppIntent {
  static var title: LocalizedStringResource = "New task"
  static var description = IntentDescription("Opens the new task form.")
  static var openAppWhenRun: Bool = true

  func perform() async throws -> some IntentResult {
    PendingEntry.store(kind: "new", text: nil)
    return .result()
  }
}

@available(iOS 16.0, *)
struct UmytpaShortcuts: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: AddTaskIntent(),
      phrases: [
        "Add a task in \(.applicationName)",
        "Add task to \(.applicationName)",
      ],
      shortTitle: "Add task",
      systemImageName: "plus.circle"
    )
    AppShortcut(
      intent: NewTaskIntent(),
      phrases: ["New task in \(.applicationName)"],
      shortTitle: "New task",
      systemImageName: "square.and.pencil"
    )
  }
}
