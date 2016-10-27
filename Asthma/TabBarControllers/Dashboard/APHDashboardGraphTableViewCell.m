//
//  APHDashboardGraphTableViewCell.m
//  Asthma
//

#import "APHDashboardGraphTableViewCell.h"

NSString * const kAPHDashboardGraphTableViewCell = @"APHDashboardLineGraphTableViewCell";

@implementation APHDashboardGraphTableViewCell

@dynamic delegate;
@dynamic lineGraphView;

- (IBAction)series1ButtonTapped:(id)sender {
    if ([self.delegate respondsToSelector:@selector(dashboardTableViewCellDidTapSeriesButton:button:)]) {
        [self.delegate dashboardTableViewCellDidTapSeriesButton:self button:sender];
    }
}

- (IBAction)series2ButtonTapped:(id)sender {
    if ([self.delegate respondsToSelector:@selector(dashboardTableViewCellDidTapSeriesButton:button:)]) {
        [self.delegate dashboardTableViewCellDidTapSeriesButton:self button:sender];
    }
}

@end
