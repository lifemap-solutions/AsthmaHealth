// 
//  APHDashboardViewController.m 
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
 
#import "APHDashboardViewController.h"
#import "APHDashboardEditViewController.h"
#import "APHDashboardAirQualityTableViewCell.h"
#import "APHDashboardButtonTableViewCell.h"
#import "APHAirQualityCollectionViewCell.h"
#import "APHTableViewDashboardButtonItem.h"
#import "APHAsthmaBadgesObject.h"
#import "APHDashboardBadgesTableViewCell.h"
#import "APHBadgesCollectionViewCell.h"
#import "APHCalendarCollectionViewController.h"
#import "APHAirQualitySectionHeaderView.h"
#import "APHCalendarDataModel.h"
#import "APHConstants.h"
#import "APHAppDelegate.h"
#import "APHCountryBasedConfig.h"
#import "UIColor+APHAppearance.h"
#import "APHLocationManager.h"
#import "APHMedicationTaskViewController.h"
#import "APHScoring.h"
#import "APCDashboardTableViewCell+Overlay.h"
#import "APHCorrelationsSelectorViewController.h"
#import "APHDashboardGraphTableViewCell.h"
#import "APCTableViewRow+Initialization.h"

#import "APHQuickReliefScoring.h"
#import "APHMedicineAdherenceScoring.h"
#import "APHCorrelatedScoring.h"

#import "APHActivityDashboardItem.h"
#import "APHStepsDashboardItem.h"
#import "APHPeakFlowDashboardItem.h"
#import "APHHeartRateDashboardItem.h"
#import "APHAsthmaSymptomsDashboardItem.h"
#import "APHCorrelationDashboardItem.h"
#import "APHBadgeDashboardItem.h"
#import "APHAirQualityNearYouDashboardItem.h"





static NSString *kTooltipAirQualityContent = @"The AQI is a daily index of how clean or polluted the air is in your area, and what associated health effects may be a concern for you. “PM2.5” is a measure of 2.5 µm particules in the air; “PM10” refers to 10 µm particles. High levels of 2.5 µm particles can aggravate asthma symptoms in some people. AQI data provided by US EPA AirNow.";



static NSString * const kAPCBasicTableViewCellIdentifier       = @"APCBasicTableViewCell";
static NSString * const kAPCRightDetailTableViewCellIdentifier = @"APCRightDetailTableViewCell";

NSString *const kDataNotAvailable = @"N/A";

@interface APHDashboardViewController () <UIViewControllerTransitioningDelegate, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, APCConcentricProgressViewDataSource, APHCorrelationsSelectorDelegate, APHDashboardTableViewCellDelegate, APHBadgeDashboardItemDelegate>

@property (nonatomic, strong) NSArray *rowItemsOrder;

@property (nonatomic, strong) APHActivityDashboardItem *activityItem;
@property (nonatomic, strong) APHStepsDashboardItem *stepItem;
@property (nonatomic, strong) APHPeakFlowDashboardItem *peakItem;
@property (nonatomic, strong) APHHeartRateDashboardItem *heartItem;
@property (nonatomic, strong) APHAsthmaSymptomsDashboardItem *asthmaItem;
@property (nonatomic, strong) APHCorrelationDashboardItem *correlatedItem;
@property (nonatomic, strong) APHBadgeDashboardItem *badgeItem;
@property (nonatomic, strong) APHAirQualityNearYouDashboardItem * aqnuItem;

@property (nonatomic, strong) APHScoring *quickReliefScore;
@property (nonatomic, strong) APHScoring *medicineAdherenceScore;

@property (nonatomic, assign) BOOL shouldAnimateObjects;

@property (nonatomic, strong) APHAsthmaBadgesObject *badgeObject;
@end



@implementation APHDashboardViewController


#pragma mark - View Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Dashboard", @"Dashboard");
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.rowItemsOrder = nil;


    self.asthmaItem.badgeObject = self.badgeObject;
    self.badgeItem.badgeObject = self.badgeObject;


    [self registerNotifications];

    self.shouldAnimateObjects = NO;

    [self.peakItem refresh];
    [self prepareData];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];

    [self unregisterNotifications];
}



