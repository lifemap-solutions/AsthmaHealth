//
//  APHTwentyThreeAndMeConsentTask.m
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

#import "APHTwentyThreeAndMeConsentTask.h"
#import "APHConsentDocumentMapper.h"
#import "APHBooleanQuestionStep.h"
#import "APHQuizQuestionStep.h"

NSString * const k23andMeConsentIdentifier = @"23andMeConsent";
NSString * const k23andMeConsentDocumentFile = @"APH23andMeConsentDocument.json";
NSString * const kSignatureIdentifier = @"participant";

NSString * const kStepIdentifier23andMeCustomer = @"customerStep";
NSString * const kStepIdentifierCancel = @"cancelStep";
NSString * const kStepIdentifierInformation = @"informationStep";
NSString * const kStepIdentifierQuizQuestion1 = @"question1";
NSString * const kStepIdentifierQuizQuestion2 = @"question2";
NSString * const kStepIdentifierQuizQuestion3 = @"question3";
NSString * const kStepIdentifierQuizEvaluation = @"quizEvaluation";
NSString * const kStepIdentifierReview = @"reviewStep";
NSString * const kStepIdentifierCompletion = @"completionStep";

@implementation APHTwentyThreeAndMeConsentTask

- (instancetype)init {
    
    NSArray *consentSteps = [self consentSteps];
    
    self = [super initWithIdentifier:k23andMeConsentIdentifier steps:consentSteps];
    if (!self) return nil;
    
    _quizResults = [NSMutableDictionary dictionary];
    
    return self;
}

- (NSArray *)consentSteps {
    
    APHConsentDocumentMapper *mapper = [[APHConsentDocumentMapper alloc] initWithDocument:k23andMeConsentDocumentFile];
    
    ORKConsentDocument *document = [ORKConsentDocument new];
    document.title = NSLocalizedString(@"23ANDME_CONSENT_TITLE", nil);
    document.htmlReviewContent = [mapper htmlReviewContent];
    document.sections = [mapper sections];
    
    NSMutableArray *steps = [NSMutableArray array];
    
    //Are you a current 23andMe customer?
    {
        ORKQuestionStep *step = [ORKQuestionStep questionStepWithIdentifier:kStepIdentifier23andMeCustomer title:NSLocalizedString(@"23ANDME_CUSTOMER_QUESTION", nil) answer:[ORKBooleanAnswerFormat booleanAnswerFormat]];
        step.optional = NO;
        [steps addObject:step];
    }
    
    //cancel step
    {
        ORKInstructionStep *step = [[ORKInstructionStep alloc] initWithIdentifier:kStepIdentifierCancel];
        step.title = NSLocalizedString(@"23ANDME_CONSENT_CANCELLED_TITLE", nil);
        step.text  = NSLocalizedString(@"23ANDME_CONSENT_CANCELLED_MESSAGE", nil);
        step.image = [UIImage imageNamed:@"cross"];
        [steps addObject:step];
    }
    
    //information step
    {
        if (document.sections) {
            ORKVisualConsentStep *step = [[ORKVisualConsentStep alloc] initWithIdentifier:kStepIdentifierInformation document:document];
            [step setOptional:NO];
            [steps addObject:step];
        }
    }
    
    //quiz steps
    {
        {
            APHQuizQuestionStep *step = [[APHQuizQuestionStep alloc] initWithIdentifier:kStepIdentifierQuizQuestion1];
            step.correctAnswer = false;
            step.questionText = NSLocalizedString(@"23ANDME_CONSENT_QUIZ_QUESTION1_TEXT", nil);
            step.questionTrueFeedback = NSLocalizedString(@"23ANDME_CONSENT_QUIZ_QUESTION1_TRUE_FEEDBACK", nil);
            step.questionTrueFeedbackEmphasizedPhrase = NSLocalizedString(@"23ANDME_CONSENT_QUIZ_QUESTION1_TRUE_FEEDBACK_EMPHASIZE", nil);
            step.questionFalseFeedback = NSLocalizedString(@"23ANDME_CONSENT_QUIZ_QUESTION1_FALSE_FEEDBACK", nil);
            step.questionFalseFeedbackEmphasizedPhrase = NSLocalizedString(@"23ANDME_CONSENT_QUIZ_QUESTION1_FALSE_FEEDBACK_EMPHASIZE", nil);
            [steps addObject:step];
        }
        
        {
            APHQuizQuestionStep *step = [[APHQuizQuestionStep alloc] initWithIdentifier:kStepIdentifierQuizQuestion2];
            step.correctAnswer = true;
            step.questionText = NSLocalizedString(@"23ANDME_CONSENT_QUIZ_QUESTION2_TEXT", nil);
            step.questionTrueFeedback = NSLocalizedString(@"23ANDME_CONSENT_QUIZ_QUESTION2_TRUE_FEEDBACK", nil);
            step.questionTrueFeedbackEmphasizedPhrase = NSLocalizedString(@"23ANDME_CONSENT_QUIZ_QUESTION2_TRUE_FEEDBACK_EMPHASIZE", nil);
            step.questionFalseFeedback = NSLocalizedString(@"23ANDME_CONSENT_QUIZ_QUESTION2_FALSE_FEEDBACK", nil);
            step.questionFalseFeedbackEmphasizedPhrase = NSLocalizedString(@"23ANDME_CONSENT_QUIZ_QUESTION2_FALSE_FEEDBACK_EMPHASIZE", nil);
            [steps addObject:step];
        }
        
        {
            APHQuizQuestionStep *step = [[APHQuizQuestionStep alloc] initWithIdentifier:kStepIdentifierQuizQuestion3];
            step.correctAnswer = false;
            step.questionText = NSLocalizedString(@"23ANDME_CONSENT_QUIZ_QUESTION3_TEXT", nil);
            step.questionTrueFeedback = NSLocalizedString(@"23ANDME_CONSENT_QUIZ_QUESTION3_TRUE_FEEDBACK", nil);
            step.questionTrueFeedbackEmphasizedPhrase = NSLocalizedString(@"23ANDME_CONSENT_QUIZ_QUESTION3_TRUE_FEEDBACK_EMPHASIZE", nil);
            step.questionFalseFeedback = NSLocalizedString(@"23ANDME_CONSENT_QUIZ_QUESTION3_FALSE_FEEDBACK", nil);
            step.questionFalseFeedbackEmphasizedPhrase = NSLocalizedString(@"23ANDME_CONSENT_QUIZ_QUESTION3_FALSE_FEEDBACK_EMPHASIZE", nil);
            [steps addObject:step];
        }
        
        {
            ORKStep *step = [[ORKStep alloc] initWithIdentifier:kStepIdentifierQuizEvaluation];
            [steps addObject:step];
        }
    }
    
    //review and signature step
    {
        APCUser *user = [APCAppDelegate sharedAppDelegate].dataSubstrate.currentUser;
        ORKConsentSignature *signature = [ORKConsentSignature signatureForPersonWithTitle:NSLocalizedString(@"23ANDME_SIGNATORY_TITLE", nil) dateFormatString:nil identifier:kSignatureIdentifier givenName:user.name familyName:nil signatureImage:nil dateString:nil];
        signature.requiresName = NO;
        ORKConsentReviewStep *step = [[ORKConsentReviewStep alloc] initWithIdentifier:kStepIdentifierReview signature:signature inDocument:document];
        [steps addObject:step];
    }
    
    //completion step
    {
        ORKInstructionStep *step = [[ORKInstructionStep alloc] initWithIdentifier:kStepIdentifierCompletion];
        step.title = NSLocalizedString(@"23ANDME_CONSENT_SUCCESS_TITLE", nil);
        step.text  = NSLocalizedString(@"23ANDME_CONSENT_SUCCESS_MESSAGE", nil);
        step.image = [UIImage imageNamed:@"checkmark"];
        [steps addObject:step];
    }
    
    return steps;
}

