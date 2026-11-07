import AVFoundation
import Flutter
import UIKit
import UserNotifications

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
    while written < maxFrames {
      try input.read(into: buffer)
      if buffer.frameLength == 0 { break }
      let left = AVAudioFrameCount(maxFrames - written)
      if buffer.frameLength > left { buffer.frameLength = left }
      try output.write(from: buffer)
      written += AVAudioFramePosition(buffer.frameLength)
    }
  }
}
