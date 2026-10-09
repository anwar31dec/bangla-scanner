import Flutter
import UIKit

/// Files other apps hand to Bangla Scanner through "Open in" / "Copy to"
/// (registered document types: PDF and images). The URLs arrive through the
/// scene delegate; each file is copied into `tmp/received/<time>/` and Dart
/// is told through `filesReceived`, or asks with `takeInitialFiles` for
/// files that arrived before it was listening. Mirrors the Android
/// `ReceivedFiles` class.
final class ReceivedFilesPlugin: NSObject, FlutterPlugin, FlutterSceneLifeCycleDelegate {
  private static let channelName = "com.codeinherit.banglascanner/received"

  private let channel: FlutterMethodChannel
  private var pending: [String] = []
  private var dartListening = false

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: registrar.messenger())
    let instance = ReceivedFilesPlugin(channel: channel)
    registrar.addMethodCallDelegate(instance, channel: channel)
    registrar.addSceneDelegate(instance)
  }

  private init(channel: FlutterMethodChannel) {
    self.channel = channel
    super.init()
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "takeInitialFiles":
      dartListening = true
      let files = pending
      pending.removeAll()
      result(files)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: - FlutterSceneLifeCycleDelegate

  func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions?) -> Bool {
    guard let contexts = connectionOptions?.urlContexts, !contexts.isEmpty else { return false }
    receive(contexts.map { $0.url })
    return true
  }

  func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) -> Bool {
    let files = URLContexts.map { $0.url }.filter { $0.isFileURL }
    guard !files.isEmpty else { return false }
    receive(files)
    return true
  }

  private func receive(_ urls: [URL]) {
    DispatchQueue.global(qos: .userInitiated).async {
      let paths = self.copyAll(urls)
      DispatchQueue.main.async {
        guard !paths.isEmpty else { return }
        if self.dartListening {
          self.channel.invokeMethod("filesReceived", arguments: paths)
        } else {
          self.pending.append(contentsOf: paths)
        }
      }
    }
  }

  private func copyAll(_ urls: [URL]) -> [String] {
    let dir = FileManager.default.temporaryDirectory
      .appendingPathComponent("received", isDirectory: true)
      .appendingPathComponent(String(Int(Date().timeIntervalSince1970 * 1000)), isDirectory: true)
    try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    var paths: [String] = []
    var used = Set<String>()
    for url in urls where url.isFileURL {
      let scoped = url.startAccessingSecurityScopedResource()
      defer { if scoped { url.stopAccessingSecurityScopedResource() } }
      var name = url.lastPathComponent.isEmpty ? "file" : url.lastPathComponent
      while !used.insert(name.lowercased()).inserted { name = "\(used.count)_\(name)" }
      let target = dir.appendingPathComponent(name)
      do {
        try FileManager.default.copyItem(at: url, to: target)
        paths.append(target.path)
        // Files dropped into Documents/Inbox are ours to remove.
        if url.path.contains("/Documents/Inbox/") { try? FileManager.default.removeItem(at: url) }
      } catch {
        // Skip what cannot be read.
      }
    }
    return paths
  }
}
