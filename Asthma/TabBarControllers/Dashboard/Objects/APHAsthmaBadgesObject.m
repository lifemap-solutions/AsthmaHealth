// 
//  APHAsthmaBadgesObject.m 
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

@import APCAppCore;
#import "APHAsthmaBadgesObject.h"
#import "APHConstants.h"
#import "APHAppDelegate.h"
#import "APHMedicationTaskViewController.h"

NSString *const APHBadgesCalculationsComplete  = @"APHBadgesCalculationsComplete";

static const int maximumWorkDaysInAWeek = 5;
static const int noOfDaysToEvaluate = 27; //28 including today

@interface APHAsthmaBadgesObject ()

@property (nonatomic, strong) NSArray  * dailyScheduledTasks;
@property (nonatomic, strong) NSArray  * weeklyScheduledTasks;
@property (nonatomic, strong) NSArray  * completedDailyScheduledTasks;
@property (nonatomic, strong) NSArray  * completedWeeklyScheduledTasks;

@end


@implementation APHAsthmaBadgesObject

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self calculateAsthmaFullyControlledValue];
        [self performSelectorInBackground:@selector(runBadgeCalculations) withObject:nil];
    }
    return self;
}

-(void) runBadgeCalculations {
    
    [self calculateCompletionValue];
    [self calculateWorkAttendanceValue];
    [self calculateAsthmaFreeDaysAndFreeNightsValues];
    [self calculateMedicationAdherenceValue];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:APHBadgesCalculationsComplete
                                                            object:nil];
    });
    

}


#pragma mark - Data Providers

+ (NSDate*) dateForEvaluation {
    APCUser *user = ((APHAppDelegate *)[UIApplication sharedApplication].delegate).dataSubstrate.currentUser;
    NSDate *inStudySince = user.estimatedConsentDate;
    
    NSDate *daysToEvaluate = [[NSDate new] dateByAddingDays:-noOfDaysToEvaluate];
    
    return [[daysToEvaluate laterDate:inStudySince] startOfDay];
}

- (NSArray *)dailyScheduledTasks
{
    if (!_dailyScheduledTasks) {
        APCAppDelegate *appDelegate = (APCAppDelegate *)[[UIApplication sharedApplication] delegate];
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"startOn" ascending:YES];
        NSFetchRequest *request = [APCScheduledTask request];
        [request setShouldRefreshRefetchedObjects:YES];
        NSDate *startDate = [APHAsthmaBadgesObject dateForEvaluation];
        NSDate *endDate = [NSDate tomorrowAtMidnight];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(startOn >= %@) AND (startOn <= %@) AND generatedSchedule.scheduleString like %@", startDate, endDate, @"0 5 * * *"];
        request.predicate = predicate;
        request.sortDescriptors = @[sortDescriptor];
        
        NSError *error = nil;
        _dailyScheduledTasks = [appDelegate.dataSubstrate.mainContext executeFetchRequest:request error:&error];
        APCLogError2(error);
    }

    return _dailyScheduledTasks;
}

- (NSArray *)completedDailyScheduledTasks
{
    if (!_completedDailyScheduledTasks) {
        _completedDailyScheduledTasks = [self.dailyScheduledTasks filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"completed == %@", @(YES)]];
    }
    return _completedDailyScheduledTasks;
}

-(NSArray *)completedDailyPromptScheduledTasks{
    
    return [self.completedDailyScheduledTasks filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"task.taskID == %@", kDailySurveyTaskID]];
    
}

-(NSArray *)weeklyScheduledTasks{
    
    if (!_weeklyScheduledTasks) {
        APCAppDelegate *appDelegate = (APCAppDelegate *)[[UIApplication sharedApplication] delegate];
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"startOn" ascending:YES];
        NSFetchRequest *request = [APCScheduledTask request];
        [request setShouldRefreshRefetchedObjects:YES];
        NSDate *startDate = [APHAsthmaBadgesObject dateForEvaluation];
        NSDate *endDate = [NSDate tomorrowAtMidnight];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(startOn >= %@) AND (startOn <= %@) AND task.taskID == %@", startDate, endDate, kWeeklySurveyTaskID];
        
        request.predicate = predicate;
        request.sortDescriptors = @[sortDescriptor];
        
        NSError *error = nil;
        _weeklyScheduledTasks = [appDelegate.dataSubstrate.mainContext executeFetchRequest:request error:&error];
        APCLogError2(error);
    }
    
    return _weeklyScheduledTasks;
}

