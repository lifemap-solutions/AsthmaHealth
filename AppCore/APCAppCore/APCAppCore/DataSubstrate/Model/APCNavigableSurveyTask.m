//
//  APCNavigableSurveyTask.m
//  APCAppCore
//
// Copyright (c) 2015, Apple Inc. All rights reserved.
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

#import <Foundation/Foundation.h>
#import "APCNavigableSurveyTask.h"


#import "APCAppCore.h"

NSString *const cEndOfSurveyMarker          = @"END_OF_SURVEY";

NSString *const cConstraintsKey   = @"constraints";
NSString *const cUiHintKey   = @"uihint";
NSString *const cSliderValue   = @"slider";


@class APCDummyObject;
static APCDummyObject * _dummyObject;

@interface APCDummyObject : NSObject

- (ORKAnswerFormat*) rkBooleanAnswerFormat:(NSDictionary *)objectDictionary;
- (ORKAnswerFormat*) rkDateAnswerFormat:(NSDictionary *)objectDictionary;
- (ORKAnswerFormat*) rkNumericAnswerFormat:(NSDictionary *)objectDictionary;
- (ORKAnswerFormat*) rkTimeIntervalAnswerFormat:(NSDictionary *)objectDictionary;
- (ORKAnswerFormat*) rkChoiceAnswerFormat:(NSDictionary *)objectDictionary;
- (ORKAnswerFormat*) rkTextAnswerFormat:(NSDictionary *)objectDictionary;

@end

@interface APCNavigableSurveyTask () <NSSecureCoding, NSCopying>

@end

@implementation APCNavigableSurveyTask

- (instancetype)initWithIdentifier: (NSString*) identifier survey:(SBBSurvey *)survey
{
    self.survey = survey;
    NSArray * elements = survey.elements;
    NSMutableArray *_navigableOrderedTaskSteps = [NSMutableArray new];
    [elements enumerateObjectsUsingBlock:^(id object, NSUInteger __unused idx, BOOL * __unused stop) {
        
        if ([object isKindOfClass:[SBBSurveyQuestion class]]) {
            SBBSurveyQuestion * obj = (SBBSurveyQuestion*) object;
            [_navigableOrderedTaskSteps addObject:[APCNavigableSurveyTask rkStepFromSBBSurveyQuestion:obj]];
            [self rkSetupNavigationRules:obj];
        }
    }];
    
    self = [super initWithIdentifier:identifier steps:_navigableOrderedTaskSteps];
    
    return self;
}

