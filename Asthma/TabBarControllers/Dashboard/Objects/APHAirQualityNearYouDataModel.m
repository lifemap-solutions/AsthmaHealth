//
//  APHAirQualityNearYouDataModel.m
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

#import "APHAirQualityNearYouDataModel.h"
#import "APHAirQualityNearYouResponse.h"
@import APCAppCore;


static NSTimeInterval kAQICheckInterval     = 60;
static NSString * kAQILastChecked           = @"AQILastChecked";
static NSString * kLifemapURL               = @"https://alerts.lifemap-solutions.com";
static NSString * kAlertGetJson             = @"/alert/get_aqi.json";
static NSString * klifemapCertificateFilename = @"mssm_asthma_public_04092015";
static NSString * kItemName                 = @"Air Quality Report";

static CLLocationDistance kCheckDistance = 5000; // 5km



@interface APHAirQualityNearYouDataModel () <CLLocationManagerDelegate>
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, getter=isFetching) BOOL fetching;

@property (nonatomic, strong) SBBNetworkManager *networkManager;
@property (nonatomic, strong) CLLocation *lastKnownLocation;
@property (nonatomic, strong) APCDataUploader *uploader;
@end



@implementation APHAirQualityNearYouDataModel

- (id)init {
    self = [super init];

    if (self) {
        [self startUpdatingLocation];
        [self clearFlag];
    }

    return self;
}

- (void)dealloc {
    [self stopUpdatingLocation];
}



#pragma mark - Network Manager

- (SBBNetworkManager *)networkManager {
    if (!_networkManager) {
        _networkManager = [[SBBNetworkManager alloc] initWithBaseURL:kLifemapURL];
    }

    return _networkManager;
}

- (void)fetchDataForLocation:(CLLocation *)location {
    self.fetching = true;
 
    NSDictionary *params = @{
                             @"lat": @(location.coordinate.latitude),
                             @"lon": @(location.coordinate.longitude)
                            };

    [self.networkManager get:kAlertGetJson headers:nil parameters:params completion:^(NSURLSessionDataTask *task, id responseObject, NSError *error) {
#pragma unused (task)

        dispatch_async(dispatch_get_main_queue(), ^{
            if (!error) {
                APCLogEventWithData(kNetworkEvent, (@{
                                                      @"event_detail" : @"Received Air Quality Info from Server"
                                                      }));

                [self parse:responseObject];
            } else {
                APCLogError2(error);
            }

            [self markFlag];
            self.fetching = false;
        });
    }];
}

- (void)parse:(NSDictionary *)responseObject {

    NSDictionary *results = [responseObject objectForKey:@"results"];
    //do we actually have air quality reports, not just a reporting area?
    if ([results objectForKey:@"reports"] && ![[results objectForKey:@"reporting_area"] isKindOfClass:[NSNull class]]) {

        [self insertIntoZipArchive:results filename:@"aqiResponse"];

        NSMutableDictionary *latLongDictionary = [[NSMutableDictionary alloc]init];
        [latLongDictionary setObject:[NSNumber numberWithFloat:self.locationManager.location.coordinate.latitude] forKey:@"latitude"];
        [latLongDictionary setObject:[NSNumber numberWithFloat:self.locationManager.location.coordinate.longitude] forKey:@"longitude"];

        if (latLongDictionary.count > 0) {
            [self insertIntoZipArchive:latLongDictionary filename:@"latlong"];
        }

        //when done adding files, call uploadWithCompletion
        [self.uploader uploadWithCompletion:^{
            APCLogDebug(@"Air Quality Data was uploaded successfully");
        }];
    }

    self.response = [[APHAirQualityNearYouResponse alloc] initWithResponseDictionary:responseObject];
    [self.delegate airQuality:self didChangedResponse:self.response];
}

- (BOOL)shouldUpdateModel {
    return [self isFlagOutdated];
}

