import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  private let screenshotChannelName = "rentalreport/screenshot"
  private let screenshotModeArgument = "--app-store-screenshot-mode"
  private let screenshotSceneArgument = "--app-store-screenshot-scene"

  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)

    guard let flutterViewController = window?.rootViewController as? FlutterViewController else {
      return
    }

    let channel = FlutterMethodChannel(
      name: screenshotChannelName,
      binaryMessenger: flutterViewController.binaryMessenger
    )
    let launchContext = makeLaunchContext()

    channel.setMethodCallHandler { call, result in
      guard call.method == "getLaunchContext" else {
        result(FlutterMethodNotImplemented)
        return
      }

      result(launchContext)
    }
  }

  private func makeLaunchContext() -> [String: Any] {
    let arguments = ProcessInfo.processInfo.arguments
    let environment = ProcessInfo.processInfo.environment

    let screenshotMode =
      arguments.contains(screenshotModeArgument)
      || environment["APP_STORE_SCREENSHOT_MODE"] == "1"
      || environment["SIMCTL_CHILD_APP_STORE_SCREENSHOT_MODE"] == "1"

    let scene =
      sceneValue(from: arguments)
      ?? environment["APP_STORE_SCREENSHOT_SCENE"]
      ?? environment["SIMCTL_CHILD_APP_STORE_SCREENSHOT_SCENE"]
      ?? ""

    return [
      "screenshotMode": screenshotMode,
      "scene": scene,
    ]
  }

  private func sceneValue(from arguments: [String]) -> String? {
    guard let index = arguments.firstIndex(of: screenshotSceneArgument) else {
      return nil
    }

    let nextIndex = arguments.index(after: index)
    guard nextIndex < arguments.endIndex else {
      return nil
    }

    return arguments[nextIndex]
  }
}
