//
//  APHAirQualityDashboardItem.m
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

#import "APHAirQualityNearYouDashboardItem.h"
#import "APHDashboardAirQualityTableViewCell.h"
#import "APHAirQualityCollectionViewCell.h"
#import "APHAirQualitySectionHeaderView.h"
#import "APHAirQualityNearYouDataModel.h"
#import "APHAirQualityNearYouResponseEntry.h"
#import "APCDashboardTableViewCell+Overlay.h"


NSString * const _Nonnull APHAQNUDashboardItemDidChangedUpdateNotification = @"APHAQNUDashboardItemDidChangedUpdateNotification";


typedef NS_ENUM(NSUInteger, APHAirQualityRowType) {
    kAPHAirQualityRowTypeOzone          = 0,
    kAPHAirQualityRowTypeSmallParticles = 1,
    kAPHAirQualityRowTypeBigParticles   = 2,
    kAPHAirQualityRowTypeAQI            = 3
};



#define T_AQNU_LOCALIZATION_NOT_PERMITED NSLocalizedString(@"To enable air qualities, turn on location sharing in Settings > Privacy > Location Service > Asthma", nil)
#define T_AQNU_COUNTRY_NOT_SUPPORTED NSLocalizedString(@"Your country is not supported", nil)
#define T_AQNU_TOOLTIP NSLocalizedString(@"The AQI is an index for reporting daily air quality. It tells you how clean or polluted your air is, and what associated health effects might be a concern for you. AQI data provided by U.S. EPA AirNow", nil)



@interface APHAirQualityNearYouDashboardItem () <APHAirQualityNearYouDataModelDelegate>
@property (nonatomic, strong) APHAirQualityNearYouDataModel *dataModel;
@property (nonatomic, readonly) APHAirQualityNearYouResponse* response;
@end



@implementation APHAirQualityNearYouDashboardItem

- (instancetype)init {
    self = [super init];

    if (self) {
        self.dataModel.delegate = self;
        [self refreshOverlayConfig];
    }

    return self;
}


#pragma mark -

- (NSString *)caption {
    return @"Air Quality Near You";
}

- (NSString *)info {
    return T_AQNU_TOOLTIP;
}

- (NSString *)detailText {
    return self.response.locationName ?: @"Unknown";
}

- (NSString *)identifier {
    return [APHDashboardAirQualityTableViewCell identifier];
}

- (void)refreshOverlayConfig {
    if (![self isLocationPermitted]) {
        self.overlayConfig = [[LocationPermissionOverlayConfig alloc] initWithOverlayText:T_AQNU_LOCALIZATION_NOT_PERMITED];
    }
    else {
        self.overlayConfig = nil;
    }
}

- (BOOL)isLocationPermitted {
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];

    return status == kCLAuthorizationStatusAuthorizedAlways
        || status == kCLAuthorizationStatusAuthorizedWhenInUse;
}



#pragma mark - Data Model

- (APHAirQualityNearYouResponse *)response {
    return self.dataModel.response;
}

- (APHAirQualityNearYouDataModel *)dataModel {
    if (!_dataModel) {
        _dataModel = [APHAirQualityNearYouDataModel new];
    }

    return _dataModel;
}

- (void)airQuality:(APHAirQualityNearYouDataModel *)airQuality didChangedResponse:(APHAirQualityNearYouResponse *)response {
#pragma unused(airQuality, response)
    [self refreshOverlayConfig];
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:APHAQNUDashboardItemDidChangedUpdateNotification object:self userInfo:nil];
}



