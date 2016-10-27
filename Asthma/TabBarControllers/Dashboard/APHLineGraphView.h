//
//  APHLineGraphView.h
//  Asthma
//

#import <APCAppCore/APCAppCore.h>


@class APCLineGraphView;



@protocol APHLineGraphViewDataSource <APCLineGraphViewDataSource>

@optional
- (CGFloat)maximumValueForLineGraphLeftYAxis:(APCLineGraphView *)graphView;
- (CGFloat)minimumValueForLineGraphLefttYAxis:(APCLineGraphView *)graphView;

@end



@interface APHLineGraphView : APCLineGraphView

@property (nonatomic, weak) IBOutlet id <APHLineGraphViewDataSource> datasource;
@property (nonatomic, readwrite) CGFloat minimumValueLeftY;
@property (nonatomic, readwrite) CGFloat maximumValueLeftY;

@property (nonatomic, strong) UIColor *leftAxisTitleColor;

- (void) drawLeftYAxis;

@end

