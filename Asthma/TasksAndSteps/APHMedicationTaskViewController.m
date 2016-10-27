//
//  APHMedicationTaskViewController.m
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
//

#import "APHMedicationTaskViewController.h"
#import "APHConstants.h"

NSString * const kPrescribedControlMedStepIdentifier = @"prescribed_asthma_control_medication";
NSString * const kInhaledMedStepIdentifier = @"daily_inhaled_medicine";
NSString * const kAdvairDoseStepIdentifier = @"advair_diskus_dose";
NSString * const kAlvescoDoseStepIdentifier = @"alvesco_dose";
NSString * const kHFADoseStepIdentifier = @"advair_hfa_dose";
NSString * const kDuleraDoseStepIdentifier = @"dulera_dose";
NSString * const kQvarDoseStepIdentifier = @"qvar_dose";
NSString * const kFloventDoseStepIdentifier = @"flovent_diskus_dose";
NSString * const kSymbicortDoseStepIdentifier = @"symbicort_dose";
NSString * const kFloventHFSDoseStepIdentifier = @"flovent_hfa_dose";
NSString * const kPulmicortDoseStepIdentifier = @"pulmicort_dose";
NSString * const kAsmanexDoseStepIdentifier = @"asmanex_dose";
NSString * const kControlMedStepIdentifier = @"controlmed";
NSString * const kNonAdherentStepIdentifier = @"non_adherent";
NSString * const kNonAdherentOtherStepIdentifier = @"non_adherent_other";
NSString * const kDailyControllerStepIdentifier = @"daily_controller_medication";
NSString * const kSteroidWhichStepIdentifier = @"steroid_which";
NSString * const kSteriodDoseStepIdentifier = @"steroid_dose";
NSString * const kMedQuickReliefStepIdentifier = @"quick_relief";
NSString * const kMedQuickReliefOtherStepIdentifier = @"quick_relief_other";
NSString * const kPastMonthStepIdentifier = @"past_month_quick_relief";
NSString * const kDailyYesStepIdentifier = @"daily_yes";

@implementation APHMedicationTaskViewController

