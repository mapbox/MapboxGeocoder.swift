import UIKit

#if swift(>=4.2)
typealias LaunchOptionsKey = UIApplication.LaunchOptionsKey
#else
typealias LaunchOptionsKey = UIApplicationLaunchOptionsKey
#endif

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [LaunchOptionsKey : Any]? = nil) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window!.rootViewController = ViewController(nibName: nil, bundle: nil)
        window!.makeKeyAndVisible()

        return true
    }
}
