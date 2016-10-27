//
//  APCSchedule2Tests.m
//  APCAppCore
//
//  Copyright (c) 2015, Apple Inc. All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification,
//  are permitted provided that the following conditions are met:
//
//  1.  Redistributions of source code must retain the above copyright notice, this
//  list of conditions and the following disclaimer.
//
//  2.  Redistributions in binary form must reproduce the above copyright notice,
//  this list of conditions and the following disclaimer in the documentation and/or
//  other materials provided with the distribution.
//
//  3.  Neither the name of the copyright holder(s) nor the names of any contributors
//  may be used to endorse or promote products derived from this software without
//  specific prior written permission. No license is granted to the trademarks of
//  the copyright holders even if such marks are included in this software.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
//  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
//  FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
//  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
//  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
//  CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
//  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
//  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "APCNewSchedule.h"
#import "APCNewCronExpression.h"
#import "APCNewIso8601Expression.h"
#import "APCNewDuration.h"

@interface APCNewScheduleTests : XCTestCase

@end

@implementation APCNewScheduleTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    XCTAssert(YES, @"Pass");
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

- (void) testMakeASchedule
{
    // In progress.

//    NSString *jsonEmptyString   = @"";
//    NSString *jsonNull          = @"null";
//    NSString *jsonGenericGarbage  = @"###garbage###";
//
//    NSArray *scheduleTypes      = @[ @"once",
//                                     @"recurring",
//                                     jsonEmptyString,
//                                     jsonGenericGarbage,
//                                     jsonNull
//                                     ];
//
//    NSArray *intervals          = @[ @"P4H",
//                                     @"P3D",
//                                     @"P1W",
//                                     @"P1M",
//                                     @"P3M",
//                                     @"P1Y",
//                                     @"P1.5M",
//                                     jsonEmptyString,
//                                     jsonGenericGarbage,
//                                     jsonNull
//                                     ];
//
//    NSArray *jsonTimes          = @[ @"[5, 10, 15]",
//                                     @" [ '05:00', '10:00', '15:00' ] ",
//                                     jsonEmptyString,
//                                     jsonGenericGarbage,
//                                     jsonNull
//                                     ];
//
//    NSArray *crons              = @[ @"0 5 * * *",
//                                     @"0 5,10,15 * * *",
//                                     @"0 5 1,15 * *",
//                                     @"0 5 * * wed",
//                                     @"0 5 31 may-jul",
//                                     jsonEmptyString,
//                                     jsonGenericGarbage,
//                                     jsonNull
//                                     ];
//
//    NSArray *expirations        = @[  jsonEmptyString,
//                                      jsonNull,
//                                      @"P4H",
//                                      @"P3D",
//                                      jsonGenericGarbage
//                                      ];
}

@end