- (NSString*) createResultSummary
{
    NSMutableDictionary * dictionary = [NSMutableDictionary dictionary];
    
    //Prescribed Asthma Controller medication
    {
        ORKChoiceQuestionResult *result = (ORKChoiceQuestionResult*)[self answerForSurveyStepIdentifier:kPrescribedControlMedStepIdentifier];
        NSArray *choiceAnswers = result.choiceAnswers;
        if (choiceAnswers.count > 0) {
            NSString *result = choiceAnswers[0];
            
            if (result) {
                dictionary[kPrescribedControlMedStepIdentifier] = [NSNumber numberWithInteger:result.integerValue];
                
            }
        }
    }
    
    //Daily Inhaled Medicine
    {
        ORKChoiceQuestionResult *result = (ORKChoiceQuestionResult*)[self answerForSurveyStepIdentifier:kInhaledMedStepIdentifier];
        NSArray *choiceAnswers = result.choiceAnswers;
        if (choiceAnswers.count > 0) {
            NSString *result = choiceAnswers[0];
            
            if (result) {
                dictionary[kInhaledMedStepIdentifier] = [NSNumber numberWithInteger:result.integerValue];
                
            }
        }
    }
    
    //kAdvairDoseStepIdentifier
    {
        ORKChoiceQuestionResult *result = (ORKChoiceQuestionResult*)[self answerForSurveyStepIdentifier:kAdvairDoseStepIdentifier];
        NSArray *choiceAnswers = result.choiceAnswers;
        if (choiceAnswers.count > 0) {
            NSString *result = choiceAnswers[0];
            
            if (result) {
                dictionary[kAdvairDoseStepIdentifier] = [NSNumber numberWithInteger:result.integerValue];
                
            }
        }
    }
    
    //kAlvescoDoseStepIdentifier
    {
        ORKChoiceQuestionResult *result = (ORKChoiceQuestionResult*)[self answerForSurveyStepIdentifier:kAlvescoDoseStepIdentifier];
        NSArray *choiceAnswers = result.choiceAnswers;
        if (choiceAnswers.count > 0) {
            NSString *result = choiceAnswers[0];
            
            if (result) {
                dictionary[kAlvescoDoseStepIdentifier] = [NSNumber numberWithInteger:result.integerValue];
                
            }
        }
    }
    
    //kHFADoseStepIdentifier
    {
        ORKChoiceQuestionResult *result = (ORKChoiceQuestionResult*)[self answerForSurveyStepIdentifier:kHFADoseStepIdentifier];
        NSArray *choiceAnswers = result.choiceAnswers;
        if (choiceAnswers.count > 0) {
            NSString *result = choiceAnswers[0];
            
            if (result) {
                dictionary[kHFADoseStepIdentifier] = [NSNumber numberWithInteger:result.integerValue];
                
            }
        }
    }
    
    //kDuleraDoseStepIdentifier
    {
        ORKChoiceQuestionResult *result = (ORKChoiceQuestionResult*)[self answerForSurveyStepIdentifier:kDuleraDoseStepIdentifier];
        NSArray *choiceAnswers = result.choiceAnswers;
        if (choiceAnswers.count > 0) {
            NSString *result = choiceAnswers[0];
            
            if (result) {
                dictionary[kDuleraDoseStepIdentifier] = [NSNumber numberWithInteger:result.integerValue];
                
            }
        }
    }
    
    //kQvarDoseStepIdentifier
    {
        ORKChoiceQuestionResult *result = (ORKChoiceQuestionResult*)[self answerForSurveyStepIdentifier:kQvarDoseStepIdentifier];
        NSArray *choiceAnswers = result.choiceAnswers;
        if (choiceAnswers.count > 0) {
            NSString *result = choiceAnswers[0];
            
            if (result) {
                dictionary[kQvarDoseStepIdentifier] = [NSNumber numberWithInteger:result.integerValue];
                
            }
        }
    }
    
    //kFloventDoseStepIdentifier
    {
        ORKChoiceQuestionResult *result = (ORKChoiceQuestionResult*)[self answerForSurveyStepIdentifier:kFloventDoseStepIdentifier];
        NSArray *choiceAnswers = result.choiceAnswers;
        if (choiceAnswers.count > 0) {
            NSString *result = choiceAnswers[0];
            
            if (result) {
                dictionary[kFloventDoseStepIdentifier] = [NSNumber numberWithInteger:result.integerValue];
                
            }
        }
    }
    
    //kSymbicortDoseStepIdentifier
    {
        ORKChoiceQuestionResult *result = (ORKChoiceQuestionResult*)[self answerForSurveyStepIdentifier:kSymbicortDoseStepIdentifier];
        NSArray *choiceAnswers = result.choiceAnswers;
        if (choiceAnswers.count > 0) {
            NSString *result = choiceAnswers[0];
            
            if (result) {
                dictionary[kSymbicortDoseStepIdentifier] = [NSNumber numberWithInteger:result.integerValue];
                
            }
        }
    }
    
    //kFloventHFSDoseStepIdentifier
    {
        ORKChoiceQuestionResult *result = (ORKChoiceQuestionResult*)[self answerForSurveyStepIdentifier:kFloventHFSDoseStepIdentifier];
        NSArray *choiceAnswers = result.choiceAnswers;
        if (choiceAnswers.count > 0) {
            NSString *result = choiceAnswers[0];
            
            if (result) {
                dictionary[kFloventHFSDoseStepIdentifier] = [NSNumber numberWithInteger:result.integerValue];
                
            }
        }
    }
    
    //kPulmicortDoseStepIdentifier
    {
        ORKChoiceQuestionResult *result = (ORKChoiceQuestionResult*)[self answerForSurveyStepIdentifier:kPulmicortDoseStepIdentifier];
        NSArray *choiceAnswers = result.choiceAnswers;
        if (choiceAnswers.count > 0) {
            NSString *result = choiceAnswers[0];
            
            if (result) {
                dictionary[kPulmicortDoseStepIdentifier] = [NSNumber numberWithInteger:result.integerValue];
                
            }
        }
    }
    
    //kAsmanexDoseStepIdentifier
    {
        ORKChoiceQuestionResult *result = (ORKChoiceQuestionResult*)[self answerForSurveyStepIdentifier:kAsmanexDoseStepIdentifier];
        NSArray *choiceAnswers = result.choiceAnswers;
        if (choiceAnswers.count > 0) {
            NSString *result = choiceAnswers[0];
            
            if (result) {
                dictionary[kAsmanexDoseStepIdentifier] = [NSNumber numberWithInteger:result.integerValue];
                
            }
        }
    }
    
    //kControlMedStepIdentifier
    {
        ORKChoiceQuestionResult *result = (ORKChoiceQuestionResult*)[self answerForSurveyStepIdentifier:kControlMedStepIdentifier];
        NSArray *choiceAnswers = result.choiceAnswers;
        if (choiceAnswers.count > 0) {
            NSString *result = choiceAnswers[0];
            
            if (result) {
                dictionary[kControlMedStepIdentifier] = [NSNumber numberWithInteger:result.integerValue];
                
            }
        }
    }
    
    //kNonAdherentStepIdentifier
    {
        ORKChoiceQuestionResult *result = (ORKChoiceQuestionResult*)[self answerForSurveyStepIdentifier:kNonAdherentStepIdentifier];
        NSArray *choiceAnswers = result.choiceAnswers;
        if (choiceAnswers.count > 0) {
            NSMutableArray *answers = [NSMutableArray new];
            
            [choiceAnswers enumerateObjectsUsingBlock:^(NSString * _Nonnull answer, __unused NSUInteger idx, __unused BOOL * _Nonnull stop) {
                
                [answers addObject:[NSNumber numberWithInteger:[answer integerValue]]];
            }];
            
            dictionary[kNonAdherentStepIdentifier] = answers;
        }
    }
    
    //kNonAdherentOtherStepIdentifier
    {
        ORKTextQuestionResult *result = (ORKTextQuestionResult*)[self answerForSurveyStepIdentifier:kNonAdherentOtherStepIdentifier];
        NSString *textAnswer = result.textAnswer;
        if (textAnswer && ![textAnswer isEqualToString:@""]) {
            dictionary[kNonAdherentOtherStepIdentifier] = textAnswer;
        }
    }
    
    //kDailyControllerStepIdentifier
    {
        ORKChoiceQuestionResult *result = (ORKChoiceQuestionResult*)[self answerForSurveyStepIdentifier:kDailyControllerStepIdentifier];
        NSArray *choiceAnswers = result.choiceAnswers;
        if (choiceAnswers.count > 0) {
            NSString *result = choiceAnswers[0];
            
            if (result) {
                dictionary[kDailyControllerStepIdentifier] = [NSNumber numberWithInteger:result.integerValue];
                
            }
        }
    }
    
    //kSteroidWhichStepIdentifier
    {
        ORKChoiceQuestionResult *result = (ORKChoiceQuestionResult*)[self answerForSurveyStepIdentifier:kSteroidWhichStepIdentifier];
        NSArray *choiceAnswers = result.choiceAnswers;
        if (choiceAnswers.count > 0) {
            NSString *result = choiceAnswers[0];
            
            if (result) {
                dictionary[kSteroidWhichStepIdentifier] = [NSNumber numberWithInteger:result.integerValue];
                
            }
        }
    }
    
    //kSteriodDoseStepIdentifier
    {
        ORKNumericQuestionResult *result = (ORKNumericQuestionResult*)[self answerForSurveyStepIdentifier:kSteriodDoseStepIdentifier];
        if ([result numericAnswer]) {
            
            NSNumber * val = [result numericAnswer] ? [result numericAnswer] : @0;
            if (val) {
                dictionary[kSteriodDoseStepIdentifier] = val;
            }
        }
    }
    
    //kMedQuickReliefStepIdentifier
    {
        ORKChoiceQuestionResult *result = (ORKChoiceQuestionResult*)[self answerForSurveyStepIdentifier:kMedQuickReliefStepIdentifier];
        NSArray *choiceAnswers = result.choiceAnswers;
        if (choiceAnswers.count > 0) {
            NSMutableArray *answers = [NSMutableArray new];
            
            [choiceAnswers enumerateObjectsUsingBlock:^(NSString * _Nonnull answer, __unused NSUInteger idx, __unused BOOL * _Nonnull stop) {
                
                [answers addObject:[NSNumber numberWithInteger:[answer integerValue]]];
            }];
            
            dictionary[kMedQuickReliefStepIdentifier] = answers;
        }
    }
    
    //kMedQuickReliefOtherStepIdentifier
    {
        ORKTextQuestionResult *result = (ORKTextQuestionResult*)[self answerForSurveyStepIdentifier:kMedQuickReliefOtherStepIdentifier];
        NSString *textAnswer = result.textAnswer;
        if (textAnswer && ![textAnswer isEqualToString:@""]) {
            dictionary[kMedQuickReliefOtherStepIdentifier] = textAnswer;
        }
    }
    
    //kPastMonthStepIdentifier
    {
        ORKChoiceQuestionResult *result = (ORKChoiceQuestionResult*)[self answerForSurveyStepIdentifier:kPastMonthStepIdentifier];
        NSArray *choiceAnswers = result.choiceAnswers;
        if (choiceAnswers.count > 0) {
            NSString *result = choiceAnswers[0];
            
            if (result) {
                dictionary[kPastMonthStepIdentifier] = [NSNumber numberWithInteger:result.integerValue];
                
            }
        }
    }
    
    //kDailyYesStepIdentifier
    {
        ORKNumericQuestionResult *result = (ORKNumericQuestionResult*)[self answerForSurveyStepIdentifier:kDailyYesStepIdentifier];
        if ([result numericAnswer]) {
            
            NSNumber * val = [result numericAnswer] ? [result numericAnswer] : @0;
            if (val) {
                dictionary[kDailyYesStepIdentifier] = val;
            }
        }
    }
    
    return [dictionary JSONString];
}

