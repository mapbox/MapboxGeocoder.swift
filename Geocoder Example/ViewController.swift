import UIKit
import MapKit
import CoreLocation
import MapboxGeocoder

// A Mapbox access token is required to use the Geocoding API.
// https://www.mapbox.com/help/create-api-access-token/
let MapboxAccessToken = "<# your Mapbox access token #>"

class ViewController: UIViewController, MKMapViewDelegate {
    
    // MARK: - Variables

    var mapView: MKMapView!
    var resultsLabel: UILabel!
    var geocoder: MBGeocoder!
    
    // MARK: - Setup

    override func viewDidLoad() {
        super.viewDidLoad()

        assert(MapboxAccessToken != "<# your Mapbox access token #>", "You must set `MapboxAccessToken` to your Mapbox access token.")
        
        mapView = MKMapView(frame: view.bounds)
        mapView.autoresizingMask = [ .FlexibleWidth, .FlexibleHeight ]
        mapView.delegate = self
        view.addSubview(mapView)
        
        resultsLabel = UILabel(frame: CGRect(x: 10, y: 20, width: view.bounds.size.width - 20, height: 30))
        resultsLabel.autoresizingMask = .FlexibleWidth
        resultsLabel.adjustsFontSizeToFitWidth = true
        resultsLabel.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.5)
        resultsLabel.userInteractionEnabled = false
        view.addSubview(resultsLabel)
        
        geocoder = MBGeocoder(accessToken: MapboxAccessToken)
    }

    // MARK: - MKMapViewDelegate

    func mapView(mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        geocoder.cancelGeocode()
    }
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        geocoder.cancelGeocode()
        geocoder.reverseGeocodeLocation(CLLocation(latitude: mapView.centerCoordinate.latitude,
            longitude: mapView.centerCoordinate.longitude)) { [unowned self] (results, error) in
            if let error = error {
                NSLog("%@", error)
            } else if let results = results where results.count > 0 {
                self.resultsLabel.text = results[0].name
            } else {
                self.resultsLabel.text = "No results"
            }
        }
    }

}
