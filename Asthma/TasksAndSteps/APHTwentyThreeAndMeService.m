//
//  APHTwentyThreeAndMeService.m
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

#import "APHTwentyThreeAndMeService.h"
#import "APHConstants.h"
#import "APHTwentyThreeAndMeTaskViewController.h"

@interface APCScheduler (Private)

- (void) clearTaskGroupCache;

@end

@interface APHTwentyThreeAndMeService ()

@property (nonatomic, strong) APCScheduler *scheduler;
@property (nonatomic, strong) NSManagedObjectContext *context;

@end

@implementation APHTwentyThreeAndMeService

- (instancetype)initWithScheduler:(APCScheduler *)scheduler {
    self = [super init];
    if (!self) return nil;
    
    _scheduler = scheduler;
    
    if (!_scheduler) return nil;
    
    NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    context.parentContext = self.scheduler.managedObjectContext;
    _context = context;
    
    return self;
}

- (void)checkIfSharingTaskIsScheduledForToday:(void (^)(BOOL))completion {
    [self isTaskScheduledForToday:k23andMeTaskId completion:^(BOOL isSharingScheduled) {
        
        if (completion) completion (isSharingScheduled);
    }];
}

- (void)checkIfAnyOf23AndMeTaskIsScheduledForToday:(void (^)(BOOL))completion {
    
    [self isTaskScheduledForToday:k23andMeTaskId completion:^(BOOL isSharingScheduled) {
        
        [self isTaskScheduledForToday:kConsentForGeneticDataSharingTaskId completion:^(BOOL isConsentScheduled) {
            
            if (completion) completion (isSharingScheduled || isConsentScheduled);
        }];
    }];
}

- (BOOL)scheduleSharingTask {
    
    APCTask *task = [self createSharingTask];
    
    if (!task) {
        return NO;
    }
    
    NSDate *today = [NSDate date];
    APCSchedule *schedule = [APCSchedule newObjectForContext:self.context];
    schedule.scheduleSource = @(APCScheduleSourceGenetics);
    schedule.createdAt = today;
    schedule.expires = @"P165D";
    schedule.scheduleType = @"once";
    schedule.startsOn = today.startOfDay;
    schedule.maxCount = nil;
    schedule.reminderOffset = nil;
    schedule.effectiveStartDate = [schedule computeDelayedStartDateFromDate: schedule.startsOn];
    schedule.effectiveEndDate = [schedule computeExpirationDateForScheduledDate: schedule.startsOn];
    [schedule addTasksObject:task];
    
    BOOL saved = NO;
    NSError *errorSavingSchedule = nil;
    saved = [schedule saveToPersistentStore: &errorSavingSchedule];
    APCLogError2(errorSavingSchedule);
    
    if (!errorSavingSchedule) {
        [self.scheduler clearTaskGroupCache];
        
        [[NSNotificationCenter defaultCenter] postNotificationName: APCActivitiesChanged
                                                            object: nil];
    }
    return saved;
}

- (BOOL)rescheduleConsentTask {
    
    APCTask *task = [self findTask:kConsentForGeneticDataSharingTaskId];
    if (!task) {
        return NO;
    }
    
    NSDate *today = [NSDate date];
    APCSchedule *schedule = [APCSchedule newObjectForContext:self.context];
    schedule.scheduleSource = @(APCScheduleSourceLocalDisk);
    schedule.createdAt = today;
    schedule.scheduleType = @"once";
    schedule.startsOn = today.startOfDay;
    schedule.maxCount = nil;
    schedule.reminderOffset = nil;
    schedule.effectiveStartDate = [schedule computeDelayedStartDateFromDate: schedule.startsOn];
    schedule.effectiveEndDate = [schedule computeExpirationDateForScheduledDate: schedule.startsOn];
    [schedule addTasksObject:task];
    
    BOOL saved = NO;
    NSError *errorSavingSchedule = nil;
    saved = [schedule saveToPersistentStore: &errorSavingSchedule];
    APCLogError2(errorSavingSchedule);
    
    if (!errorSavingSchedule) {
        [self.scheduler clearTaskGroupCache];
        
        [[NSNotificationCenter defaultCenter] postNotificationName: APCActivitiesChanged
                                                            object: nil];
    }
    return saved;
}

#pragma mark - private methods

- (void)isTaskScheduledForToday:(NSString *)taskId completion:(void (^)(BOOL scheduled))completion {
    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"%K = %@", NSStringFromSelector(@selector(taskID)), taskId];
    NSDate *today = [NSDate date];
    [self.scheduler fetchTaskGroupsFromDate: today
                                     toDate: today
                     forTasksMatchingFilter: predicate
                                 usingQueue: [NSOperationQueue mainQueue]
                            toReportResults: ^(NSDictionary *taskGroups, NSError * __unused queryError) {
        if (completion) completion(taskGroups.count > 0);
    }];
}

- (APCTask *)findTask:(NSString *)taskId {
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"%K = %@", NSStringFromSelector(@selector(taskID)), taskId];
    NSFetchRequest *request = [APCTask requestWithPredicate:predicate];
    
    NSError *errorFetchingTasks = nil;
    NSArray *tasks = [self.context executeFetchRequest:request error:&errorFetchingTasks];
    APCLogError2(errorFetchingTasks);
    
    if (tasks.count == 0){
        return nil;
    }
    
    NSArray *sortedTasksByVersion = [tasks sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSNumber *first = ((APCTask*) obj1).taskVersionNumber;
        NSNumber *second = ((APCTask*) obj2).taskVersionNumber;
        return [first compare:second];
        
    }];
    
    return [sortedTasksByVersion firstObject];
}

- (APCTask *)createSharingTask {
    
    APCTask *task = [APCTask newObjectForContext:self.context];
    task.createdAt = [NSDate date];
    task.taskClassName = NSStringFromClass([APHTwentyThreeAndMeTaskViewController class]);
    task.taskID = k23andMeTaskId;
    task.taskTitle = @"Share 23andMe data";
    
    NSError *errorSavingSchedule = nil;
    [task saveToPersistentStore: &errorSavingSchedule];
    
    APCLogError2(errorSavingSchedule);
    
    return task;
}

@end
