import AVFoundation
import Flutter
import UIKit
import UserNotifications
#if canImport(AlarmKit)
import ActivityKit
import AlarmKit
import SwiftUI
#endif

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Show notifications while the app is in the foreground.
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // iOS plays notification sounds only from PCM files (wav/aiff/caf) of at
    // most 30 seconds, so other formats are converted when the user picks them.
    let channel = FlutterMethodChannel(
      name: "umytpa/audio",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    let alarmChannel = FlutterMethodChannel(
      name: "umytpa/alarmkit",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    let entryChannel = FlutterMethodChannel(
      name: "umytpa/entry",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    entryChannel.setMethodCallHandler { call, result in
      if call.method == "take" {
        result(PendingEntry.take())
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    alarmChannel.setMethodCallHandler { call, result in
      AlarmKitBridge.handle(call, result: result)
    }
    channel.setMethodCallHandler { call, result in
      guard call.method == "toCaf",
            let args = call.arguments as? [String: String],
            let source = args["source"],
            let target = args["target"] else {
        result(FlutterMethodNotImplemented)
        return
      }
      DispatchQueue.global(qos: .userInitiated).async {
        do {
          try AppDelegate.convertToCaf(source: source, target: target)
          DispatchQueue.main.async { result(true) }
        } catch {
          DispatchQueue.main.async {
            result(FlutterError(code: "convert", message: "\(error)", details: nil))
          }
        }
      }
    }
  }

  /// Decodes any format the system can read and writes 16-bit PCM CAF,
  /// cut to the 30 seconds notifications allow.
  static func convertToCaf(source: String, target: String) throws {
    let input = try AVAudioFile(forReading: URL(fileURLWithPath: source))
    let format = input.processingFormat
    let maxFrames = AVAudioFramePosition(format.sampleRate * 30)
    let settings: [String: Any] = [
      AVFormatIDKey: kAudioFormatLinearPCM,
      AVSampleRateKey: format.sampleRate,
      AVNumberOfChannelsKey: format.channelCount,
      AVLinearPCMBitDepthKey: 16,
      AVLinearPCMIsFloatKey: false,
      AVLinearPCMIsBigEndianKey: false,
    ]
    let output = try AVAudioFile(
      forWriting: URL(fileURLWithPath: target),
      settings: settings,
      commonFormat: format.commonFormat,
      interleaved: format.isInterleaved
    )
    guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 16384) else {
      throw NSError(domain: "umytpa", code: 1)
    }
    var written: AVAudioFramePosition = 0
    let total = min(maxFrames, input.length)
    while written < total {
      let want = AVAudioFrameCount(
        min(AVAudioFramePosition(buffer.frameCapacity), total - written))
      do {
        try input.read(into: buffer, frameCount: want)
      } catch {
        // Some compressed files report a length slightly longer than they
        // hold; hitting the end after real audio is not a failure.
        if written > 0 { break }
        throw error
      }
      if buffer.frameLength == 0 { break }
      try output.write(from: buffer)
      written += AVAudioFramePosition(buffer.frameLength)
    }
    if written == 0 { throw NSError(domain: "umytpa", code: 2) }
  }
}

/// Real alarms (iOS 26+): they ring until stopped, through silent mode and
/// Focus, like the Clock app. On older systems every call reports that it is
/// unsupported and the app keeps using notifications.
enum AlarmKitBridge {
  static func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    #if canImport(AlarmKit)
    if #available(iOS 26.0, *) {
      AlarmKitImpl.handle(call, result: result)
      return
    }
    #endif
    switch call.method {
    case "status": result("unsupported")
    case "count": result(0)
    default: result(false)
    }
  }
}

#if canImport(AlarmKit)
@available(iOS 26.0, *)
struct UmytpaAlarmMetadata: AlarmMetadata {}

@available(iOS 26.0, *)
enum AlarmKitImpl {
  static func name(_ state: AlarmManager.AuthorizationState) -> String {
    switch state {
    case .notDetermined: return "notDetermined"
    case .denied: return "denied"
    case .authorized: return "authorized"
    @unknown default: return "denied"
    }
  }

  static func fail(_ result: @escaping FlutterResult, _ code: String, _ error: Error) {
    DispatchQueue.main.async {
      result(FlutterError(code: code, message: "\(error)", details: nil))
    }
  }

  static func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let manager = AlarmManager.shared
    let args = call.arguments as? [String: Any] ?? [:]
    switch call.method {
    case "status":
      result(name(manager.authorizationState))

    case "request":
      Task {
        do {
          let state = try await manager.requestAuthorization()
          DispatchQueue.main.async { result(name(state)) }
        } catch {
          fail(result, "request", error)
        }
      }

    case "schedule":
      guard let idString = args["id"] as? String,
            let id = UUID(uuidString: idString),
            let millis = (args["at"] as? NSNumber)?.doubleValue,
            let title = args["title"] as? String,
            let stop = args["stop"] as? String else {
        result(FlutterError(code: "args", message: "bad arguments", details: nil))
        return
      }
      let soundName = args["sound"] as? String
      Task {
        do {
          guard manager.authorizationState == .authorized else {
            throw NSError(domain: "umytpa", code: 10)
          }
          // A task has one deadline alarm: replace the old one, if any.
          try? manager.cancel(id: id)
          let alert = AlarmPresentation.Alert(
            title: LocalizedStringResource(String.LocalizationValue(title)),
            stopButton: AlarmButton(
              text: LocalizedStringResource(String.LocalizationValue(stop)),
              textColor: .white,
              systemImageName: "stop.circle"
            )
          )
          let attributes = AlarmAttributes<UmytpaAlarmMetadata>(
            presentation: AlarmPresentation(alert: alert),
            metadata: nil,
            tintColor: Color(red: 0.47, green: 0.31, blue: 0.91)
          )
          let sound: ActivityKit.AlertConfiguration.AlertSound =
            soundName.map { .named($0) } ?? .default
          let configuration = AlarmManager.AlarmConfiguration<UmytpaAlarmMetadata>.alarm(
            schedule: .fixed(Date(timeIntervalSince1970: millis / 1000)),
            attributes: attributes,
            sound: sound
          )
          _ = try await manager.schedule(id: id, configuration: configuration)
          DispatchQueue.main.async { result(true) }
        } catch {
          fail(result, "schedule", error)
        }
      }

    case "cancel":
      guard let idString = args["id"] as? String, let id = UUID(uuidString: idString) else {
        result(false)
        return
      }
      // Cancelling an alarm that is not there is fine.
      try? manager.cancel(id: id)
      result(true)

    case "count":
      result((try? manager.alarms.count) ?? 0)

    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
#endif