- (NSArray *)completedWeeklyScheduledTasks
{
    
    if (!_completedWeeklyScheduledTasks) {
        _completedWeeklyScheduledTasks = [self.weeklyScheduledTasks filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"completed == %@", @(YES)]];
    }
    return _completedWeeklyScheduledTasks;
    
}

- (void) calculateCompletionValue
{
    
    APCActivitiesDateState *dateState = [[APCActivitiesDateState alloc]init];
    NSUInteger totalActivities = 0;
    NSUInteger completedActivities = 0;
    NSDictionary *dailySurveyState;
    NSDictionary *weeklySurveyState;
    NSDictionary *states;
    
    NSDate *dateToQuery = [APHAsthmaBadgesObject dateForEvaluation];
    NSDate *now = [NSDate new];
    while ([dateToQuery compare:now] == NSOrderedAscending || [dateToQuery compare:[NSDate new]] == NSOrderedSame) {
        states = [dateState activitiesStateForDate:dateToQuery];
        dailySurveyState = [states objectForKey:kDailySurveyTaskID];
        weeklySurveyState = [states objectForKey:kWeeklySurveyTaskID];
        
        //iterate over times in state
        for (NSDate *time in dailySurveyState) {
            if ([[dailySurveyState objectForKey:time] isEqualToNumber:@(YES)]) {
                completedActivities ++;
            }
            totalActivities++;
        }
        
        for (NSDate *time in weeklySurveyState) {
            if ([[weeklySurveyState objectForKey:time] isEqualToNumber:@(YES)]) {
                completedActivities ++;
            }
            totalActivities++;
        }
        
        dateToQuery = [dateToQuery dateByAddingDays:1];
    }
    
    if (totalActivities == 0) {
        _completionValue = 0;
    }else{
        _completionValue = (double)completedActivities/(double)totalActivities;
    }
}

#pragma mark Row Value Calculations
- (void) calculateWorkAttendanceValue
{
    _workAttendanceValue = -1;
    if (self.completedWeeklyScheduledTasks.count > 0) {
        NSArray *uniqueWeeklyTasks = [self uniqueWeeklyScheduledTasks];
        NSUInteger maximumWorkingDays = uniqueWeeklyTasks.count * maximumWorkDaysInAWeek;
        
        int totalMissedDays = 0;
        
        for(APCScheduledTask *completedWeeklyTask in uniqueWeeklyTasks) {
            
            NSString * resultSummary = completedWeeklyTask.lastResult.resultSummary;
            NSDictionary * dictionary = resultSummary ? [NSDictionary dictionaryWithJSONString:resultSummary] : [NSDictionary new];
            NSString *keyString;
            
            int missedDays = 0;
            for (int i = 0; i < 7; i++) {
                keyString = [kDaysMissedKey stringByAppendingFormat:@"%i", i];
                if (dictionary[keyString]) {
                    missedDays++;
                }
            }
            
            if (missedDays > 5) {
                missedDays = 5;
            }
            totalMissedDays += missedDays;
        }
        
        
        
        NSNumber *inferredWorkedDays;
        if (maximumWorkingDays - totalMissedDays > 0) {
            inferredWorkedDays = [NSNumber numberWithLong:(maximumWorkingDays - totalMissedDays)];
        }else{
            inferredWorkedDays = [NSNumber numberWithInt:0];
        }
        
        _workAttendanceValue = (float)inferredWorkedDays.floatValue/(float)maximumWorkingDays;
    }
}

-(NSArray*) uniqueWeeklyScheduledTasks {
    NSMutableDictionary *weeklyTasks = [NSMutableDictionary new];
    for (APCScheduledTask *task in self.completedWeeklyScheduledTasks) {
        if (![weeklyTasks objectForKey:task.createdAt.startOfDay]) {
            [weeklyTasks setObject:task forKey:task.createdAt.startOfDay];
        } else {
            APCScheduledTask *existingTask = [weeklyTasks objectForKey:task.createdAt.startOfDay];
            if ([existingTask.createdAt isEarlierThanDate:task.createdAt]) {
                [weeklyTasks setObject:task forKey:task.createdAt.startOfDay];
            }
        }
    }
    
    return [weeklyTasks allValues];
}


