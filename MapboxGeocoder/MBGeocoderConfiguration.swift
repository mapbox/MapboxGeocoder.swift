import Foundation
import RequestKit

internal struct MBGeocoderConfiguration: Configuration {
    internal var apiEndpoint: String = "https://api.mapbox.com"
    internal var accessToken: String?
    
    internal init(_ accessToken: String) {
        self.accessToken = accessToken
    }
}
