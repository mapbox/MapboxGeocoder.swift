import UIKit
import MapKit
import CoreLocation
import MapboxGeocoder

// A Mapbox access token is required to use the Geocoding API.
// https://www.mapbox.com/help/create-api-access-token/
let MapboxAccessToken = "pk.eyJ1IjoiMWVjNSIsImEiOiJyRW5pejBNIn0.JceDoWfuprApnwKdhKA5Ig"
//let MapboxAccessToken = "<# your Mapbox access token #>"

class ViewController: UIViewController, MKMapViewDelegate {
    
    // MARK: - Variables

    var mapView: MKMapView!
    var resultsLabel: UILabel!
    var geocoder: Geocoder!
    var geocodingDataTask: NSURLSessionDataTask?
    
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
        
        geocoder = Geocoder(accessToken: MapboxAccessToken)
    }

    // MARK: - MKMapViewDelegate

    func mapView(mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        geocodingDataTask?.cancel()
    }
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        geocodingDataTask?.cancel()
        let options = ReverseGeocodeOptions(coordinate: mapView.centerCoordinate)
        geocodingDataTask = geocoder.geocode(options: options) { [unowned self] (placemarks, attribution, error) in
            if let error = error {
                NSLog("%@", error)
            } else if let placemarks = placemarks where !placemarks.isEmpty {
                self.resultsLabel.text = placemarks[0].qualifiedName
            } else {
                self.resultsLabel.text = "No results"
            }
        }
    }

}