/*********************************************************************************/
#pragma mark - Setup Navigation Rules for step
/*********************************************************************************/
- (void) rkSetupNavigationRules: (SBBSurveyQuestion*) question
{
    if(question.skipConstraints){
        NSMutableArray *destinationStepIdentifiers = [NSMutableArray new];
        NSMutableArray *compoundPredicates = [NSMutableArray new];
        __block ORKTaskResult *additionalTaskResult = nil;
        
        NSArray* constraints = question.skipConstraints;
        [constraints enumerateObjectsUsingBlock:^(id objId, NSUInteger __unused idx, BOOL * __unused stop) {
            if ([objId isKindOfClass:[SBBSkipSurveyConstraints class]]) {
                SBBSkipSurveyConstraints * constraint = (SBBSkipSurveyConstraints*)objId;
                NSMutableArray *resultPredicates = [NSMutableArray new];
                
                __block ORKQuestionType qType = ORKQuestionTypeNone;
                
                
                if(constraint.parentSurvey && ![constraint.parentSurvey isEqualToString:self.identifier]){
                    additionalTaskResult = [[ORKTaskResult alloc] initWithTaskIdentifier: constraint.parentSurvey
                                                                             taskRunUUID:[NSUUID UUID]
                                                                         outputDirectory:[NSURL fileURLWithPath:NSTemporaryDirectory()]];
                }
                
                //Setup skip logic conditions to use in rule
                NSArray * rules = constraint.skipRules;
                [rules enumerateObjectsUsingBlock:^(id object, NSUInteger __unused idx, BOOL * __unused stop) {
                    if ([object isKindOfClass:[SBBSkipSurveyRule class]]) {
                        SBBSkipSurveyRule * rule = (SBBSkipSurveyRule*)object;
                        NSPredicate *predicate = nil;
                        
                        BOOL isMultiValueType = NO;
                        BOOL allowMultiple = NO;
                        
                        if ([question.constraints isKindOfClass:[SBBMultiValueConstraints class]]) {
                            isMultiValueType = YES;
                            allowMultiple = [[(SBBMultiValueConstraints *)question.constraints allowMultiple] boolValue];
                        }
                        
                        if ([rule.skipType isEqualToString:@"boolean"]) {
                            qType = ORKQuestionTypeBoolean;
                            predicate = [ORKResultPredicate predicateForBooleanQuestionResultWithTaskIdentifier:constraint.parentSurvey resultIdentifier:rule.skipIdentifier expectedAnswer:[rule.skipValue boolValue]];
                        } else if([rule.skipType isEqualToString:@"integer"]){
                            if (isMultiValueType) {
                                qType = allowMultiple ? ORKQuestionTypeMultipleChoice : ORKQuestionTypeSingleChoice;
                                predicate = [ORKResultPredicate predicateForChoiceQuestionResultWithTaskIdentifier:constraint.parentSurvey resultIdentifier:rule.skipIdentifier expectedString:[@(rule.skipValueValue) stringValue]];
                            } else {
                                qType = ORKQuestionTypeInteger;
                                predicate = [ORKResultPredicate predicateForNumericQuestionResultWithTaskIdentifier:constraint.parentSurvey resultIdentifier:rule.skipIdentifier expectedAnswer:rule.skipValueValue];
                            }
                        } else if([rule.skipType isEqualToString:@"minmax"]){
                            qType = ORKQuestionTypeScale;
                            predicate = [ORKResultPredicate predicateForScaleQuestionResultWithTaskIdentifier:constraint.parentSurvey resultIdentifier:rule.skipIdentifier minimumExpectedAnswerValue:rule.skipMinValueValue maximumExpectedAnswerValue:rule.skipMaxValueValue];
                        } else if([rule.skipType isEqualToString:@"other"] && isMultiValueType){
                            qType = allowMultiple ? ORKQuestionTypeMultipleChoice : ORKQuestionTypeSingleChoice;
                            predicate = [ORKResultPredicate predicateForChoiceQuestionResultWithTaskIdentifier:constraint.parentSurvey resultIdentifier:rule.skipIdentifier expectedString:@"Other"];
                        }
                        
                        //In case where the skip logic conditions are not properly defined
                        if (!predicate) {
                            return;
                        }
                        
                        [resultPredicates addObject:predicate];
                        
                        if(additionalTaskResult){
                            //Predicate is for different survey task, so need to load up that task for us to be able to query it
                            NSMutableArray *stepResults = [NSMutableArray new];
                            ORKStepResult * stepResult = [self getStepResult:constraint.parentSurvey identifier:rule.skipIdentifier];
                            if(stepResult){
                                [stepResults addObject:stepResult];
                                
                                additionalTaskResult.results = stepResults;
                            }
                        }
                    }
                }];
                
                //Since we can have multi conditionals we have to use a compound predicate.
                //check operator to see if this rule grouping is and AND/OR type operation
                NSPredicate *compoundPredicate = nil;
                if([constraint.operator isEqualToString:@"or"]){
                    compoundPredicate = [NSCompoundPredicate orPredicateWithSubpredicates:resultPredicates];
                } else {
                    compoundPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:resultPredicates];
                }
                
                [compoundPredicates addObject:compoundPredicate];
                
                //Set destination to skip to if rules evaluate to true
                if([constraint.skipDestination isEqualToString:@"end"]){
                    [destinationStepIdentifiers addObject:ORKNullStepIdentifier];
                } else {
                    [destinationStepIdentifiers addObject:constraint.skipDestination];
                }
                
            }
        }];
        
        //Init rule
        ORKPredicateStepNavigationRule *predicateRule =
        [[ORKPredicateStepNavigationRule alloc] initWithResultPredicates:compoundPredicates
                                              destinationStepIdentifiers:destinationStepIdentifiers
                                                   defaultStepIdentifier:question.destinationIdentifier];
        
        if(additionalTaskResult && additionalTaskResult.results && additionalTaskResult.results.count > 0){
            predicateRule.additionalTaskResults = @[ additionalTaskResult ];
        }
        
        //Set rules for this question. To skip or not
        [self setNavigationRule:predicateRule forTriggerStepIdentifier:question.identifier];
    } else if (question.destinationIdentifier) {
        
        NSString *destinationIdentifier = question.destinationIdentifier;
        
        if([question.destinationIdentifier isEqualToString:@"end"]){
            destinationIdentifier = ORKNullStepIdentifier;
        }
        
        ORKDirectStepNavigationRule *directRule =
        [[ORKDirectStepNavigationRule alloc] initWithDestinationStepIdentifier:question.destinationIdentifier];
        
        [self setNavigationRule:directRule forTriggerStepIdentifier:question.identifier];
    }

}
/*********************************************************************************/
#pragma mark - Conversion of SBBSurvey to ORKTask
/*********************************************************************************/

+ (NSString *) lookUpAnswerFormatMethod: (NSString*) SBBClassName
{
    NSDictionary * answerFormatClass = @{
                                         @"SBBBooleanConstraints"   :   @"rkBooleanAnswerFormat:",
                                         @"SBBDateConstraints"      :   @"rkDateAnswerFormat:",
                                         @"SBBDateTimeConstraints"  :   @"rkDateAnswerFormat:",
                                         @"SBBDecimalConstraints"   :   @"rkNumericAnswerFormat:",
                                         @"SBBDurationConstraints"  :   @"rkTimeIntervalAnswerFormat:",
                                         @"SBBIntegerConstraints"   :   @"rkNumericAnswerFormat:",
                                         @"SBBMultiValueConstraints":   @"rkChoiceAnswerFormat:",
                                         @"SBBTimeConstraints"      :   @"rkDateAnswerFormat:",
                                         @"SBBStringConstraints"    :   @"rkTextAnswerFormat:"
                                         };
    NSAssert(answerFormatClass[SBBClassName], @"SBBClass Not Defined");
    return answerFormatClass[SBBClassName];
}

