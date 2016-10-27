//
//  APHDoctorDashboardViewController.m
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
#import "APHDoctorDashboardViewController.h"
#import "APHTableViewDashboardGINAItem.h"
#import "APHTableViewDashboardAsthmaControlItem.h"
#import "APHTableViewDashboardSurveyCompletionItem.h"
#import "APHDashboardStatusSummaryTableViewCell.h"
#import "APHStatusCollectionViewCell.h"
#import "APHAsthmaBadgesObject.h"
#import "APHConstants.h"

static NSString *kTooltipStepsContent = @"This graph shows the number of steps you have taken each day, as recorded by your phone or connected device. Tap the button in the upper right corner to make the graph larger.";
static NSString *kTooltipPeakFlowContent = @"This graph shows your daily peak flow values, from your daily surveys or a connected device. Tap the button in the upper right corner to make the graph larger.";

static CGFloat const kAPHLineGraphCellHeight = 150.0f;
static CGFloat const kStatusCollectionViewHeaderHeight = 74.5f;
static CGFloat const kStatusCollectionViewSummaryHeight = 62.0f;
static CGFloat const kStatusCollectionViewSummaryEmptyHeight = 26.0f;
static CGFloat const kStatusCollectionViewCellHeight = 52.0f;

static NSInteger const kNumberOfItemsForGINA = 4;
static NSInteger const kNumberOfItemsForAsthmaControl = 3;
static NSInteger const kNumberOfItemsForSurveyCompletion = 2;

static NSInteger const kGraphDaysToShow = 28;

static NSString* const kPeakFlowGraphCaption = @"Peak Expiratory Flow";
static NSString* const kStepsTakenGraphCaption = @"Steps Taken";

static NSString* const kSegmentNameLast4Weeks = @"last 4 weeks";
static NSString* const kSegmentName4_8WeeksAgo = @"4-8 weeks ago";
static NSString* const kSegmentName8_12WeeksAgo = @"8-12 weeks ago";

static NSString* const kAnalyticsParamOverallControlCategory = @"OverallControlCategory";
static NSString* const kAnalyticsParamDaySymptoms = @"DaySymptoms";
static NSString* const kAnalyticsParamNightSymptoms = @"NightSymptoms";
static NSString* const kAnalyticsParamUseRelieverMedicine = @"UseRelieverMedicine";
static NSString* const kAnalyticsParamDaysActivityLimitation = @"DaysActivityLimitation";
static NSString* const kAnalyticsParamGINAEvaluationPeriod = @"GINAEvaluationPeriod";

static NSString* const kAnalyticsParamHealthCareUtilization = @"HealthCareUtilization";
static NSString* const kAnalyticsParamMedicationAdherencePercent = @"MedicationAdherencePercent";
static NSString* const kAnalyticsParamAsthmaControlPeriod = @"AsthmaControlPeriod";

static NSString* const kAnalyticsParamDailySurveyCompletedPercent = @"DailySurveyCompletedPercent";
static NSString* const kAnalyticsParamWeeklySurveyCompletedPercent = @"WeeklySurveyCompletedPercent";
static NSString* const kAnalyticsParamSurveyCompletionPeriod = @"SurveyCompletionPeriod";

// FIXME
static NSInteger kCollectionViewsBaseTag = 0;

@interface APHDoctorDashboardViewController ()<UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, APCDashboardTableViewCellDelegate>

@property (nonatomic, strong) APCScoring *stepScore;
@property (nonatomic, strong) APCScoring *peakScore;
@property (nonatomic, strong) APHAsthmaBadgesObject * badgeObject;
@property (nonatomic, assign) BOOL shouldAnimateObjects;
@property (nonatomic, assign) APHPeriodType periodFilter;
@property (nonatomic, strong) NSString *peakOffset;
@property (nonatomic, strong) NSString *stepOffset;
@property (nonatomic, strong) NSString *surveyOffset;
@property (nonatomic, assign) NSInteger selectedGINAPeriodIndex;
@property (nonatomic, assign) NSInteger selectedACPeriodIndex;
@property (nonatomic, assign) NSInteger selectedSCPeriodIndex;
@end

