//
//  APHAwsClientIdUploader.m
//  Asthma
//
//  Created by Dariusz Lesniak on 20/01/2016.
//  Copyright © 2016 Apple, Inc. All rights reserved.
//

#import "APHAwsClientIdUploader.h"
#import "APHAnalytics.h"

NSString * const kClientIdSentKey = @"awsClientIdSent";
NSString * const kClientIdFileName = @"AwsClientId";

@interface APHAwsClientIdUploader ()
@property(nonatomic, strong) APCDataUploader *dataUploader;

@end

@implementation APHAwsClientIdUploader

-(instancetype)initWithUploader:(APCDataUploader*) dataUploader {

    self = [super init];
    if (self) {
        _dataUploader = dataUploader;
    }
    return self;
}

-(void)uploadAwsClientId: (NSString*) clientId {
    if (clientId == nil) {
        return;
    }
    
    if ([self uploadingRequired:clientId]) {
        [self doUploadClientId:clientId];
    }
}

-(BOOL) uploadingRequired: (NSString*) clientId {
    return [[APCAppDelegate sharedAppDelegate].dataSubstrate.currentUser isConsented]
    && ![[[NSUserDefaults standardUserDefaults] objectForKey:kClientIdSentKey] isEqualToString:clientId];
}

-(void) doUploadClientId: (NSString*) clientId {
    
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), ^{
        
        [self.dataUploader insertIntoZipArchive:[self buildData:clientId] filename:kClientIdFileName];
        
        [self.dataUploader uploadWithCompletion:^{
            [[NSUserDefaults standardUserDefaults] setObject:clientId forKey: kClientIdSentKey];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }];
        
    });
}

-(NSDictionary*) buildData: (NSString*) clientId {
    
    NSMutableDictionary  *clientIdData = [NSMutableDictionary dictionary];
    clientIdData[@"item"] = kClientIdFileName;
    clientIdData[@"clientId"] = clientId;
    
    return clientIdData;
}


@end
