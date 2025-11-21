import Flutter
import UIKit
import VisionKit

public class SimplestDocumentScannerPlugin: NSObject, FlutterPlugin {
  private static let METHOD_CHANNEL_NAME: String = "simplest_document_scanner"
  private static let METHOD_SCAN_DOCUMENTS: String = "scanDocuments"

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: Self.METHOD_CHANNEL_NAME,
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
    case Self.METHOD_SCAN_DOCUMENTS:
      VisionKitDocumentScanner.scanDocuments(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}

@objc
private class VisionKitDocumentScanner: NSObject,
  VNDocumentCameraViewControllerDelegate
{
  private enum ScanError: String {
    case unsupported = "DOCUMENT_SCANNER_UNSUPPORTED"
    case presentationFailed = "SCANNER_PRESENTATION_FAILED"
    case conversionFailed = "IMAGE_CONVERSION_FAILED"
    case noImagesCaptured = "NO_IMAGES_CAPTURED"

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
      }
    }
  }

  private static let compressionQuality: CGFloat = 0.9
  private static var activeScanner: VisionKitDocumentScanner?

  @objc static func scanDocuments(result: @escaping FlutterResult) {
    guard VNDocumentCameraViewController.isSupported else {
      result(
        FlutterError(
          code: ScanError.unsupported.rawValue,
          message: ScanError.unsupported.message,
          details: nil
        )
      )
      return
    }

    guard activeScanner == nil else {
      result(
        FlutterError(
          code: ScanError.presentationFailed.rawValue,
          message: "Another scan is already in progress.",
          details: nil
        )
      )
      return
    }

    let instance = VisionKitDocumentScanner(result: result)
    activeScanner = instance
    instance.present()
  }

  private let result: FlutterResult
  private var didComplete = false
  private weak var presentedController: VNDocumentCameraViewController?

  init(result: @escaping FlutterResult) {
    self.result = result
    super.init()
  }

  func present() {
    let controller = VNDocumentCameraViewController()
    controller.delegate = self
    presentedController = controller

    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }

      guard let presenter = self.findTopmostViewController() else {
        self.fail(with: .presentationFailed)
        Self.activeScanner = nil
        return
      }

      presenter.present(controller, animated: true) { [weak self] in
        if self?.didComplete == false && self?.presentedController == nil {
          self?.fail(with: .presentationFailed)
          Self.activeScanner = nil
        }
      }
    }
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

  private func complete(with value: Any?) {
    guard !didComplete else { return }
    didComplete = true

    DispatchQueue.main.async { [weak self] in
      self?.result(value)
      Self.activeScanner = nil
    }
  }

  private func fail(with error: ScanError) {
    complete(
      with: FlutterError(
        code: error.rawValue,
        message: error.message,
        details: nil
      )
    )
  }

  func documentCameraViewController(
    _ controller: VNDocumentCameraViewController,
    didFinishWith scan: VNDocumentCameraScan
  ) {
    defer {
      DispatchQueue.main.async {
        controller.dismiss(animated: true)
      }
    }

    guard scan.pageCount > 0 else {
      fail(with: .noImagesCaptured)
      return
    }

    var images = [FlutterStandardTypedData]()
    for pageIndex in 0..<scan.pageCount {
      let image = scan.imageOfPage(at: pageIndex)
      guard
        let jpeg = image.jpegData(
          compressionQuality: Self.compressionQuality
        )
      else {
        fail(with: .conversionFailed)
        return
      }
      images.append(FlutterStandardTypedData(bytes: jpeg))
    }

    complete(with: images)
  }

  func documentCameraViewControllerDidCancel(
    _ controller: VNDocumentCameraViewController
  ) {
    defer {
      DispatchQueue.main.async {
        controller.dismiss(animated: true)
      }
    }

    complete(with: nil)
  }

  func documentCameraViewController(
    _ controller: VNDocumentCameraViewController,
    didFailWithError error: Error
  ) {
    defer {
      DispatchQueue.main.async {
        controller.dismiss(animated: true)
      }
    }

    fail(with: .presentationFailed)
  }
}
