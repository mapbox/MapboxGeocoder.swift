import UIKit

// A Mapbox access token is required to use the Geocoding API.
// https://www.mapbox.com/help/create-api-access-token/
let MapboxAccessToken = NSBundle.mainBundle().objectForInfoDictionaryKey("MGLMapboxAccessToken") as? String ?? ""

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        window!.rootViewController = ViewController(nibName: nil, bundle: nil)
        window!.makeKeyAndVisible()

        return true
    }

}
