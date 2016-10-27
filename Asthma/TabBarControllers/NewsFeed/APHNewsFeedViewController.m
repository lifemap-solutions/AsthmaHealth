//
//  APHNewsFeedViewController.m
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

#import "APHNewsFeedViewController.h"
#import "APHNewsPreviewController.h"



@interface APCNewsFeedViewController ()
@property (nonatomic, strong) NSArray *posts;
@property (nonatomic, strong, readonly) APCNewsFeedManager *newsFeedManager;
@end



@implementation APHNewsFeedViewController


#pragma mark - TableViewDataSource

- (void)tableView:(UITableView *) __unused tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    APCFeedItem *item = self.posts[indexPath.row];

    [self.newsFeedManager userDidReadPostWithURL:item.link];
    [self showNewsPreviewWithTitle:item.title andURLString:item.link];
}



#pragma mark -

- (void)showNewsPreviewWithTitle:(NSString *)title andURLString:(NSString *)urlString {

    NSBundle *mainBundle = [NSBundle mainBundle];
    UIStoryboard *newsStoryboard = [UIStoryboard storyboardWithName:@"APHNewsFeed" bundle:mainBundle];

    APHNewsPreviewController *newsPreview = [newsStoryboard instantiateViewControllerWithIdentifier:@"APHNewsPreviewController"];

    newsPreview.title = title;
    newsPreview.url = [NSURL URLWithString:urlString];

    [self.navigationController pushViewController:newsPreview animated:YES];
}



#pragma mark - Fetching Data

- (void)fetchFeedInBackgroundWithCompletion:(APCFeedParserCompletionBlock)block {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [self.newsFeedManager fetchFeedWithCompletion:block];
    });
}

- (void)refreshFeed {
    [self fetchFeedInBackgroundWithCompletion:^(NSArray *posts, NSError *error) {
        [self.refreshControl endRefreshing];

        if (!error) {
            self.posts = posts;
        } else {
            [self alertFetchError];
        }

        if (self.posts.count == 0) {
            [self showEmptyPlaceholder];
        } else {
            [self hideEmptyPlaceholder];
        }

        [self.tableView reloadData];
    }];
}



#pragma mark - Empty Placeholder

- (void)showEmptyPlaceholder {
    UILabel *emptyLabel = [UILabel new];

    emptyLabel.text = NSLocalizedString(@"There's nothing here yet.", nil);
    emptyLabel.textColor = [UIColor appSecondaryColor3];
    emptyLabel.textAlignment = NSTextAlignmentCenter;
    emptyLabel.font = [UIFont appMediumFontWithSize:22];

    self.tableView.backgroundView = emptyLabel;
}

- (void)hideEmptyPlaceholder {
    self.tableView.backgroundView = nil;
}



#pragma mark - Alerts

- (void)alertFetchError {
    NSString *title = NSLocalizedString(@"Fetch Error", nil);
    NSString *message = NSLocalizedString(@"An error occured while fetching news feed.", nil);

    UIAlertController *alert = [UIAlertController simpleAlertWithTitle:title message:message];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
