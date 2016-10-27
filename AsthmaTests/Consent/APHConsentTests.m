//
//  APHConsentTests.m
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

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import <APCAppCore/APCAppCore.h>
#import "APHConsent.h"
#import "APCDataSubstrate+Testing.h"

@implementation APCTask (Testing)

- (void)willSave {}

@end

@implementation APCScheduledTask (Testing)

- (void)willSave {}

@end

@implementation APCResult (Testing)

- (void)willSave {}

@end

@interface APHConsentTests : XCTestCase

@property (nonatomic, strong) APCDataSubstrate *dataSubstrate;
@property (nonatomic, strong) APCScheduler *scheduler;
@property (nonatomic, strong) id userMock;
@property (nonatomic, strong) id bundleMock;
@property (nonatomic, strong) id fileManagerMock;
@property (nonatomic, strong) APHConsent *consent;
@property (nonatomic, strong) NSDictionary *periods;

@end

@implementation APHConsentTests

- (void)setUp {
    [super setUp];
    
    self.userMock = OCMClassMock([APCUser class]);
    self.dataSubstrate = [[APCDataSubstrate alloc] initWithInMemoryPersistentStoreAndUser:self.userMock];
    self.scheduler = [[APCScheduler alloc] initWithDataSubstrate:self.dataSubstrate];
    self.fileManagerMock = OCMClassMock([NSFileManager class]);
    self.bundleMock = OCMClassMock([NSBundle class]);
    self.consent = [[APHConsent alloc] initWithScheduler:self.scheduler dataSubtrate:self.dataSubstrate analytics:nil bundle:self.bundleMock fileManager:self.fileManagerMock];
    self.periods = @{
        @"consentPeriod": @"P12M",
        @"reconsentGracePeriod": @"P2Y",
        @"reconsentOffset": @"P2W"
    };
}

- (void)tearDown {
    self.dataSubstrate = nil;
    self.scheduler = nil;
    [self.fileManagerMock stopMocking];
    self.fileManagerMock = nil;
    self.bundleMock = nil;
    self.consent = nil;
    
    [super tearDown];
}

#pragma mark - Before grace period

- (void)testReconsentShouldNotBeShownBeforeReconsentGracePeriod {
    
    NSDate *today = [NSDate date].startOfDay;
    NSDate *consentDate = [today dateBySubtractingISO8601Duration:@"P11M"];
    
    OCMStub([self.bundleMock infoDictionary]).andReturn(self.periods);
    OCMStub([self.userMock isConsented]).andReturn(YES);
    OCMStub([self.userMock consentSignatureDate]).andReturn(consentDate);
    
    XCTAssertFalse([self.consent shouldShowReconsent]);
    XCTAssertFalse([self.consent hasConsentExpired]);
}

#pragma mark - During grace period

- (void)testReconsentSurveyShouldBeShownDuringReconsentGraceOffsetPeriodIfUserHasNotReconsentedYet {
    
    NSDate *today = [NSDate date].startOfDay;
    NSDate *consentDate = [today dateByAddingDays:-360];
    
    OCMStub([self.bundleMock infoDictionary]).andReturn(self.periods);
    OCMStub([self.userMock isConsented]).andReturn(YES);
    OCMStub([self.userMock consentSignatureDate]).andReturn(consentDate);
    
    XCTAssertTrue([self.consent shouldShowReconsent]);
    XCTAssertFalse([self.consent hasConsentExpired]);
}

- (void)testReconsentSurveyShouldBeShownDuringReconsentGracePeriodIfUserHasNotReconsentedYet {
    
    NSDate *today = [NSDate date].startOfDay;
    NSDate *consentDate = [today dateBySubtractingISO8601Duration:@"P23M"];
    
    OCMStub([self.bundleMock infoDictionary]).andReturn(self.periods);
    OCMStub([self.userMock isConsented]).andReturn(YES);
    OCMStub([self.userMock consentSignatureDate]).andReturn(consentDate);
    
    XCTAssertTrue([self.consent shouldShowReconsent]);
    XCTAssertFalse([self.consent hasConsentExpired]);
}

- (void)testReconsentSurveyShouldNotBeShownAgainDuringReconsentGraceOffsetPeriodIfUserHasAlreadyReconsentedAndAgreedToParticipate {
    
    NSDate *today = [NSDate date].startOfDay;
    NSDate *yesterday = today.dayBefore;
    NSDate *consentDate = [today dateByAddingDays:-360];
    
    OCMStub([self.bundleMock infoDictionary]).andReturn(self.periods);
    OCMStub([self.userMock isConsented]).andReturn(YES);
    OCMStub([self.userMock consentSignatureDate]).andReturn(consentDate);
    //simulate filling-in reconsent surveys
    [self createReconsentResultWithDate:yesterday answer:YES];
    
    XCTAssertFalse([self.consent shouldShowReconsent]);
    XCTAssertFalse([self.consent hasConsentExpired]);
}