- (void) calculateAsthmaFreeDaysAndFreeNightsValues
{
    NSArray *dailyPromptTasks = [self completedDailyPromptScheduledTasks];
    
    if (dailyPromptTasks.count == 0) {
        _asthmaFreeDaysValue = 0;
        _undisturbedNightsValue = 0;
    }
    else
    {
        NSInteger days = 0;
        NSInteger freeDays = 0;
        NSInteger freeNights = 0;
        
        NSDate *dateToQuery = [APHAsthmaBadgesObject dateForEvaluation];
        NSDate *now  = [NSDate new];
        NSCalendar *calendar = [NSCalendar currentCalendar];
        
        while ([dateToQuery compare:now] == NSOrderedAscending) {
            days++;
            
            APCScheduledTask *task = [APHAsthmaBadgesObject findScheduledTaskInTasks:dailyPromptTasks forDate:dateToQuery];
            
            if (task != nil) {
                NSString * resultSummary = task.lastResult.resultSummary;
                NSDictionary * dictionary = resultSummary ? [NSDictionary dictionaryWithJSONString:resultSummary] : nil;
                
                if ([dictionary[kDaytimeSickKey] isEqualToNumber:@(NO)]) {
                    freeDays ++;
                }
                if ([dictionary[kNighttimeSickKey] isEqualToNumber:@(NO)]) {
                    freeNights ++;
                }
            } else if (task == nil && [calendar isDateInToday:dateToQuery]) {
                days--;
            }

            dateToQuery = [dateToQuery dateByAddingDays:1];
        }
        
        if (days > 0) {
            _asthmaFreeDaysValue = (double)freeDays/(double)days;
            _undisturbedNightsValue = (double)freeNights/(double)days;
        } else {
            _asthmaFreeDaysValue = 0;
            _undisturbedNightsValue = 0;
        }
    }
}

+ (APCScheduledTask*) findScheduledTaskInTasks: (NSArray*) dailyPromptTasks forDate: (NSDate*) date {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(startOn >= %@) AND (startOn < %@)", [date startOfDay], [date endOfDay]];
    
    NSSortDescriptor *createAtAsc = [NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:YES];

    NSArray *foundTasks = [[dailyPromptTasks filteredArrayUsingPredicate:predicate] sortedArrayUsingDescriptors:@[createAtAsc]];
    
    return foundTasks.lastObject;
}

- (void) calculateMedicationAdherenceValue {
    _medicationAdherenceValue = [self calculateMedicationAdherencePercentForStartDate:[APHAsthmaBadgesObject dateForEvaluation] endDate:[NSDate new]];
}