@implementation APHDoctorDashboardViewController

#pragma mark - Init

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        self.title = NSLocalizedString(@"Doctor Dashboard", @"Doctor Dashboard");
    }

    return self;
}

#pragma mark - LifeCycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    APCLogEventWithData(kAnalyticsDoctorDashboardView, @{});

    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    self.peakOffset = nil;
    self.stepOffset = nil;
    self.surveyOffset = nil;
    self.selectedGINAPeriodIndex = 0;
    self.selectedACPeriodIndex = 0;
    self.selectedSCPeriodIndex = 0;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.shouldAnimateObjects = NO;
    self.badgeObject = [APHAsthmaBadgesObject new];
    self.periodFilter = kAPHPeriodTypeFourWeek;
    
    
    [self prepareScoringObjects];
    [self prepareData];
}

#pragma mark - Data

- (void)prepareScoringObjects
{
    [self prepareStepScore];
    [self preparePeakScore];
}

-(void)prepareStepScore
{
    NSDate* endDate = [NSDate date];
    
    if(_stepOffset){
        endDate = [endDate dateBySubtractingISO8601Duration:_stepOffset];
    }
    
    HKQuantityType *hkQuantity = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    self.stepScore = [[APCScoring alloc] initWithHealthKitQuantityType:hkQuantity
                                                                  unit:[HKUnit countUnit]
                                                          numberOfDays:-kGraphDaysToShow
                                                               groupBy:APHTimelineGroupWeek
                                                               endDate:endDate];
}

-(void)preparePeakScore
{
    NSDate* endDate = [NSDate date];
    
    if(_peakOffset){
        endDate = [endDate dateBySubtractingISO8601Duration:_peakOffset];
    }
    
    self.peakScore = [[APCScoring alloc] initWithTask:kDailySurveyTaskID
                                         numberOfDays:-kGraphDaysToShow
                                             valueKey:kPeakFlowKey
                                              dataKey:nil
                                              sortKey:nil
                                              groupBy:APHTimelineGroupWeek
                                              endDate:endDate];
}

