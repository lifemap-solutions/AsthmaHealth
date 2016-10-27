//
//  APHScheduler.m
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

#import "APHScheduler.h"
#import "APHAppDelegate.h"
#import "APHABTestingManager.h"

@import APCAppCore;

@interface APCScheduler()
- (void) handleSuccessfullyLoadedTasksAndSchedulesFromDisk: (NSArray *) taskAndSchduleData
                                       andThenUseThisQueue: (NSOperationQueue *) queue
                                                  toDoThis: (APCSchedulerCallbackForFetchAndLoadOperations) callbackBlock;
- (void) clearTaskGroupCache;

@end

@implementation APHScheduler

/**
 *  This method overrides `APCScheduler` implementation.
 *  This version prevents from saving APCScheduledTask
 *  to CoreData right after starting a survey.
 *  The APCScheduledTask is saved to CoreData only
 *  if the user finishes filling in the form.
 */
- (APCScheduledTask *) createScheduledTaskFromPotentialTask: (APCPotentialTask *) potentialTask
{
    APCSchedule *schedule           = potentialTask.schedule;
    NSDate *startDate               = potentialTask.scheduledAppearanceDate;
    NSDate *endDate                 = [schedule computeExpirationDateForScheduledDate: startDate];
    APCScheduledTask *scheduledTask = [APCScheduledTask newObjectForContext: self.managedObjectContext];
    scheduledTask.generatedSchedule = potentialTask.schedule;
    scheduledTask.task              = potentialTask.task;
    scheduledTask.startOn           = startDate;
    scheduledTask.endOn             = endDate;
    
    /*
     Clear the taskGroup cache, so UIs (and anything else
     depending on the cached taskGroups) draw correctly.
     This operation is thread-safe.
     */
    [self clearTaskGroupCache];
    
    
    return scheduledTask;
}

- (void) handleSuccessfullyLoadedTasksAndSchedulesFromDisk: (NSArray *) taskAndSchduleData
                                       andThenUseThisQueue: (NSOperationQueue *) queue
                                                  toDoThis: (APCSchedulerCallbackForFetchAndLoadOperations) callbackBlock
{
    NSArray *schedulesForCountry = [self filterSchedulesForCurrentCountry:taskAndSchduleData];
    NSArray *schedulesForABTestGroup = [self filterSchedulesForABTestGroup:schedulesForCountry];
    
    [super handleSuccessfullyLoadedTasksAndSchedulesFromDisk:schedulesForABTestGroup
                                         andThenUseThisQueue:queue
                                                    toDoThis:callbackBlock];
}

- (NSArray*) filterSchedulesForCurrentCountry:(NSArray*) schedulesFromFile {
    
    NSString *currentCountry = [((APHAppDelegate *)[UIApplication sharedApplication].delegate) currentCountry];
    
    return [schedulesFromFile filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(%@ IN country) OR (country = nil)", currentCountry]];
}

- (NSArray*) filterSchedulesForABTestGroup:(NSArray*) schedulesFromFile {
    
    NSString *testGroup = [[APHABTestingManager new] testGroup];
    
    return [schedulesFromFile filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(%@ IN testGroup) OR (testGroup = nil)", testGroup]];
}

@end
