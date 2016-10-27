//
//  APHConsentUpdate.m
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

#import "APHConsentUpdate.h"
#import "APHAppInformation.h"

NSString * const kDefaultConsentFileName = @"consent.pdf";
NSString * const kConsentLastUpdateDateKey = @"APHLastConsentUpdateDateKey";

@interface APHConsentUpdate ()

@property (nonatomic, strong) NSFileManager *fileManager;
@property (nonatomic, strong) NSUserDefaults *userDefaults;
@property (nonatomic, strong) id <APHAppInformationProvider> appInformation;

@end

@implementation APHConsentUpdate

- (instancetype)initWithFileManager:(NSFileManager *)fileManager userDefaults:(NSUserDefaults *)userDefaults appInformation:(id <APHAppInformationProvider>)appInformation {
    
    self = [super init];
    if (!self) return nil;
    
    _fileManager = fileManager;
    _userDefaults = userDefaults;
    _appInformation = appInformation;
    
    return self;
}

- (NSDate *)consentDate {
    
    NSString *consentFilePath = [[NSBundle mainBundle] pathForResource:[kDefaultConsentFileName stringByDeletingPathExtension] ofType:[kDefaultConsentFileName pathExtension]];
    
    NSError *error;
    
    NSDictionary *attributes = [self.fileManager attributesOfItemAtPath:consentFilePath error:&error];
    if (error) {
        
        NSLog(@"NSFileManager Error: %@", error);
        return nil;
    }
    
    return [attributes fileModificationDate];
}

- (BOOL)hasConsentChanged {
    
    NSDate *lastConsentUpdate = [self.userDefaults objectForKey:kConsentLastUpdateDateKey];
    
    if (!lastConsentUpdate) {
        
        // if the app version which supports `APHConsentUpdate` is installed for the 1st time
        if ([self.appInformation isFirstTimeInstallation]) {
            
            return NO;
        }
        
        return YES;
    }
    
    if ([[self consentDate] compare:lastConsentUpdate] == NSOrderedDescending) {
        
        return YES;
    }
    
    return NO;
}

- (void)markConsentAsUpdated {
    
    NSDate *consentDate = [self consentDate];
    
    if (consentDate) {
        [self.userDefaults setObject:consentDate forKey:kConsentLastUpdateDateKey];
        [self.userDefaults synchronize];
    }
}

- (BOOL)checkConsentUpdate {
    
    BOOL consentHasChanged = [self hasConsentChanged];
    NSDate *lastConsentUpdate = [self.userDefaults objectForKey:kConsentLastUpdateDateKey];
    
    if (consentHasChanged || !lastConsentUpdate) {
        
        [self markConsentAsUpdated];
    }
    
    return consentHasChanged;
}

+ (void)showConsentUpdateAlert:(UIViewController *)presentingViewController completion:(void (^)(void))completion {
    
    NSString *title = NSLocalizedString(@"CONSENT_UPDATE_TITLE", nil);
    NSString *message = NSLocalizedString(@"CONSENT_UPDATE_MESSAGE", nil);
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull __unused action) {
        
        if (completion) {
            completion();
        }
    }];
    
    [alert addAction:defaultAction];
    [presentingViewController presentViewController:alert animated:YES completion:nil];
}

@end

@implementation APHConsentUpdate (DefaultInitializer)

- (instancetype)init {
    self = [super init];
    if (!self) return nil;
    
    _fileManager = [NSFileManager defaultManager];
    _userDefaults = [NSUserDefaults standardUserDefaults];
    _appInformation = [APHAppInformation new];
    
    return self;
}

@end
