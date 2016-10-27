//
//  APHLocationManager.m
//  Asthma 
// 
// Copyright (c) 2015, Icahn School of Medicine at Mount Sinai. All rights reserved. 
// 
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
// 
// 1.  Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
// 
// 2.  Redistributions in binary form must reproduce the above copyright notice, 
// this list of conditions and the following disclaimer in the documentation and/or 
// other materials provided with the distribution. 
// 
// 3.  Neither the name of the copyright holder(s) nor the names of any contributors 
// may be used to endorse or promote products derived from this software without 
// specific prior written permission. No license is granted to the trademarks of 
// the copyright holders even if such marks are included in this software. 
// 
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE 
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL 
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR 
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, 
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE 
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. 
// 
 
#import "APHLocationManager.h"
#import "APHAppDelegate.h"
#import "APHCountryBasedConfig.h"



static NSString * kLocationLastChecked = @"LocationLastChecked";
static NSTimeInterval kCheckInterval = 86400.0; //24 hours



@interface APHLocationManager ()
@property (nonatomic, strong, nullable, readwrite) CLLocation *location;

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic) BOOL runningLocationUpdates;
@end



@implementation APHLocationManager


#pragma mark -

- (id)init {
    self = [super init];

    if (!self) {
        return nil;
    }

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:kLocationLastChecked];

    [self.locationManager startUpdatingLocation];

    return self;
}

- (void)dealloc {
    [self.locationManager stopUpdatingLocation];
}



#pragma mark - Location Manager

- (void)startUpdatingLocation {
    [self.locationManager startUpdatingLocation];
}

- (void)stopUpdatingLocation {
    [self.locationManager stopUpdatingLocation];
}

- (CLLocationManager*) locationManager
{
    if (!_locationManager) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        _locationManager.distanceFilter = kCLDistanceFilterNone;
    }

    return _locationManager;
}

- (void)locationManager:(CLLocationManager *) __unused manager didUpdateLocations:(NSArray *)locations {

    self.location = [locations lastObject];

    NSDate *lastCheckedTime = [[NSUserDefaults standardUserDefaults] objectForKey:kLocationLastChecked] ?: [[APCUtilities firstKnownFileAccessDate] dateByAddingTimeInterval:-kCheckInterval];//force first check but use actual date/time rather than nil for comparison.
    
    NSDate *currentTime = [NSDate date];
    
    if ((([currentTime timeIntervalSinceDate: lastCheckedTime]) >= kCheckInterval)) {
        [[NSUserDefaults standardUserDefaults]setObject:[NSDate new] forKey:kLocationLastChecked];
        [[NSUserDefaults standardUserDefaults]synchronize];
    }
}

- (void)locationManager:(CLLocationManager *) __unused manager didFailWithError:(NSError *)error {
    APCLogError2(error);
    if (error.code == kCLErrorDenied) {
        [self stopUpdatingLocation];
    }
}

- (void)locationManager:(CLLocationManager *) __unused manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if (status == kCLAuthorizationStatusAuthorizedAlways || status == kCLAuthorizationStatusAuthorizedWhenInUse) {
        [self startUpdatingLocation];
    }
}

@end
