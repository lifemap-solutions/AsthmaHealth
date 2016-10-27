//
//  APHCorrelationsSelectorViewController.h
//  Asthma
//

@import APCAppCore;

@class APHScoring;
@class APHCorrelationsSelectorViewController;

@protocol APHCorrelationsSelectorDelegate <APCCorrelationsSelectorDelegate>

- (void) viewController:(APCCorrelationsSelectorViewController *)viewController didChangeCorrelatedScoringDataSource:(APHScoring*)scoring;
@end

@interface APHCorrelationsSelectorViewController : APCCorrelationsSelectorViewController

@property (weak, nonatomic) id<APHCorrelationsSelectorDelegate> delegate;
@property NSUInteger seriesNumber;

- (id)initWithScoringObjects:(NSArray *)scoringObjects withSelectedObj1:(APCScoring *)selectedObj1 andSelectedObj2:(APCScoring*)selectedObj2;
@end
