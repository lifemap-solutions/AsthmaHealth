//
//  APHSchedulerTests.m
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

#import <XCTest/XCTest.h>
#import <APCAppCore/APCAppCore.h>
#import "APCDataSubstrate+Testing.h"

NSString * const kJSONTasksAndSchedulesFileName = @"Test_APHTasksAndSchedules.json";

@interface APCScheduler (Testing)

- (void) processSchedulesAndTasks: (NSArray *) arrayOfSchedulesAndTasks
                       fromSource: (APCScheduleSource) scheduleSource
              andThenUseThisQueue: (NSOperationQueue *) queue
                 toDoThisWhenDone: (APCSchedulerCallbackForFetchAndLoadOperations) callbackBlock;

@end

@interface APCSchedulerTests : XCTestCase

@property (nonatomic, strong) APCDataSubstrate *dataSubstrate;
@property (nonatomic, strong) APCScheduler *scheduler;
@property (nonatomic, strong) NSArray *schedulesArray;

@end

@implementation APCSchedulerTests

- (void)setUp {
    [super setUp];
    
    self.dataSubstrate = [[APCDataSubstrate alloc] initWithInMemoryPersistentStore];
    self.scheduler = [[APCScheduler alloc] initWithDataSubstrate:self.dataSubstrate];
    self.schedulesArray = [self loadSchedulesFromJson:kJSONTasksAndSchedulesFileName];
}

- (void)tearDown {
    self.scheduler = nil;
    self.dataSubstrate = nil;
    self.schedulesArray = nil;
    
    [super tearDown];
}

- (NSArray *)loadSchedulesFromJson:(NSString *)jsonFile {
    NSError *error = nil;
    NSDictionary *jsonDictionary = [NSDictionary dictionaryWithContentsOfJSONFileWithName:jsonFile inBundle:[NSBundle bundleForClass:[self class]] returningError:&error];
    XCTAssertNil(error);
    return jsonDictionary[@"schedules"];
}

- (APCTask *)findTask:(NSString *)taskTitle {
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"%K = %@", NSStringFromSelector(@selector(taskTitle)), taskTitle];
    NSFetchRequest *request = [APCTask requestWithPredicate:predicate];
    
    NSError *errorFetchingTasks = nil;
    NSArray *tasks = [self.scheduler.managedObjectContext executeFetchRequest:request error:&errorFetchingTasks];
    XCTAssertNil(errorFetchingTasks);
    
    if (tasks.count == 0){
        return nil;
    }
    
    return tasks.firstObject;
}

- (NSArray *)scheduledTasks {
    NSError *errorFetchingScheduledTasks = nil;
    NSArray *scheduledTasks = [self.scheduler.managedObjectContext executeFetchRequest:[APCScheduledTask request] error:&errorFetchingScheduledTasks];
    XCTAssertNil(errorFetchingScheduledTasks);
    return scheduledTasks;
}

- (NSArray *)schedules {
    NSError *errorFetchingSchedules = nil;
    NSArray *schedules = [self.scheduler.managedObjectContext executeFetchRequest:[APCSchedule request] error:&errorFetchingSchedules];
    XCTAssertNil(errorFetchingSchedules);
    return schedules;
}

