//
//  APHStepsDashboardItem.m
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

#import "APHStepsDashboardItem.h"
#import "APCDashboardTableViewCell+Overlay.h"
#import "APHStepScoring.h"



@implementation APHStepsDashboardItem

- (instancetype)init {

    self = [super init];

    if (!self) {
        return nil;
    }

    self.caption = self.stepScoring.caption;
    self.overlayConfig = [[HealthKitOverlayConfig alloc] initWithOverlayText: NSLocalizedString(@"No Data",nil) healthKitScoring:self.stepScoring];


    self.graphData = self.stepScoring;

    self.identifier = kAPCDashboardGraphTableViewCellIdentifier;
    self.editable = YES;
    self.tintColor = [UIColor appTertiaryPurpleColor];
    self.info = NSLocalizedString(@"DASHBOARD_STEPS_TOOLTIP", @"");

    return self;
}



#pragma mark -

- (NSString *)detailText {
    if (![self shouldShowDetails]) {
        return nil;
    }

    NSString *template = NSLocalizedString(@"Average : %0.0f Steps", @"Average: {value} ft");
    return [NSString stringWithFormat:template, self.stepScoring.averageDataPoint.doubleValue];
}

- (BOOL)shouldShowDetails {
    return self.stepScoring.averageDataPoint.doubleValue > 0 && self.stepScoring.averageDataPoint.doubleValue != self.stepScoring.maximumDataPoint.doubleValue;
}



#pragma mark -

- (APHScoring *)stepScoring {
    if (!_stepScoring) {
        _stepScoring = [APHStepScoring stepScoring];
    }

    return _stepScoring;
}

@end
