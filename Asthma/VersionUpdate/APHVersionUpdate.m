
// 
//  VersionUpdate.m
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

#import "APHVersionUpdate.h"

NSString * const kStoredVersionCheckDate = @"Stored Date From Last Version Check";
NSString * const kAppStoreLinkUniversal  = @"https://itunes.apple.com/lookup?id=%@";
NSString * const kLaunchAppStoreUrl      = @"https://itunes.apple.com/app/id%@";
NSString * const kItunesAppId            = @"972625668";

@interface APHVersionUpdate()

@property (nonatomic, strong) NSDictionary *appData;
@property (nonatomic, strong) NSDate *lastVersionCheckPerformedOnDate;
@property (nonatomic, copy) NSString *currentAppStoreVersion;
@property (nonatomic, copy) NSString *updateAvailableMessage;
@property (nonatomic, copy) NSString *theNewVersionMessage;
@property (nonatomic, copy) NSString *updateButtonText;
@property (nonatomic, copy) NSString *nextTimeButtonText;

@end

@implementation APHVersionUpdate

#pragma mark - Initialization
+ (APHVersionUpdate *)sharedInstance
{
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (id)init
{
    self = [super init];
    if (self) {
        _lastVersionCheckPerformedOnDate = [[NSUserDefaults standardUserDefaults] objectForKey:kStoredVersionCheckDate];
    }
    return self;
}

- (void)checkVersion
{
    if (![self lastVersionCheckPerformedOnDate]) {
        
        self.lastVersionCheckPerformedOnDate = [NSDate date];
        [self performVersionCheck];
    }
    
    if ([self numberOfDaysElapsedBetweenLastVersionCheckDate] > 3) {
        [self performVersionCheck];
    }
}

#pragma mark - Private
- (void)performVersionCheck
{
    NSString *storeString = [NSString stringWithFormat:kAppStoreLinkUniversal, kItunesAppId];
    
    NSURL *storeURL = [NSURL URLWithString:storeString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:storeURL];
    [request setHTTPMethod:@"GET"];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
                                            completionHandler:^(NSData *data, NSURLResponse * __unused response, NSError *error) {
                                                if ([data length] > 0 && !error) {
                                                    
                                                    self.appData = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
                                                    
                                                    dispatch_async(dispatch_get_main_queue(), ^{
                                                        
                                                        // Store version comparison date
                                                        self.lastVersionCheckPerformedOnDate = [NSDate date];
                                                        [[NSUserDefaults standardUserDefaults] setObject:[self lastVersionCheckPerformedOnDate] forKey:kStoredVersionCheckDate];
                                                        [[NSUserDefaults standardUserDefaults] synchronize];
                                                        
                                                        /**
                                                         Current version that has been uploaded to the AppStore.
                                                         Used to contain all versions, but now only contains the latest version.
                                                         Still returns an instance of NSArray.
                                                         */
                                                        NSArray *versionsInAppStore = [[self.appData valueForKey:@"results"] valueForKey:@"version"];
                                                        
                                                        if ([versionsInAppStore count]) {
                                                            _currentAppStoreVersion = [versionsInAppStore objectAtIndex:0];
                                                            [self checkIfAppStoreVersionIsNewestVersion:_currentAppStoreVersion];
                                                        }
                                                    });
                                                }
                                            }];
    [task resume];
}

- (NSUInteger)numberOfDaysElapsedBetweenLastVersionCheckDate
{
    NSCalendar *currentCalendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [currentCalendar components:NSCalendarUnitDay
                                                      fromDate:[self lastVersionCheckPerformedOnDate]
                                                        toDate:[NSDate date]
                                                       options:0];
    return [components day];
}

- (void)checkIfAppStoreVersionIsNewestVersion:(NSString *)currentAppStoreVersion
{
    if ([[self currentVersion] compare:currentAppStoreVersion options:NSNumericSearch] == NSOrderedAscending) {
        [self localizeAlertStringsForCurrentAppStoreVersion:currentAppStoreVersion];
        [self showAlertWithAppStoreVersion];
    }
}

- (void)localizeAlertStringsForCurrentAppStoreVersion:(NSString *)currentAppStoreVersion
{
    NSString *appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleNameKey];
    
    _updateAvailableMessage = NSLocalizedString(@"Update Available", nil);
    _theNewVersionMessage = [NSString stringWithFormat:NSLocalizedString(@"A new version of %@ is available. Please update to version %@ now.", nil), appName, currentAppStoreVersion];
    _updateButtonText = NSLocalizedString(@"Update", nil);
    _nextTimeButtonText = NSLocalizedString(@"Dismiss", nil);
    
}

- (void)showAlertWithAppStoreVersion
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle: _updateAvailableMessage
                                                        message: _theNewVersionMessage
                                                       delegate: self
                                              cancelButtonTitle: _updateButtonText
                                              otherButtonTitles: _nextTimeButtonText, nil];
    
    [alertView show];
}


- (void)alertView:(UIAlertView *) __unused alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (buttonIndex == 0) {
        [self launchAppStore];
    }
}

- (void)launchAppStore
{
    
    NSString *iTunesString = [NSString stringWithFormat:kLaunchAppStoreUrl, kItunesAppId];
    NSURL *iTunesURL = [NSURL URLWithString:iTunesString];
    [[UIApplication sharedApplication] openURL:iTunesURL];
    
}

- (NSString *)currentVersion
{
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
}

@end