- (void)testOneTimeSchedulesShouldNotBeDeletedAndShouldBeDisabledRightAfterCompletion {
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"One-time schedules should not be deleted and should be disabled right after completion"];
    __block NSUInteger initialSchedulesCount;
    
    NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
    
    //simulate 1st run of the application
    [self.scheduler processSchedulesAndTasks:self.schedulesArray fromSource:APCScheduleSourceLocalDisk andThenUseThisQueue:mainQueue toDoThisWhenDone:^(NSError *errorFetchingOrLoading) {
        
        NSArray *schedules = [self schedules];
        initialSchedulesCount = schedules.count;
        
        XCTAssertNil(errorFetchingOrLoading);
        APCTask *task = [self findTask:@"Consent for Genetic Data Sharing"];
        XCTAssertNotNil(task);
        APCSchedule *schedule = [task.schedules anyObject];
        XCTAssertNotNil(schedule);
        
        //simulate start of the survey - create APCScheduledTask
        NSDate *startDate = [[NSDate date] startOfDay];
        APCScheduledTask *scheduledTask = [APCScheduledTask newObjectForContext:self.scheduler.managedObjectContext];
        scheduledTask.generatedSchedule = schedule;
        scheduledTask.task = task;
        scheduledTask.startOn = startDate;
        scheduledTask.endOn = [schedule computeExpirationDateForScheduledDate:startDate];
        
        //simulate completion of the survey - save APCScheduledTask
        scheduledTask.completed = @(YES);
        NSError *errorSavingTask = nil;
        BOOL savedSuccessfully = [scheduledTask saveToPersistentStore:&errorSavingTask];
        XCTAssertNil(errorSavingTask);
        XCTAssertTrue(savedSuccessfully);
        
        //simulate 2nd run of the application
        [self.scheduler processSchedulesAndTasks:self.schedulesArray fromSource:APCScheduleSourceLocalDisk andThenUseThisQueue:mainQueue toDoThisWhenDone:^(NSError *errorFetchingOrLoading) {
            
            XCTAssertNil(errorFetchingOrLoading);
            
            //there should be only one scheduled task
            NSArray *scheduledTasks = [self scheduledTasks];
            XCTAssertEqual(scheduledTasks.count, (NSUInteger)1);
            
            //scheduled task should be completed and corresponding task and generatedSchedule should not be nil
            APCScheduledTask *scheduledTask = scheduledTasks.firstObject;
            XCTAssertTrue(scheduledTask.completed.boolValue);
            XCTAssertNotNil(scheduledTask.task);
            XCTAssertNotNil(scheduledTask.generatedSchedule);
            
            //scheduled task should be disabled so the effectiveEndDate should not be nil
            XCTAssertNotNil(scheduledTask.generatedSchedule.effectiveEndDate);
            
            //there should be the same number of schedules as for the 1st run of the application - schedule should not be deleted
            NSArray *schedules = [self schedules];
            XCTAssertEqual(schedules.count, initialSchedulesCount);
            
            //simulate 3rd run of the application
            [self.scheduler processSchedulesAndTasks:self.schedulesArray fromSource:APCScheduleSourceLocalDisk andThenUseThisQueue:mainQueue toDoThisWhenDone:^(NSError *errorFetchingOrLoading) {
                
                XCTAssertNil(errorFetchingOrLoading);
                
                //there should be only one scheduled task
                NSArray *scheduledTasks = [self scheduledTasks];
                XCTAssertEqual(scheduledTasks.count, (NSUInteger)1);
                
                //scheduled task should be completed and corresponding task and generatedSchedule should not be nil
                APCScheduledTask *scheduledTask = scheduledTasks.firstObject;
                XCTAssertTrue(scheduledTask.completed.boolValue);
                XCTAssertNotNil(scheduledTask.task);
                XCTAssertNotNil(scheduledTask.generatedSchedule);
                
                //there should be the same number of schedules as for the 1st run of the application
                NSArray *schedules = [self schedules];
                XCTAssertEqual(schedules.count, initialSchedulesCount);
                
                [expectation fulfill];
            }];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:3.0 handler:^(NSError * _Nullable error) {
        if (error) {
            XCTFail(@"Expectation Failed with error: %@", error);
        }
    }];
}

- (void)testProcessingSchedulesAndTasksFromBackgroundThreadShouldNotResultInErrorSavingNewSchedules {
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Processing schedules and tasks from background thread should not result in 'Error Saving New Schedules' error"];
    //try to add an object to main context
    NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
    NSOperationQueue *backgroundQueue = [NSOperationQueue new];
    
    [backgroundQueue addOperationWithBlock:^{
        
        [self.scheduler processSchedulesAndTasks:self.schedulesArray fromSource:APCScheduleSourceLocalDisk andThenUseThisQueue:mainQueue toDoThisWhenDone:^(NSError *errorFetchingOrLoading) {
            
            XCTAssertNil(errorFetchingOrLoading);
            
            //at this stage main context should not contain any changes
            XCTAssertFalse(self.scheduler.managedObjectContext.hasChanges);
            
            [expectation fulfill];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:3.0 handler:^(NSError * _Nullable error) {
        if (error) {
            XCTFail(@"Expectation Failed with error: %@", error);
        }
    }];
}

- (void)testProcessingSchedulesAndTasksFromDiskAndThenFromServerShouldNotResultInErrorSavingNewSchedules {
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Processing schedules and tasks from disk and then processing empty data from server should not result in 'Error Saving New Schedules' error"];
    //try to add an object to main context
    NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
    
    //simulate processing schedules and tasks from disk
    [self.scheduler processSchedulesAndTasks:self.schedulesArray fromSource:APCScheduleSourceLocalDisk andThenUseThisQueue:mainQueue toDoThisWhenDone:^(NSError *errorFetchingOrLoading) {
        
        XCTAssertNil(errorFetchingOrLoading);
        
        //simulate processing schedules and tasks from server
        [self.scheduler processSchedulesAndTasks:@[] fromSource:APCScheduleSourceServer andThenUseThisQueue:mainQueue toDoThisWhenDone:^(NSError *errorFetchingOrLoading) {
            
            XCTAssertNil(errorFetchingOrLoading);
            
            [expectation fulfill];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:3.0 handler:^(NSError * _Nullable error) {
        if (error) {
            XCTFail(@"Expectation Failed with error: %@", error);
        }
    }];
}

@end
