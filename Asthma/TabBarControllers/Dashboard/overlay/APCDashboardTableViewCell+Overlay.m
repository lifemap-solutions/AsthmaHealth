//
//  APCDashboardTableViewCell+Overlay.m
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

#import "APCDashboardTableViewCell+Overlay.h"
@import ObjectiveC;

@implementation APCDashboardTableViewCell (Overlay)

- (UIView*) overlayView {
    return objc_getAssociatedObject(self, @selector(overlayView));
}

- (void)setOverlayView:(UIView *)overlayView {
    objc_setAssociatedObject(self, @selector(overlayView), overlayView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void) configureOverlay:(id<OverlayConfig>)config {
    if(self.overlayView) {
       [self.overlayView removeFromSuperview];
    }
    
    if (!config.isVisible) {
        return;
    }
    
    self.overlayView =  [[UIView alloc] init];
    UIView *alphaOverlay =  [[UIView alloc] init];
    alphaOverlay.alpha = 0.7;
    alphaOverlay.backgroundColor = self.titleLabel.textColor;
    
    
    UILabel *label = [[UILabel alloc] init];
    label.text = config.overlayText;
    label.textColor = [UIColor whiteColor];
    
    label.lineBreakMode = NSLineBreakByWordWrapping;
    label.numberOfLines = 0;
    label.font = [UIFont appMediumFontWithSize:17];
    label.textAlignment = NSTextAlignmentCenter;
    
    self.overlayView.translatesAutoresizingMaskIntoConstraints = NO;
    label.translatesAutoresizingMaskIntoConstraints = NO;
    alphaOverlay.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.overlayView addSubview:alphaOverlay];
    [self.overlayView addSubview:label];
    [[self contentView] addSubview:self.overlayView];
    
    NSLayoutConstraint *centerX = [NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.overlayView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0];
    NSLayoutConstraint *leading = [NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.overlayView attribute:NSLayoutAttributeLeading multiplier:1.0 constant:10];
    NSLayoutConstraint *trailing = [NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.overlayView attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:-10];
    NSLayoutConstraint *centerY = [NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.overlayView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0];
    
    NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:self.overlayView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:[self contentView] attribute:NSLayoutAttributeWidth multiplier:1 constant:0];
    NSLayoutConstraint *top = [NSLayoutConstraint constraintWithItem:self.overlayView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:[self contentView] attribute:NSLayoutAttributeTop multiplier:1.0 constant:0];
    NSLayoutConstraint *bottom = [NSLayoutConstraint constraintWithItem:self.overlayView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:[self contentView] attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0];
    
    NSLayoutConstraint *alphawidthConstraint = [NSLayoutConstraint constraintWithItem:alphaOverlay attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.overlayView attribute:NSLayoutAttributeWidth multiplier:1 constant:0];
    NSLayoutConstraint *alphatop = [NSLayoutConstraint constraintWithItem:alphaOverlay attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.overlayView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0];
    NSLayoutConstraint *alphabottom = [NSLayoutConstraint constraintWithItem:alphaOverlay attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.overlayView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0];
    
    [self.overlayView addConstraints:@[centerX, centerY, leading, trailing, alphawidthConstraint, alphatop, alphabottom]];
    [[self contentView] addConstraints:@[widthConstraint, top, bottom]];
    
}

@end

@implementation APCTableViewItem (OverlayConfig)

- (id<OverlayConfig>) overlayConfig {
    return objc_getAssociatedObject(self, @selector(overlayConfig));
}

- (void)setOverlayConfig:(id <OverlayConfig>)overlayConfig {
    objc_setAssociatedObject(self, @selector(overlayConfig), overlayConfig, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
@end

@implementation HealthKitOverlayConfig

-(instancetype)initWithOverlayText:(NSString*) overlayText healthKitScoring:(APHScoring*) scoring {
    self = [super init];
    if (self) {
        self.overlayText = overlayText;
        self.scoring = scoring;
    }

    return self;
}

- (NSNumber *)healthKitDataPoints {
    return self.scoring.numberOfDataPoints;
}

- (BOOL)healthKitQueryComplete {
    return self.scoring.healthKitDataComplete;
}

-(BOOL)isVisible {
    return self.healthKitDataPoints.integerValue == 0 && self.healthKitQueryComplete;
}

@end

@implementation LocationPermissionOverlayConfig

-(instancetype)initWithOverlayText:(NSString*) overlayText {
    self = [super init];
    if (self) {
        self.overlayText = overlayText;
    }
    return self;
}

-(BOOL)isVisible {
    CLAuthorizationStatus authorizationStatus = [CLLocationManager authorizationStatus];
    
    return authorizationStatus == kCLAuthorizationStatusNotDetermined ||
        authorizationStatus == kCLAuthorizationStatusRestricted ||
        authorizationStatus == kCLAuthorizationStatusDenied;
}
@end

