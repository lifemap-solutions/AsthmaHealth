//
//  APHHeartRateDashboardItem.m
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

#import "APHHeartRateDashboardItem.h"
#import "APCDashboardTableViewCell+Overlay.h"



static NSString *kTooltipHeartRateContent = @"This graph shows your heart rate that you have taken each day, as recorded by your phone or connected device. Tap the button in the upper right corner to make the graph larger.";



@implementation APHHeartRateDashboardItem

- (instancetype)init {

    self = [super init];

    if (!self) {
        return nil;
    }

    self.caption = NSLocalizedString(@"Heart Rate", @"");
    self.overlayConfig = [[HealthKitOverlayConfig alloc] initWithOverlayText: NSLocalizedString(@"No Data",nil) healthKitScoring:self.heartRateScoring];

    self.graphData = self.heartRateScoring;
    if (self.heartRateScoring.averageDataPoint.doubleValue > 0 && self.heartRateScoring.averageDataPoint.doubleValue != self.heartRateScoring.maximumDataPoint.doubleValue) {
        self.detailText = [NSString stringWithFormat:NSLocalizedString(@"Average : %0.0f Heart Rate", @"Average: {value}"), [[self.heartRateScoring averageDataPoint] doubleValue]];
    }

    self.identifier = kAPCDashboardGraphTableViewCellIdentifier;
    self.editable = YES;
    self.tintColor = [UIColor appTertiaryPurpleColor];
    self.info = NSLocalizedString(kTooltipHeartRateContent, @"");

    return self;
}

- (APHHeartRateScoring *)heartRateScoring {
    if (!_heartRateScoring) {
        _heartRateScoring = [APHHeartRateScoring heartRateScoring];
    }

    return _heartRateScoring;
}

@end
