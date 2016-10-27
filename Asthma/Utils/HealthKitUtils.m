//
//  HealthKitUtils.m
//  Asthma
//
//  Created by David Coleman on 13/08/2015.
//  Copyright (c) 2015 Apple, Inc. All rights reserved.
//

@import HealthKit;
#import <Foundation/Foundation.h>
#import "HealthKitUtils.h"

@implementation HealthKitUtils

@synthesize supportedQuantityTypeMetricsToQuanityUnitsMap;

+ (id) sharedManager
{
    static HealthKitUtils *sharedMyManager = nil;

    static dispatch_once_t oncePredicate;

    dispatch_once(&oncePredicate, ^{
        sharedMyManager = [[HealthKitUtils alloc] init];
    });
    return sharedMyManager;
}

- (id)init
{
    if (self = [super init]) {
        supportedQuantityTypeMetricsToQuanityUnitsMap = @{
                                                             HKQuantityTypeIdentifierStepCount               : [HKUnit countUnit],
                                                             HKQuantityTypeIdentifierBodyMass                : [HKUnit gramUnitWithMetricPrefix:HKMetricPrefixKilo],
                                                             HKQuantityTypeIdentifierHeight                  : [HKUnit meterUnit],
                                                             HKQuantityTypeIdentifierPeakExpiratoryFlowRate  : [[HKUnit literUnit] unitDividedByUnit:[HKUnit minuteUnit]],
                                                             HKQuantityTypeIdentifierInhalerUsage            : [HKUnit countUnit],
                                                             HKQuantityTypeIdentifierHeartRate               : [HKUnit unitFromString:@"count/min"],
                                                             HKQuantityTypeIdentifierRespiratoryRate         : [HKUnit unitFromString:@"count/min"],
                                                             HKQuantityTypeIdentifierOxygenSaturation        : [HKUnit percentUnit],
                                                             HKQuantityTypeIdentifierActiveEnergyBurned      : [HKUnit calorieUnit],
                                                             HKQuantityTypeIdentifierDistanceCycling         : [HKUnit meterUnit],
                                                             HKQuantityTypeIdentifierFlightsClimbed          : [HKUnit countUnit],
                                                             HKQuantityTypeIdentifierBasalEnergyBurned       : [HKUnit calorieUnit],
                                                             HKQuantityTypeIdentifierDistanceWalkingRunning  : [HKUnit meterUnit]
                                                             };
    }
    return self;
}

- (HKQuantitySample*) createQuantitySampleWithType: (NSString *) quantityTypeIdentifier andValue: (double) value withMetaData:(NSDictionary *)meta {

    HKQuantityType *quantityType = [HKQuantityType quantityTypeForIdentifier:quantityTypeIdentifier];
    HKUnit * unit = supportedQuantityTypeMetricsToQuanityUnitsMap[quantityTypeIdentifier];
    HKQuantity *quantity = [HKQuantity quantityWithUnit:unit doubleValue:value];
    NSDate *now = [NSDate date];

    HKQuantitySample *quantitySample;

    if (meta == nil) {
        quantitySample = [HKQuantitySample quantitySampleWithType:quantityType quantity:quantity startDate:now endDate:now];
    } else {
        quantitySample = [HKQuantitySample quantitySampleWithType:quantityType quantity:quantity startDate:now endDate:now metadata:meta];
    }
    return quantitySample;

}

- (HKQuantitySample*) createQuantitySampleWithType: (NSString *) quantityTypeIdentifier andValue: (double) value
{
    return [self createQuantitySampleWithType: quantityTypeIdentifier andValue:value withMetaData:nil];
}

- (void) saveInHeathKit: (HKHealthStore *) healthStore quantitySamples: (NSArray *) quantitySamples
{
    [healthStore saveObjects:quantitySamples withCompletion:^(BOOL __unused success, NSError *error) {
        NSLog(@"%@",[error localizedDescription]);
    }];
}

@end