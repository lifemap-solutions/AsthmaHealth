//
//  APHTableViewDashboardAsthmaControlItem.m
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

#import "APHTableViewDashboardAsthmaControlItem.h"

static NSString * const kThinSpaceEnDashJoiner = @"\u2009\u2013\u2009";
static NSString * const kAsthmaControlPeriod = @"P4W";

@implementation APHTableViewDashboardAsthmaControlItem

- (UIColor *)controlColor
{
    if (!_controlColor) {
        _controlColor = [UIColor appTertiaryGreenColor];
    }
    return _controlColor;
}

- (NSString *)controlText {
    if (!_controlText) {
        _controlText = @"";
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
    return kAsthmaControlPeriod;
}

- (void) prepare: (APHAsthmaBadgesObject *) badgeObject
{
    NSDate* periodEndDate = [NSDate date];
    if (self.offset != nil) {
        periodEndDate = [periodEndDate dateBySubtractingISO8601Duration:self.offset];
    }
    NSDate* periodStartDate = [periodEndDate dateBySubtractingISO8601Duration:self.period];

    _majorEvents = [badgeObject calculateMajorEventsForStartDate:periodStartDate endDate:periodEndDate];
    _majorEventsStatus = (_majorEvents == 0) ? kAPHStatusGreen : kAPHStatusRed;
    _medicationAdherencePercent = round(100.0f * [badgeObject calculateMedicationAdherencePercentForStartDate:periodStartDate endDate:periodEndDate]);
    _medicationAdherencePercentStatus = (_medicationAdherencePercent == -1) ? kAPHStatusUnknown :
                                         (_medicationAdherencePercent < 80) ? kAPHStatusRed : kAPHStatusGreen;
    _neededRelieverDays = [badgeObject calculateRelieverDaysNeededForStartDate:periodStartDate endDate:periodEndDate];
    _neededRelieverDaysStatus = (_neededRelieverDays < 4) ? kAPHStatusGreen : kAPHStatusRed;

    NSDateFormatter  *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.timeZone = [NSTimeZone localTimeZone];
    [dateFormatter setDateFormat:@"MMM d"];
    NSString  *beginFormatted = [dateFormatter stringFromDate:periodStartDate];
    NSString  *endFormatted = [dateFormatter stringFromDate:periodEndDate];
    _dateRangeText = [NSString stringWithFormat:@"%@%@%@", beginFormatted, kThinSpaceEnDashJoiner, endFormatted];
}


@end