- (ORKStep *)stepBeforeStep:(ORKStep *)step withResult:(ORKTaskResult *)result {
    
    ORKStep *previousStep = [super stepBeforeStep:step withResult:result];
    
    if ([step.identifier isEqualToString:kStepIdentifierInformation]) {
        
        return [self stepWithIdentifier:kStepIdentifier23andMeCustomer];
    }
    
    return previousStep;
}

/**
 *  Transition logic for customer question, cancel and quiz steps
 */
- (ORKStep *)stepAfterStep:(ORKStep *)step withResult:(ORKTaskResult *)__unused result {
    
    ORKStep *nextStep = [super stepAfterStep:step withResult:result];
    
    if ([step.identifier isEqualToString:kStepIdentifier23andMeCustomer]) {
        
        if (self.customerQuestionResult.booleanAnswer.boolValue == YES) {
            nextStep = [self stepWithIdentifier:kStepIdentifierInformation];
        }
    } else if ([step.identifier isEqualToString:kStepIdentifierCancel]) {
        
        nextStep = nil;
    } else if ([step.identifier isEqualToString:kStepIdentifierQuizEvaluation]) {
        
        if (!self.passedQuiz) {
            //If the user failed quiz for the first time he is able to retake the quiz
            if (self.quizFailedAttempts == 1) {
                
                nextStep = [self stepWithIdentifier:kStepIdentifierQuizQuestion1];//return to quiz
                //If the user failed quiz more than one time he needs to review the consent screens
            } else {
                
                nextStep = [self stepWithIdentifier:kStepIdentifierInformation];//return to consent review step
            }
        }
    }
    
    return nextStep;
}

@end