- (void) calculateAsthmaFullyControlledValue
{
    //    < 2 days of daytime symptoms (daily survey)
    NSUInteger maxNumberOfDaytimeSymptoms = 2;
    //    Use of quick relief medicine on < 2 days and < 4 occasions/wk (daily survey)
    NSUInteger maxNumberQuickReliefUsage = 4;
    //    No nocturnal symptoms (daily survey)
    //    No exacerbations (no use of prednisone) (weekly survey, applies to BOTH prednisone questions)
    //    No emergency visits (or hospitalizations, or unscheduled MD visit for asthma)  (weekly survey)
    //    No treatment related side effects (weekly survey)
    
    NSUInteger daytimeSymptoms = 0;
    NSUInteger quickReliefUsage = 0;
    NSUInteger nocturalSymptoms = 0;
    NSUInteger excerbations = 0;
    NSUInteger emergencyVisit = 0;
    NSUInteger relatedSideEffects = 0;
    for (APCScheduledTask * dailyCompletedTask in [self completedDailyScheduledTasksForLast5Days]) {
        NSString * resultSummary = dailyCompletedTask.lastResult.resultSummary;
        NSDictionary * dictionary = resultSummary ? [NSDictionary dictionaryWithJSONString:resultSummary] : nil;
        if ([dictionary[kDaytimeSickKey] boolValue]) {
            daytimeSymptoms ++;
        }
        if ([dictionary[kQuickReliefKey] integerValue]) {
            quickReliefUsage += [dictionary[kQuickReliefKey] integerValue];
        }
        if ([dictionary[kNighttimeSickKey] boolValue]) {
            nocturalSymptoms ++;
        }
    }
    
    if (self.completedWeeklyScheduledTasks.lastObject) {
        APCScheduledTask *weeklyCompletedTask = (APCScheduledTask *)self.completedWeeklyScheduledTasks.lastObject;
        NSString * resultSummary = weeklyCompletedTask.lastResult.resultSummary;
        NSDictionary * dictionary = resultSummary ? [NSDictionary dictionaryWithJSONString:resultSummary] : nil;
        if ([dictionary[kSteroid1Key] boolValue] || [dictionary[kSteroid2Key] boolValue]) {
            excerbations ++;
        }
        if ([dictionary[kEmergencyRoomVisitKey] boolValue] || [dictionary[kHospitalAdmissionKey] boolValue]) {
            emergencyVisit ++;
        }
        if ([dictionary[kSideEffectKey] boolValue]) {
            relatedSideEffects ++;
        }
    }
    
    NSUInteger totalScore = 0;
    NSUInteger userScore  = 0;
    NSUInteger defaultScore = 10;
    
    if (self.completedDailyScheduledTasks.count > 0 || self.completedWeeklyScheduledTasks.count > 0) {
        //    < 2 days of daytime symptoms (daily survey)
        totalScore+=defaultScore;
        userScore = (daytimeSymptoms < maxNumberOfDaytimeSymptoms) ? userScore+defaultScore : userScore;
        
        //    Use of quick relief medicine on < 2 days and < 4 occasions/wk (daily survey)
        totalScore+=defaultScore;
        userScore = (quickReliefUsage < maxNumberQuickReliefUsage) ? userScore+defaultScore : userScore;
        
        //    No nocturnal symptoms (daily survey)
        totalScore+=defaultScore;
        userScore = (nocturalSymptoms == 0) ? userScore+defaultScore : userScore;
        
        //    No exacerbations (no use of prednisone) (weekly survey, applies to BOTH prednisone questions)
        totalScore+=defaultScore;
        userScore = (excerbations == 0) ? userScore+defaultScore : userScore;
        
        //    No emergency visits (or hospitalizations, or unscheduled MD visit for asthma)  (weekly survey)
        totalScore+=defaultScore;
        userScore = (emergencyVisit == 0) ? userScore+defaultScore : userScore;
        
        //    No treatment related side effects (weekly survey)
        totalScore+=defaultScore;
        userScore = (relatedSideEffects == 0) ? userScore+defaultScore : userScore;
    }

    _asthmaFullyControlUserScore = userScore;
    _asthmaFullyControlTotalScore = totalScore;
    
}

- (NSArray*) completedDailyScheduledTasksForLast5Days {
   NSDate *fiveDaysAgo = [NSDate startOfDay:[[NSDate date] dateByAddingDays:-4]];
   NSDate *tmwMidnight = [NSDate tomorrowAtMidnight];

   NSPredicate *last5Days = [NSPredicate predicateWithFormat:@"(startOn >= %@) AND (startOn <= %@)", fiveDaysAgo , tmwMidnight];
    
    return [self.completedDailyScheduledTasks filteredArrayUsingPredicate:last5Days];
}


-(NSUInteger) calculateDaytimeSymptomsForStartDate:(NSDate*)startDate
                                           endDate:(NSDate*)endDate
{
    NSUInteger daytimeSymptoms = 0;
    
    for (APCScheduledTask * dailyCompletedTask in self.completedDailyScheduledTasks) {
        if([dailyCompletedTask.updatedAt isLaterThanOrEqualToDate:startDate] &&
           [dailyCompletedTask.updatedAt isEarlierOrEqualToDate:endDate])
        {
            NSString * resultSummary = dailyCompletedTask.lastResult.resultSummary;
            NSDictionary * dictionary = resultSummary ? [NSDictionary dictionaryWithJSONString:resultSummary] : nil;
            if ([dictionary[kDaytimeSickKey] boolValue]) {
                daytimeSymptoms ++;
            }
        }
    }
    
    return daytimeSymptoms;
}

-(NSUInteger) calculateNightWakingOccurancesForStartDate:(NSDate*)startDate
                                                 endDate:(NSDate*)endDate
{
    NSUInteger nighttimeSymptoms = 0;

    for (APCScheduledTask * dailyCompletedTask in self.completedDailyScheduledTasks) {
        if([dailyCompletedTask.updatedAt isLaterThanOrEqualToDate:startDate] &&
           [dailyCompletedTask.updatedAt isEarlierOrEqualToDate:endDate])
        {
            NSString * resultSummary = dailyCompletedTask.lastResult.resultSummary;
            NSDictionary * dictionary = resultSummary ? [NSDictionary dictionaryWithJSONString:resultSummary] : nil;
            if ([dictionary[kNighttimeSickKey] boolValue]) {
                nighttimeSymptoms ++;
            }
        }
    }

    return nighttimeSymptoms;
}

