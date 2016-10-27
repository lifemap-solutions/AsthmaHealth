//
//  APHAsthmaBadgesObjectTests.m
//  Asthma
//
//  Created by Dariusz Lesniak on 20/01/2016.
//  Copyright © 2016 Apple, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "APHAsthmaBadgesObject.h"
#import <objc/runtime.h>
#import <APCAppCore/APCAppCore.h>

@interface APHAsthmaBadgesObject (Private)
- (void) calculateWorkAttendanceValue;
@end


@interface APHAsthmaBadgesObject (Test)
@property (strong, nonatomic) NSArray* weeklyScheduledTasks;
- (instancetype)initForTests;
@end

@implementation APHAsthmaBadgesObject (Test)
- (instancetype)initForTests {
    self = [super init];
    return self;
}
- (NSArray*)completedWeeklyScheduledTasks {
    return self.weeklyScheduledTasks;
}

- (NSArray*)weeklyScheduledTasks {
    return objc_getAssociatedObject(self, @selector(weeklyScheduledTasks));
}

- (void)setWeeklyScheduledTasks:(NSArray *)weeklyScheduledTasks {
    objc_setAssociatedObject(self, @selector(weeklyScheduledTasks), weeklyScheduledTasks, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
@end

@interface APHAsthmaBadgesObjectTests : XCTestCase
@property(nonatomic, strong) APHAsthmaBadgesObject *badgesObject;
@property(nonatomic, strong) NSManagedObjectContext *moc;
@end

@implementation APHAsthmaBadgesObjectTests

- (void)setUp {
    [super setUp];
    self.badgesObject = [[APHAsthmaBadgesObject alloc] initForTests];
    NSBundle* bundle =[NSBundle appleCoreBundle];
    
    NSString * modelPath = [bundle pathForResource:@"APCModel" ofType:@"momd"];
    NSURL *modelURL = [NSURL fileURLWithPath:modelPath];
    NSManagedObjectModel *mom = [[[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL] mutableCopy];

    NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
    self.moc = [[NSManagedObjectContext alloc] init];
    self.moc.persistentStoreCoordinator = psc;
    
}

- (void)testShouldIncludeMultipleWeeklySchedulesInCalculatingWorkAttendanceValue {
    self.badgesObject.weeklyScheduledTasks = @[
                                               [self createScheduledTaskWithResult:@"" createdAt:@"23-01-16 09:01"],
                                               [self createScheduledTaskWithResult:@"{\"MissedDay:1\":1}" createdAt:@"23-01-16 09:16"],
                                               [self createScheduledTaskWithResult:@"" createdAt:@"30-01-16 13:00"]
                                               ];
    
    [self.badgesObject calculateWorkAttendanceValue];
    XCTAssertEqual(90, round(self.badgesObject.workAttendanceValue * 100)); // 1 of 10 was missed
}

-(APCScheduledTask*) createScheduledTaskWithResult:(NSString *) resultSummary createdAt:(NSString*) createdAt {
    APCResult * result = [APCResult newObjectForContext:self.moc];
    result.resultSummary = resultSummary;
    
    APCScheduledTask *scheduledTask = [APCScheduledTask newObjectForContext:self.moc];
    scheduledTask.results = [NSSet setWithObjects:result, nil];
    scheduledTask.createdAt = [self createDateForString:createdAt];
    
    return scheduledTask;
}

-(NSDate*) createDateForString:(NSString*) dateString {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"dd-MM-yy HH:mm";
    return [dateFormatter dateFromString:dateString];
}




@end
