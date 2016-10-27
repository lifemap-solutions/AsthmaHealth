//
//  APHDailyRevisedTaskViewController.m
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

#import "APHDailyRevisedTaskViewController.h"
#import "APHConstants.h"



@implementation APHDailyRevisedTaskViewController

- (BOOL)shouldSetQuickReliefPuffs
{
    //if the answer for the "quick_relief_puffs" question has been provided
    {
        ORKNumericQuestionResult *result = (ORKNumericQuestionResult*)[self answerForSurveyStepIdentifier:kQuickReliefStepIdentifier];
        if ([result numericAnswer]) {
            return YES;
        }
    }
    
    //if the answer for the "any_activity" question has been "NO"
    {
        ORKBooleanQuestionResult *result = (ORKBooleanQuestionResult*)[self answerForSurveyStepIdentifier:kAnyActivityStepIdentifier];
        NSNumber *boolAnswer = result.booleanAnswer;
        if (boolAnswer && [boolAnswer boolValue] == NO) {
            return YES;
        }
    }
    
    return NO;
}

- (NSString *)createResultSummary {
    
    NSString *jsonString = [super createResultSummary];
    
    NSMutableDictionary *dictionary = [[NSDictionary dictionaryWithJSONString:jsonString] mutableCopy];
    
    //any activity
    {
        ORKBooleanQuestionResult *result = (ORKBooleanQuestionResult*)[self answerForSurveyStepIdentifier:kAnyActivityStepIdentifier];
        NSNumber *boolAnswer = result.booleanAnswer;
        if (boolAnswer) {
            dictionary[kAnyActivityKey] = boolAnswer;
            
            if ([boolAnswer boolValue] == NO) {
                
                dictionary[kDaytimeSickKey] = @NO;
                dictionary[kNighttimeSickKey] = @NO;
            }
        }
    }
    
    return [dictionary JSONString];
}

@end
