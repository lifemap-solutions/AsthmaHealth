//
//  APHAirQualityDataModel.m 
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
 
#import "APHAirQualityDataModel.h"
#import "APHTableViewDashboardAQAlertItem.h"//aqiObject

@import APCAppCore;
static NSString * kLatitudeKey              = @"latitude";
static NSString * kLongitudeKey             = @"longitude";
static NSString * kLifemapURL               = @"https://alerts.lifemap-solutions.com";
static NSString * kAlertGetJson             = @"/alert/get_aqi.json";
static NSString * kItemName                 = @"Air Quality Report";

@interface APHAirQualityDataModel ()
@property (nonatomic, strong)   SBBNetworkManager       *networkManager;
@property (nonatomic, strong)   NSMutableDictionary     *aqiResponse;
@end

@implementation APHAirQualityDataModel

-(id)init{
    self = [super init];
    if (self) {
        self.aqiObject = [APHTableViewDashboardAQAlertItem new];
        _networkManager = [[SBBNetworkManager alloc] initWithBaseURL:kLifemapURL];
    }
    return self;
}

#pragma mark prepare dictionaries

-(void) prepareDictionaries:(float)longitude latitude:(float)latitude
{
    
    //initialize a new uploader as this model is a global variable
    self.uploader = [[APCDataUploader alloc] initWithUploadReference:kItemName];
    
    if (self.aqiResponse.count > 0 && [self.aqiResponse objectForKey:@"results"]) {
        NSDictionary *results = [self.aqiResponse objectForKey:@"results"];
        //do we actually have air quality reports, not just a reporting area?
        if ([results objectForKey:@"reports"] && ![[results objectForKey:@"reporting_area"] isKindOfClass:[NSNull class]]) {
            
            [self insertIntoZipArchive:results filename:@"aqiResponse"];
            
            NSMutableDictionary *latLongDictionary = [[NSMutableDictionary alloc]init];
            [latLongDictionary setObject:[NSNumber numberWithFloat:latitude] forKey:kLatitudeKey];
            [latLongDictionary setObject:[NSNumber numberWithFloat:longitude] forKey:kLongitudeKey];
            
            if (latLongDictionary.count > 0) {
                [self insertIntoZipArchive:latLongDictionary filename:@"latlong"];
            }
            
            //when done adding files, call uploadWithCompletion
            [self.uploader uploadWithCompletion:^
             
             {
                 APCLogDebug(@"Air Quality Data was uploaded successfully");
                 
             }];
        }
    }
}

- (void) fetchData:(float)longitude latitude:(float)latitude
{
    self.aqiResponse = [[NSMutableDictionary alloc]init];
    
    __weak APHAirQualityDataModel *weakSelf = self;
    
    if (!self.isFetchingData) {
        self.isFetchingData = YES;
        //Make Network call for Air Quality in block
        [self.networkManager get:kAlertGetJson headers:nil parameters:@{@"lat":@(latitude),@"lon":@(longitude)} completion:^(NSURLSessionDataTask __unused *task, id responseObject, NSError *error) {
            APCLogError2(error);
            weakSelf.isFetchingData = NO;
            if (!error) {
                weakSelf.aqiObject.aqiDictionary = responseObject;
                //TODO:Remove logging
                NSLog(@"AQI Response : %@", [self jsonStringWithPrettyPrint:responseObject prettyPrint:YES]);
                weakSelf.aqiResponse = [[NSMutableDictionary alloc]initWithDictionary:responseObject];
                
                //send notification for [APHDashboardViewController to prepareData];
                APCLogEventWithData(kAnalyticsNetworkEvent, (@{
                                                      @"event_detail" : @"Received Air Quality Info from Server"
                                                      }));
                
                //sends a new AQIAlert to the dashboard. The dashboard should receive it on the main thread.
                dispatch_async(dispatch_get_main_queue(), ^{
                    __strong typeof(weakSelf) strongSelf = self;
                    if ([strongSelf.airQualityReportReceiver respondsToSelector:@selector(airQualityModel:didDeliverAirQualityAlert:)]) {
                        [strongSelf.airQualityReportReceiver airQualityModel:weakSelf didDeliverAirQualityAlert:strongSelf.aqiObject];
                    }
                    
                    //prepare the data to upload
                    [strongSelf prepareDictionaries:longitude latitude:latitude];
                });
            } else {
                APCLogError2(error);
            }
        }];
    }
}

-(NSString*) jsonStringWithPrettyPrint:(NSDictionary*)dict prettyPrint:(BOOL) prettyPrint {
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict
                                                       options:(NSJSONWritingOptions)    (prettyPrint ? NSJSONWritingPrettyPrinted : 0)
                                                         error:&error];
    
    if (! jsonData) {
        NSLog(@"bv_jsonStringWithPrettyPrint: error: %@", error.localizedDescription);
        return @"{}";
    } else {
        return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
}

@end
