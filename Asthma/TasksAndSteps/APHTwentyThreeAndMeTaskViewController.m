//
//  APH23andmeTaskViewController.m
//  Asthma
//
//  Created by Dariusz Lesniak on 11/03/2016.
//  Copyright © 2016 Apple, Inc. All rights reserved.
//

#import "APHTwentyThreeAndMeTaskViewController.h"
#import "APHTwentyThreeAndMeClient.h"
#import "APHTwentyThreeAndMeUser.h"

@interface APHTwentyThreeAndMeTaskViewController ()

@end

@implementation APHTwentyThreeAndMeTaskViewController

+(id<ORKTask>)createTask: (APCScheduledTask*) __unused scheduledTask {
    ORKTwentyThreeAndMeConnectTaskViewController *controller = [ORKTwentyThreeAndMeConnectTaskViewController twentyThreeAndMeTaskViewControllerWithIdentifier:@"connectWithTTAM"
                                                                                                                                                 authClientId:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"23andmeClientId"]
                                                                                                                                             authClientSecret:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"23andmeSecret"]
                                                                                                                                                   authScopes:@"basic genomes"
                                                                                                                                      investigatorDisplayName:@"Mount Sinai"
                                                                                                                                             studyDisplayName:@"Asthma Health"
                                                                                                                                            studyContactEmail:@"asthmamobilehealth@mssm.edu"
                                                                                                                                              baseURLOverride:[APHTwentyThreeAndMeClient sharedClient].baseUrl];
    
    
    
    return controller.task;
}
- (void) processTaskResult
{
    [self process23andmedata];
}

-(void) process23andmedata {
    
    ORKTwentyThreeAndMeConnectResult *result = [self get23andmeResult];
    
    if (!result) {
        return;
    }
    
    NSDate * fetchUserStart = [NSDate date];
    [[APHTwentyThreeAndMeClient sharedClient] getUser: result.authToken
                                    completionHandler:^(APHTwentyThreeAndMeUser *user, NSError *error) {
                                        NSTimeInterval duration = [[NSDate date] timeIntervalSinceDate:fetchUserStart];
                                        
                                        if (error) {
                                            [APHTwentyThreeAndMeClient logError:error forLocation:@"FetchUser"];
                                        }
                                        
                                        APCLogEventWithData(@"23andmeFetchUser", (@{@"duration": [NSString stringWithFormat:@"%f", duration]}));
                                        [[APHTwentyThreeAndMeClient sharedClient] downloadGenome:user];
                                    }];
    
}

-(ORKTwentyThreeAndMeConnectResult*) get23andmeResult {
    __block ORKTwentyThreeAndMeConnectResult *result;
    
    for (ORKStepResult *survey in self.result.results) {
        [survey.results enumerateObjectsUsingBlock:^(ORKQuestionResult *questionResult, NSUInteger __unused idx, BOOL * __unused stop)
         {
             if ([questionResult isKindOfClass:[ORKTwentyThreeAndMeConnectResult class]]) {
                 result = (ORKTwentyThreeAndMeConnectResult*) questionResult;
             }
         }];
    }
    return result;
}

@end