- (BOOL)isFlagOutdated {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDate *lastCheckedTime = [defaults objectForKey:kAQILastChecked];

    if (!lastCheckedTime) {
        return true;
    }

    return [[NSDate date] timeIntervalSinceDate:lastCheckedTime] >= kAQICheckInterval;
}

- (void)markFlag {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSDate new] forKey:kAQILastChecked];
    [defaults synchronize];
}

- (void)clearFlag {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:kAQILastChecked];
    [defaults synchronize];
}



#pragma mark - Location Manager 

- (void)startUpdatingLocation {
    [self.locationManager startUpdatingLocation];
}

- (void)stopUpdatingLocation {
    [self.locationManager stopUpdatingLocation];
}

- (CLLocationManager*) locationManager {
    if (!_locationManager) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        _locationManager.distanceFilter = kCLDistanceFilterNone;
    }

    return _locationManager;
}

- (void)locationManager:(CLLocationManager *) __unused manager didFailWithError:(NSError *)error {
    APCLogError2(error);

    if (error.code == kCLErrorDenied) {
        [self stopUpdatingLocation];
    }
}

- (void)locationManager:(CLLocationManager *) __unused manager didUpdateLocations:(NSArray *)locations {
    if (self.isFetching) {
        return;
    }

    CLLocation *location = locations.lastObject;

    if (!location) {
        return;
    }

    if (!self.lastKnownLocation) {
        self.lastKnownLocation = location;
        [self fetchDataForLocation:location];
    }
    else if ([self.lastKnownLocation distanceFromLocation:location] > kCheckDistance) {
        self.lastKnownLocation = location;
        [self fetchDataForLocation:location];
    }
    else if ([self shouldUpdateModel]) {
        self.lastKnownLocation = location;
        [self fetchDataForLocation:location];
    }
}


#pragma mark -

- (APCDataUploader *)uploader {
    if (!_uploader) {
        _uploader = [[APCDataUploader alloc] initWithUploadReference:kItemName];
    }

    return _uploader;
}

- (NSString*) pemPath {
    NSString * path = [[NSBundle mainBundle] pathForResource:klifemapCertificateFilename ofType:@"pem"];
    return path;
}


-(void)insertIntoZipArchive:(NSDictionary *)dictionary filename: (NSString *)filename{

    NSData * jsonData;
    if ([NSJSONSerialization isValidJSONObject:dictionary]) {

        //encrypt latlong with special certificate
        if ([filename isEqualToString:@"latlong"]) {
            //encrypt the latLongDictionary before inserting into zip archive
            jsonData = [NSJSONSerialization dataWithJSONObject:dictionary options:NSJSONWritingPrettyPrinted error:nil];
            NSError * encryptionError;
            jsonData = cmsEncrypt(jsonData, [self pemPath], &encryptionError);

            if (!jsonData) {
                APCLogError2(encryptionError);
            } else {
                [self.uploader insertJSONDataIntoZipArchive:jsonData filename:filename];
            }
        } else {
            NSError * serializationError;
            jsonData = [NSJSONSerialization dataWithJSONObject:dictionary options:NSJSONWritingPrettyPrinted error:&serializationError];

            //add jsonData to the archive
            if (jsonData) {
                [self.uploader insertJSONDataIntoZipArchive:jsonData filename:filename];
            }else{
                APCLogDebug(@"serialization error: %@", serializationError.message);
            }
        }
    } else {
        APCLogDebug(@"%@ is not a valid JSON object, attempting to fix...", filename);

        APCDataArchiver *archiver = [[APCDataArchiver alloc]init];
        NSDictionary *newDictionary = [archiver generateSerializableDataFromSourceDictionary:dictionary];
        //recursively call once if we get a validJSONObject
        if ([NSJSONSerialization isValidJSONObject:newDictionary]) {
            [self insertIntoZipArchive:newDictionary filename:filename];
        }
    }
}

@end
