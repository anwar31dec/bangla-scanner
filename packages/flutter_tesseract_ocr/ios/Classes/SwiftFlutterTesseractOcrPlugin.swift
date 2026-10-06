import Flutter
import UIKit
import SwiftyTesseract

/// Points SwiftyTesseract at a `tessdata` folder outside the app bundle.
///
/// Bangla Scanner patch: the upstream plugin tried to symlink a folder into
/// the (read-only) app bundle, which fails on real devices. The Dart side
/// already copies the traineddata files into `<Documents>/tessdata`, so we
/// read them from there instead.
struct DirectoryDataSource: LanguageModelDataSource {
    let pathToTrainedData: String
}

public class SwiftFlutterTesseractOcrPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_tesseract_ocr", binaryMessenger: registrar.messenger())
        let instance = SwiftFlutterTesseractOcrPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard call.method == "extractText" else {
            result(FlutterMethodNotImplemented)
            return
        }
        guard let params = call.arguments as? [String: Any],
              let imagePath = params["imagePath"] as? String,
              let tessDataParent = params["tessData"] as? String else {
            result(FlutterError(code: "bad_args", message: "Missing imagePath or tessData", details: nil))
            return
        }
        let language = (params["language"] as? String) ?? "eng"
        let tessdataDir = (tessDataParent as NSString).appendingPathComponent("tessdata")

        // SwiftyTesseract calls fatalError() if a model is missing, so check first.
        for lang in language.split(separator: "+") {
            let model = (tessdataDir as NSString).appendingPathComponent("\(lang).traineddata")
            if !FileManager.default.fileExists(atPath: model) {
                result(FlutterError(code: "missing_model", message: "Missing \(lang).traineddata", details: nil))
                return
            }
        }
        guard let image = UIImage(contentsOfFile: imagePath) else {
            result(FlutterError(code: "bad_image", message: "Could not read image", details: nil))
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            let tesseract = SwiftyTesseract(
                language: .custom(language),
                dataSource: DirectoryDataSource(pathToTrainedData: tessdataDir)
            )
            let ocr = tesseract.performOCR(on: image)
            DispatchQueue.main.async {
                switch ocr {
                case .success(let text):
                    result(text)
                case .failure(let error):
                    result(FlutterError(code: "ocr_failed", message: error.localizedDescription, details: nil))
                }
            }
        }
    }
}
