//
//  APHAwsClientIdUploader.h
//  Asthma
//
//  Created by Dariusz Lesniak on 20/01/2016.
//  Copyright © 2016 Apple, Inc. All rights reserved.
//

@import APCAppCore;

@interface APHAwsClientIdUploader : NSObject

-(instancetype)initWithUploader:(APCDataUploader*) dataUploader;

-(void)uploadAwsClientId: (NSString*) clientId;

@end