- (void)prepareData
{

    [self.items removeAllObjects];

    {
        NSMutableArray *rowItems = [NSMutableArray new];

        {
            APHTableViewDashboardGINAItem *item = [APHTableViewDashboardGINAItem new];
            item.caption = NSLocalizedString(@"GINA Evaluation", @"");

            item.identifier = kAPHDashboardStatusSummaryTableViewCellIdentifier;
            item.editable = YES;
            item.info = NSLocalizedString(kTooltipStepsContent, @"");
            [item prepare:self.badgeObject];

            APCTableViewRow *row = [APCTableViewRow new];
            row.item = item;
            row.itemType = kAPHDashboardItemTypeSteps;
            [rowItems addObject:row];
        }
        {
            APCTableViewDashboardGraphItem *item = [APCTableViewDashboardGraphItem new];
            item.caption = NSLocalizedString(kStepsTakenGraphCaption, @"");
            item.graphData = self.stepScore;
            if (self.stepScore.averageDataPoint.doubleValue > 0 && self.stepScore.averageDataPoint.doubleValue != self.stepScore.maximumDataPoint.doubleValue) {
                item.detailText = [NSString stringWithFormat:NSLocalizedString(@"Average : %0.0f Steps", @"Average: {value} ft"), [[self.stepScore averageDataPoint] doubleValue]];
            }
            item.identifier = kAPCDashboardGraphTableViewCellIdentifier;
            item.editable = YES;
            item.info = NSLocalizedString(kTooltipStepsContent, @"");
            item.tintColor = [UIColor appTertiaryPurpleColor];
            
            APCTableViewRow *row = [APCTableViewRow new];
            row.item = item;
            row.itemType = kAPHDashboardItemTypeSteps;
            [rowItems addObject:row];
        }
        {
            APHTableViewDashboardAsthmaControlItem *item = [APHTableViewDashboardAsthmaControlItem new];
            item.caption = NSLocalizedString(@"Asthma Control", @"");

            item.identifier = kAPHDashboardStatusSummaryTableViewCellIdentifier;
            item.editable = YES;
            item.info = NSLocalizedString(kTooltipStepsContent, @"");

            [item prepare:self.badgeObject];

            APCTableViewRow *row = [APCTableViewRow new];
            row.item = item;
            row.itemType = kAPHDashboardItemTypeSteps;
            [rowItems addObject:row];
        }
        {
            APCTableViewDashboardGraphItem *item = [APCTableViewDashboardGraphItem new];
            item.caption = NSLocalizedString(kPeakFlowGraphCaption, @"");
            if (self.peakScore.averageDataPoint.doubleValue > 0 && self.peakScore.averageDataPoint.doubleValue != self.peakScore.maximumDataPoint.doubleValue) {
                item.detailText = [NSString stringWithFormat:NSLocalizedString(@"Average : %0.0f", @"Average: {value} ft"), [[self.peakScore averageDataPoint] doubleValue]];
            }
            item.graphData = self.peakScore;
            item.identifier = kAPCDashboardGraphTableViewCellIdentifier;
            item.editable = YES;
            item.tintColor = [UIColor appTertiaryBlueColor];
            item.info = NSLocalizedString(kTooltipPeakFlowContent, @"");

            APCTableViewRow *row = [APCTableViewRow new];
            row.item = item;
            row.itemType = kAPHDashboardItemTypePeakFlow;
            [rowItems addObject:row];
        }
        {
            APHTableViewDashboardSurveyCompletionItem *item = [APHTableViewDashboardSurveyCompletionItem new];
            item.caption = NSLocalizedString(@"Survey Completion", @"");
            
            item.identifier = kAPHDashboardStatusSummaryTableViewCellIdentifier;
            item.editable = YES;
            item.info = NSLocalizedString(kTooltipStepsContent, @"");
            
            [item prepare:self.badgeObject];
            
            APCTableViewRow *row = [APCTableViewRow new];
            row.item = item;
            row.itemType = kAPHDashboardItemTypeSteps;
            [rowItems addObject:row];
        }

        APCTableViewSection *section = [APCTableViewSection new];
        section.rows = [NSArray arrayWithArray:rowItems];
        section.sectionTitle = NSLocalizedString(@"Recent Activity", @"");
        [self.items addObject:section];
    }

    [self.tableView reloadData];
    
    [self sendAnalyticsData];
}

- (void)updateScoringForOffset:(APCScoring*)scoring offeset:(NSString*)offset
{
    NSDate* endDate = [NSDate date];
    
    if(offset){
        endDate = [endDate dateBySubtractingISO8601Duration:offset];
    }

    [scoring updatePeriodForDays:-kGraphDaysToShow groupBy:APHTimelineGroupWeek endDate:endDate];
}

