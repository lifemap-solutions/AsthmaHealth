// 
//  APHDailyTaskViewController.m 
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
 
#import "APHDailyTaskViewController.h"
#import "APHConstants.h"
#import "APHAppDelegate.h"
#import "HealthKitUtils.h"



NSString * const kUseQuickReliefInhalerStepIdentifier = @"use_qr";
NSString * const kGetWorseStepIdentifier = @"get_worse";
NSString * const kGetWorseOtherStepIdentifier = @"get_worse_other";
NSString * const kQuickReliefStepIdentifier = @"quick_relief_puffs";
NSString * const kMedicineTakenStepIdentifier = @"medicine";
NSString * const kNightSymptomsIdentifier = @"night_symptoms";
NSString * const kDaySymptomsIdentifier = @"day_symptoms";
NSString * const kPeakFlowStepIdentifier = @"peakflow";
NSString * const kAnyActivityStepIdentifier = @"any_activity";

NSString * const kDaytimeValue   = @"1";
NSString * const kNighttimeValue = @"2";
NSString * const kMedicineValue  = @"3";

NSString * const kQuickReliefInhalerCountDeviceName  = @"rescue";



// Internal API
@interface ORKQuestionResult ()
- (void)setAnswer:(id)answer;
@end

// Internal API
@interface ORKAnswerFormat ()
- (Class)questionResultClass;
@end



@interface APHDailyTaskViewController () <ORKTaskResultSource>
@property (nullable, nonatomic, strong) APCResult *previousTaskResult;
@end



@implementation APHDailyTaskViewController


#pragma mark - Designed Initializers

- (instancetype)initWithTask:(id<ORKTask>)task taskRunUUID:(NSUUID *)taskRunUUID {

    if (self = [super initWithTask:task taskRunUUID:taskRunUUID]) {
        self.defaultResultSource = self;
    }

    return self;
}


#pragma mark - ORKTaskResultSource

- (ORKStepResult *)stepResultForStepIdentifier:(NSString *)stepIdentifier {

    NSString *keyIdentifier = [self mapIdentifierToJSONKey:stepIdentifier];

    if (!keyIdentifier) {
        NSLog(@"JSON Key not found for stepIdentifier '%@'", stepIdentifier);
        return nil;
    }

    NSDictionary *summary = [self previousResultSummary];
    id answer = summary[keyIdentifier];

    if (!answer) {
        NSLog(@"Result Summary not found for stepIdentifier '%@'", stepIdentifier);
        return nil;
    }

    ORKQuestionStep *step = (ORKQuestionStep *)[self.task stepWithIdentifier:stepIdentifier];
    ORKQuestionResult *result = [[[step.answerFormat questionResultClass] alloc] initWithIdentifier:stepIdentifier];

    answer = [self correctedAnswerFromAnswer:answer forResult:result];
    [result setAnswer:answer];

    return [[ORKStepResult alloc] initWithStepIdentifier:stepIdentifier results:@[ result ]];
}


#pragma mark - Helpers

- (id)correctedAnswerFromAnswer:(id)answer forResult:(ORKQuestionResult *)result {

    if ([result isKindOfClass:[ORKNumericQuestionResult class]] && [answer isEqual:@0]) {
        return nil;
    }

    if ([result isKindOfClass:[ORKChoiceQuestionResult class]]) {

        NSMutableArray *fixedAnswer = [NSMutableArray new];

        if (![answer isKindOfClass:[NSArray class]]) {
            answer = @[ answer ];
        }

        for (id number in answer) {

            if ([number isKindOfClass:[NSString class]]) {
                [fixedAnswer addObject:number];
            } else if ([number respondsToSelector:@selector(stringValue)]) {
                [fixedAnswer addObject:[number stringValue]];
            }
        }

        return [fixedAnswer copy];
    }

    return answer;
}

