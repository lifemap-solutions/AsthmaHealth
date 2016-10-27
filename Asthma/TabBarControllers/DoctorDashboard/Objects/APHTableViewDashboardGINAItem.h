//
//  APHTableViewDashboardGINAItem.h
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

#import <Foundation/Foundation.h>
#import "APHAsthmaBadgesObject.h"
#import "APHTableViewItem.h"
@import APCAppCore;

typedef NS_ENUM(NSUInteger, APHGINAStatusRowType) {
    kAPHGINAStatusRowTypeDaytimeAsthmaSymptoms,
    kAPHGINAStatusRowTypeNightWaking,
    kAPHGINAStatusRowTypeRelieverNeeded,
    kAPHGINAStatusRowTypeLimitations
};

@interface APHTableViewDashboardGINAItem : APCTableViewDashboardItem

@property (nonatomic, strong) NSString * dateRangeText;
@property (nonatomic, strong) NSString * controlText;
@property (nonatomic, strong) UIColor * controlColor;
@property (nonatomic, strong) NSString * offset;
@property (nonatomic, strong, readonly) NSString * period;

@property (nonatomic, assign, readonly) NSInteger daytimeSymptoms;
@property (nonatomic, assign, readonly) NSInteger nightWakingOccurrences;
@property (nonatomic, assign, readonly) NSInteger neededReliever;
@property (nonatomic, assign, readonly) NSInteger limitationsDays;

@property (nonatomic, assign, readonly) APHStatus daytimeSymptomsStatus;
@property (nonatomic, assign, readonly) APHStatus nightWakingOccurrencesStatus;
@property (nonatomic, assign, readonly) APHStatus neededRelieverStatus;
@property (nonatomic, assign, readonly) APHStatus limitationsDaysStatus;


- (void) prepare: (APHAsthmaBadgesObject *) badgeObject;

@end