- (void)testReconsentSurveyShouldNotBeShownAgainDuringReconsentGracePeriodIfUserHasAlreadyReconsentedAndAgreedToParticipate {
    
    NSDate *today = [NSDate date].startOfDay;
    NSDate *yesterday = today.dayBefore;
    NSDate *consentDate = [today dateBySubtractingISO8601Duration:@"P23M"];
    
    OCMStub([self.bundleMock infoDictionary]).andReturn(self.periods);
    OCMStub([self.userMock isConsented]).andReturn(YES);
    OCMStub([self.userMock consentSignatureDate]).andReturn(consentDate);
    //simulate filling-in reconsent surveys
    [self createReconsentResultWithDate:yesterday answer:YES];
    
    XCTAssertFalse([self.consent shouldShowReconsent]);
    XCTAssertFalse([self.consent hasConsentExpired]);
}

- (void)testReconsentSurveyShouldNotBeShownAgainDuringReconsentGraceOffsetPeriodIfUserHasAlreadyReconsentedAndRefusedToParticipate {
    
    NSDate *today = [NSDate date].startOfDay;
    NSDate *yesterday = today.dayBefore;
    NSDate *consentDate = [today dateByAddingDays:-360];
    
    OCMStub([self.bundleMock infoDictionary]).andReturn(self.periods);
    OCMStub([self.userMock isConsented]).andReturn(YES);
    OCMStub([self.userMock consentSignatureDate]).andReturn(consentDate);
    //simulate filling-in reconsent surveys
    [self createReconsentResultWithDate:yesterday answer:NO];
    
    XCTAssertFalse([self.consent shouldShowReconsent]);
    XCTAssertFalse([self.consent hasConsentExpired]);
}

- (void)testReconsentSurveyShouldBeMarkedAsExpiredAndShouldNotBeShownAgainDuringReconsentGracePeriodIfUserHasAlreadyReconsentedAndRefusedToParticipate {
    
    NSDate *today = [NSDate date].startOfDay;
    NSDate *yesterday = today.dayBefore;
    NSDate *consentDate = [today dateBySubtractingISO8601Duration:@"P23M"];
    
    OCMStub([self.bundleMock infoDictionary]).andReturn(self.periods);
    OCMStub([self.userMock isConsented]).andReturn(YES);
    OCMStub([self.userMock consentSignatureDate]).andReturn(consentDate);
    //simulate filling-in reconsent surveys
    [self createReconsentResultWithDate:yesterday answer:NO];
    
    XCTAssertFalse([self.consent shouldShowReconsent]);
    XCTAssertTrue([self.consent hasConsentExpired]);
}

#pragma mark - After grace period

- (void)testReconsentSurveyShouldBeMarkedAsExpiredAndShouldNotBeShownAfterReconsentGracePeriodIfUserHasNotReconsented {
    
    NSDate *today = [NSDate date].startOfDay;
    NSDate *consentDate = [today dateBySubtractingISO8601Duration:@"P3Y"];
    
    OCMStub([self.bundleMock infoDictionary]).andReturn(self.periods);
    OCMStub([self.userMock isConsented]).andReturn(YES);
    OCMStub([self.userMock consentSignatureDate]).andReturn(consentDate);
    
    XCTAssertFalse([self.consent shouldShowReconsent]);
    XCTAssertTrue([self.consent hasConsentExpired]);
}

- (void)testReconsentSurveyShouldBeMarkedAsExpiredAndShouldNotBeShownAfterReconsentGracePeriodIfUserHasAlreadyReconsentedAndAgreedToParticipate {
    
    NSDate *today = [NSDate date].startOfDay;
    NSDate *twoYearsAgo = [today dateBySubtractingISO8601Duration:@"P2Y"];
    NSDate *consentDate = [today dateBySubtractingISO8601Duration:@"P3Y"];
    
    OCMStub([self.bundleMock infoDictionary]).andReturn(self.periods);
    OCMStub([self.userMock isConsented]).andReturn(YES);
    OCMStub([self.userMock consentSignatureDate]).andReturn(consentDate);
    //simulate filling-in reconsent surveys
    [self createReconsentResultWithDate:twoYearsAgo answer:YES];
    
    XCTAssertFalse([self.consent shouldShowReconsent]);
    XCTAssertTrue([self.consent hasConsentExpired]);
}

