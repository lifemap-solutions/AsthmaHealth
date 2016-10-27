//
//  APCSmartSurveyTask+MultipleChoice.m
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

#import "APCSmartSurveyTask+MultipleChoice.h"

NSString *const kRuleOperatorKey = @"operator";
NSString *const kRuleSkipToKey = @"skipTo";
NSString *const kRuleValueKey = @"value";

NSString *const kOperatorEqual              = @"eq";
NSString *const kOperatorNotEqual           = @"ne";
NSString *const kOperatorOtherThan          = @"ot";

@implementation APCSmartSurveyTask (MultipleChoice)

- (NSString *) processRules: (NSArray*) rules forAnswer: (id) answer
{
    /**
     * Check if answer is nil (Skip) or NSNumber or NSString then process rules. Otherwise no processing of rules.
     *      Single choice: the selected RKAnswerOption's `value` property. SUPPORTED
     *      Multiple choice: SUPPORTED
     *      Boolean: NSNumber SUPPORTED
     *      Text: NSString SUPPORTED
     *      Scale: NSNumber SUPPORTED
     *      Date: ORKDateAnswer with date components having (NSCalendarUnitEra|NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay). NOT SUPPORTED
     *      Time: ORKDateAnswer with date components having (NSCalendarUnitHour|NSCalendarUnitMinute|NSCalendarUnitSecond). NOT SUPPORTED
     *      DateAndTime: ORKDateAnswer with date components having (NSCalendarUnitEra|NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay|NSCalendarUnitHour|NSCalendarUnitMinute|NSCalendarUnitSecond). NOT SUPPORTED
     *      Time Interval: NSNumber, containing a time span in seconds. SUPPORTED
     */
    __block NSString * skipToIdentifier = nil;
    if (answer == nil || [answer isKindOfClass:[NSNumber class]] || [answer isKindOfClass:[NSString class]] || [answer isKindOfClass:[NSArray class]]) {
        [rules enumerateObjectsUsingBlock:^(SBBSurveyRule * rule, NSUInteger __unused idx, BOOL *stop) {
            skipToIdentifier = [self checkRuleWithMultipleChoiceSupport:rule againstAnswer:answer];
            if (skipToIdentifier) {
                *stop = YES;
            }
        }];
    }
    if (skipToIdentifier) {
        APCLogDebug(@"SKIPPING TO: %@", skipToIdentifier);
    }
    return skipToIdentifier;
}

- (NSString *)checkRuleWithMultipleChoiceSupport:(SBBSurveyRule*)rule againstAnswer:(id)answer
{
    //if the answer is not a multiple-choice
    if (![answer isKindOfClass:[NSArray class]]) {
        SEL selector = NSSelectorFromString(@"checkRule:againstAnswer:");
        if ([self respondsToSelector:selector]) {
            IMP imp = [self methodForSelector:selector];
            id (*func)(id, SEL, id, id) = (void *)imp;
            return func(self, selector, rule, answer);
        }
        return nil;
    }
    
    id value = [rule valueForKeyPath:kRuleValueKey];
    NSString *skipToValue  = [rule valueForKeyPath:kRuleSkipToKey];
    NSString *operator = [rule valueForKeyPath:kRuleOperatorKey];
    if (operator.length > 0) {
        operator = operator.lowercaseString;
    }
    
    //if the answer is a multiple-choice
    
    NSPredicate *stringFilter = [NSPredicate predicateWithFormat:@"self != nil && self isKindOfClass: %@", [NSString class]];
    NSArray *onlyStringAnswers = [answer filteredArrayUsingPredicate:stringFilter];
    
    //Equal
    if ([operator isEqualToString:kOperatorEqual]) {
        
        if ([value isKindOfClass:[NSString class]]) {
            
            if ([answer containsObject:value]) {
                return skipToValue;
            }
        } else if ([value isKindOfClass:[NSNumber class]]) {
            
            if ([[onlyStringAnswers valueForKey:@"doubleValue"] containsObject:value]) {
                return skipToValue;
            }
        }
    }
    
    //Not Equal / Other Than
    if ([operator isEqualToString:kOperatorNotEqual] || [operator isEqualToString:kOperatorOtherThan]) {
        
        if ([value isKindOfClass:[NSString class]]) {
            
            if (![answer containsObject:value]) {
                return skipToValue;
            }
        } else if ([value isKindOfClass:[NSNumber class]]) {
            
            if (![[onlyStringAnswers valueForKey:@"doubleValue"] containsObject:value]) {
                return skipToValue;
            }
        }
    }
    
    return nil;
}

@end
