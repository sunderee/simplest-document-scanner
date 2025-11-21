import Flutter
import UIKit
import VisionKit

public class SimplestDocumentScannerPlugin: NSObject, FlutterPlugin {
  private static let methodChannelName = "simplest_document_scanner"
  private static let scanMethod = "scanDocuments"

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: methodChannelName,
      binaryMessenger: registrar.messenger()
    )
    let instance = SimplestDocumentScannerPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(
    _ call: FlutterMethodCall,
    result: @escaping FlutterResult
  ) {
    switch call.method {
    case Self.scanMethod:
      do {
        let request = try DocumentScannerRequest(arguments: call.arguments)
        Task { @MainActor in
          VisionKitDocumentScanner.shared.scan(
            request: request,
            flutterResult: result
          )
        }
      } catch let error as DocumentScannerRequestError {
        result(error.flutterError)
      } catch {
        result(
          FlutterError(
            code: "INVALID_ARGUMENT",
            message: "Unable to parse scanner request.",
            details: error.localizedDescription
          )
        )
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}

@MainActor
private final class VisionKitDocumentScanner: NSObject, VNDocumentCameraViewControllerDelegate {
  static let shared = VisionKitDocumentScanner()

  private var completion: FlutterResult?
  private var request: DocumentScannerRequest?
  private weak var presentedController: VNDocumentCameraViewController?

  func scan(request: DocumentScannerRequest, flutterResult: @escaping FlutterResult) {
    guard VNDocumentCameraViewController.isSupported else {
      flutterResult(ScanError.unsupported.flutterError)
      return
    }

    guard completion == nil else {
      flutterResult(
        FlutterError(
          code: "SCAN_IN_PROGRESS",
          message: "Another scan is already running.",
          details: nil
        )
      )
      return
    }

    self.request = request
    completion = flutterResult

    let controller = VNDocumentCameraViewController()
    controller.delegate = self
    presentedController = controller

    guard let presenter = findTopmostViewController() else {
      fail(.presentationFailed)
        return
      }

    presenter.present(controller, animated: true)
  }

  private func findTopmostViewController() -> UIViewController? {
    guard
      let windowScene = UIApplication.shared.connectedScenes
        .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
      let window = windowScene.windows.first(where: { $0.isKeyWindow })
    else {
      return UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .flatMap { $0.windows }
        .first(where: { $0.isKeyWindow })?
        .rootViewController
        .flatMap { findTopmostViewController(from: $0) }
    }

    return findTopmostViewController(from: window.rootViewController)
  }

  private func findTopmostViewController(from root: UIViewController?) -> UIViewController? {
    guard let root = root else { return nil }

    if let presented = root.presentedViewController {
      return findTopmostViewController(from: presented)
    }

    if let navigationController = root as? UINavigationController {
      return findTopmostViewController(from: navigationController.visibleViewController)
    }

    if let tabBarController = root as? UITabBarController {
      return findTopmostViewController(from: tabBarController.selectedViewController)
    }

    return root
  }

  func documentCameraViewController(
    _ controller: VNDocumentCameraViewController,
    didFinishWith scan: VNDocumentCameraScan
  ) {
    defer { controller.dismiss(animated: true) }
    guard let request else {
      fail(.presentationFailed)
      return
    }

    processScan(scan, with: request)
  }

  func documentCameraViewControllerDidCancel(
    _ controller: VNDocumentCameraViewController
  ) {
    defer { controller.dismiss(animated: true) }
    complete(with: nil)
  }

  func documentCameraViewController(
    _ controller: VNDocumentCameraViewController,
    didFailWithError error: Error
  ) {
    defer { controller.dismiss(animated: true) }
    fail(.presentationFailed)
  }

  private func processScan(
    _ scan: VNDocumentCameraScan,
    with request: DocumentScannerRequest
  ) {
    var images: [UIImage] = []
    for index in 0..<scan.pageCount {
      images.append(scan.imageOfPage(at: index))
    }

    if
      request.enforceMaxPageLimit,
      let maxPages = request.maxPages,
      images.count > maxPages
    {
      images = Array(images.prefix(maxPages))
    }

    guard !images.isEmpty else {
      fail(.noImagesCaptured)
      return
    }

    var pagePayloads = [[String: Any]]()
    if request.returnJpegs {
      for (index, image) in images.enumerated() {
        guard let jpegData = image.jpegData(compressionQuality: request.jpegQuality) else {
          fail(.conversionFailed)
          return
        }

        pagePayloads.append([
          "index": index,
          "bytes": FlutterStandardTypedData(bytes: jpegData),
        ])
      }
    }

    var response: [String: Any] = ["pages": pagePayloads]

    if request.returnPdf {
      do {
        let pdfData = try makePdfData(from: images)
        response["pdf"] = FlutterStandardTypedData(bytes: pdfData)
      } catch {
        fail(.pdfGenerationFailed)
        return
      }
    }

    complete(with: response)
  }

  private func makePdfData(from images: [UIImage]) throws -> Data {
    guard let firstSize = images.first?.size else {
      throw ScanError.noImagesCaptured
    }

    let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: firstSize))
    return renderer.pdfData { context in
      for image in images {
        let bounds = CGRect(origin: .zero, size: image.size)
        context.beginPage(withBounds: bounds, pageInfo: [:])
        image.draw(in: bounds)
      }
    }
  }

  private func complete(with value: Any?) {
    guard let completion else { return }
    completion(value)
    reset()
  }

  private func fail(_ error: ScanError) {
    completion?(error.flutterError)
    reset()
  }

  private func reset() {
    completion = nil
    request = nil
    presentedController = nil
  }
}

