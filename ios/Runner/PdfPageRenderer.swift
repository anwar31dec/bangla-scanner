import Flutter
import UIKit

/// Renders PDF pages to JPEG files for the "Import PDF" feature, with Core
/// Graphics. Same channel contract as the Android `PdfPageRenderer`:
/// `open {path} -> {id, pageCount}`, `render {id, index, maxEdge, path}`,
/// `close {id}`; errors `pdf_locked` and `pdf_invalid`.
final class PdfPageRenderer: NSObject {
  private static let channelName = "com.codeinherit.banglascanner/pdf"
  private static let jpegQuality: CGFloat = 0.92

  private var documents: [Int: CGPDFDocument] = [:]
  private var nextId = 1
  private let queue = DispatchQueue(label: "com.codeinherit.banglascanner.pdf")

  static func register(with registrar: FlutterPluginRegistrar) {
    let instance = PdfPageRenderer()
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: registrar.messenger())
    channel.setMethodCallHandler { call, result in instance.handle(call, result: result) }
    objc_setAssociatedObject(channel, "pdfRenderer", instance, .OBJC_ASSOCIATION_RETAIN)
    registrar.publish(instance)
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any] ?? [:]
    switch call.method {
    case "open":
      guard let path = args["path"] as? String else {
        result(FlutterError(code: "bad_args", message: "path is required", details: nil))
        return
      }
      queue.async { self.open(path: path, result: result) }
    case "render":
      guard let id = args["id"] as? Int, let index = args["index"] as? Int, let path = args["path"] as? String else {
        result(FlutterError(code: "bad_args", message: "id, index and path are required", details: nil))
        return
      }
      let maxEdge = args["maxEdge"] as? Int ?? 2339
      queue.async { self.render(id: id, index: index, maxEdge: maxEdge, path: path, result: result) }
    case "close":
      let id = args["id"] as? Int
      queue.async {
        if let id { self.documents.removeValue(forKey: id) }
        DispatchQueue.main.async { result(nil) }
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func open(path: String, result: @escaping FlutterResult) {
    guard let document = CGPDFDocument(URL(fileURLWithPath: path) as CFURL) else {
      DispatchQueue.main.async { result(FlutterError(code: "pdf_invalid", message: "Not a readable PDF", details: nil)) }
      return
    }
    if document.isEncrypted && !document.isUnlocked {
      // An empty user password is tried by CGPDFDocument already.
      DispatchQueue.main.async { result(FlutterError(code: "pdf_locked", message: "PDF needs a password", details: nil)) }
      return
    }
    let id = nextId
    nextId += 1
    documents[id] = document
    let count = document.numberOfPages
    DispatchQueue.main.async { result(["id": id, "pageCount": count]) }
  }

  private func render(id: Int, index: Int, maxEdge: Int, path: String, result: @escaping FlutterResult) {
    // CGPDFDocument pages are 1-based.
    guard let document = documents[id], let page = document.page(at: index + 1) else {
      DispatchQueue.main.async { result(FlutterError(code: "pdf_invalid", message: "Page not found", details: nil)) }
      return
    }
    let box = page.getBoxRect(.cropBox)
    let rotation = page.rotationAngle
    let rotated = rotation == 90 || rotation == 270
    let pageWidth = rotated ? box.height : box.width
    let pageHeight = rotated ? box.width : box.height
    guard pageWidth > 0, pageHeight > 0 else {
      DispatchQueue.main.async { result(FlutterError(code: "pdf_invalid", message: "Empty page", details: nil)) }
      return
    }
    let scale = CGFloat(maxEdge) / max(pageWidth, pageHeight)
    let size = CGSize(width: max(1, (pageWidth * scale).rounded()), height: max(1, (pageHeight * scale).rounded()))

    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    format.opaque = true
    let renderer = UIGraphicsImageRenderer(size: size, format: format)
    let image = renderer.image { ctx in
      let cg = ctx.cgContext
      UIColor.white.setFill()
      cg.fill(CGRect(origin: .zero, size: size))
      // PDF space has its origin bottom-left; flip, then let Core Graphics
      // fit the (possibly rotated) page into our rectangle.
      cg.translateBy(x: 0, y: size.height)
      cg.scaleBy(x: 1, y: -1)
      cg.interpolationQuality = .high
      let transform = page.getDrawingTransform(.cropBox, rect: CGRect(origin: .zero, size: size), rotate: 0, preserveAspectRatio: true)
      cg.concatenate(transform)
      cg.drawPDFPage(page)
    }
    guard let data = image.jpegData(compressionQuality: Self.jpegQuality) else {
      DispatchQueue.main.async { result(FlutterError(code: "render_failed", message: "Could not encode page", details: nil)) }
      return
    }
    do {
      let url = URL(fileURLWithPath: path)
      try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
      try data.write(to: url, options: .atomic)
      DispatchQueue.main.async { result(path) }
    } catch {
      DispatchQueue.main.async { result(FlutterError(code: "render_failed", message: error.localizedDescription, details: nil)) }
    }
  }
}
