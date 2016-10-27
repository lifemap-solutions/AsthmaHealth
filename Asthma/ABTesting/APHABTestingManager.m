//
//  APHABTestingManager.m
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

#import "APHABTestingManager.h"
#import "APHABTestingGroupProvider.h"
#import "NSString+APHCyclicRedundancyChecksum.h"

static NSString * const kAPHABTestingGroupInput = @"ABTestingGroupInput";

@interface APHABTestingManager ()

@property (nonatomic, strong) NSUserDefaults *userDefaults;
@property (nonatomic, strong) NSUUID *uuid;
@property (nonatomic, strong) NSNumber *testGroupInput;

/**
 *  Method that generates `group input`
 *  based on unique device identifier (number between 0 and 99)
 *  on the basis of which the user is assigned
 *  to one of the testing group (`A` or `B`).
 *  `group input` is stored in NSUserDefaults,
 *  it is generated only for the 1st time.
 */
- (void)generateTestGroupInputIfNeeded;

@end

@implementation APHABTestingManager

- (instancetype)init {
    NSUUID *identifierForVendor = [[UIDevice currentDevice] identifierForVendor];
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    self = [self initWithUUID:identifierForVendor userDefaults:standardUserDefaults];
    
    if (!self) {
        return nil;
    }
    
    return self;
}

- (instancetype)initWithUUID:(NSUUID *)uuid userDefaults:(NSUserDefaults *)userDefaults {
    self = [super init];
    
    if (!self) {
        return nil;
    }
    
    _uuid = uuid;
    _userDefaults = userDefaults;
    _testGroupInput = [_userDefaults objectForKey:kAPHABTestingGroupInput];
    [self generateTestGroupInputIfNeeded];
    
    return self;
}

- (NSString *)testGroup {
    NSString *group = [APHABTestingGroupProvider determineTestGroup:[self.testGroupInput unsignedIntegerValue]];
    
    return group;
}

#pragma mark - Private methods

- (void)generateTestGroupInputIfNeeded {
    if (self.testGroupInput) {
        return;
    }
    
    unsigned long result = [[self.uuid UUIDString] crc32];
    self.testGroupInput = @(result % 100);
    
    [self.userDefaults setObject:self.testGroupInput forKey:kAPHABTestingGroupInput];
    [self.userDefaults synchronize];
}

@end
