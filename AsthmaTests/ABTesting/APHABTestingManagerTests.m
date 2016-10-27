//
//  APHABTestingManagerTests.m
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
#import "APHABTestingManager.h"
#import "APHABTestingGroupProvider.h"

@interface APHABTestingManagerTests : XCTestCase

@end

@implementation APHABTestingManagerTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testGroupInputCreation {
    NSString *bundleIdentifier = [[NSBundle bundleForClass:[self class]] bundleIdentifier];
    NSUserDefaults *userDefaults = [[NSUserDefaults alloc] initWithSuiteName:bundleIdentifier];
    [userDefaults removePersistentDomainForName:bundleIdentifier];
    
    NSUUID *uuid = [NSUUID UUID];
    APHABTestingManager *manager = [[APHABTestingManager alloc] initWithUUID:uuid userDefaults:userDefaults];
    NSNumber *testGroupInput = [manager testGroupInput];
    
    XCTAssertNotNil(testGroupInput);
}

- (void)testGroupInputPersistence {
    NSString *bundleIdentifier = [[NSBundle bundleForClass:[self class]] bundleIdentifier];
    NSUserDefaults *userDefaults = [[NSUserDefaults alloc] initWithSuiteName:bundleIdentifier];
    [userDefaults removePersistentDomainForName:bundleIdentifier];
    
    NSUUID *uuid1 = [NSUUID UUID];
    NSUUID *uuid2 = [NSUUID UUID];
    APHABTestingManager *manager1 = [[APHABTestingManager alloc] initWithUUID:uuid1 userDefaults:userDefaults];
    APHABTestingManager *manager2 = [[APHABTestingManager alloc] initWithUUID:uuid2 userDefaults:userDefaults];
    
    XCTAssertEqualObjects([manager1 testGroupInput], [manager2 testGroupInput]);
}

- (void)testGroupAssignment {
    NSString *bundleIdentifier = [[NSBundle bundleForClass:[self class]] bundleIdentifier];
    NSUserDefaults *userDefaults = [[NSUserDefaults alloc] initWithSuiteName:bundleIdentifier];
    [userDefaults removePersistentDomainForName:bundleIdentifier];
    
    NSString *uuidString = @"95D3008A-DF8B-4727-A9A9-90C96EE2330F";
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:uuidString];
    APHABTestingManager *manager = [[APHABTestingManager alloc] initWithUUID:uuid userDefaults:userDefaults];
    
    NSString *expectedGroup = @"B";
    
    XCTAssertEqualObjects([manager testGroup], expectedGroup);
}

- (void)testGroupDistributionAccuracy {
    NSUInteger bucketA = 0;
    NSUInteger bucketB = 0;
    
    NSUInteger numberOfTrials = 10000;
    NSUInteger accuracy = 0.04 * numberOfTrials; // 4%
    
    for (NSUInteger i = 0; i < numberOfTrials; i++) {
        NSUUID *randomUuid = [NSUUID UUID];
        APHABTestingManager *manager = [[APHABTestingManager alloc] initWithUUID:randomUuid userDefaults:nil];
        
        if ([[manager testGroup] isEqualToString:kAPHABTestGroupA]) {
            bucketA++;
        } else {
            bucketB++;
        }
    }
    
    NSLog(@"bucketA: %ld, bucketB: %ld, accuracy +/- %ld", bucketA, bucketB, accuracy);
    
    XCTAssertEqualWithAccuracy(bucketA, bucketB, accuracy);
}

@end
