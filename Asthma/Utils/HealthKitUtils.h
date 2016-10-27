#import <Foundation/Foundation.h>

#import <HealthKit/HealthKit.h>
@interface HealthKitUtils : NSObject {
    NSDictionary *supportedQuantityTypeMetricsToQuanityUnitsMap;;
}

@property (readonly) NSDictionary *supportedQuantityTypeMetricsToQuanityUnitsMap;

+ (id) sharedManager;
- (HKQuantitySample*) createQuantitySampleWithType: (NSString *) quantityTypeIdentifier andValue: (double) value;
- (HKQuantitySample*) createQuantitySampleWithType: (NSString *) quantityTypeIdentifier andValue: (double) value withMetaData: (NSDictionary *) meta;
- (void) saveInHeathKit: (HKHealthStore *) healthStore quantitySamples: (NSArray *) quantitySamples;

@end