- (void)sendAnalyticsData
{
    NSMutableDictionary *data = [@{} mutableCopy];
    
    NSUInteger sections = [self.tableView numberOfSections];
    
    for (NSUInteger section = 0; section < sections; section++) {
        NSUInteger rows = [self.tableView numberOfRowsInSection:section];
        
        for (NSUInteger row = 0; row < rows; row++) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
            
            APCTableViewDashboardItem *dashboardItem = (APCTableViewDashboardItem *)[self itemForIndexPath:indexPath];
            
            if ([dashboardItem isKindOfClass:[APHTableViewDashboardGINAItem class]]) {
                APHTableViewDashboardGINAItem *ginaItem = (APHTableViewDashboardGINAItem *)dashboardItem;
                
                [data setObject:ginaItem.controlText ? ginaItem.controlText : @"" forKey:kAnalyticsParamOverallControlCategory];
                [data setObject:[@(ginaItem.daytimeSymptoms) stringValue] forKey:kAnalyticsParamDaySymptoms];
                [data setObject:[@(ginaItem.nightWakingOccurrences) stringValue] forKey:kAnalyticsParamNightSymptoms];
                [data setObject:[@(ginaItem.neededReliever) stringValue] forKey:kAnalyticsParamUseRelieverMedicine];
                [data setObject:[@(ginaItem.limitationsDays) stringValue] forKey:kAnalyticsParamDaysActivityLimitation];
                NSString *period = [self segmentNameForIndex:self.selectedGINAPeriodIndex];
                [data setObject:period ? period : @"" forKey:kAnalyticsParamGINAEvaluationPeriod];
            } else if ([dashboardItem isKindOfClass:[APHTableViewDashboardAsthmaControlItem class]]) {
                APHTableViewDashboardAsthmaControlItem *asthmaItem = (APHTableViewDashboardAsthmaControlItem *)dashboardItem;
                
                [data setObject:[@(asthmaItem.majorEvents) stringValue] forKey:kAnalyticsParamHealthCareUtilization];
                [data setObject:[@(asthmaItem.medicationAdherencePercent) stringValue] forKey:kAnalyticsParamMedicationAdherencePercent];
                NSString *period = [self segmentNameForIndex:self.selectedACPeriodIndex];
                [data setObject:period ? period : @"" forKey:kAnalyticsParamAsthmaControlPeriod];
            } else if ([dashboardItem isKindOfClass:[APHTableViewDashboardSurveyCompletionItem class]]) {
                APHTableViewDashboardSurveyCompletionItem *surveyItem = (APHTableViewDashboardSurveyCompletionItem *)dashboardItem;
                
                [data setObject:[@(surveyItem.dailySurveyCompletedPercent) stringValue] forKey:kAnalyticsParamDailySurveyCompletedPercent];
                [data setObject:[@(surveyItem.weeklySurveyCompletedPercent) stringValue] forKey:kAnalyticsParamWeeklySurveyCompletedPercent];
                NSString *period = [self segmentNameForIndex:self.selectedSCPeriodIndex];
                [data setObject:period ? period : @"" forKey:kAnalyticsParamSurveyCompletionPeriod];
            }
        }
    }
    
    APCLogEventWithData(kAnalyticsDoctorDashboardView, data);
}

