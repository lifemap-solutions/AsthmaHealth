//
//  APHAppInformation.m
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

#import "APHAppInformation.h"

NSString * const kAppInstallationVersion = @"APHAppInstallationVersion";

@interface APHAppInformation ()

@property (nonatomic, strong) NSUserDefaults *userDefaults;
@property (nonatomic, strong) APCAppDelegate *appDelegate;
@property (nonatomic, strong) NSBundle *bundle;

@end

@implementation APHAppInformation

- (instancetype)initWithUserDefaults:(NSUserDefaults *)userDefaults appDelegate:(APCAppDelegate *)appDelegate bundle:(NSBundle *)bundle {
    
    self = [super init];
    if (!self) return nil;
    
    _userDefaults = userDefaults;
    _appDelegate = appDelegate;
    _bundle = bundle;
    
    return self;
}

- (NSString *)currentVersion {
    
    return [self.bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
}

- (void)determineInstallationVersion {
    NSString *appInstallationVersion = [self.userDefaults objectForKey:kAppInstallationVersion];
    
    if (!appInstallationVersion) {
        
        if ([self.appDelegate doesPersisteStoreExist] == NO) {
            
            [self.userDefaults setObject:[self currentVersion] forKey:kAppInstallationVersion];
            [self.userDefaults synchronize];
        }
    }
}

- (BOOL)isFirstTimeInstallation {
    
    NSString *appInstallationVersion = [self.userDefaults objectForKey:kAppInstallationVersion];
    
    if ([[self currentVersion] compare:appInstallationVersion options:NSNumericSearch] == NSOrderedSame) {
        
        return YES;
    }
    
    return NO;
}

@end

@implementation APHAppInformation (DefaultInitializer)

- (instancetype)init {
    self = [super init];
    if (!self) return nil;
    
    _userDefaults = [NSUserDefaults standardUserDefaults];
    _appDelegate = (APCAppDelegate *)[[UIApplication sharedApplication] delegate];
    _bundle = [NSBundle mainBundle];
    
    return self;
}

@end
