// 
//  APHWeeklyTaskViewController.m 
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
 
#import "APHWeeklyTaskViewController.h"
#import "APHConstants.h"

@implementation APHWeeklyTaskViewController

- (NSString*) createResultSummary
{
    NSMutableDictionary * dictionary = [NSMutableDictionary dictionary];
    
    {//Steroid 1 Step
        ORKBooleanQuestionResult *result = (ORKBooleanQuestionResult *)[self answerForSurveyStepIdentifier:kSteroid1StepIdentifier];
        if ([result booleanAnswer]) {
            dictionary[kSteroid1Key] = [result booleanAnswer];
        }

    }
    {//Steroid 2 Step
        ORKBooleanQuestionResult *result = (ORKBooleanQuestionResult *)[self answerForSurveyStepIdentifier:kSteroid2StepIdentifier];
        if ([result booleanAnswer]) {
            dictionary[kSteroid2Key] = [result booleanAnswer];
        }
    }    
    {//Side Effect Step
        ORKChoiceQuestionResult *result = (ORKChoiceQuestionResult *)[self answerForSurveyStepIdentifier:kSideEffectStepIdentifier];
        
        if ([[result choiceAnswers]firstObject]) {
            dictionary[kSideEffectKey] = [[result choiceAnswers]firstObject];
        }
    }
    
    {//Miss Work Step
        ORKBooleanQuestionResult *result = (ORKBooleanQuestionResult *) [self answerForSurveyStepIdentifier:kMissWorkStepIdentifier];
        if ([result booleanAnswer]) {
            dictionary[kMissWorkKey] = [result booleanAnswer];
        }
    }
    {//Days Missed Step
        ORKChoiceQuestionResult *result = (ORKChoiceQuestionResult *) [self answerForSurveyStepIdentifier:kDaysMissedStepIdentifier];
        if ([result choiceAnswers]) {
            NSArray *choiceAnswers = result.choiceAnswers ? result.choiceAnswers : [NSArray new];
            
            if (choiceAnswers.count >0) {
                for (NSString *day in choiceAnswers) {
                    NSString *keyString = [kDaysMissedKey stringByAppendingFormat:@"%@",day];
                    dictionary[keyString] = @"1";
                }
            }
        }
    }
    {//Limitations Step
        ORKBooleanQuestionResult *result = (ORKBooleanQuestionResult *) [self answerForSurveyStepIdentifier:kLimitationsStepIdentifier];
        if ([result booleanAnswer]) {
            dictionary[kLimitationsKey] = [result booleanAnswer];
        }
    }
    {//Limitations Days Step
        ORKNumericQuestionResult *result = (ORKNumericQuestionResult *) [self answerForSurveyStepIdentifier:kLimitationsDaysStepIdentifier];
        if ([result numericAnswer]) {
            dictionary[kLimitationsDaysKey] = [result numericAnswer];

        }
    }
    {//Asthma Doc Visit Step
        ORKBooleanQuestionResult *result = (ORKBooleanQuestionResult *) [self answerForSurveyStepIdentifier:kAsthmaDocVisitStepIdentifier];
        if ([result booleanAnswer]) {
            dictionary[kAsthmaDocVisitKey] = [result booleanAnswer];
        }
    }
    {//Emergency Room Step
        ORKBooleanQuestionResult *result = (ORKBooleanQuestionResult *) [self answerForSurveyStepIdentifier:kEmergencyRoomStepIdentifier];
        if ([result booleanAnswer]) {
            dictionary[kEmergencyRoomVisitKey] = [result booleanAnswer];
        }
    }
    {//Admission Step
        ORKBooleanQuestionResult *result = (ORKBooleanQuestionResult *) [self answerForSurveyStepIdentifier:kAdmissionStepIdentifier];
        if ([result booleanAnswer]) {
            dictionary[kHospitalAdmissionKey] = [result booleanAnswer];
        }
    }
    return [dictionary JSONString];
}

- (ORKResult *) answerForSurveyStepIdentifier: (NSString*) identifier
{
    NSArray * stepResults = [(ORKStepResult*)[self.result resultForIdentifier:identifier] results];
    ORKStepResult *answer = (ORKStepResult *)[stepResults firstObject];
    return answer;
}

