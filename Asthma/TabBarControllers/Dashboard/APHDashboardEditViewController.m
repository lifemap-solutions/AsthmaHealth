// 
//  APHDashboardEditViewController.m 
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
 
#import "APHDashboardEditViewController.h"
#import "APHDashboardEditTableViewCell.h"






@implementation APHDashboardEditViewController


#pragma mark - View Life Cycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self reloadItemOrder];
    [self prepareData];
    [self.tableView reloadData];
}



#pragma mark - Table View Data Source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    APHDashboardEditTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kAPHDashboardEditTableViewCellIdentifier forIndexPath:indexPath];
    [self configureCell:cell forIndexPath:indexPath];
    return cell;
}

- (void)configureCell:(APHDashboardEditTableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath {

    APCTableViewDashboardItem *item = self.items[indexPath.row];

    cell.caption = item.caption;
    cell.color = item.tintColor;
}



#pragma mark -

- (void)reloadItemOrder {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.rowItemsOrder = [NSMutableArray arrayWithArray:[defaults objectForKey:kAPCDashboardRowItemsOrder]];
}

- (void)prepareData {

    [self.items removeAllObjects];
    for (NSNumber *typeNumber in self.rowItemsOrder) {

        APHDashboardItemType rowType = typeNumber.integerValue;
        APCTableViewDashboardItem *item = [self dashboardItemForRowType:rowType];

        if (item) {
            [self.items addObject:item];
        }
    }
}

- (APCTableViewDashboardItem *)dashboardItemForRowType:(APHDashboardItemType)type {

    APCTableViewDashboardItem *item = [APCTableViewDashboardItem new];

    switch (type) {
        case kAPHDashboardItemTypeSteps:
            item.caption = NSLocalizedString(@"Steps", @"");
            item.tintColor = [UIColor appTertiaryPurpleColor];
            break;

        case kAPHDashboardItemTypeHeartRate:
            item.caption = NSLocalizedString(@"Heart Rate", @"");
            item.tintColor = [UIColor appTertiaryPurpleColor];
            break;

        case kAPHDashboardItemTypeSleep:
            item.caption = NSLocalizedString(@"Sleep", @"");
            item.tintColor = [UIColor appTertiaryPurpleColor];
            break;

        case kAPHDashboardItemTypePeakFlow:
            item.caption = NSLocalizedString(@"Peak Flow", @"");
            item.tintColor = [UIColor appTertiaryYellowColor];
            break;

        case kAPHDashboardItemTypeBadges:
            item.caption = NSLocalizedString(@"Badges", @"");
            item.tintColor = [UIColor appTertiaryGreenColor];
            break;

        case kAPHDashboardItemTypeAsthmaControl:
            item.caption = NSLocalizedString(@"Asthma Symptom Control", @"");
            item.tintColor = [UIColor appTertiaryRedColor];
            break;

        case kAPHDashboardItemTypeAQNU:
            item.caption = NSLocalizedString(@"Air Quality Near You", @"");
            item.tintColor = [UIColor appTertiaryBlueColor];
            break;

//        case kAPHDashboardItemTypeInsights:
//            item.caption = NSLocalizedString(@"Insights", @"");
//            break;

        case kAPHDashboardItemTypeCorrelation:
            item.caption = NSLocalizedString(@"Data Correlations", @"");;
            item.tintColor = [UIColor appTertiaryYellowColor];
            break;

        default:
            item = nil;
            break;
    }

    return item;
}

@end