#pragma mark - UITableViewDelegate methods

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];

    APCTableViewDashboardItem *dashboardItem = (APCTableViewDashboardItem *)[self itemForIndexPath:indexPath];

    if ([dashboardItem isKindOfClass:[APHTableViewDashboardGINAItem class]]) {
        APHTableViewDashboardGINAItem *ginaItem = (APHTableViewDashboardGINAItem *)dashboardItem;

        APHDashboardStatusSummaryTableViewCell *statusCell = (APHDashboardStatusSummaryTableViewCell *)cell;
        statusCell.delegate = self;
        statusCell.textLabel.text = @"";
        statusCell.overallLabel.text = NSLocalizedString(@"Overall Evaluation", @"");
        statusCell.title = ginaItem.caption;
        statusCell.tintColor = ginaItem.tintColor;
        
        statusCell.dateRangeLabel.text = ginaItem.dateRangeText;
        statusCell.controlLabel.text = ginaItem.controlText;
        statusCell.controlLabel.textColor = ginaItem.controlColor;

        statusCell.collectionView.delegate = self;
        statusCell.collectionView.dataSource = self;
        statusCell.collectionView.tag = kCollectionViewsBaseTag + indexPath.row;
        
        [statusCell.segmentedControl setSelectedSegmentIndex:self.selectedGINAPeriodIndex];
        
        [statusCell.collectionView reloadData];
    } else if ([dashboardItem isKindOfClass:[APHTableViewDashboardAsthmaControlItem class]]) {
        APHTableViewDashboardAsthmaControlItem *asthmaItem = (APHTableViewDashboardAsthmaControlItem *)dashboardItem;

        APHDashboardStatusSummaryTableViewCell *statusCell = (APHDashboardStatusSummaryTableViewCell *)cell;
        statusCell.delegate = self;
        statusCell.textLabel.text = @"";
        statusCell.overallLabel.text = @"";
        statusCell.title = asthmaItem.caption;
        statusCell.tintColor = asthmaItem.tintColor;

        statusCell.dateRangeLabel.text = asthmaItem.dateRangeText;
        statusCell.controlLabel.text = asthmaItem.controlText;
        statusCell.controlLabel.textColor = asthmaItem.controlColor;

        statusCell.collectionView.delegate = self;
        statusCell.collectionView.dataSource = self;
        statusCell.collectionView.tag = kCollectionViewsBaseTag + indexPath.row;
        
        [statusCell.segmentedControl setSelectedSegmentIndex:self.selectedACPeriodIndex];
        
        [statusCell.collectionView reloadData];
    } else if ([dashboardItem isKindOfClass:[APHTableViewDashboardSurveyCompletionItem class]]) {
        APHTableViewDashboardSurveyCompletionItem *asthmaItem = (APHTableViewDashboardSurveyCompletionItem *)dashboardItem;
        
        APHDashboardStatusSummaryTableViewCell *statusCell = (APHDashboardStatusSummaryTableViewCell *)cell;
        statusCell.delegate = self;
        statusCell.textLabel.text = @"";
        statusCell.overallLabel.text = @"";
        statusCell.title = asthmaItem.caption;
        statusCell.tintColor = asthmaItem.tintColor;
        
        statusCell.dateRangeLabel.text = asthmaItem.dateRangeText;
        statusCell.controlLabel.text = asthmaItem.controlText;
        statusCell.controlLabel.textColor = asthmaItem.controlColor;
        
        statusCell.collectionView.delegate = self;
        statusCell.collectionView.dataSource = self;
        statusCell.collectionView.tag = kCollectionViewsBaseTag + indexPath.row;
        
        [statusCell.segmentedControl setSelectedSegmentIndex:self.selectedSCPeriodIndex];
        
        [statusCell.collectionView reloadData];
    }
    // TODO: handle other custom cells

    return cell;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = 0;

    APCTableViewItem *dashboardItem = [self itemForIndexPath:indexPath];

    if ([dashboardItem isKindOfClass:[APCTableViewDashboardGraphItem class]]) {
        height = kAPHLineGraphCellHeight;
    } else if ([dashboardItem isKindOfClass:[APHTableViewDashboardGINAItem class]]) {
        height = kStatusCollectionViewHeaderHeight + kStatusCollectionViewSummaryHeight;
        height += (kNumberOfItemsForGINA*kStatusCollectionViewCellHeight);
    } else if ([dashboardItem isKindOfClass:[APHTableViewDashboardAsthmaControlItem class]]) {
        height = kStatusCollectionViewHeaderHeight + kStatusCollectionViewSummaryEmptyHeight;
        height += (kNumberOfItemsForAsthmaControl*kStatusCollectionViewCellHeight);
    } else if ([dashboardItem isKindOfClass:[APHTableViewDashboardSurveyCompletionItem class]]) {
        height = kStatusCollectionViewHeaderHeight + kStatusCollectionViewSummaryEmptyHeight;
        height += (kNumberOfItemsForSurveyCompletion*kStatusCollectionViewCellHeight);
    } else {
        height = [super tableView:tableView heightForRowAtIndexPath:indexPath];
    }
    return height;
}

- (void)tableView:(UITableView *)__unused tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    APCTableViewItem *dashboardItem = [self itemForIndexPath:indexPath];
    
    if ([dashboardItem isKindOfClass:[APCTableViewDashboardGraphItem class]]){
        APCTableViewDashboardGraphItem *graphItem = (APCTableViewDashboardGraphItem *)dashboardItem;
        APCDashboardGraphTableViewCell *graphCell = (APCDashboardGraphTableViewCell *)cell;
        
        APCBaseGraphView *graphView;
        
        if (graphItem.graphType == kAPCDashboardGraphTypeLine) {
            graphView = (APCLineGraphView *)graphCell.lineGraphView;
            
        } else if (graphItem.graphType == kAPCDashboardGraphTypeDiscrete) {
            graphView = (APCDiscreteGraphView *)graphCell.discreteGraphView;
        }
        
        [graphView setNeedsLayout];
        [graphView layoutIfNeeded];
        [graphView refreshGraph];
    }
}

#pragma mark - Helper methods