#pragma mark - Badge Dashboard Item Delegate

- (void)badgeDashboardItem:(APHBadgeDashboardItem *) __unused badgeItem didSelectTaskWithType:(APHCalendarTaskType)taskType {
    APHCalendarCollectionViewController *calendarViewController = [[UIStoryboard storyboardWithName:@"APHDashboard" bundle:nil] instantiateViewControllerWithIdentifier:@"APHCalendarCollectionViewController"];

    calendarViewController.dataSource = self.badgeItem.calendarDataModel;
    calendarViewController.taskType = taskType;

    [self.navigationController pushViewController:calendarViewController animated:YES];
}



#pragma mark - Dashboard Items

- (APHAsthmaBadgesObject *)badgeObject {
    if (!_badgeObject) {
        _badgeObject = [APHAsthmaBadgesObject new];
    }

    return _badgeObject;
}

- (APHActivityDashboardItem *)activityItem {
    if (!_activityItem) {
        _activityItem = [APHActivityDashboardItem new];
    }

    return _activityItem;
}

- (APHStepsDashboardItem *)stepItem {
    if (!_stepItem) {
        _stepItem = [APHStepsDashboardItem new];
    }

    return _stepItem;
}

- (APHPeakFlowDashboardItem *)peakItem {
    if (!_peakItem) {
        _peakItem = [APHPeakFlowDashboardItem new];
    }

    return _peakItem;
}

- (APHHeartRateDashboardItem *)heartItem {
    if (!_heartItem) {
        _heartItem = [APHHeartRateDashboardItem new];
    }

    return _heartItem;
}

- (APHAsthmaSymptomsDashboardItem *)asthmaItem {
    if (!_asthmaItem) {
        _asthmaItem = [APHAsthmaSymptomsDashboardItem new];
    }

    return _asthmaItem;
}

- (APHCorrelationDashboardItem *)correlatedItem {
    if (!_correlatedItem) {
        _correlatedItem = [APHCorrelationDashboardItem new];
        _correlatedItem.correlatedScore = [APHCorrelatedScoring correlatedScoringWithScore:self.stepItem.stepScoring andScore:self.peakItem.peakScoring];
    }

    return _correlatedItem;
}

- (APHBadgeDashboardItem *)badgeItem {
    if (!_badgeItem) {
        _badgeItem = [APHBadgeDashboardItem new];
        _badgeItem.delegate = self;
    }

    return _badgeItem;
}

- (APHAirQualityNearYouDashboardItem *)aqnuItem {
    if (!_aqnuItem) {
        _aqnuItem = [APHAirQualityNearYouDashboardItem new];
    }

    return _aqnuItem;
}



#pragma mark - Scoring Objects

- (APCScoring *)quickReliefScore {
    if (!_quickReliefScore) {
        _quickReliefScore = [APHQuickReliefScoring quickReliefScoring];
    }

    return _quickReliefScore;
}

- (APCScoring *)medicineAdherenceScore {
    if(!_medicineAdherenceScore) {
        _medicineAdherenceScore = [APHMedicineAdherenceScoring medicineAdherenceScoring];
    }

    return _medicineAdherenceScore;
}



#pragma mark -

@synthesize items = _items;

