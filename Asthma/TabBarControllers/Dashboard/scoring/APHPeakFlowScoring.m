//
//  APHPeakFlowScoring.m
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

#import "APHPeakFlowScoring.h"



NSString * const APHPeakFlowScoringUpdateNotification = @"APHPeakFlowScoringUpdateNotification";



@interface APHPeakFlowScoring ()
@property (nonatomic, strong) NSDate *startDate;
@property (nonatomic, strong) NSDate *endDate;
@end



@interface APCScoring ()
@property (nonatomic, strong) NSMutableArray *dataPoints;
@property (nonatomic) APHTimelineGroups groupBy;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
- (NSDictionary *)generateDataPointForDate:(NSDate *)pointDate withValue:(NSNumber *)pointValue noDataValue:(BOOL)noDataValue;
- (NSMutableArray *)dataPointsArrayForDays:(NSInteger)days groupBy:(NSUInteger)groupBy;
@end



@implementation APHPeakFlowScoring

+ (instancetype)peakFlowScoring {

    APHPeakFlowScoring *scoring = [[APHPeakFlowScoring alloc] init];

    scoring.caption = NSLocalizedString(@"Peak Flow", @"");

    return scoring;
}


- (instancetype)init {
    self = [super init];

    if (!self) {
        return nil;
    }

    self.customMaximumPoint = CGFLOAT_MAX;
    self.customMinimumPoint = CGFLOAT_MIN;

    self.groupBy = APHTimelineGroupDay;
    _dataPoints = [self dataPointsArrayForDays:-[self numberOfDaysBetweenStartAndEndDate] groupBy:APHTimelineGroupDay];

    [self reload];

    return self;
}




- (void)reload {

    NSFetchRequest *request = [self prepareRequest];
    NSManagedObjectContext *context = [self context];

    [context performBlock:^{
        NSError *error = nil;
        NSArray *tasks = [context executeFetchRequest:request error:&error];

        NSMutableArray *records = [NSMutableArray new];

        for(APCScheduledTask *task in tasks) {

            NSArray *results = [[task.results allObjects] sortedArrayUsingComparator:^NSComparisonResult(APCResult *obj1, APCResult *obj2) {
                return [obj1.createdAt compare:obj2.createdAt];
            }];

            for (APCResult *result in results) {
                NSData *summaryData = [result.resultSummary dataUsingEncoding:NSUTF8StringEncoding];

                NSError *error = nil;
                NSDictionary *summary = [NSJSONSerialization JSONObjectWithData:summaryData options:NSJSONReadingAllowFragments error:&error];

                if (!summary) {
                    continue;
                }

                [records addObject:[self generateDataPointForDate:task.createdAt withValue:summary[kPeakFlowKey] noDataValue:NO]];
            }
        }

        NSSortDescriptor *sortByDateAscending = [NSSortDescriptor sortDescriptorWithKey:kDatasetDateKey ascending:YES];
        NSArray *sortedRecords = [records sortedArrayUsingDescriptors:@[ sortByDateAscending ]];


        NSMutableDictionary *uniqueRecords = [NSMutableDictionary new];

        for(NSDictionary *record in sortedRecords) {
            NSDate *date = [record[kDatasetDateKey] endOfDay];
            uniqueRecords[ date ] = record;
        }

        NSArray *computedRecords = [[uniqueRecords allValues] sortedArrayUsingDescriptors:@[ sortByDateAscending ]];

        dispatch_async(dispatch_get_main_queue(), ^{
            self.dataPoints = [computedRecords mutableCopy];

            [[NSNotificationCenter defaultCenter] postNotificationName:APHPeakFlowScoringUpdateNotification object:self];
        });
    }];
}



#pragma mark - Normalization

@synthesize dataPoints = _dataPoints;

- (void)setDataPoints:(NSMutableArray *)dataPoints {
    _dataPoints = [self normalizeDataPoints:dataPoints];
}

- (NSMutableArray *)normalizeDataPoints:(NSMutableArray *)points {

    NSMutableArray *dataPoints = [self dataPointsArrayForDays:-[self numberOfDaysBetweenStartAndEndDate] groupBy:APHTimelineGroupDay];

    for (NSDictionary *point in points) {
        NSDate *date = [point[kDatasetDateKey] startOfDay];

        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K = %@", kDatasetDateKey, date];
        NSArray *found = [dataPoints filteredArrayUsingPredicate:predicate];

        if (found.count == 0) {
            continue;
        }

        NSUInteger index = [dataPoints indexOfObject:found.firstObject];
        [dataPoints replaceObjectAtIndex:index withObject:point];
    }

    return dataPoints;
}



#pragma mark - Dates

- (NSInteger)numberOfDaysBetweenStartAndEndDate {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:NSCalendarUnitDay fromDate:self.startDate toDate:self.endDate options:NSCalendarWrapComponents];

    return components.day;
}

- (NSDate *)startDate {
    if (!_startDate) {
        _startDate = [[self.endDate dateByAddingDays:-kNumberOfDaysToDisplay] startOfDay];
    }

    return _startDate;
}

- (NSDate *)endDate {
    if (!_endDate) {
        _endDate = [[NSDate date] endOfDay];
    }

    return _endDate;
}

- (NSDate *)dateForSpan:(NSInteger)daySpan {
    return [self.endDate dateByAddingDays:daySpan];
}



#pragma mark -

@synthesize dateFormatter = _dateFormatter;

- (NSDateFormatter *)dateFormatter {
    if (!_dateFormatter) {
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setTimeZone:[NSTimeZone localTimeZone]];
    }

    return _dateFormatter;
}



#pragma mark -

- (NSFetchRequest *)prepareRequest {
    NSFetchRequest *request = [APCScheduledTask request];

    NSSortDescriptor *sortByStartOnAscending = [NSSortDescriptor sortDescriptorWithKey:@"startOn" ascending:YES];

    request.predicate = [NSPredicate predicateWithFormat:@"(task.taskID == %@) AND (startOn >= %@) AND (startOn <= %@) && (completed == YES)", kDailySurveyTaskID, self.startDate, self.endDate];
    request.sortDescriptors = @[ sortByStartOnAscending ];

    return request;
}

- (NSManagedObjectContext *)context {
    APCAppDelegate *delegate = (APCAppDelegate *)[UIApplication sharedApplication].delegate;

    NSManagedObjectContext * context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    context.parentContext = delegate.dataSubstrate.persistentContext;
    
    return context;
}

@end
