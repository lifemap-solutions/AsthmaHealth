//
//  APHLineGraphView.m
//  Asthma
//

#import "APHLineGraphView.h"

static CGFloat const kYAxisPaddingFactor = 0.15f;
static CGFloat const kAxisMarkingRulerLength = 8.0f;

@interface APHLineGraphView ()

@property (nonatomic, strong) UIView *yAxisLeftView;
@property (nonatomic, strong) UILabel *emptyLabel;
@property (nonatomic) BOOL hasDataPoint;

@end

@implementation APHLineGraphView

@dynamic datasource;
@dynamic emptyLabel;
@dynamic hasDataPoint;

- (void) drawLeftYAxis{
    
    [self prepareData];
    
    if (self.yAxisLeftView){
        [self.yAxisLeftView removeFromSuperview];
    }
    
    CGFloat axisViewWidth = CGRectGetWidth(self.frame)*kYAxisPaddingFactor;
    self.yAxisLeftView = [[UIView alloc] initWithFrame:CGRectMake(0, kAPCGraphTopPadding,
                                                                  axisViewWidth, CGRectGetHeight(self.plotsView.frame))];
    [self addSubview:_yAxisLeftView];
    
    NSArray *yAxisLabelFactors;
    
    if (self.minimumValueLeftY == self.maximumValueLeftY) {
        yAxisLabelFactors = @[@0.5f];
    } else {
        yAxisLabelFactors = @[@0.2f,@1.0f];
    }
    
    for (NSUInteger i =0; i<yAxisLabelFactors.count; i++) {
        
        CGFloat factor = [yAxisLabelFactors[i] floatValue];
        CGFloat positionOnYAxis = (CGRectGetHeight(self.plotsView.frame) - kAxisMarkingRulerLength) * (1 - factor);
        
        UIBezierPath *rulerPath = [UIBezierPath bezierPath];
        [rulerPath moveToPoint:CGPointMake(2, positionOnYAxis)];
        [rulerPath addLineToPoint:CGPointMake(kAxisMarkingRulerLength, positionOnYAxis)];
        
        CAShapeLayer *rulerLayer = [CAShapeLayer layer];
        rulerLayer.strokeColor = self.axisColor.CGColor;
        rulerLayer.path = rulerPath.CGPath;
        [_yAxisLeftView.layer addSublayer:rulerLayer];
        
        CGFloat labelHeight = 20;
        CGFloat labelYPosition = positionOnYAxis - labelHeight/2;
        
        CGFloat yValue = self.minimumValueLeftY + (self.maximumValueLeftY - self.minimumValueLeftY)*factor;
        
        UILabel *axisTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(kAxisMarkingRulerLength, labelYPosition, CGRectGetWidth(_yAxisLeftView.frame) - kAxisMarkingRulerLength, labelHeight)];
        
        if (yValue != 0) {
            axisTitleLabel.text = [NSString stringWithFormat:@"%0.0f", yValue];
        }
        axisTitleLabel.backgroundColor = [UIColor clearColor];
        axisTitleLabel.textColor = self.leftAxisTitleColor;
        axisTitleLabel.textAlignment = NSTextAlignmentLeft;
        axisTitleLabel.font = self.isLandscapeMode ? [UIFont fontWithName:self.axisTitleFont.familyName size:16.0f] : self.axisTitleFont;
        axisTitleLabel.minimumScaleFactor = 0.8;
        [_yAxisLeftView addSubview:axisTitleLabel];
    }
    
    _yAxisLeftView.hidden = self.hidesYAxis;
}

-(void) prepareData{
    
    if ([self.datasource respondsToSelector:@selector(minimumValueForLineGraphLefttYAxis:)]) {
        self.minimumValueLeftY = [self.datasource minimumValueForLineGraphLefttYAxis:self];
    }
    
    if ([self.datasource respondsToSelector:@selector(maximumValueForLineGraphLeftYAxis:)]){
        self.maximumValueLeftY = [self.datasource maximumValueForLineGraphLeftYAxis:self];
    }
}

- (void)checkForDataPointsAtIndex:(NSInteger)plotIndex {
    for (int i = 0; i<[self numberOfPointsinPlot:plotIndex]; i++) {
        
        if ([self.datasource respondsToSelector:@selector(lineGraph:plot:valueForPointAtIndex:)]) {
            CGFloat value = [self.datasource lineGraph:self plot:plotIndex valueForPointAtIndex:i];
            if (value != NSNotFound){
                self.hasDataPoint = YES;
            }
        }
    }
}

-(void) refreshGraph {
    [super refreshGraph];
    [self drawLeftYAxis];
    
    if (!self.hasDataPoint){
        
        [self checkForDataPointsAtIndex:0];
        
        // if it has dataPoint on plotIndex0
        // remove the empty label
        
        if (self.hasDataPoint){
            if (self.emptyLabel){
                [self.emptyLabel removeFromSuperview];
            }
        }
    }
}

@end