- (void)testReconsentSurveyShouldBeMarkedAsExpiredAndShouldNotBeShownAfterReconsentGracePeriodIfUserHasAlreadyReconsentedAndRefusedToParticipate {
    
    NSDate *today = [NSDate date].startOfDay;
    NSDate *twoYearsAgo = [today dateBySubtractingISO8601Duration:@"P2Y"];
    NSDate *consentDate = [today dateBySubtractingISO8601Duration:@"P3Y"];
    
    OCMStub([self.bundleMock infoDictionary]).andReturn(self.periods);
    OCMStub([self.userMock isConsented]).andReturn(YES);
    OCMStub([self.userMock consentSignatureDate]).andReturn(consentDate);
    //simulate filling-in reconsent surveys
    [self createReconsentResultWithDate:twoYearsAgo answer:NO];
    
    XCTAssertFalse([self.consent shouldShowReconsent]);
    XCTAssertTrue([self.consent hasConsentExpired]);
}

#pragma mark - After 1st grace period if user agreed to reconsent and during 2nd grace period

- (void)testReconsentSurveyShouldBeShownDuringSecondReconsentGraceOffsetPeriodIfUserHasNotReconsentedYet {
    
    NSDate *today = [NSDate date].startOfDay;
    NSDate *reconsentDate = [today dateByAddingDays:-360];
    NSDate *consentDate = [reconsentDate dateBySubtractingISO8601Duration:@"P23M"];
    
    OCMStub([self.bundleMock infoDictionary]).andReturn(self.periods);
    OCMStub([self.userMock isConsented]).andReturn(YES);
    OCMStub([self.userMock consentSignatureDate]).andReturn(consentDate);
    //simulate filling-in reconsent surveys
    [self createReconsentResultWithDate:reconsentDate answer:YES];
    
    XCTAssertTrue([self.consent shouldShowReconsent]);
    XCTAssertFalse([self.consent hasConsentExpired]);
}

- (void)testReconsentSurveyShouldBeShownDuringSecondReconsentGracePeriodIfUserHasNotReconsentedYet {
    
    NSDate *today = [NSDate date].startOfDay;
    NSDate *reconsentDate = [today dateBySubtractingISO8601Duration:@"P23M"];
    NSDate *consentDate = [reconsentDate dateBySubtractingISO8601Duration:@"P23M"];
    
    OCMStub([self.bundleMock infoDictionary]).andReturn(self.periods);
    OCMStub([self.userMock isConsented]).andReturn(YES);
    OCMStub([self.userMock consentSignatureDate]).andReturn(consentDate);
    //simulate filling-in reconsent surveys
    [self createReconsentResultWithDate:reconsentDate answer:YES];
    
    XCTAssertTrue([self.consent shouldShowReconsent]);
    XCTAssertFalse([self.consent hasConsentExpired]);
}

- (void)testReconsentSurveyShouldNotBeShownAgainDuringSecondReconsentGraceOffsetPeriodIfUserHasAlreadyReconsentedAndAgreedToParticipate {
    
    NSDate *today = [NSDate date].startOfDay;
    NSDate *yesterday = today.dayBefore;
    NSDate *reconsentDate = [today dateByAddingDays:-360];
    NSDate *consentDate = [reconsentDate dateBySubtractingISO8601Duration:@"P23M"];
    
    OCMStub([self.bundleMock infoDictionary]).andReturn(self.periods);
    OCMStub([self.userMock isConsented]).andReturn(YES);
    OCMStub([self.userMock consentSignatureDate]).andReturn(consentDate);
    //simulate filling-in reconsent surveys
    [self createReconsentResultWithDate:reconsentDate answer:YES];
    [self createReconsentResultWithDate:yesterday answer:YES];
    
    XCTAssertFalse([self.consent shouldShowReconsent]);
    XCTAssertFalse([self.consent hasConsentExpired]);
}

- (void)testReconsentSurveyShouldNotBeShownAgainDuringSecondReconsentGracePeriodIfUserHasAlreadyReconsentedAndAgreedToParticipate {
    
    NSDate *today = [NSDate date].startOfDay;
    NSDate *yesterday = today.dayBefore;
    NSDate *reconsentDate = [today dateBySubtractingISO8601Duration:@"P23M"];
    NSDate *consentDate = [reconsentDate dateBySubtractingISO8601Duration:@"P23M"];
    
    OCMStub([self.bundleMock infoDictionary]).andReturn(self.periods);
    OCMStub([self.userMock isConsented]).andReturn(YES);
    OCMStub([self.userMock consentSignatureDate]).andReturn(consentDate);
    //simulate filling-in reconsent surveys
    [self createReconsentResultWithDate:reconsentDate answer:YES];
    [self createReconsentResultWithDate:yesterday answer:YES];
    
    XCTAssertFalse([self.consent shouldShowReconsent]);
    XCTAssertFalse([self.consent hasConsentExpired]);
}

