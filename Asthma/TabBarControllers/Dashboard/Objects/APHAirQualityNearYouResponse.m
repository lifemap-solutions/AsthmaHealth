//
//  APHAirQualityNearYourResponse.m
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

#import "APHAirQualityNearYouResponse.h"
@import APCAppCore;



static NSString * kValidDateKey = @"valid_date";
static NSString * kDataTypeKey = @"data_type";

@interface APHAirQualityNearYouResponse ()
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@end



@implementation APHAirQualityNearYouResponse

- (instancetype)initWithResponseDictionary:(NSDictionary *)response {
    self = [super init];

    if (!self) {
        return nil;
    }

    if (![self parseFromResponse:response]) {
        return nil;
    }

    return self;
}

- (NSDateFormatter *)dateFormatter {
    if (!_dateFormatter) {
        _dateFormatter = [NSDateFormatter new];
        _dateFormatter.dateFormat = @"YYYY-MM-dd";
    }

    return _dateFormatter;
}

- (BOOL)parseFromResponse:(NSDictionary *)response {

    if (![response isKindOfClass:[NSDictionary class]]) {
        return false;
    }

    NSDictionary *results = response[@"results"];

    if (![results isKindOfClass:[NSDictionary class]]) {
        return false;
    }


    // parse location

    NSString *reporting_area = results[@"reporting_area"];
    NSString *state_code = results[@"state_code"];
    NSMutableArray *locationArray = [NSMutableArray new];


    if ([reporting_area isKindOfClass:[NSString class]]) {
        [locationArray addObject:reporting_area];
    }

    if ([state_code isKindOfClass:[NSString class]]) {
        [locationArray addObject:state_code];
    }

    if (locationArray.count == 0) {
        return false;
    }

    self.locationName = [locationArray componentsJoinedByString:@", "];


    // parse reports

    NSArray *reports = results[@"reports"];

    if (![reports isKindOfClass:[NSArray class]]) {
        return false;
    }

    NSString * validTodayDateExpected = [self.dateFormatter stringFromDate:[NSDate todayAtMidnight]];
    NSString * validTomorrowDateExpected = [self.dateFormatter stringFromDate:[NSDate tomorrowAtMidnight]];

    NSSortDescriptor *reportDateDescriptor = [[NSSortDescriptor alloc] initWithKey:kValidDateKey ascending:YES];
    NSSortDescriptor *dataTypeDescriptor = [[NSSortDescriptor alloc] initWithKey:kDataTypeKey ascending:NO];

    NSArray *sortDescriptors = [NSArray arrayWithObjects:reportDateDescriptor, dataTypeDescriptor, nil];
    NSArray *sortedReports = [reports sortedArrayUsingDescriptors:sortDescriptors];

    self.todayEntry = [APHAirQualityNearYouResponseEntry new];
    self.tomorrowEntry = [APHAirQualityNearYouResponseEntry new];

    for (NSDictionary *report in sortedReports) {
        if (![report isKindOfClass:[NSDictionary class]]) {
            continue;
        }

        NSString *reportDate = report[kValidDateKey];

        if ([reportDate isEqualToString:validTodayDateExpected]) {
            [self parseReport:report intoEntry:self.todayEntry];
        } else if ([reportDate isEqualToString:validTomorrowDateExpected]) {
            [self parseReport:report intoEntry:self.tomorrowEntry];
        }
    }

    if ([self.todayEntry isEmpty]) {
        self.todayEntry = nil;
    }

    if ([self.tomorrowEntry isEmpty]) {
        self.tomorrowEntry = nil;
    }

    return true;
}

- (void)parseReport:(NSDictionary *)report intoEntry:(APHAirQualityNearYouResponseEntry *)entry {

    NSNumber *value = report[@"aqi_value"];

    if (value == (NSNumber *)[NSNull null]) {
        value = nil;
    }

    if ([report[@"report_type"] isEqualToString:@"OZONE"]) {
        entry.ozone = value;
    }

    else if ([report[@"report_type"] isEqualToString:@"PM2.5"]) {
        entry.smallParticles = value;
    }

    else if ([report[@"report_type"] isEqualToString:@"PM10"]) {
        entry.bigParticles = value;
    }

    else if([report[@"aqi_category"] isEqualToString:@""]) {
        entry.quality = value;
    }
}