struct DocumentScannerRequest {
  let maxPages: Int?
  let returnJpegs: Bool
  let returnPdf: Bool
  let jpegQuality: CGFloat
  let enforceMaxPageLimit: Bool

  init(arguments: Any?) throws {
    let dictionary = arguments as? [String: Any] ?? [:]

    let returnJpegs = dictionary["returnJpegs"] as? Bool ?? true
    let returnPdf = dictionary["returnPdf"] as? Bool ?? false
    guard returnJpegs || returnPdf else {
      throw DocumentScannerRequestError.noOutputFormats
    }

    let maxPages = dictionary["maxPages"] as? Int
    if let maxPages, maxPages <= 0 {
      throw DocumentScannerRequestError.invalidMaxPages
    }

    let jpegQualityValue = dictionary["jpegQuality"] as? Double ?? 0.9
    guard jpegQualityValue >= 0, jpegQualityValue <= 1 else {
      throw DocumentScannerRequestError.invalidJpegQuality
    }

    let iosArgs = dictionary["ios"] as? [String: Any]
    let enforceLimit = iosArgs?["enforceMaxPageLimit"] as? Bool ?? true

    self.maxPages = maxPages
    self.returnJpegs = returnJpegs
    self.returnPdf = returnPdf
    self.jpegQuality = CGFloat(jpegQualityValue)
    self.enforceMaxPageLimit = enforceLimit
  }
}

enum DocumentScannerRequestError: Error {
  case invalidArguments
  case invalidMaxPages
  case invalidJpegQuality
  case noOutputFormats

  var flutterError: FlutterError {
    switch self {
    case .invalidArguments:
      return FlutterError(
        code: "INVALID_ARGUMENT",
        message: "Invalid scanner arguments provided.",
        details: nil
      )
    case .invalidMaxPages:
      return FlutterError(
        code: "INVALID_ARGUMENT",
        message: "maxPages must be a positive integer.",
        details: nil
      )
    case .invalidJpegQuality:
      return FlutterError(
        code: "INVALID_ARGUMENT",
        message: "jpegQuality must be between 0 and 1.",
        details: nil
      )
    case .noOutputFormats:
      return FlutterError(
        code: "INVALID_ARGUMENT",
        message: "At least one of returnJpegs or returnPdf must be true.",
        details: nil
      )
    }
  }
}

private enum ScanError: String {
  case unsupported = "DOCUMENT_SCANNER_UNSUPPORTED"
  case presentationFailed = "SCANNER_PRESENTATION_FAILED"
  case conversionFailed = "IMAGE_CONVERSION_FAILED"
  case noImagesCaptured = "NO_IMAGES_CAPTURED"
  case pdfGenerationFailed = "PDF_GENERATION_FAILED"

  var message: String {
    switch self {
    case .unsupported:
      return "Document scanning is unsupported on this device."
    case .presentationFailed:
      return "Unable to present the document scanner UI."
    case .conversionFailed:
      return "Captured image could not be converted to JPEG."
    case .noImagesCaptured:
      return "No document images were captured."
    case .pdfGenerationFailed:
      return "Unable to generate a PDF from the captured images."
    }
  }

  var flutterError: FlutterError {
    FlutterError(code: rawValue, message: message, details: nil)
  }
}
