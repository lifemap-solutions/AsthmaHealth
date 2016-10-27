//
//  APHConsentUpdateTests.m
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
#import "APHConsentUpdate.h"
#import "APHAppInformationProvider.h"

NSString * const consentLastUpdateDateKey = @"APHLastConsentUpdateDateKey";

@interface APHConsentUpdateTests : XCTestCase

@property (nonatomic, strong) id fileManagerMock;
@property (nonatomic, strong) id userDefaultsMock;
@property (nonatomic, strong) id appInformationProviderMock;

@end

@implementation APHConsentUpdateTests

- (void)setUp {
    [super setUp];
    
    NSUserDefaults *userDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"Testable"];
    [userDefaults removePersistentDomainForName:@"Testable"];
    self.userDefaultsMock = OCMPartialMock(userDefaults);
    self.fileManagerMock = OCMClassMock([NSFileManager class]);
    self.appInformationProviderMock = OCMProtocolMock(@protocol(APHAppInformationProvider));
}

- (void)tearDown {
    [super tearDown];
}

- (void)testConsentShouldNotBeDisplayedAndShouldBeMarkedAsUpdatedIfAppIsInstalledForTheFirstTime {
    
    NSDate *consentDate = [NSDate date];
    
    OCMStub([self.userDefaultsMock objectForKey:consentLastUpdateDateKey]).andReturn(nil);
    
    NSDictionary *consentFileAttributes = @{ NSFileModificationDate: consentDate };
    OCMStub([self.fileManagerMock attributesOfItemAtPath:[OCMArg any] error:(NSError * __autoreleasing *)[OCMArg anyPointer]]).andReturn(consentFileAttributes);
    
    OCMStub([self.appInformationProviderMock isFirstTimeInstallation]).andReturn(YES);
    
    APHConsentUpdate *consentUpdate = [[APHConsentUpdate alloc] initWithFileManager:self.fileManagerMock userDefaults:self.userDefaultsMock appInformation:self.appInformationProviderMock];
    
    XCTAssertFalse([consentUpdate checkConsentUpdate]);
    
    OCMVerify([self.userDefaultsMock setObject:consentDate forKey:consentLastUpdateDateKey]);
}

- (void)testConsentShouldBeDisplayedAndShouldBeMarkedAsUpdatedIfAppIsUpgradedFromVersionWhichDoesNotSupportConsentAlerts {
    
    NSDate *consentDate = [NSDate date];
    
    OCMStub([self.userDefaultsMock objectForKey:consentLastUpdateDateKey]).andReturn(nil);
    
    NSDictionary *consentFileAttributes = @{ NSFileModificationDate: consentDate };
    OCMStub([self.fileManagerMock attributesOfItemAtPath:[OCMArg any] error:(NSError * __autoreleasing *)[OCMArg anyPointer]]).andReturn(consentFileAttributes);
    
    OCMStub([self.appInformationProviderMock isFirstTimeInstallation]).andReturn(NO);
    
    APHConsentUpdate *consentUpdate = [[APHConsentUpdate alloc] initWithFileManager:self.fileManagerMock userDefaults:self.userDefaultsMock appInformation:self.appInformationProviderMock];
    
    XCTAssertTrue([consentUpdate checkConsentUpdate]);
    
    OCMVerify([self.userDefaultsMock setObject:consentDate forKey:consentLastUpdateDateKey]);
}

- (void)testConsentShouldNotBeDisplayedAndShouldNotBeMarkedAsUpdatedIfTheConsentHasNotBeenUpdated {
    
    NSDate *lastSavedDate = [NSDate date];
    NSDate *consentDate = lastSavedDate;
    
    OCMStub([self.userDefaultsMock objectForKey:consentLastUpdateDateKey]).andReturn(lastSavedDate);
    
    NSDictionary *consentFileAttributes = @{ NSFileModificationDate: consentDate };
    OCMStub([self.fileManagerMock attributesOfItemAtPath:[OCMArg any] error:(NSError * __autoreleasing *)[OCMArg anyPointer]]).andReturn(consentFileAttributes);
    
    APHConsentUpdate *consentUpdate = [[APHConsentUpdate alloc] initWithFileManager:self.fileManagerMock userDefaults:self.userDefaultsMock appInformation:self.appInformationProviderMock];
    
    ([[self.userDefaultsMock reject] setObject:consentDate forKey:consentLastUpdateDateKey]);
    
    XCTAssertFalse([consentUpdate checkConsentUpdate]);
    
    OCMVerify(self.userDefaultsMock);
}

- (void)testConsentShouldBeDisplayedAndMarkedAsChangedIfTheConsentHasBeenUpdated {
    
    NSDate *lastSavedDate = [NSDate date];
    NSDate *consentDate = [lastSavedDate dateByAddingTimeInterval:1.0];
    
    [self.userDefaultsMock setObject:lastSavedDate forKey:consentLastUpdateDateKey];
    
    NSDictionary *consentFileAttributes = @{ NSFileModificationDate: consentDate };
    
    OCMStub([self.fileManagerMock attributesOfItemAtPath:[OCMArg any] error:(NSError * __autoreleasing *)[OCMArg anyPointer]]).andReturn(consentFileAttributes);
    
    APHConsentUpdate *consentUpdate = [[APHConsentUpdate alloc] initWithFileManager:self.fileManagerMock userDefaults:self.userDefaultsMock appInformation:self.appInformationProviderMock];
    
    XCTAssertTrue([consentUpdate checkConsentUpdate]);
    
    OCMVerify([self.userDefaultsMock setObject:consentDate forKey:consentLastUpdateDateKey]);
}

@end
