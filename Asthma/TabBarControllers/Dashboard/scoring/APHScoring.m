//
//  APHScoring.m
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

#import "APHScoring.h"
#import "APHAsthmaBadgesObject.h"

int const kDefaultMinimumMaxStepCount = 10000;
int const kDefaultMaxTookMedicine = 1;
int const kMaxTookMedicineChoice = 4;
NSString *const kDatasetRangeValueKey  = @"datasetRangeValueKey";

@interface APHScoring ()
@property (nonatomic, strong) APCScoring *correlatedScoring;

@end

@implementation APHScoring

- (instancetype)initWithHealthKitQuantityType:(HKQuantityType *)quantityType
                                         unit:(HKUnit *)unit
                                 numberOfDays:(NSInteger)numberOfDays
                               useOriginalMax:(BOOL)useOriginalMax {
    
    self = [self initWithHealthKitQuantityType:quantityType unit:unit numberOfDays:numberOfDays];
    _useOriginalMax = useOriginalMax;
    return self;
}

- (NSNumber *)minimumDataPoint {
    return @0;
}

- (NSNumber *)maximumDataPoint {
    if (self.useOriginalMax) {
        return [super maximumDataPoint];
    } else {
        
        NSNumber *maximuDataPoint = [super maximumDataPoint];
        
        if (self.correlatedScoring){
            maximuDataPoint = [self maximumDataPointInSeries:self.allObjects];
        }
        
        HKQuantityType *hkSteps = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
        
        if ([self.quantityType isEqual:hkSteps]){
            NSNumber *defaultMinMaxStepCount = [NSNumber numberWithInt:kDefaultMinimumMaxStepCount];
            if ([defaultMinMaxStepCount floatValue] > [maximuDataPoint floatValue]){
                maximuDataPoint = defaultMinMaxStepCount;
            }
        } else if(self.valueKey == kTookMedicineKey){
            NSNumber *defaultMaxTookMedicine = [NSNumber numberWithInt:kDefaultMaxTookMedicine];
            maximuDataPoint = defaultMaxTookMedicine;
        }
        
        return maximuDataPoint;
    }
}

- (void)dataIsAvailableFromHealthKit
{
    self.healthKitDataComplete = YES;

    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:APCScoringHealthKitDataIsAvailableNotification
                                                            object:nil];
    });
}

- (void)indexDataSeries:(NSMutableArray *)series{
    
    NSNumber *pointValue = @0;
    NSNumber *minValue = @0;
    NSNumber *maxValue = @0;

    // find the max point value from the series
    for (int i = (int)series.count -1; i >= 0; i--) {
        NSNumber *checkPointValue = [series[i] valueForKey:kDatasetValueKey];
        if (![checkPointValue  isEqual: @(NSNotFound)]) {
            pointValue = checkPointValue;
            if (maxValue.floatValue < pointValue.floatValue){
                maxValue = pointValue;
            }
        }
    }
    
    // set the range point value for each element
    for (NSUInteger i = 0; i < series.count; i++) {
        NSNumber *dataPoint = [(NSDictionary *)[series objectAtIndex:i] valueForKey:kDatasetValueKey];
        if (![dataPoint isEqual: @(NSNotFound)]) {
            NSMutableDictionary *dictionary = [[series objectAtIndex:i] mutableCopy];
            APCRangePoint *point = [[APCRangePoint alloc]initWithMinimumValue:minValue.floatValue
                                                                 maximumValue:maxValue.floatValue];
            
            [dictionary setValue:point forKey:kDatasetRangeValueKey];
            [series replaceObjectAtIndex:i withObject:dictionary];
        }
    }
    
}

- (NSNumber *)maximumDataPointInSeries:(NSArray *)series
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K <> %@", kDatasetValueKey, @(NSNotFound)];
    
    NSArray *filteredArray = [series filteredArrayUsingPredicate:predicate];
    NSArray *rangeArray = [filteredArray valueForKey:kDatasetRangeValueKey];
    NSPredicate *rangePredicate = [NSPredicate predicateWithFormat:@"SELF <> %@", [NSNull null]];
    
    NSArray *rangePoints = [rangeArray filteredArrayUsingPredicate:rangePredicate];
    
    NSNumber *maxValue = @0;
    
    if (rangePoints.count != 0) {
        maxValue = [rangeArray valueForKeyPath:@"@max.maximumValue"];
    } else {
        maxValue = [filteredArray valueForKeyPath:@"@max.datasetValueKey"];
    }
    
    return maxValue ? maxValue : @0;
}


