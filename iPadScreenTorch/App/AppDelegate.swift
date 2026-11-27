import UIKit
import SwiftUI

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions options: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = UIHostingController(rootView: Text("Screen Torch").foregroundColor(.white).frame(maxWidth: .infinity, maxHeight: .infinity).background(Color.black).ignoresSafeArea())
        self.window = window
        window.makeKeyAndVisible()
        return true
    }
}
