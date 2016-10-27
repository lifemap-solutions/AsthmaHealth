//
//  APHConsent.m
//  Asthma
//
// Copyright (c) 2016, Icahn School of Medicine at Mount Sinai. All rights reserved.
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

#import "APHConsent.h"

@interface APHConsent ()

@property (nonatomic, strong) NSUserDefaults *userDefaults;
@property (nonatomic, strong) NSBundle *bundle;
@property (nonatomic, strong) APCDataSubstrate *dataSubstrate;
@property (nonatomic, strong) APCScheduler *scheduler;
@property (nonatomic, strong) APHAnalytics *analytics;
@property (nonatomic, strong) NSFileManager *fileManager;
@property (nonatomic, assign) BOOL didShowReconsent;
@property (nonatomic, assign) BOOL consentExpired;

@end

@implementation APHConsent

#pragma mark - Convenience Initializers

- (instancetype)initWithScheduler:(APCScheduler *)scheduler dataSubtrate:(APCDataSubstrate *)dataSubstrate analytics:(APHAnalytics *)analytics {
    
    self = [super init];
    if (!self) return nil;
    
    _dataSubstrate = dataSubstrate;
    _scheduler = scheduler;
    _analytics = analytics;
    _bundle = [NSBundle mainBundle];
    _fileManager = [NSFileManager defaultManager];
    
    return self;
}

#pragma mark - Initializers

- (instancetype)initWithScheduler:(APCScheduler *)scheduler dataSubtrate:(APCDataSubstrate *)dataSubstrate analytics:(APHAnalytics *)analytics bundle:(NSBundle *)bundle fileManager:(NSFileManager *)fileManager {
    
    self = [super init];
    if (!self) return nil;
    
    _bundle = bundle;
    _dataSubstrate = dataSubstrate;
    _scheduler = scheduler;
    _analytics = analytics;
    _fileManager = fileManager;
    
    return self;
}

- (BOOL)shouldShowReconsent {
    
    if (self.didShowReconsent == YES) {
        return NO;
    }
    
    self.didShowReconsent = YES; //Set flag to ensure we do not get stuck in a loop. Sometimes querying survey results does not yield results of surveys just completed.
    
    NSString *consentPeriod = [[self.bundle infoDictionary] objectForKey:@"consentPeriod"];
    NSString *reconsentOffset = [[self.bundle infoDictionary] objectForKey:@"reconsentOffset"];
    NSString *reconsentGracePeriod = [[self.bundle infoDictionary] objectForKey:@"reconsentGracePeriod"];
    BOOL showReconsent = NO;
    NSDate *currentDate = [NSDate date];
    
    NSDate *consentDate = [self determineConsentDate];
    
    if (consentDate)
    {
        NSDate *reconsentDate = [[consentDate dateByAddingISO8601Duration:consentPeriod] dateBySubtractingISO8601Duration:reconsentOffset];
        //if consent date is greater than consent period, check reconsent survey responses
        if ([currentDate isLaterThanDate:reconsentDate]) { //We use an offset of the expiration date
            //Show reconsent if they have not already done reconsent
            showReconsent = YES;
        } else {
            showReconsent = NO; //Original conesent date still within initial consent period so no need to show any re-consent
        }
    }
    
    if (showReconsent || !consentDate) //We are past our original consent period, now check if the user has already done a re-consent survey
    {
        //Fetch surveys from local Coredata in descending order so we get most recently completed ones first
        NSArray *results = [self reconsentResults];
        BOOL answer = NO;
        BOOL reconsentFound = NO;
        
        if (results && [results count] > 0) {
            
            APCResult *result = results.firstObject; //Get last completed reconsent survey
            APCScheduledTask *task = result.scheduledTask;
            if (task) {
                reconsentFound = YES;
                answer = [self hasReconsentBeenRenewedForResult:result];
                if (answer) {
                    consentDate = task.updatedAt;
                } else {
                    //Get date of previous reconsent as consent date to determine if user is still within consent period
                    // if count is 1 then consentDate is original consent date
                    if ([results count] > 1)
                    {
                        APCResult *prevResult = results[1];
                        APCScheduledTask *prevTask = prevResult.scheduledTask;
                        consentDate = prevTask.updatedAt;
                    }
                }
            }
        }
        
        if (reconsentFound){
            if (answer) {
                NSDate *reconsentDate = [[consentDate dateByAddingISO8601Duration:consentPeriod] dateBySubtractingISO8601Duration:reconsentOffset];
                
                if ([currentDate isLaterThanDate:reconsentDate]){ //We use an offset of the expiration date
                    showReconsent = YES;
                } else {
                    showReconsent = NO;
                }
            } else {
                showReconsent = NO;
                //Check if the date when survey was completed and if the date is past the consentPeriod then expire the consent
                NSDate *consentExpireDate = [consentDate dateByAddingISO8601Duration:consentPeriod];
                
                if ([currentDate isLaterThanDate:consentExpireDate]) { //We use an offset of the expiration date
                    self.consentExpired = YES;
                }
                
            }
        } else {
            showReconsent = YES; //User has not re-consented
        }
    }
    
    //If our last consent date is over reconsentGracePeriod and the user had not opted out already, then trigger study end for user
    NSDate *gracePeriodDate = [consentDate dateByAddingISO8601Duration:reconsentGracePeriod];
    if ([currentDate isLaterThanDate:gracePeriodDate]) {
        showReconsent = NO;
        
        if ([self.dataSubstrate.currentUser isConsented])
        {
            [self.analytics logMessage:(@{kAnalyticsEventKey : kAnalyticsConsentExpired,
                                          @"time" : [self getStringFromDate:[NSDate date]]})];
        }
        
        self.consentExpired = YES;
    }
    
    return showReconsent;
}

