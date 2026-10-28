import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  private var secureScreenEnabled = false
  private var privacyCover: UIView?

  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)
    guard let controller = window?.rootViewController as? FlutterViewController else {
      return
    }
    let channel = FlutterMethodChannel(
      name: "on_air/secure_screen",
      binaryMessenger: controller.binaryMessenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "setSecure",
            let args = call.arguments as? [String: Any],
            let enabled = args["enabled"] as? Bool else {
        result(FlutterMethodNotImplemented)
        return
      }
      self?.secureScreenEnabled = enabled
      if !enabled { self?.removePrivacyCover() }
      result(nil)
    }
  }

  override func sceneWillResignActive(_ scene: UIScene) {
    super.sceneWillResignActive(scene)
    guard secureScreenEnabled, let window else { return }
    let cover = UIView(frame: window.bounds)
    cover.backgroundColor = UIColor(red: 0, green: 0.18, blue: 0.28, alpha: 1)
    cover.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    window.addSubview(cover)
    privacyCover = cover
  }

  override func sceneDidBecomeActive(_ scene: UIScene) {
    super.sceneDidBecomeActive(scene)
    removePrivacyCover()
  }

  private func removePrivacyCover() {
    privacyCover?.removeFromSuperview()
    privacyCover = nil
  }

}
