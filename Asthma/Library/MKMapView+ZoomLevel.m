//
// http://troybrant.net/blog/2010/01/set-the-zoom-level-of-an-mkmapview/
// http://stackoverflow.com/questions/1636868/is-there-way-to-limit-mkmapview-maximum-zoom-level
//

#import "MKMapView+ZoomLevel.h"

static CGFloat const kMercatorOffset = 268435456;
static CGFloat const kMercatorRadius = 85445659.44705395;



@implementation MKMapView (ZoomLevel)


#pragma mark - Map conversion methods

- (CGFloat)longitudeToPixelSpaceX:(CGFloat)longitude {
    return round(kMercatorOffset + kMercatorRadius * longitude * M_PI / 180.0);
}

- (CGFloat)latitudeToPixelSpaceY:(CGFloat)latitude {
    return round(kMercatorOffset - kMercatorRadius * logf((1 + sinf(latitude * M_PI / 180.0)) / (1 - sinf(latitude * M_PI / 180.0))) / 2.0);
}

- (CGFloat)pixelSpaceXToLongitude:(CGFloat)pixelX {
    return ((round(pixelX) - kMercatorOffset) / kMercatorRadius) * 180.0 / M_PI;
}

- (CGFloat)pixelSpaceYToLatitude:(CGFloat)pixelY {
    return (M_PI / 2.0 - 2.0 * atan(exp((round(pixelY) - kMercatorOffset) / kMercatorRadius))) * 180.0 / M_PI;
}



#pragma mark - Helper methods

- (MKCoordinateSpan)coordinateSpanWithMapView:(MKMapView *)mapView centerCoordinate:(CLLocationCoordinate2D)centerCoordinate andZoomLevel:(NSUInteger)zoomLevel {

    CGFloat centerPixelX = [self longitudeToPixelSpaceX:centerCoordinate.longitude];
    CGFloat centerPixelY = [self latitudeToPixelSpaceY:centerCoordinate.latitude];

    NSInteger zoomExponent = 20 - zoomLevel;
    CGFloat zoomScale = pow(2, zoomExponent);

    CGSize mapSizeInPixels = mapView.bounds.size;
    CGFloat scaledMapWidth = mapSizeInPixels.width * zoomScale;
    CGFloat scaledMapHeight = mapSizeInPixels.height * zoomScale;

    CGFloat topLeftPixelX = centerPixelX - (scaledMapWidth / 2);
    CGFloat topLeftPixelY = centerPixelY - (scaledMapHeight / 2);

    CLLocationDegrees minLng = [self pixelSpaceXToLongitude:topLeftPixelX];
    CLLocationDegrees maxLng = [self pixelSpaceXToLongitude:topLeftPixelX + scaledMapWidth];
    CLLocationDegrees longitudeDelta = maxLng - minLng;

    CLLocationDegrees minLat = [self pixelSpaceYToLatitude:topLeftPixelY];
    CLLocationDegrees maxLat = [self pixelSpaceYToLatitude:topLeftPixelY + scaledMapHeight];
    CLLocationDegrees latitudeDelta = -1 * (maxLat - minLat);

    MKCoordinateSpan span = MKCoordinateSpanMake(latitudeDelta, longitudeDelta);
    return span;
}



#pragma mark - Public methods

- (void)setCenterCoordinate:(CLLocationCoordinate2D)centerCoordinate zoomLevel:(NSUInteger)zoomLevel animated:(BOOL)animated {

    zoomLevel = MIN(zoomLevel, (NSUInteger)28);

    MKCoordinateSpan span = [self coordinateSpanWithMapView:self centerCoordinate:centerCoordinate andZoomLevel:zoomLevel];
    MKCoordinateRegion region = MKCoordinateRegionMake(centerCoordinate, span);

    [self setRegion:region animated:animated];
}



- (CGFloat)zoomLevel {
    MKCoordinateRegion reg=self.region; // the current visible region
    MKCoordinateSpan span=reg.span; // the deltas
    CLLocationCoordinate2D centerCoordinate=reg.center; // the center in degrees
                                                        // Get the left and right most lonitudes
    CLLocationDegrees leftLongitude=(centerCoordinate.longitude-(span.longitudeDelta/2));
    CLLocationDegrees rightLongitude=(centerCoordinate.longitude+(span.longitudeDelta/2));
    CGSize mapSizeInPixels = self.bounds.size; // the size of the display window

    // Get the left and right side of the screen in fully zoomed-in pixels
    CGFloat leftPixel=[self longitudeToPixelSpaceX:leftLongitude];
    CGFloat rightPixel=[self longitudeToPixelSpaceX:rightLongitude];
    // The span of the screen width in fully zoomed-in pixels
    CGFloat pixelDelta = fabs(rightPixel-leftPixel);

    // The ratio of the pixels to what we're actually showing
    CGFloat zoomScale= mapSizeInPixels.width /pixelDelta;
    // Inverse exponent
    CGFloat zoomExponent=log2(zoomScale);
    // Adjust our scale
    return zoomExponent+20;;
}


@end