- (void)testReconsentSurveyShouldNotBeShownAgainDuringSecondReconsentGraceOffsetPeriodIfUserHasAlreadyReconsentedAndRefusedToParticipate {
    
    NSDate *today = [NSDate date].startOfDay;
    NSDate *yesterday = today.dayBefore;
    NSDate *reconsentDate = [today dateByAddingDays:-360];
    NSDate *consentDate = [reconsentDate dateBySubtractingISO8601Duration:@"P23M"];
    
    OCMStub([self.bundleMock infoDictionary]).andReturn(self.periods);
    OCMStub([self.userMock isConsented]).andReturn(YES);
    OCMStub([self.userMock consentSignatureDate]).andReturn(consentDate);
    //simulate filling-in reconsent surveys
    [self createReconsentResultWithDate:reconsentDate answer:YES];
    [self createReconsentResultWithDate:yesterday answer:NO];
    
    XCTAssertFalse([self.consent shouldShowReconsent]);
    XCTAssertFalse([self.consent hasConsentExpired]);
}

- (void)testReconsentSurveyShouldBeMarkedAsExpiredAndShouldNotBeShownAgainDuringSecondReconsentGracePeriodIfUserHasAlreadyReconsentedAndRefusedToParticipate {
    
    NSDate *today = [NSDate date].startOfDay;
    NSDate *yesterday = today.dayBefore;
    NSDate *reconsentDate = [today dateBySubtractingISO8601Duration:@"P23M"];
    NSDate *consentDate = [reconsentDate dateBySubtractingISO8601Duration:@"P23M"];
    
    OCMStub([self.bundleMock infoDictionary]).andReturn(self.periods);
    OCMStub([self.userMock isConsented]).andReturn(YES);
    OCMStub([self.userMock consentSignatureDate]).andReturn(consentDate);
    //simulate filling-in reconsent surveys
    [self createReconsentResultWithDate:reconsentDate answer:YES];
    [self createReconsentResultWithDate:yesterday answer:NO];
    
    XCTAssertFalse([self.consent shouldShowReconsent]);
    XCTAssertTrue([self.consent hasConsentExpired]);
}

#pragma mark - Migration from 6M to 12M consent period

- (void)testReconsentSurveyShouldNotBeMarkedAsExpiredAndShouldBeShownDuringReconsentGracePeriodIfUserMigratedAfter12Months {
    
    NSDate *today = [NSDate date].startOfDay;
    NSDate *migrationDate = [today dateBySubtractingISO8601Duration:@"P1M"];
    NSDate *consentDate = [migrationDate dateBySubtractingISO8601Duration:@"P12M"];
    
    OCMStub([self.bundleMock infoDictionary]).andReturn(self.periods);
    OCMStub([self.userMock isConsented]).andReturn(YES);
    OCMStub([self.userMock consentSignatureDate]).andReturn(consentDate);
    
    XCTAssertTrue([self.consent shouldShowReconsent]);
    XCTAssertFalse([self.consent hasConsentExpired]);
}

#pragma mark - Helper methods

- (APCResult *)createReconsentResultWithDate:(NSDate *)date answer:(BOOL)answer {
    
    NSManagedObjectContext *context = self.scheduler.managedObjectContext;
    
    APCTask *task = [APCTask newObjectForContext:context];
    task.taskID = kReconsentTaskID;
    task.createdAt = date;
    task.updatedAt = date;
    
    APCScheduledTask *scheduledTask = [APCScheduledTask newObjectForContext:context];
    scheduledTask.completed = @YES;
    scheduledTask.createdAt = date;
    scheduledTask.updatedAt = date;
    scheduledTask.task = task;
    [task addScheduledTasksObject:scheduledTask];
    
    APCResult *result = [APCResult newObjectForContext:context];
    result.scheduledTask = scheduledTask;
    [scheduledTask addResultsObject:result];
    result.createdAt = date;
    result.updatedAt = date;
    result.endDate = date;
    
    NSError *error;
    NSDictionary *resultDictionary = @{ @"reconsented": @(answer)};
    NSData *resultData = [NSJSONSerialization dataWithJSONObject:resultDictionary options:NSJSONWritingPrettyPrinted error:&error];
    NSString *resultSummary = [[NSString alloc] initWithData:resultData encoding:NSUTF8StringEncoding];
    XCTAssertNil(error);
    result.resultSummary = resultSummary;
    
    [result saveToPersistentStore:&error];
    XCTAssertNil(error);
    
    return result;
}

@end