#pragma mark -

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
#pragma unused (collectionView)
    return 1 + (self.response.tomorrowEntry != NULL);
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
#pragma unused (collectionView, section)
    return 4;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    APHAirQualityCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:[APHAirQualityCollectionViewCell identifer] forIndexPath:indexPath];

    APHAirQualityNearYouResponseEntry *entry = indexPath.section == 0 ? self.response.todayEntry : self.response.tomorrowEntry;

    cell.detailTextLabel.text = @"-";

    switch (indexPath.row) {
        case kAPHAirQualityRowTypeOzone:
            cell.textLabel.text = NSLocalizedString(@"Ozone", @"");
            cell.imageView.image = [UIImage imageNamed:@"icon_ozone"];
            cell.detailTextLabel.text = [self formatNumber:entry.ozone];
            break;

        case kAPHAirQualityRowTypeSmallParticles:
            cell.textLabel.attributedText = [self smallPatriclesStringWithFont:cell.textLabel.font];
            cell.imageView.image = [UIImage imageNamed:@"icon_smallParticles"];
            cell.detailTextLabel.text = [self formatNumber:entry.smallParticles];
            break;

        case kAPHAirQualityRowTypeBigParticles:
            cell.textLabel.attributedText = [self bigPatriclesStringWithFont:cell.textLabel.font];
            cell.imageView.image = [UIImage imageNamed:@"icon_bigParticles"];
            cell.detailTextLabel.text = [self formatNumber:entry.bigParticles];
            break;

        case kAPHAirQualityRowTypeAQI:
            cell.textLabel.text = NSLocalizedString(@"Air Quality Index", @"");
            cell.imageView.image = [UIImage imageNamed:@"icon_airQuality"];
            cell.detailTextLabel.text = [self formatNumber:entry.quality];
            break;
    }

    cell.detailTextLabel.textColor = entry.color ?: [UIColor appTertiaryRedColor];

    return cell;
}


- (NSString *)formatNumber:(NSNumber *)number {
    if (!number || number == (NSNumber *)[NSNull null]) {
        return @"N/A";
    }

    return [number stringValue];
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {

    if (![kind isEqualToString:UICollectionElementKindSectionHeader]) {
        return nil;
    }

    APHAirQualitySectionHeaderView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:kAPHAirQualitySectionHeaderViewIdentifier forIndexPath:indexPath];

    if (indexPath.section == 0) {
        headerView.titleLabel.text = @"Today";
    } else {
        headerView.titleLabel.text = @"Tomorrow";
    }

    return headerView;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
#pragma unused (collectionViewLayout, indexPath)
    return CGSizeMake(CGRectGetWidth(collectionView.frame), kAirQualityCollectionViewCellHeight);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
#pragma unused (collectionViewLayout, section)
    return CGSizeMake(CGRectGetWidth(collectionView.frame), kAirQualityCollectionViewHeaderHeight);
}



#pragma mark -

- (NSMutableAttributedString *)smallPatriclesStringWithFont:(UIFont *)font {
    NSMutableAttributedString *subscriptedString = [[NSMutableAttributedString alloc] initWithString:@" 2.5"];
    [subscriptedString addAttribute:NSFontAttributeName
                              value:[UIFont fontWithName:font.fontName size:font.pointSize/1.5]
                              range:NSMakeRange(1, 3)];

    [subscriptedString addAttribute:@"NSBaselineOffset"
                              value:[NSNumber numberWithFloat:-(font.pointSize*1/3)]
                              range:NSMakeRange(1, 3)];

    NSMutableAttributedString * finalString = [[NSMutableAttributedString alloc] initWithString:@"Small Particles PM"];
    [finalString appendAttributedString:subscriptedString];

    return finalString;
}

- (NSMutableAttributedString *)bigPatriclesStringWithFont:(UIFont *)font {
    NSMutableAttributedString *subscriptedString = [[NSMutableAttributedString alloc] initWithString:@" 10"];

    [subscriptedString addAttribute:NSFontAttributeName
                              value:[UIFont fontWithName:font.fontName size:font.pointSize/1.5]
                              range:NSMakeRange(1, 2)];
    [subscriptedString addAttribute:@"NSBaselineOffset"
                              value:[NSNumber numberWithFloat:-(font.pointSize*1/3)]
                              range:NSMakeRange(1, 2)];

    NSMutableAttributedString * finalString = [[NSMutableAttributedString alloc] initWithString:@"Big Particles PM"];
    [finalString appendAttributedString:subscriptedString];

    return finalString;
}

@end