-(NSUInteger) calculateLimitationsDaysForStartDate:(NSDate*)startDate
                                           endDate:(NSDate*)endDate
{
    NSUInteger limitationsDays = 0;

    for (APCScheduledTask * weeklyCompletedTask in self.completedWeeklyScheduledTasks) {
        if([weeklyCompletedTask.updatedAt isLaterThanOrEqualToDate:startDate] &&
           [weeklyCompletedTask.updatedAt isEarlierOrEqualToDate:endDate])
        {
            NSString * resultSummary = weeklyCompletedTask.lastResult.resultSummary;
            NSDictionary * dictionary = resultSummary ? [NSDictionary dictionaryWithJSONString:resultSummary] : nil;
            if ([dictionary[kLimitationsDaysKey] intValue]) {
                limitationsDays += [dictionary[kLimitationsDaysKey] intValue];
            }
        }
    }

    return limitationsDays;
}


-(NSUInteger) calculateLimitationsForStartDate:(NSDate*)startDate
                                       endDate:(NSDate*)endDate
{
    NSUInteger limitations = 0;

    for (APCScheduledTask * weeklyCompletedTask in self.completedWeeklyScheduledTasks) {
        if([weeklyCompletedTask.updatedAt isLaterThanOrEqualToDate:startDate] &&
           [weeklyCompletedTask.updatedAt isEarlierOrEqualToDate:endDate])
        {
            NSString * resultSummary = weeklyCompletedTask.lastResult.resultSummary;
            NSDictionary * dictionary = resultSummary ? [NSDictionary dictionaryWithJSONString:resultSummary] : nil;
            if ([dictionary[kLimitationsKey] boolValue]) {
                limitations++;
            }
        }
    }

    return limitations;
}

-(NSUInteger) calculateMajorEventsForStartDate:(NSDate*)startDate
                                       endDate:(NSDate*)endDate
{
    NSUInteger majorEvents = 0;

    for (APCScheduledTask * weeklyCompletedTask in self.completedWeeklyScheduledTasks) {
        if([weeklyCompletedTask.updatedAt isLaterThanOrEqualToDate:startDate] &&
           [weeklyCompletedTask.updatedAt isEarlierOrEqualToDate:endDate])
        {
            NSString * resultSummary = weeklyCompletedTask.lastResult.resultSummary;
            NSDictionary * dictionary = resultSummary ? [NSDictionary dictionaryWithJSONString:resultSummary] : nil;
            if ([dictionary[kEmergencyRoomVisitKey] boolValue]) {
                majorEvents ++;
            }
            
            if ([dictionary[kHospitalAdmissionKey] boolValue]) {
                majorEvents ++;
            }
        }
    }

    return majorEvents;
}

-(double) calculateMedicationAdherencePercentForStartDate:(NSDate*)startDate
                                                      endDate:(NSDate*)endDate
{
    NSUInteger adheredDays = 0;
    NSUInteger totalDays = 0;
    
    NSDate *dateFrom = [startDate laterDate:[APHAsthmaBadgesObject dateForEvaluation]];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    while ([dateFrom compare:endDate] == NSOrderedAscending) {
        
        totalDays++;
        
        APCScheduledTask *task = [APHAsthmaBadgesObject findScheduledTaskInTasks:[self completedDailyPromptScheduledTasks] forDate:dateFrom];
        
        NSString * resultSummary = task.lastResult.resultSummary;
        NSDictionary * dictionary = resultSummary ? [NSDictionary dictionaryWithJSONString:resultSummary] : nil;
        
        if ([dictionary[kTookMedicineKey] isEqualToNumber:[NSNumber numberWithInt:1]]) {
            adheredDays ++;
        } else if (task == nil && [calendar isDateInToday:dateFrom]) {
            totalDays --;
        }
        
        dateFrom = [dateFrom dateByAddingDays:1];
    }
    if (totalDays > 0) {
        return (double) adheredDays / totalDays;
    } else {
        return 0;
    }
    
}

-(NSUInteger) calculateRelieverDaysNeededForStartDate:(NSDate*)startDate
                                              endDate:(NSDate*)endDate
{
    NSUInteger quickRelief = 0;

    for (APCScheduledTask * dailyCompletedTask in self.completedDailyScheduledTasks) {
        if([dailyCompletedTask.updatedAt isLaterThanOrEqualToDate:startDate] &&
           [dailyCompletedTask.updatedAt isEarlierOrEqualToDate:endDate])
        {
            NSString * resultSummary = dailyCompletedTask.lastResult.resultSummary;
            NSDictionary * dictionary = resultSummary ? [NSDictionary dictionaryWithJSONString:resultSummary] : nil;
            if ([dictionary[kQuickReliefKey] boolValue]) {
                quickRelief ++;
            }
        }
    }

    return quickRelief;
}

