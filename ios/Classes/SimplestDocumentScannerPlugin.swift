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
    @objc static func scanDocuments(result: @escaping FlutterResult) {
        let instance = VisionKitDocumentScanner(result: result)
        instance.present()
    }

    private var result: FlutterResult

    init(result: @escaping FlutterResult) {
        self.result = result
        super.init()
    }

    func present() {
        let controller = VNDocumentCameraViewController()
        controller.delegate = self

        if let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
            let window = windowScene.windows.first(where: { $0.isKeyWindow }),
            let rootVC = window.rootViewController
        {
            rootVC.present(controller, animated: true)
        } else {
            if let anyRootVC = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap({ $0.windows })
                .first?.rootViewController
            {
                anyRootVC.present(controller, animated: true)
            }
        }
    }

    func documentCameraViewController(
        _ controller: VNDocumentCameraViewController,
        didFinishWith scan: VNDocumentCameraScan
    ) {
        let image = scan.imageOfPage(at: 0)
        if let jpeg = image.jpegData(compressionQuality: 0.9) {
            result(FlutterStandardTypedData(bytes: jpeg))
        } else {
            result(
                FlutterError(
                    code: "NO_IMAGE",
                    message: "Failed to convert",
                    details: nil
                )
            )
        }
        controller.dismiss(animated: true)
    }

    func documentCameraViewControllerDidCancel(
        _ controller: VNDocumentCameraViewController
    ) {
        result(nil)
        controller.dismiss(animated: true)
    }
}
