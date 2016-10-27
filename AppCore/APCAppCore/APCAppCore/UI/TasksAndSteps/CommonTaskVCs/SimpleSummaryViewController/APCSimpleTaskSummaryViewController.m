// 
//  APCSimpleTaskSummaryViewController.m 
//  APCAppCore 
// 
// Copyright (c) 2015, Apple Inc. All rights reserved. 
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
 
#import "APCSimpleTaskSummaryViewController.h"
#import "APCAppCore.h"

NSDate* pageStart;

@interface APCSimpleTaskSummaryViewController ()

@property (weak, nonatomic) IBOutlet UILabel *completingActivitiesMessage;
@property (weak, nonatomic) IBOutlet UILabel *thankYouBanner;
@property (weak, nonatomic) IBOutlet APCConfirmationView *confirmation;

@end

@implementation APCSimpleTaskSummaryViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIColor *viewBackgroundColor = [UIColor appSecondaryColor4];
    
    [self.view setBackgroundColor:viewBackgroundColor];
    self.navigationItem.leftBarButtonItem = nil;
    self.navigationItem.hidesBackButton = YES;
    self.confirmation.completed = YES;
    
    [self setUpAppearance];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
  APCLogViewControllerAppeared();
    
    //Log Analytics event
    pageStart = [NSDate date];
    APCAppDelegate * appDelegate = (APCAppDelegate*)[UIApplication sharedApplication].delegate;
    APCLogEventWithData(kAnalyticsPageStarted, (@{@"pageName" : NSStringFromClass(self.class),
                                           @"time" : [appDelegate getStringFromDate:pageStart]}));
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    //Log Analytics event
    NSDate *now = [NSDate date];
    NSTimeInterval secondsBetween = [now timeIntervalSinceDate:pageStart];
    
    APCLogEventWithData(kAnalyticsPageEnded, (@{@"pageName" : NSStringFromClass(self.class), @"duration" : [NSString stringWithFormat:@"%d", (int)secondsBetween]}));
}

- (void) setUpAppearance
{
    self.completingActivitiesMessage.font = [UIFont appLightFontWithSize:17];
    self.completingActivitiesMessage.textColor = [UIColor appSecondaryColor3];
    self.youCanCompareMessage.textColor = [UIColor appSecondaryColor2];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                           target:self
                                                                                           action:@selector(doneButtonTapped:)];

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] init];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Actions

- (void)doneButtonTapped:(UIBarButtonItem *) __unused sender
{
    if (self.delegate != nil) {
        if ([self.delegate respondsToSelector:@selector(stepViewController:didFinishWithNavigationDirection:)] == YES) {
            [self.delegate stepViewController:self didFinishWithNavigationDirection: ORKStepViewControllerNavigationDirectionForward];
        }
    }
}



@end