- (NSString *)mapIdentifierToJSONKey:(NSString *)identifier {
    NSDictionary *identifierMappings = @{
                                         kDaySymptomsIdentifier:               kDaytimeSickKey,
                                         kNightSymptomsIdentifier:             kNighttimeSickKey,
                                         kUseQuickReliefInhalerStepIdentifier: kUseQuickReliefInhalerKey,
                                         kPeakFlowStepIdentifier:              kPeakFlowKey,
                                         kQuickReliefStepIdentifier:           kQuickReliefKey,
                                         kGetWorseStepIdentifier:              kGetWorseKey,
                                         kGetWorseOtherStepIdentifier:         kGetWorseOtherKey,
                                         kAnyActivityStepIdentifier:           kAnyActivityKey,
                                         kMedicineTakenStepIdentifier:         kTookMedicineKey
                                         };

    return identifierMappings[identifier];
}


#pragma mark - Previous Task Result

- (NSDictionary *)previousResultSummary {

    if (!self.previousTaskResult) {
        return @{};
    }

    NSData *data = [self.previousTaskResult.resultSummary dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *resultSummary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];

    return resultSummary ?: @{};
}


- (APCResult *)previousTaskResult {
    if (_previousTaskResult) {
        return _previousTaskResult;
    }

    NSArray *allResults = [self fetchResultsWithTaskIdentifier:self.task.identifier];
    _previousTaskResult = allResults.firstObject;

    return _previousTaskResult;
}

- (NSArray *)fetchResultsWithTaskIdentifier:(NSString *)taskIdentifier {

    NSManagedObjectContext *context = [self appDelegate].dataSubstrate.mainContext;

    NSDate *now = [NSDate date];

    NSPredicate *taskIdPredicate = [NSPredicate predicateWithFormat:@"taskID = %@", taskIdentifier];
    NSPredicate *nonEmptySummaryPredicate = [NSPredicate predicateWithFormat:@"resultSummary != nil"];
    NSPredicate *todayPredicate = [NSPredicate predicateWithFormat:@"endDate >= %@ AND endDate <= %@", [now startOfDay], [now endOfDay]];

    NSFetchRequest * request = [APCResult request];
    request.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[taskIdPredicate, nonEmptySummaryPredicate, todayPredicate]];
    request.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"endDate" ascending:false] ];
    request.fetchLimit = 1;

    NSError *error;
    NSArray *results = [context executeFetchRequest:request error:&error];
    APCLogError2(error);
    
    return results ?: @[];
}



#pragma mark -

- (BOOL)shouldSetQuickReliefPuffs
{
    //if the answer for the "quick_relief_puffs" question has been provided
    {
        ORKNumericQuestionResult *result = (ORKNumericQuestionResult*)[self answerForSurveyStepIdentifier:kQuickReliefStepIdentifier];
        if ([result numericAnswer]) {
            return YES;
        }
    }
    
    //if the answer for the "use_qr" question has been "NO"
    {
        ORKBooleanQuestionResult *result = (ORKBooleanQuestionResult*)[self answerForSurveyStepIdentifier:kUseQuickReliefInhalerStepIdentifier];
        NSNumber *boolAnswer = result.booleanAnswer;
        if (boolAnswer && [boolAnswer boolValue] == NO) {
            return YES;
        }
    }
    
    return NO;
}

