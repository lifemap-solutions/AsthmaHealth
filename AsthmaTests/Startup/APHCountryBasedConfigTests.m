//
//  APHCountryBasedConfigTests.m
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

#import <XCTest/XCTest.h>
#import "APHCountryBasedConfig.h"
#import "APHDashboardEditViewController.h"
#import <APCAppCore/APCUser.h>




@interface APHCountryBasedConfigTests : XCTestCase
@property(nonatomic) APCUser *user;
@property(nonatomic) APHCountryBasedConfig *config;
@end



@implementation APHCountryBasedConfigTests

//- (void)testConfigForUSUser {
//    [self setUpConfig:@"US"];
//    BOOL airQualityAllowed = [self.config airQualityAllowed];
//    XCTAssertTrue(airQualityAllowed);
//    
//    NSArray *dashboardItems = [self.config dashboardItems];
//    XCTAssertEqual([dashboardItems count], 9);
//    XCTAssertEqual([dashboardItems objectAtIndex:0],@(kAPHDashboardItemTypeAsthmaControl));
//    XCTAssertEqual([dashboardItems objectAtIndex:1],@(kAPHDashboardItemTypeAlerts));
//    XCTAssertEqual([dashboardItems objectAtIndex:3],@(kAPHDashboardItemTypeBadges));
//    XCTAssertEqual([dashboardItems objectAtIndex:4],@(kAPHDashboardItemTypeSteps));
//    XCTAssertEqual([dashboardItems objectAtIndex:5],@(kAPHDashboardItemTypeHeartRate));
//    XCTAssertEqual([dashboardItems objectAtIndex:6],@(kAPHDashboardItemTypePeakFlow));
//    XCTAssertEqual([dashboardItems objectAtIndex:7],@(kAPHDashboardItemTypeSleep));
//    XCTAssertEqual([dashboardItems objectAtIndex:8],@(kAPHDashboardItemTypeCorrelation));
//
//    
//    XCTAssertTrue([[self.config countryCode] isEqualToString:@"US"]);
//}
//
//- (void)testConfigForUKUser {
//    [self setUpConfig:@"UK"];
//    BOOL airQualityAllowed = [self.config airQualityAllowed];
//    XCTAssertFalse(airQualityAllowed);
//    
//    NSArray *dashboardItems = [self.config dashboardItems];
//    XCTAssertEqual([dashboardItems count], 8);
//    XCTAssertEqual([dashboardItems objectAtIndex:0],@(kAPHDashboardItemTypeAsthmaControl));
//    XCTAssertEqual([dashboardItems objectAtIndex:2],@(kAPHDashboardItemTypeBadges));
//    XCTAssertEqual([dashboardItems objectAtIndex:3],@(kAPHDashboardItemTypeSteps));
//    XCTAssertEqual([dashboardItems objectAtIndex:4],@(kAPHDashboardItemTypeHeartRate));
//    XCTAssertEqual([dashboardItems objectAtIndex:5],@(kAPHDashboardItemTypePeakFlow));
//    XCTAssertEqual([dashboardItems objectAtIndex:6],@(kAPHDashboardItemTypeSleep));
//    XCTAssertEqual([dashboardItems objectAtIndex:7],@(kAPHDashboardItemTypeCorrelation));
//
//    
//    XCTAssertTrue([[self.config countryCode] isEqualToString:@"UK"]);
//}


#pragma mark - Configuration

- (void)setUp {
    [super setUp];
    [self setUpConfig:nil];
}

- (void)setUpConfig:(NSString *)country {
    self.user = [[APCUser alloc] init];
    self.user.country = country;
    self.config = [[APHCountryBasedConfig alloc] initWithUser:_user];
}



#pragma mark - Tests

- (void)testConfigForUserWithoutCountryDefaultsToUS {
    XCTAssertTrue([self.config airQualityAllowed]);
}

@end