//
//
//
////note: dictionaries may contain <null> values
//for (NSDictionary *report in sortedReports) {
//    if ([[report objectForKey:kValidDateKey] isEqualToString:validTodayDateExpected]) {
//
//        if ([[report objectForKey:kReportsTypeKey] isEqualToString:@"OZONE"]) {
//            if (!_ozone || [_ozone  isEqual: @0]) {
//                _ozone = [[report objectForKey:kAQIValueKey] isKindOfClass:[NSNull class]] ? @0 : [report objectForKey:kAQIValueKey];
//            }
//        }
//
//        if ([[report objectForKey:kReportsTypeKey] isEqualToString:@"PM2.5"]) {
//            if (!_PM25 || [_PM25 isEqual:@0]) {
//                _PM25 = [[report objectForKey:kAQIValueKey] isKindOfClass:[NSNull class]] ? @0 : [report objectForKey:kAQIValueKey];
//            }
//        }
//
//        if ([[report objectForKey:kReportsTypeKey] isEqualToString:@"PM10"]) {
//            if (!_PM10 || [_PM10 isEqual:@0]) {
//                _PM10 = [[report objectForKey:kAQIValueKey] isKindOfClass:[NSNull class]] ? @0 : [report objectForKey:kAQIValueKey];
//            }
//        }
//
//        if ([report objectForKey:kReportsTypeKey]) {
//            if (!_airQuality || [_airQuality isEqual:@0]) {
//                _airQuality = [[report objectForKey:kAQICategoryKey] isKindOfClass:[NSNull class]] ? @0 : [report objectForKey:kAQICategoryKey];
//            }
//        }
//
//        NSNumber *pmValue = [report objectForKey:kAQIValueKey] ? [report objectForKey:kAQIValueKey] : @0;
//        if (![pmValue isKindOfClass:[NSNull class]]) {
//            if (NSLocationInRange(pmValue.doubleValue, NSMakeRange(0, 51))) {
//                _alertColor = [UIColor appTertiaryGreenColor];
//            }
//            else if (NSLocationInRange(pmValue.doubleValue, NSMakeRange(51, 150)))
//            {
//                _alertColor = [UIColor appTertiaryYellowColor];
//            }
//            else if (pmValue.doubleValue >=200)
//            {
//                _alertColor = [UIColor appTertiaryRedColor];
//            }
//        }
//    }
//
//    else if ([[report objectForKey:kValidDateKey] isEqualToString:validTomorrowDateExpected]&& [[report objectForKey:kReportDataTypeKey] isEqualToString:@"F"]){
//        //Forecasts
//        if ([[report objectForKey:kReportsTypeKey] isEqualToString:@"OZONE"]) {
//            _ozone_tomorow = [[report objectForKey:kAQIValueKey] isKindOfClass:[NSNull class]] ? @0 : [report objectForKey:kAQIValueKey];
//        }
//        if ([[report objectForKey:kReportsTypeKey] isEqualToString:@"PM2.5"]) {
//            _PM25_tomorrow = [[report objectForKey:kAQIValueKey] isKindOfClass:[NSNull class]] ? @0 : [report objectForKey:kAQIValueKey];
//        }
//        if ([[report objectForKey:kReportsTypeKey] isEqualToString:@"PM10"]) {
//            _PM10_tomorrow = [[report objectForKey:kAQIValueKey] isKindOfClass:[NSNull class]] ? @0 : [report objectForKey:kAQIValueKey];
//        }
//        if ([report objectForKey:kReportsTypeKey]) {
//            _airQuality_tomorrow = [[report objectForKey:kAQICategoryKey] isKindOfClass:[NSNull class]] ? @0 : [report objectForKey:kAQICategoryKey];
//        }
//
//        NSNumber *pmValue = [report objectForKey:kAQIValueKey] ? [report objectForKey:kAQIValueKey] : @0;
//        if (![pmValue isKindOfClass:[NSNull class]]) {
//            if (NSLocationInRange(pmValue.doubleValue, NSMakeRange(0, 51))) {
//                _alertColor_tomorrow = [UIColor appTertiaryGreenColor];
//            }
//            else if (NSLocationInRange(pmValue.doubleValue, NSMakeRange(51, 150)))
//            {
//                _alertColor_tomorrow = [UIColor appTertiaryYellowColor];
//            }
//            else if (pmValue.doubleValue >=200)
//            {
//                _alertColor_tomorrow = [UIColor appTertiaryRedColor];
//            }
//        }
//    }
//}


@end
