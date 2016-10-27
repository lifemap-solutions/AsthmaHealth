//
//  APHAwsPublisherTests.m
//  CardioHealth
//
//  Created by Dariusz Lesniak on 17/12/2015.
//  Copyright © 2015 Apple, Inc. All rights reserved.
//

#import "APHAwsClientIdUploader.h"
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>

@interface NSUserDefaults (Testable)

@end

@interface APHAwsClientIdUplodaderTests : XCTestCase

@property (nonatomic, strong) id userMock;
@property (nonatomic, strong) id userDefaultsMock;
@property (nonatomic, strong) id uploaderMock;
@property (nonatomic, strong) APHAwsClientIdUploader* awsIdUploader;

@end

@implementation APHAwsClientIdUplodaderTests

- (void)setUp {
    [super setUp];
    
    self.userMock = OCMClassMock([APCUser class]);
    self.userDefaultsMock = OCMClassMock([NSUserDefaults class]);
    self.uploaderMock = OCMClassMock([APCDataUploader class]);
    self.awsIdUploader = [[APHAwsClientIdUploader alloc] initWithUploader: self.uploaderMock];
    
    [APCAppDelegate sharedAppDelegate].dataSubstrate.currentUser = self.userMock;
    OCMStub([self.userDefaultsMock standardUserDefaults]).andReturn(self.userDefaultsMock);
    
}

- (void)testShouldNotUploadAwsClientIdIfTheUserIsConsentedAndClientIdHaventChanged {
    OCMStub([self.userMock isConsented]).andReturn(YES);
    OCMStub([self.userDefaultsMock objectForKey:@"awsClientIdSent"]).andReturn(@"clientId");
    [[self.uploaderMock reject] insertIntoZipArchive:[OCMArg any] filename:[OCMArg any]];
    
    [self.awsIdUploader uploadAwsClientId:@"clientId"];
    
    OCMVerifyAll(self.userDefaultsMock);
    OCMVerifyAllWithDelay(self.uploaderMock, 0.5);
}

- (void)testShouldNotUploadAwsClientIdIfTheUserIsNotConsentedAndClientIdHaveChanged {
    OCMStub([self.userMock isConsented]).andReturn(NO);
    OCMStub([self.userDefaultsMock objectForKey:@"awsClientIdSent"]).andReturn(nil);
    [[self.uploaderMock reject] insertIntoZipArchive:[OCMArg isNotNil] filename:[OCMArg isNotNil]];
    
    [self.awsIdUploader uploadAwsClientId:@"clientId"];
    
    OCMVerifyAll(self.userDefaultsMock);
    OCMVerifyAllWithDelay(self.uploaderMock, 0.5);
}

- (void)testShouldUploadDataWhenUserConsentedAndClientIdHaveChanged {
    OCMStub([self.userMock isConsented]).andReturn(YES);
    OCMStub([self.userDefaultsMock objectForKey:@"awsClientIdSent"]).andReturn(@"test");
    
    OCMExpect([self.uploaderMock insertIntoZipArchive:[OCMArg isNotNil] filename:@"AwsClientId"]);

    OCMExpect([self.uploaderMock uploadWithCompletion:[OCMArg invokeBlock]]);
    OCMExpect([self.userDefaultsMock setObject:@"clientId" forKey:@"awsClientIdSent"]);
    
    [self.awsIdUploader uploadAwsClientId:@"clientId"];
    
    OCMVerifyAllWithDelay(self.uploaderMock, 0.5);
    OCMVerifyAllWithDelay(self.userDefaultsMock, 0.5);
    
}


@end
