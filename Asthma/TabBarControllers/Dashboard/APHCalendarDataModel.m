//
//  APHCalendarDataModel.m
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

#import "APHCalendarDataModel.h"
#import "APHConstants.h"
static float const kParticipationTrophyThreshold = 0.85;

static NSString *kHadSymptomsBoolean            = @"0";
static NSString *kNoSymptomsBoolean             = @"1";
static NSString *kMissedWorkBoolean             = @"0";
static NSString *kAttendedWorkBoolean           = @"1";
static NSString *kParticipatedBoolean           = @"1";
static NSString *kNoParticipationBoolean        = @"0";
static NSString *kUnansweredSurveyQuestion      = @"";

@implementation APHCalendarDataModel

#pragma mark APHCalendarCollectionViewController delegate
-(void)createComplianceDictionaryForTaskType:(APHCalendarTaskType)task
                                     inMonth:(NSUInteger)month
                                      inYear:(NSUInteger)year
{
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    NSCalendar *gregorian = [[NSCalendar alloc]
                             initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    APCDateRange *dateRange;
    
    if (task == kAPHCalendarTaskTypeParticipation) {
        //should reflect the completion of the Daily Survey and Weekly Survey (when shown)
        
        [comps setDay:1];
        [comps setMonth:month];
        [comps setYear:year];
        
        NSDate *startDate = [gregorian dateFromComponents:comps];
        
        NSRange daysRange = [gregorian rangeOfUnit:NSCalendarUnitDay inUnit:NSCalendarUnitMonth forDate:startDate];
        
        NSInteger endDay = daysRange.length;
        
        [comps setDay:endDay];
        [comps setMonth:month];
        [comps setYear:year];
        NSDate *endDate = [gregorian dateFromComponents:comps];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"taskID == %@ OR taskID == %@", kDailySurveyTaskID, kWeeklySurveyTaskID];
        
        [[APCScheduler defaultScheduler] fetchTaskGroupsFromDate:startDate
                                                          toDate:endDate
                                          forTasksMatchingFilter:predicate
                                                      usingQueue:[NSOperationQueue mainQueue]
                                                 toReportResults:^(NSDictionary *dates, NSError *queryError)
         {
             
             NSMutableDictionary *complianceDictionary = [[NSMutableDictionary alloc]init];
             //iterate over the task groups setting the complianceDictionary
             if (!queryError) {
                 for (NSDate *date in dates) {
                     NSUInteger required = 0;
                     NSUInteger completed = 0;
                     NSArray *tasks = [dates objectForKey:date];
                     for (APCTaskGroup *taskGroup in tasks) {
                         required += [taskGroup requiredRemainingTasks].count + [taskGroup requiredCompletedTasks].count;
                         completed += [taskGroup requiredCompletedTasks].count;
                     }
                     
                     if ([date compare:[NSDate new]] == NSOrderedDescending) {
                         [complianceDictionary setObject:kUnansweredSurveyQuestion forKey:[self dayFromDate:date]];
                     }else if ((float)completed / (float)required > kParticipationTrophyThreshold){
                         [complianceDictionary setObject:kParticipatedBoolean forKey:[self dayFromDate:date]];
                     }else{
                         [complianceDictionary setObject:kNoParticipationBoolean forKey:[self dayFromDate:date]];
                     }
                 }
                 
                 dispatch_async(dispatch_get_main_queue(), ^{
                     [[NSNotificationCenter defaultCenter] postNotificationName:calendarDataSourceDidUpdateComplianceDictionaryNotification object:complianceDictionary];
                 });
                 
             }
         }];
        
    }
    
    if (task == kAPHCalendarTaskTypeAttendance) {
        //get a date range for the month using date components
        [comps setDay:1];
        [comps setMonth:month];
        [comps setYear:year];
        NSDate *startDate = [gregorian dateFromComponents:comps];
        
        //need to include 1 week of following month in retrospective
        [comps setDay:7];
        [comps setMonth:month +1];
        [comps setYear:year];
        NSDate *endDate = [gregorian dateFromComponents:comps];
        
        dateRange = [[APCDateRange alloc]initWithStartDate:startDate endDate:endDate];
        
        NSMutableDictionary *complianceDictionary = [[NSMutableDictionary alloc]init];
        NSArray *scheduledTasks = [self scheduledTasksForDateRange:dateRange survey:kWeeklySurveyTaskID];
        for(APCScheduledTask *scheduledTask in scheduledTasks){
            //need to get to scheduledTasks
            
            //the task startDate is always a Saturday because that's the delivery date.
            //However, the results always relate to the prior week from Sun to Sat
            NSDate *startOn = scheduledTask.startOn;
            
            //Sunday of prior week
            NSDate *priorSunday = [NSDate priorSundayAtMidnightFromDate:startOn];
            
            NSDate *dateToExamine = priorSunday;
            
            //get the weekday corresponding to dateToExamine
            NSDateComponents *dayComponents = [gregorian components:(NSCalendarUnitWeekday) fromDate:dateToExamine];
            NSInteger weekday = [dayComponents weekday];
            NSDateComponents *monthComponents = [gregorian components:(NSCalendarUnitMonth) fromDate:dateToExamine];
            
            while (weekday < 8) {
                //get the result summary for this weekly prompt task
                NSString * resultSummary = scheduledTask.lastResult.resultSummary;
                NSDictionary * dictionary = resultSummary ? [NSDictionary dictionaryWithJSONString:resultSummary] : nil;
                
                //check we're still in the current month
                if ((int)monthComponents.month == (int)month) {
                    NSString *keyString = [kDaysMissedKey stringByAppendingFormat:@"%i", (int)weekday];
                    if (dictionary[keyString]) {//missed work, red == 0
                        [complianceDictionary setObject:kMissedWorkBoolean forKey:[self dayFromDate:dateToExamine]];
                    }else{
                        [complianceDictionary setObject:kAttendedWorkBoolean forKey:[self dayFromDate:dateToExamine]];
                    }
                }
                
                weekday++;
                dateToExamine = [dateToExamine dateByAddingDays:1];
                monthComponents = [gregorian components:(NSCalendarUnitMonth) fromDate:dateToExamine];
            }
        }
        
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:calendarDataSourceDidUpdateComplianceDictionaryNotification object:complianceDictionary];
        });
        
    }
    
    if (task == kAPHCalendarTaskTypeFreeNights || task == kAPHCalendarTaskTypeFreeDays
        || task == kAPHCalendarTaskTypeMedicationAdherence) {
        
        //get a date range for the month using date components
        [comps setDay:1];
        [comps setMonth:month];
        [comps setYear:year];
        NSDate *startDate = [gregorian dateFromComponents:comps];
        
        [comps setDay:31];
        [comps setMonth:month];
        [comps setYear:year];
        NSDate *endDate = [gregorian dateFromComponents:comps];
        
        dateRange = [[APCDateRange alloc]initWithStartDate:startDate endDate:[endDate endOfDay]];
        
        if (task == kAPHCalendarTaskTypeFreeNights) {
            [self dailySurveyDataForRange: dateRange withPredicate:^BOOL(NSDictionary *results) {
                NSNumber *hasNighttimeAsthmaSymptoms = results[kNighttimeSickKey];
                return ![hasNighttimeAsthmaSymptoms boolValue];
            }];
        } else if (task == kAPHCalendarTaskTypeFreeDays) {
            [self dailySurveyDataForRange: dateRange withPredicate:^BOOL(NSDictionary *results) {
                NSNumber *hasDaytimeAsthmaSymptoms = results[kDaytimeSickKey];
                return ![hasDaytimeAsthmaSymptoms boolValue];
            }];
        } else if (task == kAPHCalendarTaskTypeMedicationAdherence) {
            [self dailySurveyDataForRange: dateRange withPredicate:^BOOL(NSDictionary *results) {
                return [results[kTookMedicineKey] isEqualToNumber: [NSNumber numberWithInt:1]];
            }];
        }
        
        
    }
}