- (NSMutableArray *)items {
    if (_items) {
        return _items;
    }

    _items = [NSMutableArray new];

    APHTableViewDashboardButtonItem *doctorItem = [APHTableViewDashboardButtonItem new];
    doctorItem.identifier = kAPHDashboardButtonTableViewCellIdentifier;
    doctorItem.editable = NO;
    doctorItem.buttonText = NSLocalizedString(@"Doctor Dashboard", @"");

    NSArray *orderable = @[
                    [APCTableViewRow rowWithItem:self.stepItem andType:kAPHDashboardItemTypeSteps],
                    [APCTableViewRow rowWithItem:self.heartItem andType:kAPHDashboardItemTypeHeartRate],
                    [APCTableViewRow rowWithItem:self.peakItem andType:kAPHDashboardItemTypePeakFlow],
                    [APCTableViewRow rowWithItem:self.asthmaItem andType:kAPHDashboardItemTypeAsthmaControl],
                    [APCTableViewRow rowWithItem:self.correlatedItem andType:kAPHDashboardItemTypeCorrelation],
                    [APCTableViewRow rowWithItem:self.badgeItem andType:kAPHDashboardItemTypeBadges],
                    [APCTableViewRow rowWithItem:self.aqnuItem andType:kAPHDashboardItemTypeAQNU]
                   ];

    NSArray *ordered = [orderable sortedArrayUsingComparator:^NSComparisonResult(APCTableViewRow *a, APCTableViewRow *b) {
        return [self compareTableRow:a withTableRow:b];
    }];

    NSMutableArray *arr = [NSMutableArray new];
    [arr addObject:[APCTableViewRow rowWithItem:self.activityItem andType:kAPHDashboardItemTypeActivity]];
    [arr addObjectsFromArray:ordered];
    [arr addObject:[APCTableViewRow rowWithItem:doctorItem andType:kAPHDashboardItemTypeDoctor]];

    APCTableViewSection *section = [APCTableViewSection new];
    section.rows = [arr copy];

    section.sectionTitle = NSLocalizedString(@"Recent Activity", @"");
    [_items addObject:section];

    return _items;
}

- (void)prepareData {
    self.items = nil;

    [self.tableView reloadData];
}



#pragma mark -

