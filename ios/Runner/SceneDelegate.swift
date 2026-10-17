import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    for context in URLContexts {
      if context.url.scheme == "coolcare-zalopay" {
        _ = (UIApplication.shared.delegate as? AppDelegate)?.handleZaloPayCallback(context.url)
        return
      }
    }
    super.scene(scene, openURLContexts: URLContexts)
  }
}
