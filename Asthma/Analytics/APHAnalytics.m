//
//  APHAnalytics.m
//  Asthma
//
//  Created by Matthew Wright on 5/18/15.
//  Copyright (c) 2015 Apple, Inc. All rights reserved.
//
#import "APHAnalytics.h"
#import "APHAwsClientIdUploader.h"
@import APCAppCore;

@implementation APHAnalytics

-(void) initAnalytics{
    self.appVersion = [NSString stringWithFormat:@"%@ (%@)", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"], [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]];
    //For debugging purposes only
    //[AWSLogger defaultLogger].logLevel = AWSLogLevelVerbose;
    
    // Create a credentials provider.
    //NSLog(@"Cognito identityPoolID --> %@",[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CognitoID"]);
    AWSCognitoCredentialsProvider *credentialsProvider = [[AWSCognitoCredentialsProvider alloc]
                                                          initWithRegionType: AWSRegionUSEast1
                                                          identityPoolId: [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CognitoID"]];
    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc]
                                              initWithRegion: AWSRegionUSEast1
                                              credentialsProvider: credentialsProvider];
    
    [AWSServiceManager defaultServiceManager].defaultServiceConfiguration = configuration;
    
    AWSMobileAnalyticsConfiguration *mobileAnalyticsConfiguration = [AWSMobileAnalyticsConfiguration new];
    mobileAnalyticsConfiguration.transmitOnWAN = YES;
    
    //NSLog(@"Cognito mobileAnalyticsForAppId --> %@",[[NSBundle mainBundle] objectForInfoDictionaryKey:@"AWSAppID"]);
    
    self.mobileAnalytics = [AWSMobileAnalytics
                                     mobileAnalyticsForAppId: [[NSBundle mainBundle] objectForInfoDictionaryKey:@"AWSAppID"] //Mobile Analytics App ID
                                     configuration: mobileAnalyticsConfiguration
                                     completionBlock: nil];
    
    id<AWSMobileAnalyticsEventClient> eventClient = self.mobileAnalytics.eventClient;
    
    [eventClient submitEvents];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(receiveNotification:)
     name:@"AnalyticsEvent"
     object:nil];

    //NSLog(@"Initialized Analytics");
}

-(void) receiveNotification:(NSNotification *)notification
{
    [self logMessage:[notification userInfo]];
}

-(void) logMessage:(NSDictionary*)data
{
    NSString *eventName = [data valueForKey:kAnalyticsEventKey];
    //NSLog(@"Received Event --> %@",eventName);
    
    id<AWSMobileAnalyticsEventClient> eventClient = self.mobileAnalytics.eventClient;
    id<AWSMobileAnalyticsEvent> analyticsEvent = [eventClient createEventWithEventType:eventName];
    
    //Add custom attributes if necessary
    for (NSString* key in data) {
        NSString* value = [data objectForKey:key];
        if(![key isEqualToString:kAnalyticsEventKey]){
            // NSLog(@"Custom event attribute --> %@: %@", key, value);
            [analyticsEvent addAttribute:value forKey:key];
        }
    }
    
    //add app version code
    [analyticsEvent addAttribute:self.appVersion forKey:@"version"];
    
    [eventClient recordEvent:analyticsEvent];
    
    //[eventClient submitEvents]; //TODO: Comment this out before submitting to production
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void) uploadAwsClientId {
    APHAwsClientIdUploader *awsIdUploader = [[APHAwsClientIdUploader alloc] initWithUploader:[[APCDataUploader alloc] initWithUploadReference:@"AwsClientIdTask"
                                                                                                                               schemaRevision:@"2"]];
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    if ([self.mobileAnalytics respondsToSelector:NSSelectorFromString(@"mobileAnalyticsContext")]) {
        id mobileAnalyticsContext = [self.mobileAnalytics performSelector:NSSelectorFromString(@"mobileAnalyticsContext")];
        
        if ([mobileAnalyticsContext respondsToSelector:NSSelectorFromString(@"uniqueId")]) {
            [awsIdUploader uploadAwsClientId:[mobileAnalyticsContext performSelector:NSSelectorFromString(@"uniqueId")]];
        }
        
    }
#pragma clang diagnostic pop
    
    
}


@end