//
//  APHReconsentTaskViewController.m
//  Asthma
//
//  Created by David Coleman on 20/08/2015.
//  Copyright (c) 2015 Apple, Inc. All rights reserved.
//
#import "APHReconsentTaskViewController.h"
#import "APHAppDelegate.h"

NSString * const kReconsent = @"reconsented";
NSString * const kConfirmNotReconsenting = @"confirmNotReconsenting";

@interface APHReconsentTaskViewController ()

- (void) showReconsentAcceptedDialog:(ORKStepViewController *)  stepViewController continueAction:(void (^)(void)) confirmedReconsentAction;
- (void) showRejectedConsentDialog:(ORKStepViewController *) stepViewController
         confirmNotReconsentAction:(void (^)(void)) confirmNotReconsentAction;
- (void) showConfirmNotReconsentDialog: (ORKStepViewController *) stepViewController
                             yesAction:(void (^)(void)) confirmNotReconsentAction
                              noAction:(void (^)(void)) goBackAction;

@end

@implementation APHReconsentTaskViewController

- (NSString*) createResultSummary
{
    NSMutableDictionary * dictionary = [NSMutableDictionary dictionary];

    // Re-consent
    {
        ORKBooleanQuestionResult *result = (ORKBooleanQuestionResult *)[self answerForSurveyStepIdentifier:kReconsent];
        NSNumber * answer = [result booleanAnswer];
        if (answer) {
            dictionary[kReconsent] = answer;
            
            APHAppDelegate* appDelegate = ((APHAppDelegate *)[UIApplication sharedApplication].delegate );
            if([answer intValue] == 0){
                [appDelegate.analytics logMessage:(@{kAnalyticsEventKey : kAnalyticsReconsent, @"Answer" : @"NO",
                                                     @"time" : [appDelegate getStringFromDate:[NSDate date]]})];
            } else {
                [appDelegate.analytics logMessage:(@{kAnalyticsEventKey : kAnalyticsReconsent, @"Answer" : @"YES",
                                                     @"time" : [appDelegate getStringFromDate:[NSDate date]]})];
            }
        }
    }
    
    return [dictionary JSONString];
}

- (void)stepViewController:(ORKStepViewController *)stepViewController didFinishWithNavigationDirection:(ORKStepViewControllerNavigationDirection)direction {

    ORKBooleanQuestionResult *result = (ORKBooleanQuestionResult *) [(ORKCollectionResult *) [stepViewController result] firstResult];

    NSNumber * answer = [result booleanAnswer];

    // if user answered no, pause moving onto next step and prompt action from user
    if (direction == ORKStepViewControllerNavigationDirectionForward && answer) {

        if ([answer intValue] == YES) {

            void (^confirmReconsentAction)(void) = ^{
                // Continue with persisting survey results
                [super stepViewController:stepViewController didFinishWithNavigationDirection:direction];
            };

            [self showReconsentAcceptedDialog:stepViewController continueAction:confirmReconsentAction];
        } else {

            void (^confirmNotReconsentAction)(void) = ^{
                // Continue with persisting survey results
                [super stepViewController:stepViewController didFinishWithNavigationDirection:direction];
            };
            void (^goBackAction)(void) = ^{
                // Pause survey at same step, do not move forward
                [self goBackward];
            };

            [self showConfirmNotReconsentDialog:stepViewController
                      yesAction:confirmNotReconsentAction
                      noAction:goBackAction];
        }

    } else {
        [super stepViewController:stepViewController didFinishWithNavigationDirection:direction];
    }
}

// Disable cancel button
-(void)stepViewControllerWillAppear:(ORKStepViewController *)viewController
{
    viewController.cancelButtonItem=nil;
}

// Set optional to No, each step is mandatory
-(BOOL)taskViewController:(ORKTaskViewController *) __unused taskViewController shouldPresentStep:(ORKStep *)step{
    step.optional = NO;
    return YES;
}

- (ORKResult *) answerForSurveyStepIdentifier: (NSString*) identifier {
    NSArray * stepResults = [(ORKStepResult*)[self.result resultForIdentifier:identifier] results];
    ORKStepResult *answer = (ORKStepResult *)[stepResults firstObject];
    return answer;
}

