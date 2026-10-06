import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "FileExporter") {
      FileExporter.register(with: registrar)
    }
  }
}

/// "Save to phone" on iOS: shows the system Files picker so the user can
/// choose where a copy of the PDF / JPEG / TXT is stored (On My iPhone,
/// iCloud Drive, ...). Mirrors the Android `saveToDownloads` channel.
class FileExporter: NSObject, UIDocumentPickerDelegate {
  private static let channelName = "com.codeinherit.banglascanner/storage"
  private var pendingResult: FlutterResult?

  static func register(with registrar: FlutterPluginRegistrar) {
    let instance = FileExporter()
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: registrar.messenger())
    channel.setMethodCallHandler { call, result in
      instance.handle(call, result: result)
    }
    // Keep the instance alive for the lifetime of the engine.
    objc_setAssociatedObject(channel, "exporter", instance, .OBJC_ASSOCIATION_RETAIN)
    registrar.publish(instance)
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "exportToFiles" else {
      result(FlutterMethodNotImplemented)
      return
    }
    guard let args = call.arguments as? [String: Any],
          let paths = args["paths"] as? [String], !paths.isEmpty else {
      result(FlutterError(code: "bad_args", message: "paths is required", details: nil))
      return
    }
    guard let presenter = Self.topViewController() else {
      result(FlutterError(code: "no_ui", message: "No view controller to present from", details: nil))
      return
    }
    pendingResult?(false)
    pendingResult = result
    let urls = paths.map { URL(fileURLWithPath: $0) }
    let picker = UIDocumentPickerViewController(forExporting: urls, asCopy: true)
    picker.delegate = self
    presenter.present(picker, animated: true)
  }

  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    pendingResult?(true)
    pendingResult = nil
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    pendingResult?(false)
    pendingResult = nil
  }

  private static func topViewController() -> UIViewController? {
    let scene = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .first { $0.activationState == .foregroundActive } ??
      UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
    var top = scene?.windows.first { $0.isKeyWindow }?.rootViewController
    while let presented = top?.presentedViewController {
      top = presented
    }
    return top
  }
}
