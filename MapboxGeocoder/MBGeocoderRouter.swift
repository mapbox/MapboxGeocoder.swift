import Foundation
import CoreLocation
import RequestKit

internal enum MBGeocoderRouter: Router {
    case V5(Configuration, Bool, String, [String]?, CLLocationCoordinate2D?, [MBPlacemark.Scope]?, Bool?)
    
    var method: HTTPMethod {
        return .GET
    }
    
    var encoding: HTTPEncoding {
        return .URL
    }
    
    var configuration: Configuration {
        switch self {
        case .V5(let config, _, _, _, _, _, _):
            return config
        }
    }
    
    var params: [String : String] {
        switch self {
        case .V5(_, _, _, let ISOCountryCodes, let focusCoordinate, let scopes, let autocomplete):
            var params: [String: String] = [:]
            if let ISOCountryCodes = ISOCountryCodes {
                params["country"] = ISOCountryCodes.joinWithSeparator(",")
            }
            if let focusCoordinate = focusCoordinate {
                params["proximity"] = String(format: "%.3f,%.3f", focusCoordinate.longitude, focusCoordinate.latitude)
            }
            if let scopes = scopes {
                params["types"] = scopes.map { $0.rawValue }.joinWithSeparator(",")
            }
            if let autocomplete = autocomplete {
                params["autocomplete"] = String(autocomplete)
            }
            return params
        }
    }
    
    var path: String {
        switch self {
        case .V5(_, let isPermanent, let query, _, _, _, _):
            return "geocoding/v5/mapbox.places\(isPermanent ? "-permanent" : "")/\(query).json"
        }
    }
}
