import Flutter
import Photos
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let downloadsChannelName = "yallamarket/downloads"
  private var downloadsChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let channel = FlutterMethodChannel(
      name: downloadsChannelName,
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handleDownloadCall(call, result: result)
    }
    downloadsChannel = channel
  }

  private func handleDownloadCall(
    _ call: FlutterMethodCall,
    result: @escaping FlutterResult
  ) {
    guard call.method == "saveImageToDownloads" else {
      result(FlutterMethodNotImplemented)
      return
    }
    guard
      let arguments = call.arguments as? [String: Any],
      let typedData = arguments["bytes"] as? FlutterStandardTypedData,
      !typedData.data.isEmpty
    else {
      result(false)
      return
    }

    let requestedName = arguments["fileName"] as? String ?? "image.png"
    saveImageToPhotos(
      data: typedData.data,
      fileName: sanitizeFileName(requestedName),
      result: result
    )
  }

  private func saveImageToPhotos(
    data: Data,
    fileName: String,
    result: @escaping FlutterResult
  ) {
    let save = {
      PHPhotoLibrary.shared().performChanges({
        let request = PHAssetCreationRequest.forAsset()
        let options = PHAssetResourceCreationOptions()
        options.originalFilename = fileName
        request.addResource(with: .photo, data: data, options: options)
      }) { success, _ in
        DispatchQueue.main.async { result(success) }
      }
    }

    switch PHPhotoLibrary.authorizationStatus(for: .addOnly) {
    case .authorized, .limited:
      save()
    case .notDetermined:
      PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
        guard status == .authorized || status == .limited else {
          DispatchQueue.main.async { result(false) }
          return
        }
        save()
      }
    default:
      result(false)
    }
  }

  private func sanitizeFileName(_ fileName: String) -> String {
    let invalidCharacters = CharacterSet(charactersIn: "<>:\"/\\|?*")
      .union(.controlCharacters)
    let parts = fileName
      .components(separatedBy: invalidCharacters)
      .filter { !$0.isEmpty }
    let cleaned = parts.joined(separator: "_").trimmingCharacters(in: .whitespaces)
    let name = cleaned.isEmpty ? "image.png" : cleaned
    return name.contains(".") ? name : "\(name).png"
  }
}
