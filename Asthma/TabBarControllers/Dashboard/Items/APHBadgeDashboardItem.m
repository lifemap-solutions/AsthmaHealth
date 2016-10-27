//
//  APHBadgeDashboardItem.m
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

#import "APHBadgeDashboardItem.h"
#import "APHDashboardBadgesTableViewCell.h"
#import "APHMedicationTaskViewController.h"
#import "APHBadgesCollectionViewCell.h"
#import "APHCalendarCollectionViewController.h"
#import "APHCalendarDataModel.h"



NSInteger const kCollectionViewsBaseTag = 101;
CGFloat const kBadgesCollectionViewCellHeight = 54.0f;



@implementation APHBadgeDashboardItem

- (instancetype)init {

    self = [super init];

    if (!self) {
        return nil;
    }

    self.caption = NSLocalizedString(@"DASHBOARD_BADGED_CAPTION", @"");
    self.identifier = kAPHDashboardBadgesTableViewCellIdentifier;
    self.tintColor = [UIColor appTertiaryGreenColor];
    self.editable = YES;

    self.dailyParticipationPercent = self.badgeObject.completionValue;
    self.workAttendancePercent = self.badgeObject.workAttendanceValue;
    self.undisturbedNightsPercent =self.badgeObject.undisturbedNightsValue;
    self.asthmaFreeDaysPercent = self.badgeObject.asthmaFreeDaysValue;
    self.medicationAdherencePercent = self.badgeObject.medicationAdherenceValue;
    self.info = NSLocalizedString(@"DASHBOARD_BADGES_TOOLTIP", @"");

    return self;
}



#pragma mark -

- (APHAsthmaBadgesObject *)badgeObject {
    if (!_badgeObject) {
        _badgeObject = [APHAsthmaBadgesObject new];
    }

    return _badgeObject;
}

- (NSArray *)badgeItems {
    if (!_badgeItems) {
        _badgeItems = [self calculateBadgeItems];
    }

    return _badgeItems;
}

- (NSArray *)calculateBadgeItems {

    NSMutableArray *items = [NSMutableArray new];
    [items addObjectsFromArray:@[
                                @(kAPHBadgesRowTypeDailyParticipation),
                                @(kAPHBadgesRowTypeWorkAttendance),
                                @(kAPHBadgesRowTypeUndisturbedNights),
                                @(kAPHBadgesRowTypeAsthmaFreeDays)
                               ]];

    if (![[self isUserTakingMedication] isEqualToString:@"NO"]) {
        [items addObject:@(kAPHBadgesRowTypeMedicationAdherence)];
    }

    return [items copy];
}


- (NSString*)isUserTakingMedication {

    APCAppDelegate *appDelegate = (APCAppDelegate *)[UIApplication sharedApplication].delegate;

    NSFetchRequest *request = [APCScheduledTask request];
    request.shouldRefreshRefetchedObjects = YES;
    request.predicate = [NSPredicate predicateWithFormat:@"task.taskID contains %@ AND completed == %@", @"AsthmaMedication", @(YES)];;
    request.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"startOn" ascending:YES] ];

    NSError *error = nil;
    NSArray *medicationScheduledTasks = [appDelegate.dataSubstrate.mainContext executeFetchRequest:request error:&error];
    APCScheduledTask *lastMedicationTask = medicationScheduledTasks.lastObject;

    if (lastMedicationTask) {
        NSString *resultSummary = lastMedicationTask.lastResult.resultSummary;
        NSDictionary *dictionary = resultSummary ? [NSDictionary dictionaryWithJSONString:resultSummary] : @{};

        if ([dictionary[kPrescribedControlMedStepIdentifier] isEqualToNumber:@(YES)]) {
            return @"YES";
        } else {
            return @"NO";
        }
    }

    APCLogError2(error);
    return @"NOT_SPECIFIED";
}



#pragma mark -

- (APHCalendarDataModel *)calendarDataModel {
    if (!_calendarDataModel) {
        _calendarDataModel = [APHCalendarDataModel new];
    }

    return _calendarDataModel;
}



#pragma mark - APCConcentricProgressViewDataSource

- (NSUInteger)numberOfComponentsInConcentricProgressView {
    return self.badgeItems.count;
}

- (CGFloat)concentricProgressView:(APCConcentricProgressView *) __unused concentricProgressView valueForComponentAtIndex:(NSUInteger)index {

    NSNumber *badgeItem = [self.badgeItems objectAtIndex:index];

    switch (badgeItem.integerValue) {
        case kAPHBadgesRowTypeDailyParticipation:
            return self.badgeObject.completionValue;

        case kAPHBadgesRowTypeWorkAttendance:
            return self.badgeObject.workAttendanceValue;

        case kAPHBadgesRowTypeUndisturbedNights:
            return self.badgeObject.undisturbedNightsValue;

        case kAPHBadgesRowTypeAsthmaFreeDays:
            return self.badgeObject.asthmaFreeDaysValue;

        case kAPHBadgesRowTypeMedicationAdherence:
            return self.badgeObject.medicationAdherenceValue;
    }

    return 0;
}

