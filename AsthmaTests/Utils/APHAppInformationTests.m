//
//  APHAppInformationTests.m
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
#import <OCMock/OCMock.h>
#import "APHAppInformation.h"

NSString * const appInstallationVersion = @"APHAppInstallationVersion";

@interface APHAppInformationTests : XCTestCase

@property (nonatomic, strong) id apcAppDelegateMock;
@property (nonatomic, strong) id userDefaultsMock;
@property (nonatomic, strong) id bundleMock;

@end

@implementation APHAppInformationTests

- (void)setUp {
    [super setUp];
    
    NSUserDefaults *userDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"Testable"];
    [userDefaults removePersistentDomainForName:@"Testable"];
    self.userDefaultsMock = OCMPartialMock(userDefaults);
    self.apcAppDelegateMock = OCMClassMock([APCAppDelegate class]);
    self.bundleMock = OCMClassMock([NSBundle class]);
}

- (void)tearDown {
    [super tearDown];
    self.userDefaultsMock = nil;
}

- (void)testIfPersistentStoreDoesNotExistCurrentVersionShouldBeMarkedAsFirstTimeInstallation {
    
    NSString *currentVersion = @"1.2.0";
    
    OCMStub([self.apcAppDelegateMock doesPersisteStoreExist]).andReturn(NO);
    OCMStub([self.bundleMock objectForInfoDictionaryKey:[OCMArg any]]).andReturn(currentVersion);
    
    
    APHAppInformation *appInformation = [[APHAppInformation alloc] initWithUserDefaults:self.userDefaultsMock appDelegate:self.apcAppDelegateMock bundle:self.bundleMock];
    
    [appInformation determineInstallationVersion];
    
    XCTAssertTrue([appInformation isFirstTimeInstallation]);
    
    OCMVerify([self.userDefaultsMock setObject:currentVersion forKey:appInstallationVersion]);
}

- (void)testIfPersistentStoreExistsCurrentVersionShouldNotBeMarkedAsFirstTimeInstallation {
    
    NSString *currentVersion = @"1.2.0";
    
    OCMStub([self.apcAppDelegateMock doesPersisteStoreExist]).andReturn(YES);
    OCMStub([self.bundleMock objectForInfoDictionaryKey:[OCMArg any]]).andReturn(currentVersion);
    
    
    APHAppInformation *appInformation = [[APHAppInformation alloc] initWithUserDefaults:self.userDefaultsMock appDelegate:self.apcAppDelegateMock bundle:self.bundleMock];
    
    [appInformation determineInstallationVersion];
    
    XCTAssertFalse([appInformation isFirstTimeInstallation]);
    
    OCMVerify([[self.userDefaultsMock reject] setObject:[OCMArg any] forKey:appInstallationVersion]);
}

@end