#pragma mark - Utility methods

- (void) dailySurveyDataForRange: (APCDateRange*) range withPredicate: (BOOL(^)(NSDictionary *results)) questionPredicate {
    NSMutableDictionary *complianceDictionary = [[NSMutableDictionary alloc]init];
    
    NSArray *scheduledTasks = [self scheduledTasksForDateRange:range survey:kDailySurveyTaskID];
    
    NSDate *startDate = [[APHAsthmaBadgesObject dateForEvaluation] laterDate:range.startDate];
    NSDate *endDate = [range.endDate earlierDate:[NSDate new]];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    while ([startDate compare:endDate] == NSOrderedAscending) {
        
        APCScheduledTask *taskOnDay = [APHAsthmaBadgesObject findScheduledTaskInTasks:scheduledTasks forDate:startDate];
        
        
        if (taskOnDay == nil) {
            if(![calendar isDateInToday:startDate]) {
                [complianceDictionary setObject:kHadSymptomsBoolean forKey:[self dayFromDate:startDate]];
            }
        } else {
            NSString * resultSummary = taskOnDay.lastResult.resultSummary;
            NSDictionary * dictionary = resultSummary ? [NSDictionary dictionaryWithJSONString:resultSummary] : nil;
            
            if(questionPredicate(dictionary)){
                [complianceDictionary setObject:kNoSymptomsBoolean forKey:[self dayFromDate:startDate]];
            } else {
                [complianceDictionary setObject:kHadSymptomsBoolean forKey:[self dayFromDate:startDate]];
            }
        }
        
        startDate = [startDate dateByAddingDays:1];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:calendarDataSourceDidUpdateComplianceDictionaryNotification object:complianceDictionary];
    });
}

- (NSString *)dayFromDate : (NSDate *)date
{
    
    NSCalendar *gregorian = [[NSCalendar alloc]
                             initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    
    NSDateComponents* components = [gregorian components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:date];
    
    return [NSString stringWithFormat:@"%lu", (long)components.day];
}


#pragma mark - Fetch Request
- (NSArray *)scheduledTasksForDateRange: (APCDateRange *)dateRange survey: (NSString *)surveyTaskID
{
    NSArray *scheduledTasks = nil;
    APCAppDelegate *appDelegate = (APCAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"createdAt" ascending:YES];
    NSFetchRequest *request = [APCScheduledTask request];
    [request setShouldRefreshRefetchedObjects:YES];
    NSDate *startDate = dateRange.startDate;
    NSDate *endDate = dateRange.endDate;
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(startOn >= %@) AND (startOn <= %@) AND task.taskID == %@", startDate, endDate, surveyTaskID];
    request.predicate = predicate;
    request.sortDescriptors = @[sortDescriptor];
    
    NSError *error = nil;
    scheduledTasks = [appDelegate.dataSubstrate.mainContext executeFetchRequest:request error:&error];
    APCLogError2(error);
    
    return scheduledTasks;
}

@end