+ (ORKQuestionStep*) rkStepFromSBBSurveyQuestion: (SBBSurveyQuestion*) question
{
    
    ORKQuestionStep * retStep =[ORKQuestionStep questionStepWithIdentifier:question.identifier title:question.prompt answer:[self rkAnswerFormatFromSBBSurveyConstraints:question.constraints uiHint:question.uiHint]];
    
    retStep.skipSurveyConstraints = question.skipConstraints;

    if (question.promptDetail.length > 0) {
        retStep.text = question.promptDetail;
    }
    
    if (question.promptFontStyle.length > 0) {
        retStep.fontStyle = question.promptFontStyle;
    }
    
    return retStep;
}

+ (ORKAnswerFormat*) rkAnswerFormatFromSBBSurveyConstraints: (SBBSurveyConstraints*) constraints uiHint: (NSString*) hint
{
    ORKAnswerFormat * retAnswer;
    
    if (!_dummyObject) {
        _dummyObject = [[APCDummyObject alloc] init];
    }
    
    NSString * selectorName = [self lookUpAnswerFormatMethod:NSStringFromClass([constraints class])];
    SEL selector = NSSelectorFromString(selectorName);
    
    NSMutableDictionary * objDict = [NSMutableDictionary dictionary];
    objDict[cConstraintsKey] = constraints;
    if (hint.length > 0) {
        objDict[cUiHintKey] = hint;
    }
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    retAnswer = (ORKAnswerFormat*) [_dummyObject performSelector:selector withObject:objDict];
#pragma clang diagnostic pop
    
    return retAnswer;
}

//TODO: Need to modify to be more dynamic. Currently is setup to work for specific condition setup for Medication Survey in the Asthma app layer
// Need to pass in question type and question result class
- (ORKStepResult *) getStepResult : (NSString *)taskIdentifier identifier:(NSString *)stepIdentifier  {
    
    NSManagedObjectContext *context = [[APCScheduler defaultScheduler] managedObjectContext];
    NSFetchRequest * request = [APCResult request];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"endDate" ascending:NO]];
    NSError * error;
    NSArray * results;
    id answer;
    
    @try {
        results = [context executeFetchRequest:request error:&error];
        for (APCResult * result in results) {
            NSLog(@"Summary = %@",result.resultSummary);
            APCScheduledTask* task = result.scheduledTask;
            if(task){
                NSRange  range = [task.task.taskID rangeOfString:@"-"];
                NSString* taskName = [task.task.taskID substringToIndex:range.location];
                if([taskName isEqualToString:taskIdentifier]){
                    NSLog(@"Found medication survey");
                    
                    NSData *resultData = [result.resultSummary dataUsingEncoding:NSUTF8StringEncoding];
                    NSError *error = nil;
                    NSDictionary *resultDict = [NSJSONSerialization JSONObjectWithData:resultData
                                                                               options:NSJSONReadingAllowFragments
                                                                                 error:&error];
                    
                    answer = [resultDict valueForKey:stepIdentifier];
                    break;
                }
            }
        }
        
        ORKQuestionResult *questionResult = [[ORKNumericQuestionResult alloc] init];
        questionResult.identifier = stepIdentifier;
        questionResult.answer = answer;
        questionResult.questionType = ORKQuestionTypeScale;
        
        ORKStepResult *stepResult = [[ORKStepResult alloc] initWithStepIdentifier:stepIdentifier results:@[questionResult]];
        return stepResult;
    }
    @catch ( NSException *e ) {
        APCLogError2(error);
        return nil;
    }
}

- (ORKStep *)stepAfterStep:(ORKStep *)step withResult:(ORKTaskResult *)result {
    
    [self updateAdditionalTaskResults:step];
    
    return [super stepAfterStep:step withResult:result];
}

- (void)updateAdditionalTaskResults:(ORKStep *)step {
    
    if (!step) {
        return;
    }
    
    ORKStepNavigationRule *navigationRule = [self navigationRuleForTriggerStepIdentifier:step.identifier];
    
    if (![navigationRule isKindOfClass:[ORKPredicateStepNavigationRule class]]) {
        return;
    }
    
    ORKPredicateStepNavigationRule *predicateRule = (ORKPredicateStepNavigationRule *)navigationRule;
    
    if (predicateRule.additionalTaskResults.count == 0) {
        return;
    }
    
    for (ORKTaskResult *additionalTaskResult in predicateRule.additionalTaskResults) {
        
        if (additionalTaskResult.results.count == 0) {
            continue;
        }
        
        ORKStepResult *stepResult = additionalTaskResult.results.firstObject;
        NSString *skipIdentifier = [stepResult identifier];
        
        //Updating step result
        ORKStepResult *updatedStepResult = [self getStepResult:additionalTaskResult.identifier identifier:skipIdentifier];
        NSArray *updatedStepResults = updatedStepResult ? @[ updatedStepResult ] : nil;
        additionalTaskResult.results = updatedStepResults;
    }
}

@end
