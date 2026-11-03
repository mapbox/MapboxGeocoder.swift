import UIKit
import CoreLocation
import Mapbox
import MapboxGeocoder

// A Mapbox access token is required to use the Geocoding API.
// https://www.mapbox.com/help/create-api-access-token/
let MapboxAccessToken = "<# your Mapbox access token #>"

class ViewController: UIViewController, MGLMapViewDelegate {
    
    // MARK: - Variables

    var mapView: MGLMapView!
    var resultsLabel: UILabel!
    var geocoder: Geocoder!
    var geocodingDataTask: URLSessionDataTask?
    var geocodedAnnotation: MGLPointAnnotation?
    
    // MARK: - Setup

    override func viewDidLoad() {
        super.viewDidLoad()

        assert(MapboxAccessToken != "<# your Mapbox access token #>", "You must set `MapboxAccessToken` to your Mapbox access token.")
        
        MGLAccountManager.accessToken = MapboxAccessToken
        mapView = MGLMapView(frame: view.bounds)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.delegate = self
        view.addSubview(mapView)
        
        resultsLabel = UILabel(frame: CGRect(x: 10, y: 20, width: view.bounds.size.width - 20, height: 30))
        resultsLabel.autoresizingMask = .flexibleWidth
        resultsLabel.adjustsFontSizeToFitWidth = true
        resultsLabel.backgroundColor = UIColor.white.withAlphaComponent(0.5)
        resultsLabel.isUserInteractionEnabled = false
        view.addSubview(resultsLabel)
        
        geocoder = Geocoder(accessToken: MapboxAccessToken)
    }

    // MARK: - MGLMapViewDelegate

    func mapView(_ mapView: MGLMapView, regionWillChangeAnimated animated: Bool) {
        geocodingDataTask?.cancel()
    }
    
    func mapView(_ mapView: MGLMapView, regionDidChangeAnimated animated: Bool) {
        geocodingDataTask?.cancel()
        if let geocodedAnnotation = geocodedAnnotation {
            mapView.removeAnnotation(geocodedAnnotation)
            self.geocodedAnnotation = nil
        }
        let options = ReverseGeocodeOptions(coordinate: mapView.centerCoordinate)
        geocodingDataTask = geocoder.geocode(options) { [unowned self] (placemarks, attribution, error) in
            if let error = error {
                NSLog("%@", error)
            } else if let placemarks = placemarks, !placemarks.isEmpty {
                let placemark = placemarks[0]
                self.resultsLabel.text = placemark.qualifiedName
                let annotation = MGLPointAnnotation()
                annotation.coordinate = placemark.location.coordinate
                self.mapView.addAnnotation(annotation)
                self.geocodedAnnotation = annotation
            } else {
                self.resultsLabel.text = "No results"
            }
        }
    }

}
