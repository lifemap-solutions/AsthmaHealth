//
//  APHTwentyThreeAndMeConsentTaskViewController.m
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

#import "APHTwentyThreeAndMeConsentTaskViewController.h"
#import "APHTwentyThreeAndMeConsentTask.h"
#import "APHTwentyThreeAndMeTaskViewController.h"
#import "APHAppDelegate.h"
#import "APHConstants.h"
#import "APHQuizStepViewController.h"
#import "APHQuizEvaluationViewController.h"
#import "APHQuizQuestionStep.h"
#import "APHTwentyThreeAndMeService.h"

@implementation APHTwentyThreeAndMeConsentTaskViewController

+ (id<ORKTask>)createTask:(APCScheduledTask*) __unused scheduledTask
{
    return [APHTwentyThreeAndMeConsentTask new];
}

#pragma mark - ORKStepViewControllerDelegate

/**
 *  Providing step titles
 */
- (void)stepViewControllerWillAppear:(ORKStepViewController *)viewController {
    
    if ([viewController isKindOfClass:[ORKStepViewController class]]) {
        viewController.navigationController.navigationBar.topItem.title = NSLocalizedString(@"Consent", nil);
    }
    
    if ([viewController isKindOfClass:[APHQuizStepViewController class]]) {
        viewController.navigationController.navigationBar.topItem.title = NSLocalizedString(@"Quiz", nil);
    }
    
    if ([viewController isKindOfClass:[APHQuizEvaluationViewController class]]) {
        viewController.navigationController.navigationBar.topItem.title = NSLocalizedString(@"Quiz Evaluation", nil);
    }
}

/**
 *  Gathering user signature result
 */
- (void)stepViewController:(ORKStepViewController *)stepViewController didFinishWithNavigationDirection:(ORKStepViewControllerNavigationDirection)direction {
    
    [super stepViewController:stepViewController didFinishWithNavigationDirection:direction];
    
    if (direction != ORKStepViewControllerNavigationDirectionForward) {
        return;
    }
    
    if ([stepViewController.result.identifier isEqualToString:kStepIdentifierReview]) {
        
        for (ORKStepResult *result in stepViewController.result.results) {
            if ([result isKindOfClass:[ORKConsentSignatureResult class]]) {
                self.signatureResult = (ORKConsentSignatureResult*)result;
            }
        }
        
        if (!self.signatureResult.consented) {
            
            [self taskViewController:stepViewController.taskViewController didFinishWithReason:ORKTaskViewControllerFinishReasonDiscarded error:nil];
        }
    }
}

/**
 *  Gathering quiz results for each step
 */
- (void)stepViewControllerResultDidChange:(ORKStepViewController *)stepViewController{
    
    NSString *stepIdentifier = [stepViewController.step identifier];
    APHTwentyThreeAndMeConsentTask *task = (APHTwentyThreeAndMeConsentTask *)self.task;
    
    if ([stepViewController isKindOfClass:[APHQuizStepViewController class]]) {
        APHQuizStepViewController *quizStepViewController = (APHQuizStepViewController *)stepViewController;
        ORKQuestionResult *result = quizStepViewController.questionResult;
        if (result) {
            [task.quizResults setObject:result forKey:result.identifier];
        }
    } else if ([stepIdentifier isEqualToString:kStepIdentifier23andMeCustomer]) {
        ORKBooleanQuestionResult *result = stepViewController.result.results.firstObject;
        task.customerQuestionResult = result;
    }
}

#pragma mark - ORKTaskViewControllerDelegate

/**
 *  Gathering quiz summary before quiz evaluation step
 */
- (BOOL)taskViewController:(ORKTaskViewController *)__unused taskViewController shouldPresentStep:(ORKStep *)step {
    
    if (![step.identifier isEqualToString:kStepIdentifierQuizEvaluation]) return YES;
    
    APHTwentyThreeAndMeConsentTask *task = (APHTwentyThreeAndMeConsentTask *)self.task;
    NSUInteger correctCount = 0;
    
    for (NSString *identifier in task.quizResults) {
        
        ORKBooleanQuestionResult *result = task.quizResults[identifier];
        ORKStep *step = [task stepWithIdentifier:result.identifier];
        
        if (![step isKindOfClass:[APHQuizQuestionStep class]]) continue;
        
        APHQuizQuestionStep *quizStep = (APHQuizQuestionStep *)step;
        
        if (result.booleanAnswer.boolValue == quizStep.correctAnswer) {
            correctCount++;
        }
    }
    
    if (correctCount < task.quizResults.count){
        task.quizFailedAttempts++;
        task.passedQuiz = NO;
    } else {
        task.passedQuiz = YES;
    }
    
    return YES;
}

/**
 *  Providing user interface for quiz steps
 */
- (ORKStepViewController *)taskViewController:(ORKTaskViewController *) __unused taskViewController viewControllerForStep:(ORKStep *)step {
    
    if ([step isKindOfClass:[APHQuizQuestionStep class]]) {
        APHQuizStepViewController *questionStepViewController = [[UIStoryboard storyboardWithName:@"APHOnboarding" bundle:nil] instantiateViewControllerWithIdentifier:@"APHQuizStepViewController"];
        
        questionStepViewController.step = step;
        questionStepViewController.feedbackFontSize = 14.0;
        questionStepViewController.delegate = self;
        return questionStepViewController;
        
    }
    
    if ([step.identifier isEqualToString:kStepIdentifierQuizEvaluation]) {
        APHQuizEvaluationViewController *quizEvaluation = [[UIStoryboard storyboardWithName:@"APHOnboarding" bundle:nil] instantiateViewControllerWithIdentifier:@"APHQuizEvaluationViewController"];
        quizEvaluation.step = step;
        quizEvaluation.delegate = self;
        APHTwentyThreeAndMeConsentTask *task = (APHTwentyThreeAndMeConsentTask *)self.task;
        quizEvaluation.passedQuiz = task.passedQuiz;
        quizEvaluation.failedAttempts = task.quizFailedAttempts;
        return quizEvaluation;
    }
    
    return nil;
}


- (void)processTaskResult {
    
    APHTwentyThreeAndMeConsentTask *task = (APHTwentyThreeAndMeConsentTask *)self.task;
    
    if (task.customerQuestionResult.booleanAnswer.boolValue == NO) {
        return;
    }
    
    ORKConsentSignature *signature = self.signatureResult.signature;
    
    APCUser *user = self.appDelegate.dataSubstrate.currentUser;
    [user sendGeneticsUserConsent:signature.givenName
                    withSignature:signature.signatureImage
            withSubpopulationGuid: [[NSBundle mainBundle] objectForInfoDictionaryKey:@"geneticsSubpopulation"]
                   withCompletion:^(NSError *error) {
                       
                       if (!error || error.code == 409) { //409 indicates a conflict, user has already consented
                           [self trySchedule23andmeActivity];
                       } else {
                           APCLogError2(error);
                       }
                   }];
    
}

- (void)trySchedule23andmeActivity {
    APHTwentyThreeAndMeService *service = [[APHTwentyThreeAndMeService alloc] initWithScheduler:self.appDelegate.scheduler];
    [service checkIfSharingTaskIsScheduledForToday:^(BOOL scheduled) {
        if (!scheduled) {
            [service scheduleSharingTask];
        }
    }];
}

@end