- (void)setupStatusCell:(APHStatusCollectionViewCell *)statusCell count:(NSInteger)count status:(APHStatus)status
{
    switch (status) {
        case kAPHStatusUnknown:
            statusCell.countBackgroundColor = [UIColor appTertiaryGrayColor];
            statusCell.countLabel.text = @"N/A";
            break;
        case kAPHStatusGreen:
            statusCell.countBackgroundColor = [UIColor appTertiaryGreenColor];
            statusCell.countLabel.text = [NSString stringWithFormat:@"%ld", count];
            break;
        case kAPHStatusOrange:
            statusCell.countBackgroundColor = [UIColor appTertiaryYellowColor];
            statusCell.countLabel.text = [NSString stringWithFormat:@"%ld", count];
            break;
        case kAPHStatusRed:
            statusCell.countBackgroundColor = [UIColor appTertiaryRedColor];
            statusCell.countLabel.text = [NSString stringWithFormat:@"%ld", count];
            break;
        default:
            break;
    }
}

- (NSString *)segmentNameForIndex:(NSInteger)index {
    NSString *name;
    
    switch (index) {
        case 1:
            name = kSegmentName4_8WeeksAgo;
            break;
            
        case 2:
            name = kSegmentName8_12WeeksAgo;
            break;
            
        default:
            name = kSegmentNameLast4Weeks;
            break;
    };
    
    return name;
}

