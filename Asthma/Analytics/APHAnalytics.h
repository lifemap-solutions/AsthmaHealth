//
//  APHAnalytics.h
//  Asthma
//
//  Created by Matthew Wright on 5/18/15.
//  Copyright (c) 2015 Apple, Inc. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <AWSCore/AWSCore.h>

@interface APHAnalytics : NSObject

@property (nonatomic, strong) AWSMobileAnalytics* mobileAnalytics;
@property (nonatomic, strong) NSString* appVersion;

-(void) initAnalytics;
-(void) receiveNotification:(NSNotification *)notification;
-(void) logMessage:(NSDictionary*)data;
-(void) uploadAwsClientId;

@end