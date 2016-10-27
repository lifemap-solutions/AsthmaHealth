//
//  APHTableViewDashboardGINAItem.m
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

#import "APHTableViewDashboardGINAItem.h"

static NSString * const kThinSpaceEnDashJoiner = @"\u2009\u2013\u2009";
static NSString * const kGINAPeriod = @"P4W";
static NSString * const kGINASubPeriod = @"P1W";

@interface APHTableViewDashboardGINAItem ()

-(NSUInteger) calculateRelieverNeeded:(APHAsthmaBadgesObject *)badgeObject startDate:(NSDate*)startDate endDate:(NSDate*)endDate;
-(NSUInteger) calculateDaytimeSymptoms:(APHAsthmaBadgesObject *)badgeObject startDate:(NSDate*)startDate endDate:(NSDate*)endDate;

@end

@implementation APHTableViewDashboardGINAItem

- (UIColor *)controlColor
{
    if (!_controlColor) {
        _controlColor = [UIColor appTertiaryGreenColor];
    }
    return _controlColor;
}

- (NSString *)controlText {
    if (!_controlText) {
        _controlText = NSLocalizedString(@"Well controlled", @"");
    }
    return _controlText;
}

- (NSString *)dateRangeText {
    if (!_dateRangeText) {
        _dateRangeText = NSLocalizedString(@"Unknown", @"");
    }
    return _dateRangeText;
}

- (NSString *)period {
    return kGINAPeriod;
}

// In the past 4 weeks, has the patient had:
// * Reliever needed more than twice a week
-(NSUInteger) calculateRelieverNeeded:(APHAsthmaBadgesObject *)badgeObject
                            startDate:(NSDate*)startDate
                              endDate:(NSDate*)endDate
{
    NSUInteger threshold = 2;
    NSUInteger count = 0;
    while ([startDate compare:endDate] == NSOrderedAscending) {
        NSDate *periodEndDate = [startDate dateByAddingISO8601Duration:kGINASubPeriod];
        NSUInteger subCount = [badgeObject calculateRelieverDaysNeededForStartDate:startDate endDate: periodEndDate];
        if (subCount > threshold) {
            count++;
        }
        startDate = periodEndDate;
    }

    return count;
}

// In the past 4 weeks, has the patient had:
// * Daytime symptoms more than twice a week
-(NSUInteger) calculateDaytimeSymptoms:(APHAsthmaBadgesObject *)badgeObject
                             startDate:(NSDate*)startDate
                               endDate:(NSDate*)endDate
{
    NSUInteger threshold = 2;
    NSUInteger count = 0;
    while ([startDate compare:endDate] == NSOrderedAscending) {
        NSDate *periodEndDate = [startDate dateByAddingISO8601Duration:kGINASubPeriod];
        NSUInteger subCount = [badgeObject calculateDaytimeSymptomsForStartDate:startDate endDate: periodEndDate];
        if (subCount > threshold) {
            count++;
        }
        startDate = periodEndDate;
    }

    return count;
}

- (void) prepare: (APHAsthmaBadgesObject *) badgeObject
{
    NSDate* periodEndDate = [NSDate date];
    if (self.offset != nil) {
        periodEndDate = [periodEndDate dateBySubtractingISO8601Duration:self.offset];
    }
    NSDate* periodStartDate = [periodEndDate dateBySubtractingISO8601Duration:self.period];

    NSInteger setCount = 0;
    NSInteger overThreshold;

    // The commented out line is what I would use if I wanted to display the actual number of days where there were symptoms
    // instead of the number of weeks in which there were daytime symptoms more than twice.
    //_daytimeSymptoms = [badgeObject calculateDaytimeSymptomsForStartDate:periodStartDate endDate:periodEndDate];
    _daytimeSymptoms =  [self calculateDaytimeSymptoms:badgeObject startDate:periodStartDate endDate:periodEndDate];
    if (_daytimeSymptoms > 0) {
        _daytimeSymptomsStatus = kAPHStatusRed;
        setCount++;
    } else {
        _daytimeSymptomsStatus = kAPHStatusGreen;
    }

    _nightWakingOccurrences = [badgeObject calculateNightWakingOccurancesForStartDate:periodStartDate endDate:periodEndDate];
    if (_nightWakingOccurrences > 0) {
        _nightWakingOccurrencesStatus = kAPHStatusRed;
        setCount++;
    } else {
        _nightWakingOccurrencesStatus = kAPHStatusGreen;
    }

    // The commented out line is what I would use if I wanted to display the actual number of days where the reliever was needed
    // instead of the number of weeks in which the reliever was needed more than twice.
    //_neededReliever = [badgeObject calculateRelieverDaysNeededForStartDate:periodStartDate endDate: periodEndDate];
    _neededReliever = [self calculateRelieverNeeded:badgeObject startDate:periodStartDate endDate:periodEndDate];
    if (_neededReliever > 0) {
        _neededRelieverStatus = kAPHStatusRed;
        setCount++;
    } else {
        _neededRelieverStatus = kAPHStatusGreen;
    }

    // Show red here, even if they skipped the number of days answer (if they said they had limitations).
    overThreshold = [badgeObject calculateLimitationsForStartDate:periodStartDate endDate:periodEndDate];
    _limitationsDays = [badgeObject calculateLimitationsDaysForStartDate:periodStartDate endDate:periodEndDate];
    if (overThreshold > 0) {
        _limitationsDaysStatus = kAPHStatusRed;
        setCount++;
    } else {
        _limitationsDaysStatus = kAPHStatusGreen;
    }

    if (setCount == 0) {
        _controlText = NSLocalizedString(@"Well controlled", @"");
        _controlColor = [UIColor appTertiaryGreenColor];
    } else if (setCount <= 2) {
        _controlText = NSLocalizedString(@"Partly controlled", @"");
        _controlColor = [UIColor appTertiaryYellowColor];
    } else {
        _controlText = NSLocalizedString(@"Uncontrolled", @"");
        _controlColor = [UIColor appTertiaryRedColor];
    }

    NSDateFormatter  *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.timeZone = [NSTimeZone localTimeZone];
    [dateFormatter setDateFormat:@"MMM d"];
    NSString  *beginFormatted = [dateFormatter stringFromDate:periodStartDate];
    NSString  *endFormatted = [dateFormatter stringFromDate:periodEndDate];
    _dateRangeText = [NSString stringWithFormat:@"%@%@%@", beginFormatted, kThinSpaceEnDashJoiner, endFormatted];
}


@end