- (ORKResult *) answerForSurveyStepIdentifier: (NSString*) identifier
{
    NSArray * stepResults = [(ORKStepResult*)[self.result resultForIdentifier:identifier] results];
    ORKStepResult *answer = (ORKStepResult *)[stepResults firstObject];
    return answer;
}

- (void) processTaskResult
{
    [super processTaskResult];
    
    [self shouldShowMedicationReminder];
}

-(void)shouldShowMedicationReminder
{
    NSPredicate *medicationPredicate = [NSPredicate predicateWithFormat:@"SELF.integerValue == 1"];
    APCTaskReminder *medicationReminder = [[APCTaskReminder alloc]initWithTaskID:kDailySurveyTaskID resultsSummaryKey:kTookMedicineKey completedTaskPredicate:medicationPredicate reminderBody:NSLocalizedString(@"Take Medication", nil)];
    
    //If medication reminder permission is false then we leave it that way
    if(![[NSUserDefaults standardUserDefaults]objectForKey:medicationReminder.reminderIdentifier])
        return;
    
    ORKChoiceQuestionResult *result = (ORKChoiceQuestionResult*)[self answerForSurveyStepIdentifier:kPrescribedControlMedStepIdentifier];
    NSArray *choiceAnswers = result.choiceAnswers;
    if (choiceAnswers.count > 0) {
        NSString *result = choiceAnswers[0];
        
        if (result) {
            NSNumber *answer = [NSNumber numberWithInteger:result.integerValue];
            if(answer.longValue == 2)//2 is the No answer
            {//Turn off med reminder since user does not take any controller meds
                [[NSUserDefaults standardUserDefaults]removeObjectForKey:medicationReminder.reminderIdentifier];
            }
        }
    }
    
    

}
@end