- (void)configureAqnuCell:(APHDashboardAirQualityTableViewCell *)cell forDashboardItem:(APHAirQualityNearYouDashboardItem *)dashboardItem {

    cell.delegate = self;
    cell.collectionView.delegate = dashboardItem;
    cell.collectionView.dataSource = dashboardItem;
    cell.airQualityLocationLabel.text = dashboardItem.detailText;
    cell.textLabel.text = @"";
    cell.title = dashboardItem.caption;
    cell.tintColor = dashboardItem.tintColor;
    [cell.collectionView reloadData];

}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    APCDashboardTableViewCell *cell = (APCDashboardTableViewCell*)[super tableView:tableView cellForRowAtIndexPath:indexPath];
    APCTableViewDashboardItem *dashboardItem = (APCTableViewDashboardItem *)[self itemForIndexPath:indexPath];
    
    [cell configureOverlay:dashboardItem.overlayConfig];

    if ([dashboardItem isKindOfClass:[APHAirQualityNearYouDashboardItem class]]) {

        [self configureAqnuCell:(APHDashboardAirQualityTableViewCell *)cell forDashboardItem:(APHAirQualityNearYouDashboardItem *)dashboardItem];

    } else if ([dashboardItem isKindOfClass:[APHTableViewDashboardBadgesItem class]]) {
        
        APHTableViewDashboardBadgesItem *badgeItem = (APHTableViewDashboardBadgesItem *)dashboardItem;
        
        APHDashboardBadgesTableViewCell *badgeCell = (APHDashboardBadgesTableViewCell *)cell;
        badgeCell.delegate = self;
        badgeCell.concentricProgressView.datasource = self.badgeItem;
        badgeCell.textLabel.text = @"";
        badgeCell.title = badgeItem.caption;
        badgeCell.tintColor = badgeItem.tintColor;
        
        badgeCell.collectionView.delegate = self.badgeItem;
        badgeCell.collectionView.dataSource = self.badgeItem;
        badgeCell.collectionView.tag = kCollectionViewsBaseTag + indexPath.row;
        [badgeCell.collectionView reloadData];
        if (self.shouldAnimateObjects) {
            [badgeCell.concentricProgressView setNeedsLayout];
        }
    
    } else if ([dashboardItem isKindOfClass:[APCTableViewDashboardAsthmaControlItem class]]){
        APCTableViewDashboardAsthmaControlItem *asthmaItem = (APCTableViewDashboardAsthmaControlItem *)dashboardItem;
        
        APCDashboardPieGraphTableViewCell *pieGraphCell = (APCDashboardPieGraphTableViewCell *)cell;
        pieGraphCell.delegate = self;
        pieGraphCell.pieGraphView.datasource = self.asthmaItem;
        pieGraphCell.textLabel.text = @"";
        pieGraphCell.title = asthmaItem.caption;
        pieGraphCell.tintColor = asthmaItem.tintColor;
        if (self.shouldAnimateObjects) {
            [pieGraphCell.pieGraphView setNeedsLayout];
        }
        
    } else if ([dashboardItem isKindOfClass:[APHTableViewDashboardButtonItem class]]){
        APHTableViewDashboardButtonItem *buttonItem = (APHTableViewDashboardButtonItem *)dashboardItem;

        APHDashboardButtonTableViewCell *buttonCell = (APHDashboardButtonTableViewCell *)cell;
        [buttonCell setButtonText:buttonItem.buttonText];

    } else if ([dashboardItem isKindOfClass:[APCTableViewDashboardGraphItem class]]){
        
        if ([cell isKindOfClass:[APHDashboardGraphTableViewCell class]]){
            APHDashboardGraphTableViewCell *graphCell = (APHDashboardGraphTableViewCell *)cell;
            
            UIFont *font = [UIFont appLightFontWithSize:15.0f];
            UIColor *blue = [UIColor appTertiaryBlueColor];
            UIColor *yellow = [UIColor appTertiaryYellowColor];
            
            NSAttributedString *series1Title = [[NSMutableAttributedString alloc]initWithString:self.correlatedItem.correlatedScore.series1Name attributes:@{NSFontAttributeName : font, NSForegroundColorAttributeName : yellow, NSUnderlineStyleAttributeName : @1 }];

            NSAttributedString *series2Title = [[NSMutableAttributedString alloc]initWithString:self.correlatedItem.correlatedScore.series2Name attributes:@{NSFontAttributeName : font, NSForegroundColorAttributeName : blue, NSUnderlineStyleAttributeName : @1 }];

            APHLineGraphView *lineGraph = (APHLineGraphView *)graphCell.lineGraphView;
            
            lineGraph.axisTitleColor = [UIColor appTertiaryBlueColor];
            lineGraph.leftAxisTitleColor = [UIColor appTertiaryYellowColor];
            
            [graphCell.series1Button setAttributedTitle:series1Title forState:UIControlStateNormal];
            [graphCell.series2Button setAttributedTitle:series2Title forState:UIControlStateNormal];
            
            graphCell.delegate = self;
        }
        
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {

    APCTableViewItem *dashboardItem = [self itemForIndexPath:indexPath];

    if ([dashboardItem isKindOfClass:[APHAirQualityNearYouDashboardItem class]]) {
        APHAirQualityNearYouDashboardItem *item = (APHAirQualityNearYouDashboardItem *)dashboardItem;

        NSInteger numberOfItemsForAirQuality = [item collectionView:nil numberOfItemsInSection:0];
        NSInteger multiplier = [item numberOfSectionsInCollectionView:nil];

        return 70 + (numberOfItemsForAirQuality * kAirQualityCollectionViewCellHeight * multiplier) + (kAirQualityCollectionViewHeaderHeight * multiplier);
    }

    if ([dashboardItem isKindOfClass:[APHTableViewDashboardBadgesItem class]]){
        return 179 + (self.badgeItem.badgeItems.count*kBadgesCollectionViewCellHeight);
    }

    if ([dashboardItem isKindOfClass:[APCTableViewDashboardAsthmaControlItem class]]){
        return 259;
    }

    if ([dashboardItem isKindOfClass:[APHTableViewDashboardButtonItem class]]){
        return 140;
    }

    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}



#pragma mark -

-(void) updateBadgesData: (NSNotification *)notification {

    NSArray *visibleIndexPaths = [self.tableView indexPathsForVisibleRows];

    for (NSIndexPath* indexPath in visibleIndexPaths) {

        APCTableViewDashboardItem *dashboardItem = (APCTableViewDashboardItem *)[self itemForIndexPath:indexPath];

        if ([dashboardItem isKindOfClass:[APHTableViewDashboardBadgesItem class]]) {
            [self updateVisibleRowsInTableView:notification];
            break;
        }
    }
}



#pragma mark - Overriding APHDashboardVC

- (void)updateVisibleRowsInTableView:(NSNotification *)notification
{
    [super updateVisibleRowsInTableView:notification];
    [self prepareData];
    self.shouldAnimateObjects = YES;
}



#pragma mark - APCDashboardTableViewCellDelegate

- (void)viewController:(APCCorrelationsSelectorViewController *)__unused viewController didChangeCorrelatedScoringDataSource:(APHScoring *)scoring
{
    NSString *caption = self.correlatedItem.correlatedScore.caption;

    self.correlatedItem.correlatedScore = scoring;
    self.correlatedItem.correlatedScore.caption = caption;
    
    [self prepareData];
}

-(void)dashboardTableViewCellDidTapSeriesButton:(APCDashboardTableViewCell *)__unused cell button:(UIButton *) seriesButton
{
    NSUInteger seriesNumber = seriesButton.tag;
    [self presentCorrelationsSelectorWithSeriesNumber:seriesNumber];
}

-(void)dashboardTableViewCellDidTapExpand:(APCDashboardTableViewCell *)cell{
    
    if ([cell isKindOfClass:[APHDashboardGraphTableViewCell class]]){
        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
        
        APCTableViewDashboardGraphItem *graphItem = (APCTableViewDashboardGraphItem *)[self itemForIndexPath:indexPath];
        UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"APHDashboard" bundle:[NSBundle mainBundle]];
        APCGraphViewController *graphViewController = [mainStoryboard instantiateViewControllerWithIdentifier:@"APHLineGraphViewController"];
        
        graphViewController.graphItem = graphItem;
        NSAttributedString *legendAttrString = [APCTableViewDashboardGraphItem legendForSeries1:self.correlatedItem.correlatedScore.series1Name series2:self.correlatedItem.correlatedScore.series2Name];
        graphViewController.graphItem.legend = legendAttrString;
        graphViewController.graphItem.detailText = @"";
        graphItem.graphData.scoringDelegate = graphViewController;
        
        
        [self.navigationController presentViewController:graphViewController animated:YES completion:^{
            
            APHLineGraphView *lineGraph = (APHLineGraphView *)graphViewController.lineGraphView;
            
            lineGraph.axisTitleColor = [UIColor appTertiaryBlueColor];
            lineGraph.leftAxisTitleColor = [UIColor appTertiaryYellowColor];
            
        }];
        
    }else{
        [super dashboardTableViewCellDidTapExpand:cell];
    }
}