-(NSInteger) calculateDailySurveyCompletedPercentForStartDate:(NSDate*)startDate endDate:(NSDate*)endDate
{
    NSUInteger surveysCompleted = 0;
    NSUInteger totalSurveys = 0;
    NSDateComponents *components;
    
    //ensure that the start date is not prior to user's original consent date, otherwise total survey calculation will be off.
    APCAppDelegate *appDelegate = (APCAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSDate* consentDate = appDelegate.dataSubstrate.currentUser.consentSignatureDate;
    
    NSLog(@"calculateDailySurveyCompletedPercentForStartDate - consentDate = %@", consentDate);
    
    if(consentDate && [consentDate isLaterThanDate:startDate])
    {
        startDate = consentDate;
    }
    
    NSLog(@"calculateDailySurveyCompletedPercentForStartDate - startDate = %@", startDate);
    
    if([endDate isEarlierThanDate:startDate])
    {
        return -1; //No data for that period
    }
    
    for (APCScheduledTask * dailyCompletedTask in self.completedDailyScheduledTasks) {
        if([dailyCompletedTask.task.taskID isEqualToString:kDailySurveyTaskID] && [dailyCompletedTask.updatedAt isLaterThanOrEqualToDate:startDate] &&
           [dailyCompletedTask.updatedAt isEarlierOrEqualToDate:endDate])
        {
            surveysCompleted++;
        }
    }
    
    components = [[NSCalendar currentCalendar] components: NSCalendarUnitDay
                                                 fromDate: startDate toDate: endDate options: 0];
    totalSurveys = [components day] + 1; //1:1 between days and daily surveys, add 1 to account for current day
    
    if(totalSurveys == 0)
    {
        return -1;
    }
    
    NSLog(@"calculateDailySurveyCompletedPercentForStartDate - total daily surveys = %lu", (unsigned long)totalSurveys);
    
    return round((100.0f * surveysCompleted) / totalSurveys);
}

-(NSInteger) calculateWeeklySurveyCompletedPercentForStartDate:(NSDate*)startDate endDate:(NSDate*)endDate
{
    NSUInteger surveysCompleted = 0;
    NSUInteger totalSurveys = 0;
    NSDateComponents *components;
    
    //ensure that the start date is not prior to user's original consent date, otherwise total survey calculation will be off.
    APCAppDelegate *appDelegate = (APCAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSDate* consentDate = appDelegate.dataSubstrate.currentUser.consentSignatureDate;
    
    NSLog(@"calculateWeeklySurveyCompletedPercentForStartDate - consentDate = %@", consentDate);
    
    if(consentDate && [consentDate isLaterThanDate:startDate])
    {
        startDate = consentDate;
    }
    
    NSLog(@"calculateWeeklySurveyCompletedPercentForStartDate - startDate = %@", startDate);
    
    if([endDate isEarlierThanDate:startDate])
    {
        return -1; //No data for that period
    }
    
    for (APCScheduledTask * weeklyCompletedTask in self.completedWeeklyScheduledTasks) {

        if([weeklyCompletedTask.task.taskID isEqualToString:kWeeklySurveyTaskID] && [ weeklyCompletedTask.updatedAt isLaterThanOrEqualToDate:startDate] &&
           [weeklyCompletedTask.updatedAt isEarlierOrEqualToDate:endDate])
        {
            surveysCompleted++;
        }
    }
    
    //Weekly Surveys appear every Saturday. Total number of surveys equals the number of Saturdays in our date range
    while([startDate isEarlierOrEqualToDate:endDate]){
        components = [[NSCalendar currentCalendar] components: NSCalendarUnitWeekday fromDate:startDate];
        NSInteger weekDay = [components weekday];
        if(weekDay == 7){
            totalSurveys++;
        }
        
        startDate = [startDate dateByAddingISO8601Duration:@"P1D"];
    }
    
    if(totalSurveys == 0)
    {
        return -1;
    }
    
    NSLog(@"calculateWeeklySurveyCompletedPercentForStartDate - total weekly surveys = %lu", (unsigned long)totalSurveys);
    
    return round((100.0f * surveysCompleted) / totalSurveys);
}

@end