- (void) processTaskResult
{
    [super processTaskResult];
    
    [self redoMedicationSurvey];
}

- (void) redoMedicationSurvey {
    ORKBooleanQuestionResult *steroid1Answer = (ORKBooleanQuestionResult *)[self answerForSurveyStepIdentifier:kSteroid1StepIdentifier];
    ORKChoiceQuestionResult *sideEffectsAnswer = (ORKChoiceQuestionResult *)[self answerForSurveyStepIdentifier:kSideEffectStepIdentifier];
    
    if ([[steroid1Answer booleanAnswer] integerValue] == 1 || [@"3" isEqualToString:[[sideEffectsAnswer choiceAnswers] firstObject]] ) {
        
        NSPredicate *medicationTask = [NSPredicate predicateWithFormat: @"%K contains %@",
                                       NSStringFromSelector(@selector(taskID)),
                                       @"AsthmaMedication"];
        
        NSDate *today = [NSDate date];
        [[APCScheduler defaultScheduler] fetchTaskGroupsFromDate: today
                                                          toDate: today
                                          forTasksMatchingFilter: medicationTask
                                                      usingQueue: [NSOperationQueue mainQueue]
                                                 toReportResults: ^(NSDictionary *todaysMedicationSurveyGroups, NSError * __unused queryError)
         {
             BOOL shouldNotifyUser = YES;
             if(todaysMedicationSurveyGroups.count == 0) {
                 shouldNotifyUser = [self rescheduleMedicationSurvey:medicationTask];
             }
             
             if (shouldNotifyUser) {
                 UIAlertView *alertView = [[UIAlertView alloc] initWithTitle: NSLocalizedString(@"REDO_MEDICATION_SURVEY_TITLE", @"")
                                                                     message: NSLocalizedString(@"REDO_MEDICATION_SURVEY_MSG", @"")
                                                                    delegate: nil
                                                           cancelButtonTitle: NSLocalizedString(@"REDO_MEDICATION_SURVEY_CANCEL", @"")
                                                           otherButtonTitles: nil, nil];
                 [alertView show];
             }
         }];
    }
    
    
}

-(BOOL) rescheduleMedicationSurvey: (NSPredicate *) medicationTaskPredicate {
    APCTask *medicationTask = [self findMedicationTask:medicationTaskPredicate];
    
    BOOL saved = NO;
    if (medicationTask)
    {
        NSManagedObjectContext *context = self.appDelegate.scheduler.managedObjectContext;
        
        NSDate *today = [NSDate date];
        APCSchedule *schedule   = [APCSchedule newObjectForContext: context];
        schedule.scheduleSource = @(APCScheduleSourceWeekly);
        schedule.createdAt = today;
        schedule.expires = @"P165D";
        schedule.scheduleType = @"once";
        schedule.startsOn = today.startOfDay;
        schedule.maxCount = nil;
        schedule.reminderOffset = nil;
        schedule.effectiveStartDate = [schedule computeDelayedStartDateFromDate: schedule.startsOn];
        schedule.effectiveEndDate = [schedule computeExpirationDateForScheduledDate: schedule.startsOn];
        [schedule addTasksObject:medicationTask];
        
        NSError *errorSavingSchedule = nil;
        saved = [schedule saveToPersistentStore: &errorSavingSchedule];
        
        APCLogError2(errorSavingSchedule);
    }
    
    return saved;
}

-(APCTask*) findMedicationTask: (NSPredicate*) medicationTaskPredicate {
    NSManagedObjectContext *context = self.appDelegate.scheduler.managedObjectContext;
    NSFetchRequest *request = [APCTask requestWithPredicate: medicationTaskPredicate];
    NSError *errorFetchingTasks = nil;
    NSArray *tasks = [context executeFetchRequest: request
                                            error: & errorFetchingTasks];
    APCLogError2(errorFetchingTasks);
    
    if  (tasks.count == 0){
        return nil;
    } else {
        
        NSArray *sortedTasksByVersion = [tasks sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            NSNumber *first = ((APCTask*) obj1).taskVersionNumber;
            NSNumber *second = ((APCTask*) obj2).taskVersionNumber;
            return [first compare:second];
            
        }];
        
        return [sortedTasksByVersion objectAtIndex:0];
    }
}

@end