// Return control to password view controller (should pass reconsent check this time)
- (void)taskViewController:(ORKTaskViewController *) __unused taskViewController didFinishWithReason:(ORKTaskViewControllerFinishReason) __unused reason error:(nullable NSError *) __unused error {
    [super taskViewController:taskViewController didFinishWithReason: reason error: error];

    // Return view back to passcode view controller
    // TODO: Perhaps add reconsent flag to confirm that app was re-consented/not-reconsented
    [[APCAppDelegate sharedAppDelegate] passcodeViewControllerDidSucceed: nil];
}


- (void) showConfirmNotReconsentDialog: (ORKStepViewController *) stepViewController
                yesAction:(void (^)(void)) confirmNotReconsentAction
                          noAction:(void (^)(void)) goBackAction {

    UIAlertController * confirmNotReconsentDialog = [UIAlertController
                                                     alertControllerWithTitle: NSLocalizedString(@"CONFIRM_NOT_RECONSENTING_TITLE", @"")
                                                     message:NSLocalizedString(@"CONFIRM_NOT_RECONSENTING_BLURB", @"")
                                                     preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction* acceptReconsent = [UIAlertAction
                                      actionWithTitle:NSLocalizedString(@"Yes", @"")
                                      style:UIAlertActionStyleDefault
                                      handler:^(UIAlertAction * __unused action)
                                      {
                                          [confirmNotReconsentDialog dismissViewControllerAnimated:YES completion:nil];

                                          [self showRejectedConsentDialog:stepViewController confirmNotReconsentAction:confirmNotReconsentAction];

                                      }];

    UIAlertAction* doNotAcceptReconsentAction = [UIAlertAction
                                                 actionWithTitle:NSLocalizedString(@"No", @"")
                                                 style:UIAlertActionStyleDefault
                                                 handler:^(UIAlertAction * __unused action)
                                                 {
                                                     [confirmNotReconsentDialog dismissViewControllerAnimated:YES completion:nil];

                                                     goBackAction();

                                                 }];

    [confirmNotReconsentDialog addAction:acceptReconsent];
    [confirmNotReconsentDialog addAction:doNotAcceptReconsentAction];

     [stepViewController presentViewController:confirmNotReconsentDialog animated:YES completion:nil];
}

- (void) showRejectedConsentDialog:(ORKStepViewController *) stepViewController
confirmNotReconsentAction:(void (^)(void)) confirmNotReconsentAction{

    UIAlertController * rejectedConsentDialog = [UIAlertController
                                                 alertControllerWithTitle: NSLocalizedString(@"CONFIRMED_NOT_RECONSENTING_TITLE", @"")
                                                 message:NSLocalizedString(@"CONFIRMED_NOT_RECONSENTING_BLURB", @"")
                                                 preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction* ok = [UIAlertAction
                         actionWithTitle:NSLocalizedString(@"Continue", @"")
                         style:UIAlertActionStyleDefault
                         handler:^(UIAlertAction * __unused action)
                         {
                             [rejectedConsentDialog dismissViewControllerAnimated:YES completion:nil];

                             // Return to user screen
                            confirmNotReconsentAction();
                         }];
    [rejectedConsentDialog addAction:ok];

    [stepViewController presentViewController:rejectedConsentDialog animated:YES completion:nil];
}

- (void) showReconsentAcceptedDialog:(ORKStepViewController *)  stepViewController continueAction:(void (^)(void)) confirmedReconsentAction {

    UIAlertController * reconsentedAlert = [UIAlertController
                                            alertControllerWithTitle: NSLocalizedString(@"RECONSENTED_TITLE", @"")
                                            message:NSLocalizedString(@"RECONSENTED_BLURB", @"")
                                            preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction * ok = [UIAlertAction
                          actionWithTitle:NSLocalizedString(@"Continue", @"")
                          style:UIAlertActionStyleDefault
                          handler:^(UIAlertAction * __unused action)
                          {
                              [reconsentedAlert dismissViewControllerAnimated:YES completion:nil];
                              confirmedReconsentAction();
                          }];
    [reconsentedAlert addAction:ok];

    [stepViewController presentViewController:reconsentedAlert animated:YES completion:nil];
}

@end