//
//  APHNewsPreviewController.m
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

#import "APHNewsPreviewController.h"
#import "NSError+Domain.h"


const NSTimeInterval kTimeLimit = 15.0;
const NSTimeInterval kFadeOutAnimationDuration = 0.2;


@interface APHNewsPreviewController () <UIWebViewDelegate>
@property (weak, nonatomic) IBOutlet UIWebView *webView;

@property (strong, nonatomic) NSTimer *timer;
@property (assign, nonatomic) NSInteger resourcesCount;

@property (strong, nonatomic) IBOutlet UIView *overlay;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@end



@implementation APHNewsPreviewController


#pragma mark - View Life Cycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self startTimer];
    [self startLoading];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];

    [self stopTimer];
    [self stopLoading];
}

- (void)loadView {
    [super loadView];

    self.overlay.frame = self.view.bounds;
    [self.view addSubview:self.overlay];
}


#pragma mark - Timer

- (void)startTimer {
    self.timer = [NSTimer scheduledTimerWithTimeInterval:kTimeLimit target:self selector:@selector(accomplishWithTimeoutIfNeeded) userInfo:nil repeats:false];
}

- (void)stopTimer {
    [self.timer invalidate];
    self.timer = nil;
}

- (void)accomplishWithTimeoutIfNeeded {
    if (!self.webView.isLoading) {
        return;
    }

    [self stopLoading];
    [self loadedWithError:[NSError errorWithCode:NSErrorCodeRequestTimeout message:@"UIWebView request timeout"]];
}


#pragma mark -

- (void)startLoading {
    NSURLRequest *request = [NSURLRequest requestWithURL:self.url];
    [self.webView loadRequest:request];
}

- (void)stopLoading {
    [self.webView stopLoading];

    if (self.timer != nil) {
        [self.timer invalidate];
        self.timer = nil;
    }
}

- (void)loadedWithSuccess {
    [self hideOverlay];
}

- (void)loadedWithError:(NSError *) __unused error {
    [self showAlertWithError:error];

    [UIView animateWithDuration:kFadeOutAnimationDuration animations:^{
        self.spinner.alpha = 0;
    } completion:^(BOOL __unused finished) {
        self.spinner.hidden = YES;
    }];
}

- (void)hideOverlay {
    [UIView animateWithDuration:kFadeOutAnimationDuration animations:^{
        self.overlay.alpha = 0;
    } completion:^(BOOL __unused finished) {
        [self.overlay removeFromSuperview];
    }];
}


#pragma mark - Alert

- (void)showAlertWithError:(NSError * __unused)error {
    NSString *title = NSLocalizedString(@"Error", @"Error");
    NSString *message = NSLocalizedString(@"Could not connect to internet", @"Could not connect to internet");

    UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull __unused action) {
        [self.navigationController popViewControllerAnimated:true];
    }];

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:dismissAction];

    [self presentViewController:alert animated:true completion:nil];
}


#pragma mark - WebViewDelegate

- (void)webViewDidStartLoad:(UIWebView *) __unused webView {
    self.resourcesCount++;
}

- (void)webViewDidFinishLoad:(UIWebView *) __unused webView {
    self.resourcesCount--;

    if (self.resourcesCount == 0) {
        [self loadedWithSuccess];
    }
}

- (void)webView:(UIWebView *) __unused webView didFailLoadWithError:(NSError *)error {
    [self loadedWithError:error];
}

@end
