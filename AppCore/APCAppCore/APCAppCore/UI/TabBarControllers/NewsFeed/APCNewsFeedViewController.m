//
//  APCNewsFeedViewController.m
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

#import "APCNewsFeedViewController.h"
#import "APCFeedParser.h"
#import "APCFeedTableViewCell.h"
#import "APCAppCore.h"
#import "APCAppDelegate.h"

@interface APCNewsFeedViewController ()

@property (nonatomic, strong) NSArray *posts;

@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@end

@implementation APCNewsFeedViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.refreshControl = [UIRefreshControl new];
    [self.refreshControl addTarget:self action:@selector(refreshFeed) forControlEvents:UIControlEventValueChanged];
    
    self.dateFormatter = [NSDateFormatter new];
    self.dateFormatter.dateFormat = @"MM/dd/yy";
    
    self.title = NSLocalizedString(@"News Feed", nil);
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.posts = [self newsFeedManager].feedPosts;
    
    if (self.posts.count > 0) {
        self.tableView.backgroundView = nil;
    } else {
        UILabel *emptyLabel = [UILabel new];
        emptyLabel.frame = self.tableView.bounds;
        
        emptyLabel.text = NSLocalizedString(@"There's nothing here yet.", nil);
        emptyLabel.textColor = [UIColor appSecondaryColor3];
        emptyLabel.textAlignment = NSTextAlignmentCenter;
        emptyLabel.font = [UIFont appMediumFontWithSize:22];
        
        self.tableView.backgroundView = emptyLabel;
    }
    
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
    
    NSUInteger unreadCount = [[self newsFeedManager] unreadPostsCount];
    NSNumber *unreadValue = @(unreadCount);
    
    APCAppDelegate *appDelegate = (APCAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    UITabBarItem *newsFeedTab = appDelegate.tabBarController.tabBar.selectedItem;
    if (newsFeedTab.tag == (NSInteger)kAPCNewsFeedTabIndex) {
        if (unreadCount != 0) {
            newsFeedTab.badgeValue = [unreadValue stringValue];
        } else {
            newsFeedTab.badgeValue = nil;
        }
    }
}

- (APCNewsFeedManager *)newsFeedManager
{
    return ((APCAppDelegate *)[[UIApplication sharedApplication] delegate]).dataSubstrate.newsFeedManager;
}

#pragma mark - UITableViewDataSource methods

- (NSInteger)tableView:(UITableView *)__unused tableView numberOfRowsInSection:(NSInteger)__unused section {

    return self.posts.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    APCFeedTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kAPCFeedTableViewCellIdentifier];
    
    APCFeedItem *item = self.posts[indexPath.row];
    
    cell.titleLabel.text = item.title;
    cell.descriptionLabel.text = item.itemDescription;
    cell.dateLabel.text = [self.dateFormatter stringFromDate:item.pubDate];
    
    BOOL read = [[self newsFeedManager] hasUserReadPostWithURL:item.link];
    [cell setupAppearanceForRead:read];
    
    return cell;
}

- (void)tableView:(UITableView *)__unused tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    APCFeedItem *item = self.posts[indexPath.row];
    
    APCWebViewController *webViewVC = [[UIStoryboard storyboardWithName:@"APCOnboarding" bundle:[NSBundle appleCoreBundle]] instantiateViewControllerWithIdentifier:@"APCWebViewController"];
    
    webViewVC.link = item.link;
    webViewVC.title = item.title;
    webViewVC.navigationItem.rightBarButtonItem = nil;
    webViewVC.webToolBar.hidden = NO;
    
    [self.navigationController pushViewController:webViewVC animated:YES];
    
    [[self newsFeedManager] userDidReadPostWithURL:item.link];
}

- (void)refreshFeed
{
    __weak typeof(self) weakSelf = self;
    
    [[self newsFeedManager] fetchFeedWithCompletion:^(NSArray *posts, NSError *error) {
        [weakSelf.refreshControl endRefreshing];
        
        if (!error) {
            weakSelf.posts = posts;
        } else {
            UIAlertController *alert = [UIAlertController simpleAlertWithTitle:NSLocalizedString(@"Fetch Error",nil) message:NSLocalizedString(@"An error occured while fetching news feed.",nil)];
            [weakSelf presentViewController:alert animated:YES completion:nil];
        }
        
        if (weakSelf.posts.count > 0) {
            weakSelf.tableView.backgroundView = nil;
        } else {
            UILabel *emptyLabel = [UILabel new];
            emptyLabel.frame = weakSelf.tableView.bounds;
            
            emptyLabel.text = NSLocalizedString(@"There's nothing here yet.", nil);
            emptyLabel.textColor = [UIColor appSecondaryColor3];
            emptyLabel.textAlignment = NSTextAlignmentCenter;
            emptyLabel.font = [UIFont appMediumFontWithSize:22];
            
            weakSelf.tableView.backgroundView = emptyLabel;
        }
        
        [weakSelf.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
    }];
}

@end