- (UIColor *)concentricProgressView:(APCConcentricProgressView *) __unused concentricProgressView colorForComponentAtIndex:(NSUInteger)index {

    NSArray *colors = @[
                        [UIColor appTertiaryBlueColor],
                        [UIColor appTertiaryPurpleColor],
                        [UIColor appTertiaryGreenColor],
                        [UIColor appTertiaryYellowColor],
                        [UIColor appTertiaryBrightRedColor]
                       ];

    return colors[index];
}



#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *) __unused collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *) __unused collectionView numberOfItemsInSection:(NSInteger) __unused section {
    return self.badgeItems.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {

    APHBadgesCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kAPHBadgesCollectionViewCellIdentifier forIndexPath:indexPath];
    NSNumber *badgeItem = [self.badgeItems objectAtIndex:indexPath.row];

    cell.imageView.image = [UIImage imageNamed:@"icon_trophy_empty"];
    cell.tintView.backgroundColor = [UIColor appTertiaryGreenColor];

    CGFloat percent = 0.0;

    switch (badgeItem.integerValue) {

        case kAPHBadgesRowTypeDailyParticipation:
            cell.textLabel.text = NSLocalizedString(@"DASHBOARD_BADGES_SURVEY_COMPLETION", @"");
            percent = self.badgeObject.completionValue;
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%2.0f%%", percent *100];
            cell.detailTextLabel.textColor = [UIColor appTertiaryBlueColor];
            if (percent > 0.60) {
                cell.imageView.image = [UIImage imageNamed:@"icon_trophy_blue"];
            }
            if (percent > 0.85){
                cell.imageView.image = [UIImage imageNamed:@"icon_trophy_blue_crown"];
            }
            break;

        case kAPHBadgesRowTypeWorkAttendance:
            cell.textLabel.text = NSLocalizedString(@"DASHBOARD_BADGES_WORK_ATTENDANCE", @"");
            percent = self.badgeObject.workAttendanceValue;
            if (percent >= 0) {
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%2.0f%%", percent *100];
            }else{
                cell.detailTextLabel.text = @"No Data";
            }

            cell.detailTextLabel.textColor = [UIColor appTertiaryPurpleColor];
            if (percent > 0.60) {
                cell.imageView.image = [UIImage imageNamed:@"icon_trophy_purple"];
            }
            if (percent > 0.85){
                cell.imageView.image = [UIImage imageNamed:@"icon_trophy_purple_crown"];
            }
            break;

        case kAPHBadgesRowTypeUndisturbedNights:
            cell.textLabel.text = NSLocalizedString(@"DASHBOARD_BADGES_UNDISTURBED_NIGHTS", @"");
            percent = self.badgeObject.undisturbedNightsValue;
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%2.0f%%", percent *100];
            cell.detailTextLabel.textColor = [UIColor appTertiaryGreenColor];
            if (percent > 0.60) {
                cell.imageView.image = [UIImage imageNamed:@"icon_trophy_green"];
            }
            if (percent > 0.85){
                cell.imageView.image = [UIImage imageNamed:@"icon_trophy_green_crown"];
            }
            break;

        case kAPHBadgesRowTypeAsthmaFreeDays:
            cell.textLabel.text = NSLocalizedString(@"DASHBOARD_BADGES_UNDISTURBED_DAYS", @"");
            percent = self.badgeObject.asthmaFreeDaysValue;
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%2.0f%%", percent *100];
            cell.detailTextLabel.textColor = [UIColor appTertiaryYellowColor];
            if (percent > 0.60) {
                cell.imageView.image = [UIImage imageNamed:@"icon_trophy_yellow"];
            }
            if (percent > 0.85){
                cell.imageView.image = [UIImage imageNamed:@"icon_trophy_yellow_crown"];
            }
            break;

        case kAPHBadgesRowTypeMedicationAdherence:
            cell.textLabel.text = NSLocalizedString(@"DASHBOARD_BADGES_MEDICINE_ADHERENCE", @"");
            percent = self.badgeObject.medicationAdherenceValue;
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%2.0f%%", percent *100];
            cell.detailTextLabel.textColor = [UIColor appTertiaryBrightRedColor];
            if (percent > 0.60) {
                cell.imageView.image = [UIImage imageNamed:@"icon_trophy_red"];
            }
            if (percent > 0.85){
                cell.imageView.image = [UIImage imageNamed:@"icon_trophy_red_crown"];
            }
            break;
    }

    return cell;
}



#pragma mark  - UICollectionViewDelegate

-(void)collectionView:(UICollectionView *) __unused collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {

    if (![self.delegate respondsToSelector:@selector(badgeDashboardItem:didSelectTaskWithType:)]) {
        return;
    }

    NSNumber *badgeItem = [self.badgeItems objectAtIndex:indexPath.row];
    APHCalendarTaskType type = badgeItem.integerValue;

    [self.delegate badgeDashboardItem:self didSelectTaskWithType:type];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*) __unused collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)__unused indexPath {

    return CGSizeMake(CGRectGetWidth(collectionView.frame), kBadgesCollectionViewCellHeight);
}

@end