#pragma mark - UICollectionViewDataSource methods

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *) __unused collectionView
{
    NSInteger count = 1;

    //NSIndexPath *indexPath = [NSIndexPath indexPathForRow:(collectionView.tag - kCollectionViewsBaseTag) inSection:0];

    //APCTableViewDashboardItem *dashboardItem = (APCTableViewDashboardItem *)[self itemForIndexPath:indexPath];

    return count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger) __unused section
{
    NSInteger count = 0;

    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:(collectionView.tag - kCollectionViewsBaseTag) inSection:0];

    APCTableViewDashboardItem *dashboardItem = (APCTableViewDashboardItem *)[self itemForIndexPath:indexPath];

    if ([dashboardItem isKindOfClass:[APHTableViewDashboardGINAItem class]]){
        count = kNumberOfItemsForGINA;
    } else if ([dashboardItem isKindOfClass:[APHTableViewDashboardAsthmaControlItem class]]){
        count = kNumberOfItemsForAsthmaControl;
    } else if ([dashboardItem isKindOfClass:[APHTableViewDashboardSurveyCompletionItem class]]){
        count = kNumberOfItemsForSurveyCompletion;
    }

    return count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *itemIndexPath = [NSIndexPath indexPathForRow:(collectionView.tag - kCollectionViewsBaseTag) inSection:0];

    APCTableViewDashboardItem *dashboardItem = (APCTableViewDashboardItem *)[self itemForIndexPath:itemIndexPath];

    UICollectionViewCell *cell;

    if ([dashboardItem isKindOfClass:[APHTableViewDashboardGINAItem class]]){
        APHTableViewDashboardGINAItem *ginaItem = (APHTableViewDashboardGINAItem *)dashboardItem;
        APHStatusCollectionViewCell *statusCell = [collectionView dequeueReusableCellWithReuseIdentifier:kAPHStatusCollectionViewCellIdentifier forIndexPath:indexPath];

        switch (indexPath.row) {
            case kAPHGINAStatusRowTypeDaytimeAsthmaSymptoms:
                statusCell.textLabel.text = NSLocalizedString(@"Instances of daytime asthma symptoms more than twice within any given week", @"");
                [self setupStatusCell:statusCell count:ginaItem.daytimeSymptoms status:ginaItem.daytimeSymptomsStatus];
                break;
            case kAPHGINAStatusRowTypeNightWaking:
                statusCell.textLabel.text = NSLocalizedString(@"Instances of night waking due to asthma within period", @"");
                [self setupStatusCell:statusCell count:ginaItem.nightWakingOccurrences status:ginaItem.nightWakingOccurrencesStatus];
                break;
            case kAPHGINAStatusRowTypeRelieverNeeded:
                statusCell.textLabel.text = NSLocalizedString(@"Instances of reliever needed more than twice within any given week", @"");
                [self setupStatusCell:statusCell count:ginaItem.neededReliever status:ginaItem.neededRelieverStatus];
                break;
            case kAPHGINAStatusRowTypeLimitations:
                statusCell.textLabel.text = NSLocalizedString(@"Instances of activity limitation due to asthma", @"");
                [self setupStatusCell:statusCell count:ginaItem.limitationsDays status:ginaItem.limitationsDaysStatus];
                break;
            default:
                break;
        }
        
        return statusCell;
    } else if ([dashboardItem isKindOfClass:[APHTableViewDashboardAsthmaControlItem class]]){
        APHTableViewDashboardAsthmaControlItem *asthmaItem = (APHTableViewDashboardAsthmaControlItem *)dashboardItem;
        APHStatusCollectionViewCell *statusCell = [collectionView dequeueReusableCellWithReuseIdentifier:kAPHStatusCollectionViewCellIdentifier forIndexPath:indexPath];

        switch (indexPath.row) {
            case kAPHAsthmaControlStatusRowTypeMajorEvents:
                statusCell.textLabel.text = NSLocalizedString(@"Major events involving health care utilization", @"");
                [self setupStatusCell:statusCell count:asthmaItem.majorEvents status:asthmaItem.majorEventsStatus];
                break;
            case kAPHAsthmaControlStatusRowTypeAdherence:
                statusCell.textLabel.text = NSLocalizedString(@"% of period where patient adhered to control medication regimen", @"");
                [self setupStatusCell:statusCell count:asthmaItem.medicationAdherencePercent status:asthmaItem.medicationAdherencePercentStatus];
                break;
            case kAPHAsthmaControlStatusRowTypeQuickRelief:
                statusCell.textLabel.text = NSLocalizedString(@"Instances where quick relief inhaler was used", @"");
                [self setupStatusCell:statusCell count:asthmaItem.neededRelieverDays status:asthmaItem.neededRelieverDaysStatus];
                break;
            default:
                break;
        }
        
        return statusCell;
    } else if ([dashboardItem isKindOfClass:[APHTableViewDashboardSurveyCompletionItem class]]){
        APHTableViewDashboardSurveyCompletionItem *asthmaItem = (APHTableViewDashboardSurveyCompletionItem *)dashboardItem;
        APHStatusCollectionViewCell *statusCell = [collectionView dequeueReusableCellWithReuseIdentifier:kAPHStatusCollectionViewCellIdentifier forIndexPath:indexPath];
        NSInteger count = 0;
        
        switch (indexPath.row) {
                
            case kAPHSurveyCompletionRowTypeDailySurveyCompletedPercent:
            {
                count = asthmaItem.dailySurveyCompletedPercent;
                NSString* text  = [NSString stringWithFormat:@"%i%% Daily Surveys Completed", count == -1 ? 0 : (int)count];
                statusCell.textLabel.text = NSLocalizedString(text, @"");
                
                if(count == -1){
                    statusCell.textLabel.textColor  = [UIColor appTertiaryGrayColor];
                } else if (count >= 80) {
                    statusCell.textLabel.textColor = [UIColor appTertiaryGreenColor];
                } else {
                    statusCell.textLabel.textColor = [UIColor appTertiaryRedColor];
                }
                
                [statusCell.countLabel setHidden:YES];
                statusCell.countBackgroundColor = [UIColor clearColor];
            }
                break;
            case kAPHSurveyCompletionRowTypeWeeklySurveyCompletedPercent:
            {
                count = asthmaItem.weeklySurveyCompletedPercent;
                NSString* text  = [NSString stringWithFormat:@"%i%% Weekly Surveys Completed", count == -1 ? 0 : (int)count];
                statusCell.textLabel.text = NSLocalizedString(text, @"");
                
                if(count == -1){
                    statusCell.textLabel.textColor = [UIColor appTertiaryGrayColor];
                } else if (count >= 80) {
                    statusCell.textLabel.textColor = [UIColor appTertiaryGreenColor];
                } else {
                    statusCell.textLabel.textColor = [UIColor appTertiaryRedColor];
                }
                
                [statusCell.countLabel setHidden:YES];
                statusCell.countBackgroundColor = [UIColor clearColor];
            }
                break;
            default:
                break;
        }
        
        return statusCell;
    }
    return cell;
}

