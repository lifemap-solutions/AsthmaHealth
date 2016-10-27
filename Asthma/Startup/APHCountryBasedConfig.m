//
//  APHCountryBasedConfig.m
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

@import APCAppCore;
#import "APHCountryBasedConfig.h"
#import "APHDashboardEditViewController.h"

@interface APHCountryBasedConfig ()

@property(strong, nonatomic) id<APHCountryConfig> config;

@end

@implementation APHCountryBasedConfig

-(instancetype)initWithUser:(APCUser *)user {
    self = [super init];
    
    if(self != nil) {
        
        self.user = user;
        [self createConfigForCountry];
        //observing changes for user, needed as at signup and signin country will change
        [user addObserver:self forKeyPath:@"country" options:0 context:NULL];
    }
    
    
    return self;
}
-(void)dealloc {
    [self.user removeObserver:self forKeyPath:@"country"];
}

-(BOOL)airQualityAllowed {
    return [self.config airQualityAllowed];
}

-(void)createConfigForCountry {
    NSString *countryCode = [self.user.country uppercaseString];
    
    if([countryCode isEqualToString:kUKCountry]) {
        self.config = [[UKConfig alloc] init];
    }
    else if([countryCode isEqualToString:kIECountry]) {
        self.config = [[IEConfig alloc] init];
    } else {
        self.config = [[USConfig alloc] init];
    }
}

-(NSString *)countryCode {
    return [self.config countryCode];
}

-(void)observeValueForKeyPath:(NSString *) __unused keyPath ofObject:(id)__unused object change:(NSDictionary *) __unused change context:(void *) __unused context {
    [self createConfigForCountry];
    
    [[NSNotificationCenter defaultCenter] postNotificationName: kCountryConfigReloaded
                                                         object:self];
}


@end

@implementation USConfig


-(BOOL)airQualityAllowed {
    return YES;
}

-(NSString *)countryCode {
    return kUSCountry;
}

@end

@implementation UKConfig


-(BOOL)airQualityAllowed {
    return NO;
}

-(NSString *)countryCode {
    return kUKCountry;
}

@end

@implementation IEConfig

-(NSString *)countryCode {
    return kIECountry;
}

@end