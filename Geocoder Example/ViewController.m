@import MapKit;
@import CoreLocation;
@import MapboxGeocoder;

#import "ViewController.h"

NSString *const MapboxAccessToken = @"pk.eyJ1IjoianVzdGluIiwiYSI6ImFqZFg3Q0UifQ.C44vLEurzqpLtKJXT6c20g";

@interface ViewController () <MKMapViewDelegate>

#pragma mark -
#pragma mark Variables

@property (nonatomic) MKMapView *mapView;
@property (nonatomic) UILabel *resultsLabel;
//@property (nonatomic) CLGeocoder *geocoder;
@property (nonatomic) MBGeocoder *geocoder;

@end

#pragma mark -

@implementation ViewController

#pragma mark -
#pragma mark Setup


- (void)viewDidLoad {
    [super viewDidLoad];

    self.mapView = [[MKMapView alloc] initWithFrame:self.view.bounds];
    self.mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.mapView.delegate = self;
    [self.view addSubview:self.mapView];

    self.resultsLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 20, self.view.bounds.size.width - 20, 30)];
    self.resultsLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth
    self.resultsLabel.adjustsFontSizeToFitWidth = YES
    self.resultsLabel.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.5];
    self.resultsLabel.userInteractionEnabled = NO;
    [self.view addSubview:self.resultsLabel];

//    self.geocoder = [CLGeocoder new];
    self.geocoder = [[MBGeocoder alloc] initWithAccessToken:MapboxAccessToken];
}

#pragma mark -
#pragma mark MKMapViewDelegate

- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated {
    [self.geocoder cancelGeocode];
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    [self.geocoder cancelGeocode];
    [self.geocoder reverseGeocodeLocation:[[CLLocation alloc] initWithLatitude:self.mapView.centerCoordinate.latitude longitude:self.mapView.centerCoordinate.longitude] completionHandler:^(NSArray *results, NSError *error) {
        if (error) {
            NSLog(@"%@", error);
        } else if (results.count > 0) {
//            self.resultsLabel.text = ((CLPlacemark *)results[0]).name;
            self.resultsLabel.text = ((MBPlacemark *)results[0]).name;
        } else {
            self.resultsLabel.text = @"No results";
        }
    }];
}

@end