- (NSString*) createResultSummary
{
    NSMutableDictionary * dictionary = [NSMutableDictionary dictionary];

    HealthKitUtils * healthKitUtils = [HealthKitUtils sharedManager];
    NSMutableArray * healthKitQuantitySampleUpdates = [NSMutableArray arrayWithCapacity:healthKitUtils.supportedQuantityTypeMetricsToQuanityUnitsMap.count];

    //Quick Relief Puffs
    {
        if ([self shouldSetQuickReliefPuffs]) {
            
            ORKNumericQuestionResult *result = (ORKNumericQuestionResult*)[self answerForSurveyStepIdentifier:kQuickReliefStepIdentifier];
            
            NSNumber *puffs = [result numericAnswer] ? : @0;
            
            dictionary[kQuickReliefKey] = puffs;

            // Add inhaler count to health kit updates
            NSDictionary * healthKitMetaData = @{HKMetadataKeyDeviceName: kQuickReliefInhalerCountDeviceName};
            HKQuantitySample * inhalerPuffQuantitySample = [healthKitUtils createQuantitySampleWithType:HKQuantityTypeIdentifierInhalerUsage andValue: puffs.doubleValue withMetaData:healthKitMetaData];

            [healthKitQuantitySampleUpdates addObject: inhalerPuffQuantitySample];
        }
    }
    
    //medicine taken
    {
        ORKChoiceQuestionResult *result = (ORKChoiceQuestionResult*)[self answerForSurveyStepIdentifier:kMedicineTakenStepIdentifier];
        NSArray *choiceAnswers = result.choiceAnswers;
        if (choiceAnswers.count > 0) {
            NSString *result = choiceAnswers[0];
            
            if (result) {
                dictionary[kTookMedicineKey] = [NSNumber numberWithInteger:result.integerValue];

            }
        }
    }
    
    //day symptoms
    {
        ORKBooleanQuestionResult *result = (ORKBooleanQuestionResult *)[self answerForSurveyStepIdentifier:kDaySymptomsIdentifier];
        
        if ([result booleanAnswer]) {
            dictionary[kDaytimeSickKey] = [result booleanAnswer];
        }
    }
    
    //night symptoms
    {
        ORKBooleanQuestionResult *result = (ORKBooleanQuestionResult *)[self answerForSurveyStepIdentifier:kNightSymptomsIdentifier];
        
        if ([result booleanAnswer]) {
            dictionary[kNighttimeSickKey] = [result booleanAnswer];
        }
    }
    
    //use qr
    {
        ORKBooleanQuestionResult *result = (ORKBooleanQuestionResult*)[self answerForSurveyStepIdentifier:kUseQuickReliefInhalerStepIdentifier];
        NSNumber *boolAnswer = result.booleanAnswer;
        if (boolAnswer) {
            dictionary[kUseQuickReliefInhalerKey] = boolAnswer;
        }
    }
    
    //get worse
    {
        ORKChoiceQuestionResult *result = (ORKChoiceQuestionResult*)[self answerForSurveyStepIdentifier:kGetWorseStepIdentifier];
        NSArray *choiceAnswers = result.choiceAnswers;
        if (choiceAnswers.count > 0) {
            
            NSMutableArray *answers = [NSMutableArray new];
            
            [choiceAnswers enumerateObjectsUsingBlock:^(NSString * _Nonnull answer, __unused NSUInteger idx, __unused BOOL * _Nonnull stop) {
                
                [answers addObject:[NSNumber numberWithInteger:[answer integerValue]]];
            }];
            
            dictionary[kGetWorseKey] = answers;
        }
    }
    
    //get worse other
    {
        ORKTextQuestionResult *result = (ORKTextQuestionResult*)[self answerForSurveyStepIdentifier:kGetWorseOtherStepIdentifier];
        NSString *textAnswer = result.textAnswer;
        if (textAnswer && ![textAnswer isEqualToString:@""]) {
            dictionary[kGetWorseOtherKey] = textAnswer;
        }
    }
    
    //PeakFlow
    {
        ORKNumericQuestionResult *result = (ORKNumericQuestionResult *)[self answerForSurveyStepIdentifier:kPeakFlowStepIdentifier];

        NSNumber * peakFlowValue = [result numericAnswer] ?: @(NO);

        if (peakFlowValue) {
            dictionary[kPeakFlowKey] = peakFlowValue;

            // Add peak flow to health kit updates
            HKQuantitySample * peakFlowQuantitySample = [healthKitUtils createQuantitySampleWithType:HKQuantityTypeIdentifierPeakExpiratoryFlowRate andValue: peakFlowValue.doubleValue];
            [healthKitQuantitySampleUpdates addObject: peakFlowQuantitySample];

        }
    }

    // Save in Healthkit
    if ([healthKitQuantitySampleUpdates count] > 0) {
        HKHealthStore * healthStore = ((APHAppDelegate *)[UIApplication sharedApplication].delegate ).dataSubstrate.healthStore;
        [healthKitUtils saveInHeathKit: healthStore quantitySamples: healthKitQuantitySampleUpdates];
    }

    return [dictionary JSONString];
}


- (ORKResult *)answerForSurveyStepIdentifier:(NSString *)identifier
{
    NSArray * stepResults = [(ORKStepResult*)[self.result resultForIdentifier:identifier] results];
    ORKStepResult *answer = (ORKStepResult *)[stepResults firstObject];
    return answer;
}

@end
