//
//  APHAsthmaSymptomControlDashboardItem.m
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

#import "APHAsthmaSymptomsDashboardItem.h"



@implementation APHAsthmaSymptomsDashboardItem

- (instancetype)init {

    self = [super init];

    if (!self) {
        return nil;
    }

    self.caption = NSLocalizedString(@"DASHBOARD_SYMPTOMS_CAPTION", @"");
    self.info = NSLocalizedString(@"DASHBOARD_SYMPTOMS_TOOLTIP", @"");

    self.editable = YES;
    self.identifier = kAPCDashboardPieGraphTableViewCellIdentifier;
    self.tintColor = [UIColor appTertiaryRedColor];

    return self;
}



#pragma mark - APCPieGraphViewDatasource

- (NSInteger)numberOfSegmentsInPieGraphView {

    return self.badgeObject.asthmaFullyControlUserScore == 0 ? 1 : 2;
}

- (CGFloat)pieGraphView:(APCPieGraphView *)__unused pieGraphView valueForSegmentAtIndex:(NSInteger)index {

    if (self.badgeObject.asthmaFullyControlUserScore == 0) {
        if (index == 0) {
            return 100;
        }
    } else {
        if (index == 0) {
            return self.badgeObject.asthmaFullyControlUserScore;
        } else if (index == 1) {
            return self.badgeObject.asthmaFullyControlTotalScore - self.badgeObject.asthmaFullyControlUserScore;
        }
    }

    return 0;
}

- (NSString *)pieGraphView:(APCPieGraphView *)__unused pieGraphView titleForSegmentAtIndex:(NSInteger)index {

    if (self.badgeObject.asthmaFullyControlUserScore == 0) {
        return NSLocalizedString(@"DASHBOARD_SYMPTOMS_RATE_UNKNOWN", @"");
    }

    NSArray *titles = @[
                        NSLocalizedString(@"DASHBOARD_SYMPTOMS_RATE_GOOD", @""),
                        NSLocalizedString(@"DASHBOARD_SYMPTOMS_RATE_BAD", @"")
                       ];

    return titles[index];
}

- (UIColor *)pieGraphView:(APCPieGraphView *)__unused pieGraphView colorForSegmentAtIndex:(NSInteger)index {

    if (self.badgeObject.asthmaFullyControlUserScore == 0) {
        return [UIColor appTertiaryYellowColor];
    }

    NSArray *colors = @[
                        [UIColor appTertiaryGreenColor],
                        [UIColor appTertiaryRedColor]
                       ];

    return colors[index];
}

@end