- (CGFloat)maximumValueForLineGraph:(APCLineGraphView *) __unused graphView
{
    CGFloat maxValue = 0;
    if (self.correlatedScoring
        && [self.correlatedScoring maximumDataPoint].floatValue > 0){
        maxValue = (self.customMaximumPoint == CGFLOAT_MAX) ? [[self.correlatedScoring maximumDataPoint] doubleValue] : self.customMaximumPoint;
    }else{
        maxValue = [super maximumValueForLineGraph:graphView];
    }
    
    return maxValue;
}


- (CGFloat)minimumValueForLineGraph:(APCLineGraphView *) __unused graphView
{
    CGFloat minValue = 0;
    if (self.correlatedScoring &&
        [self.correlatedScoring maximumDataPoint].floatValue > 0){
        
        CGFloat factor = 0.2;
        CGFloat maxDataPoint = (self.customMaximumPoint == CGFLOAT_MAX) ? [[self.correlatedScoring maximumDataPoint] doubleValue] : self.customMaximumPoint;
        CGFloat minDataPoint = (self.customMinimumPoint == CGFLOAT_MIN) ? [[self.correlatedScoring minimumDataPoint] doubleValue] : self.customMinimumPoint;
        
        minValue = (minDataPoint - factor*maxDataPoint)/(1-factor);
        
    }else{
        minValue = [super minimumValueForLineGraph:graphView];
    }
    
    return minValue;
}

- (CGFloat)maximumValueForLineGraphLeftYAxis:(APCLineGraphView *)graphView{
    return [super maximumValueForLineGraph:graphView];
}


- (CGFloat)minimumValueForLineGraphLefttYAxis:(APCLineGraphView *)graphView{
    return [super minimumValueForLineGraph:graphView];
}


- (CGFloat)lineGraph:(APCLineGraphView *) __unused graphView plot:(NSInteger)plotIndex valueForPointAtIndex:(NSInteger) pointIndex
{
    CGFloat value;
    if (self.correlatedScoring){
        if (plotIndex == 0){ // correlating
            
            NSDictionary *dataSet = [self.allObjects objectAtIndex:pointIndex];
            CGFloat plotIndex0Value = [[dataSet valueForKey:kDatasetValueKey] doubleValue];
            APHLineGraphView *lineGraphView = (APHLineGraphView *)graphView;
            value = plotIndex0Value;
        
            if (plotIndex0Value != NSNotFound){
                
                if ([self.valueKey isEqualToString:kTookMedicineKey]){
                    plotIndex0Value = [self tookMedicinePointValue:plotIndex0Value];
                } else {
                    plotIndex0Value = plotIndex0Value ? : 0.01; // since we need to plot zero values
                                                                // and zeros are not added to graph datapoints
                }
                
                CGFloat rate = plotIndex0Value / self.maximumDataPoint.doubleValue;
                value = lineGraphView.maximumValue * rate;
                if (!value){
                    value = NSNotFound;
                }
            }
            
        }else{ // correlated
            
            NSDictionary *dataSet = [self.correlatedScoring.allObjects objectAtIndex:pointIndex];
            CGFloat plotIndex1Value = [[dataSet valueForKey:kDatasetValueKey] doubleValue];
            
            value = plotIndex1Value;
            if (plotIndex1Value != NSNotFound){
                if ([self.correlatedScoring.valueKey isEqualToString:kTookMedicineKey]){
                    value = [self tookMedicinePointValue:plotIndex1Value];
                } else {
                    value = value ? : 0.01; // since we need to plot zero values
                                            // and zeros are not added to graph datapoints
                }
            }
        }

    }else{
        value = [super lineGraph:graphView plot:plotIndex valueForPointAtIndex:pointIndex];
    }
    
    return value;
}

- (CGFloat)tookMedicinePointValue:(CGFloat)choiceValue {
    
    CGFloat pointValue = 0.01;  // since we need to plot zero values
                                // and zeros are not added to graph datapoints
   
    if (choiceValue > kMaxTookMedicineChoice){
        return choiceValue;
    }
    
    if (choiceValue == 1){
        pointValue = 1.0;
    }else if (choiceValue == 2){
        pointValue = 0.5;
    }
    
    return pointValue;
}

@end
