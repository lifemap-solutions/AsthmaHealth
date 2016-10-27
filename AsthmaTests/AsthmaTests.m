//
//  AsthmaTests.m
//  AsthmaTests
//
//  Created by David Coleman on 13/08/2015.
//  Copyright (c) 2015 Apple, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "HealthKitUtils.h"

@interface AsthmaTests : XCTestCase

@end

@implementation AsthmaTests


- (void)testCreateQuantitySampleWithTypePeakFlowUnitType {

    double pealFlowValue = 62.0;
    HKUnit * peakFlowUnit = [[HKUnit literUnit] unitDividedByUnit:[HKUnit minuteUnit]];

    HKQuantitySample * peakFlowQuantitySample = [[HealthKitUtils sharedManager] createQuantitySampleWithType:HKQuantityTypeIdentifierPeakExpiratoryFlowRate andValue: pealFlowValue];

    XCTAssertTrue(peakFlowQuantitySample.metadata==nil);
    XCTAssertTrue([peakFlowQuantitySample.quantity isCompatibleWithUnit: peakFlowUnit]);
}

- (void)testCreateQuantitySampleWithTypeInhalerUsageUnitType {

    double inhalerCount = 2;
    HKUnit * peakFlowUnit = [HKUnit countUnit];

    NSDictionary * healthKitMetaData = @{HKMetadataKeyDeviceName: @"rescue"};
    HKQuantitySample * inhalerQuantitySample = [[HealthKitUtils sharedManager] createQuantitySampleWithType:HKQuantityTypeIdentifierInhalerUsage andValue: inhalerCount withMetaData:healthKitMetaData];

    XCTAssertTrue([inhalerQuantitySample.quantity isCompatibleWithUnit: peakFlowUnit]);
    XCTAssertFalse(inhalerQuantitySample.metadata==nil);

    XCTAssertTrue([inhalerQuantitySample.metadata[HKMetadataKeyDeviceName] isEqualToString: @"rescue"]);
}

@end
