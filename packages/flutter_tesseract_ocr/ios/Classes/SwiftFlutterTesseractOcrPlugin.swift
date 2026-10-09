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
        // Bangla Scanner patch: `extractHocr` returns hOCR (text plus the
        // box of every word) like the Android side does, built from
        // SwiftyTesseract's result iterator.
        guard call.method == "extractText" || call.method == "extractHocr" else {
            result(FlutterMethodNotImplemented)
            return
        }
        let wantHocr = call.method == "extractHocr"
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
            var output: Result<String, Error> = ocr
            if wantHocr, case .success = ocr {
                // Valid only right after performOCR, on the same engine.
                let lines = (try? tesseract.recognizedBlocks(for: .textline).get()) ?? []
                let words = (try? tesseract.recognizedBlocks(for: .word).get()) ?? []
                let width = Int(image.size.width * image.scale)
                let height = Int(image.size.height * image.scale)
                output = .success(Self.hocr(lines: lines, words: words, width: width, height: height))
            }
            DispatchQueue.main.async {
                switch output {
                case .success(let text):
                    result(text)
                case .failure(let error):
                    result(FlutterError(code: "ocr_failed", message: error.localizedDescription, details: nil))
                }
            }
        }
    }

    /// A minimal hOCR document: one `ocr_line` span per recognized line,
    /// holding the `ocrx_word` spans whose centre lies inside it (words
    /// that fit no line get a line of their own). Box coordinates are
    /// pixels of the image, top-left origin, as Tesseract reports them.
    static func hocr(lines: [RecognizedBlock], words: [RecognizedBlock], width: Int, height: Int) -> String {
        func bbox(_ r: CGRect) -> String {
            "bbox \(Int(r.minX)) \(Int(r.minY)) \(Int(r.maxX)) \(Int(r.maxY))"
        }
        func escape(_ s: String) -> String {
            s.replacingOccurrences(of: "&", with: "&amp;")
                .replacingOccurrences(of: "<", with: "&lt;")
                .replacingOccurrences(of: ">", with: "&gt;")
                .replacingOccurrences(of: "\"", with: "&quot;")
        }
        var buckets = [[RecognizedBlock]](repeating: [], count: lines.count)
        var loose = [RecognizedBlock]()
        for word in words {
            let centre = CGPoint(x: word.boundingBox.midX, y: word.boundingBox.midY)
            if let index = lines.firstIndex(where: { $0.boundingBox.contains(centre) }) {
                buckets[index].append(word)
            } else {
                loose.append(word)
            }
        }
        var out = "<div class='ocr_page' title='image \"\"; bbox 0 0 \(width) \(height)'>\n<p class='ocr_par'>\n"
        func line(_ box: CGRect, _ items: [RecognizedBlock]) {
            out += "<span class='ocr_line' title='\(bbox(box))'>"
            for w in items {
                let text = w.text.trimmingCharacters(in: .whitespacesAndNewlines)
                if text.isEmpty { continue }
                out += "<span class='ocrx_word' title='\(bbox(w.boundingBox)); x_wconf \(Int(w.confidence))'>\(escape(text))</span> "
            }
            out += "</span>\n"
        }
        for (index, l) in lines.enumerated() {
            line(l.boundingBox, buckets[index])
        }
        for w in loose {
            line(w.boundingBox, [w])
        }
        out += "</p>\n</div>\n"
        return out
    }
}