- (BOOL)hasConsentExpired {
    [self shouldShowReconsent];
    return self.consentExpired;
}

- (NSDate *)determineConsentDate {
    
    APCUser *user = self.dataSubstrate.currentUser;
    
    if (user.consentSignatureDate) {
        return user.consentSignatureDate;
    }
    
    //For some reason the consent date is nil, so we figure out what it should be
    [self.analytics logMessage:(@{kAnalyticsEventKey : kAnalyticsConsentDateNull})];
    
    NSString *filePath = [[self applicationDocumentsDirectory] stringByAppendingPathComponent:@"db.sqlite"];
    
    if (![self.fileManager fileExistsAtPath:filePath]) {
        return nil;
    }
    
    NSError *error = nil;
    NSDictionary *attributes = [self.fileManager attributesOfItemAtPath:filePath error:&error];
    
    if (error) {
        APCLogError2(error);
        return [[NSDate date] startOfDay];
    }
    
    return [attributes fileCreationDate];
}

/*********************************************************************************/
#pragma mark - Private Helper Methods
/*********************************************************************************/

- (BOOL)hasReconsentBeenRenewedForResult:(APCResult *)result {
    NSLog(@"Survey result = %@", result.resultSummary);
    NSData *resultData = [result.resultSummary dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    NSDictionary *resultDict = [NSJSONSerialization JSONObjectWithData:resultData options:NSJSONReadingAllowFragments error:&error];
    
    BOOL answer = [[resultDict valueForKey:@"reconsented"] boolValue];
    return answer;
}

- (NSArray *)reconsentResults {
    
    NSManagedObjectContext *context = [self.scheduler managedObjectContext];
    NSFetchRequest *request = [APCResult request];
    NSError *error;
    NSArray *results;
    
    request.predicate = [NSPredicate predicateWithFormat:@"scheduledTask.task.taskID == %@", kReconsentTaskID];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"endDate" ascending:NO]];
    //request.fetchLimit = 1; //need to get all so we know how many reconsent periods there have been
    
    results = [context executeFetchRequest:request error:&error];
    if (error) {
        APCLogError2(error);
        return nil;
    }
    
    return results;
}

- (NSString *)applicationDocumentsDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return paths.firstObject;
}

- (NSString *)getStringFromDate:(NSDate *)date
{
    NSDateFormatter * dateformatter=[[NSDateFormatter alloc]init];
    [dateformatter setDateFormat:@"yyyy-MM-dd HH:mm:ss zzz"];
    NSString *dateString = [dateformatter stringFromDate:date];
    
    return dateString;
}

@end