#pragma mark  UICollectionViewDelegate Methods

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*) __unused collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)__unused indexPath
{
    return CGSizeMake(CGRectGetWidth(collectionView.frame), kStatusCollectionViewCellHeight);
}

#pragma mark - APCDashboardTableViewCellDelegate methods

//- (void)dashboardTableViewCellDidTapExpand:(APCDashboardTableViewCell *)cell
//{
//    [self dashboardTableViewCellDidTapExpand:cell];
//    
//    if ([cell isKindOfClass:[APCDashboardGraphTableViewCell class]]) {
//        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
//        
//        APCTableViewDashboardGraphItem *graphItem = (APCTableViewDashboardGraphItem *)[self itemForIndexPath:indexPath];
//        if([graphItem.caption isEqualToString:kPeakFlowGraphCaption]){
//            [self updateScoringForOffset:self.peakScore];
//        } else if([graphItem.caption isEqualToString:kStepsTakenGraphCaption]){
//            [self updateScoringForOffset:self.stepScore];
//        }
//
//    }
//}

#pragma mark - IB Actions

- (IBAction)statusSummaryDateRangeValueChanged:(id)sender {
    if ([sender isKindOfClass:[UISegmentedControl class]]) {
        UISegmentedControl *segmentedControl = (UISegmentedControl *)sender;
        
        NSString* offset = nil;
        switch (segmentedControl.selectedSegmentIndex) {
            case 1:
                offset = @"P4W"; // 4-8 weeks ago
                break;
            case 2:
                offset = @"P8W"; // 8-12 weeks ago
                break;
            default:
                offset = nil; // last 4 weeks
        }
        for (id cell in [self.tableView visibleCells]) {
            if ([cell isKindOfClass:[APHDashboardStatusSummaryTableViewCell class]]) {
                APHDashboardStatusSummaryTableViewCell *statusCell = (APHDashboardStatusSummaryTableViewCell *)cell;
                if (statusCell.segmentedControl == segmentedControl) {
                    // We've found the cell for which we got the segmented control update
                    NSIndexPath *indexPath = [self.tableView indexPathForCell:statusCell];
                    APCTableViewDashboardItem *dashboardItem = (APCTableViewDashboardItem *)[self itemForIndexPath:indexPath];
                    if ([dashboardItem isKindOfClass:[APHTableViewDashboardGINAItem class]]) {
                        APHTableViewDashboardGINAItem *statusItem = (APHTableViewDashboardGINAItem *)dashboardItem;
                        statusItem.offset = offset;
                        _stepOffset = offset;
                        [statusItem prepare:self.badgeObject];
                        self.selectedGINAPeriodIndex = segmentedControl.selectedSegmentIndex;
                        [self updateScoringForOffset:self.stepScore offeset:_stepOffset];
                    } else if ([dashboardItem isKindOfClass:[APHTableViewDashboardAsthmaControlItem class]]) {
                        APHTableViewDashboardAsthmaControlItem *statusItem = (APHTableViewDashboardAsthmaControlItem *)dashboardItem;
                        statusItem.offset = offset;
                        _peakOffset = offset;
                        [statusItem prepare:self.badgeObject];
                        self.selectedACPeriodIndex = segmentedControl.selectedSegmentIndex;
                        [self updateScoringForOffset:self.peakScore offeset:_peakOffset];
                    } else if ([dashboardItem isKindOfClass:[APHTableViewDashboardSurveyCompletionItem class]]) {
                        APHTableViewDashboardSurveyCompletionItem *statusItem = (APHTableViewDashboardSurveyCompletionItem *)dashboardItem;
                        statusItem.offset = offset;
                        _surveyOffset = offset;
                        [statusItem prepare:self.badgeObject];
                        self.selectedSCPeriodIndex = segmentedControl.selectedSegmentIndex;
                    }
                }
            }
        }
        [self.tableView reloadData];
        
        [self sendAnalyticsData];
    }
}

- (IBAction) done: (id) __unused sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