#pragma mark - Correlations

-(void)presentCorrelationsSelectorWithSeriesNumber:(NSUInteger) seriesNumber
{
    NSArray *scoringObjects = @[
                                self.stepItem.stepScoring,
                                self.peakItem.peakScoring,
                                self.quickReliefScore,
                                self.medicineAdherenceScore
                               ];
    
    APHCorrelationsSelectorViewController *correlationSelector = [[APHCorrelationsSelectorViewController  alloc] initWithScoringObjects:scoringObjects
                                                                                                                       withSelectedObj1:self.correlatedItem.correlatedScore.seriesObject1
                                                                                                                        andSelectedObj2:self.correlatedItem.correlatedScore.seriesObject2];
    correlationSelector.seriesNumber = seriesNumber;
    correlationSelector.delegate = self;

    [self.navigationController pushViewController:correlationSelector animated:YES];
}




#pragma mark - Notifications

- (void)registerNotifications {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];

    [notificationCenter addObserver:self selector:@selector(updateBadgesData:) name:APHBadgesCalculationsComplete object:nil];
    [notificationCenter addObserver:self selector:@selector(peakScoringDidChanged:) name:APHPeakFlowScoringUpdateNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(aqnuDidChanged:) name:APHAQNUDashboardItemDidChangedUpdateNotification object:nil];
}

