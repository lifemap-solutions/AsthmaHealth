//
//  APHDashboardGraphTableViewCell.h
//  Asthma
//

@import APCAppCore;
#import "APHLineGraphView.h"

FOUNDATION_EXPORT NSString * const kAPHDashboardGraphTableViewCell;



@protocol APHDashboardTableViewCellDelegate <APCDashboardTableViewCellDelegate>

-(void)dashboardTableViewCellDidTapSeriesButton:(APCDashboardTableViewCell *)cell button:(UIButton *)seriesButton;

@end



@interface APHDashboardGraphTableViewCell : APCDashboardGraphTableViewCell

@property (weak, nonatomic) IBOutlet UIButton *series1Button;
@property (weak, nonatomic) IBOutlet UIButton *series2Button;
@property (weak, nonatomic) IBOutlet APHLineGraphView *lineGraphView;

@property (weak, nonatomic) id <APHDashboardTableViewCellDelegate> delegate;

@end