- (void)unregisterNotifications {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];

    [notificationCenter removeObserver:self name:APHBadgesCalculationsComplete object:nil];
    [notificationCenter removeObserver:self name:APHPeakFlowScoringUpdateNotification object:nil];
    [notificationCenter removeObserver:self name:APHAQNUDashboardItemDidChangedUpdateNotification object:nil];
}

- (void)peakScoringDidChanged:(NSNotification *) __unused notification {
    [self reloadDashboardItemWithType:kAPHDashboardItemTypePeakFlow];
}

- (void)aqnuDidChanged:(NSNotification *) __unused notification {

    NSIndexPath *indexPath = [self indexPathForDashboardItemType:kAPHDashboardItemTypeAQNU];

    if (!indexPath) {
        return;
    }

    APHDashboardAirQualityTableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    APHAirQualityNearYouDashboardItem *item = (APHAirQualityNearYouDashboardItem *)[self itemForIndexPath:indexPath];

    [self configureAqnuCell:cell forDashboardItem:item];
    [self.tableView reloadRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)reloadDashboardItemWithType:(APHDashboardItemType)type {
    NSIndexPath *indexPath = [self indexPathForDashboardItemType:type];

    if (!indexPath) {
        return;
    }

    [self.tableView reloadRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (nullable NSIndexPath *)indexPathForDashboardItemType:(APHDashboardItemType)type {
    NSUInteger index = [self.rowItemsOrder indexOfObject:@(type)];

    if (index == NSNotFound) {
        return nil;
    }

    NSUInteger offset = 1; // activity item
    return [NSIndexPath indexPathForRow:index+offset inSection:0];
}



#pragma mark - Row Items Order

- (NSComparisonResult)compareTableRow:(APCTableViewRow *)first withTableRow:(APCTableViewRow *)second {
    NSUInteger indexA = [self.rowItemsOrder indexOfObject:@(first.itemType)];
    NSUInteger indexB = [self.rowItemsOrder indexOfObject:@(second.itemType)];

    if (indexA < indexB) {
        return NSOrderedAscending;
    } else if (indexA > indexB) {
        return NSOrderedDescending;
    } else {
        return NSOrderedSame;
    }
}

- (NSArray *)rowItemsOrder {

    if (_rowItemsOrder) {
        return _rowItemsOrder;
    }

    NSOrderedSet *defaultItemsOrder = [NSOrderedSet orderedSetWithArray:[self defaultItemsOrder]];
    NSOrderedSet *storedItemsOrder = [NSOrderedSet orderedSetWithArray:[self loadStoredItemsOrder]];

    NSMutableOrderedSet *itemsOrder = [NSMutableOrderedSet new];

    [itemsOrder unionOrderedSet:storedItemsOrder];
    [itemsOrder intersectOrderedSet:defaultItemsOrder];
    [itemsOrder unionOrderedSet:defaultItemsOrder];

    _rowItemsOrder = [itemsOrder array];
    [self saveStoredItemsOrder:_rowItemsOrder]; // APHDashboardEditViewController is tricky
    return _rowItemsOrder;
}

- (NSArray *)defaultItemsOrder {
    return @[
             @(kAPHDashboardItemTypeAsthmaControl),
             @(kAPHDashboardItemTypeAQNU),
             @(kAPHDashboardItemTypeBadges),
             @(kAPHDashboardItemTypeSteps),
             @(kAPHDashboardItemTypeHeartRate),
             @(kAPHDashboardItemTypePeakFlow),
             //             @(kAPHDashboardItemTypeSleep)
             @(kAPHDashboardItemTypeCorrelation)
             ];
}

- (NSArray *)loadStoredItemsOrder {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    return [defaults objectForKey:kAPCDashboardRowItemsOrder] ?: @[];
}

- (void)saveStoredItemsOrder:(NSArray *)itemsOrder {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    [defaults setObject:itemsOrder forKey:kAPCDashboardRowItemsOrder];
    [defaults synchronize];
}

@end
