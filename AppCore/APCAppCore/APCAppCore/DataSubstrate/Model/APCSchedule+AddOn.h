// 
//  APCSchedule+AddOn.h 
//  APCAppCore 
// 
// Copyright (c) 2015, Apple Inc. All rights reserved. 
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
 
#import "APCSchedule.h"
#import "APCScheduleExpression.h"


@class APCTopLevelScheduleEnumerator;
@class APCTask;
@class APCDateRange;



/**
 We enumerate the dates in a schedule differently based on
 this style.
 */
typedef enum : NSUInteger {

    /** The schedule specifies a single occurrence. */
    APCScheduleRecurrenceStyleExactlyOnce,

    /** The schedule recurs according to the rules of 
     a Unix-style cron expression. */
    APCScheduleRecurrenceStyleCronExpression,

    /** The schedule recurs according to a (human-readable)
     ISO8601 time interval, like "every 90 days," and
     an optional list of times in a given day. */
    APCScheduleRecurrenceStyleInterval,

}   APCScheduleRecurrenceStyle;


/**
 Used in the very occasional place we need to know one
 specific value of the scheduleType field outside this
 category.  For the most part, we can get more and
 better information from schedule.recurrenceStyle.
 */
FOUNDATION_EXPORT NSString * const kAPCScheduleTypeValueOneTimeSchedule;



@interface APCSchedule (AddOn)

@property (nonatomic, readonly) APCScheduleExpression * scheduleExpression;

+ (APCSchedule*) cannedScheduleForTaskID: (NSString*) taskID inContext:(NSManagedObjectContext *)context;

@property (readonly) APCScheduleRecurrenceStyle recurrenceStyle;
@property (readonly) NSString *firstTaskTitle;
@property (readonly) NSString *firstTaskId;

/** Quick accessors for the different types of recurrenceStyle.
 Mostly for debugging, so we can test for these easy-to-read
 items in the "Edit Breakpoints" window.  :-) */
@property (readonly) BOOL isOneTimeSchedule;
@property (readonly) BOOL isRecurringCronSchedule;
@property (readonly) BOOL isRecurringIntervalSchedule;

- (APCTopLevelScheduleEnumerator *) enumeratorFromDate: (NSDate *) startDate
                                                toDate: (NSDate *) endDate;

- (APCTopLevelScheduleEnumerator *) enumeratorOverDateRange: (APCDateRange *) dateRange;

- (NSComparisonResult) compareWithSchedule: (APCSchedule *) otherSchedule;

+ (NSComparisonResult) compareSchedule: (APCSchedule *) schedule1
                          withSchedule: (APCSchedule *) schedule2;

+ (NSArray *) sortSchedules: (NSArray *) schedules;

/**
 Embodies our rules for applying a delay to a schedule's start date.  Adds
 self.delay to date.  (Does not check whether date is, in fact, self's startsOn
 date.)  Returns date if self.delay is nil; otherwise, adds self.delay to
 date and rounds to the nearest morning.  For example:
 
 -  Feb 1, 2010, noon + 4 hours (P4H) = Feb 1, 00:00:00 (start of the same day)
 -  Feb 1, 2010, noon + 3 days  (P3D) = Feb 4, 00:00:00 (start of the day, 3 days later)
 
 Please use this method when adding delays to a date, in order to get
 consistent behavior when comparing such dates.

 Uses very similar logic to -computeExpirationDateForScheduledDate:.  If you
 change one of these methods, please be sure to change the other, so the logic
 for handling ISO 8601 dates is consistent.

 This method simply calls the class-level method of the same name.
 */
- (NSDate *) computeDelayedStartDateFromDate: (NSDate *) date;

/**
 Embodies our rules for applying a delay to a schedule's start date.  Adds
 the delay, an ISO 8601 duration, to date.  Returns date if delay is nil.
 Otherwise, adds delay to date and rounds to the nearest morning.  For example:

 -  Feb 1, 2010, noon + 4 hours (P4H) = Feb 1, 00:00:00 (start of the same day)
 -  Feb 1, 2010, noon + 3 days  (P3D) = Feb 4, 00:00:00 (start of the day, 3 days later)

 Please use this method when adding delays to a date, in order to get
 consistent behavior when comparing such dates.

 Uses very similar logic to +computeExpirationDateForScheduledDate:.  If you
 change one of these methods, please be sure to change the other, so the logic
 for handling ISO 8601 dates is consistent.

 This method is called by the instance method of the same name.
 */
+ (NSDate *) computeDelayedStartDateFromDate: (NSDate *) date
                      usingISO860DelayPeriod: (NSString *) delay;

/**
 Embodies our rules for "expiration periods" ("grace periods").

 Adds self.expires to date.  (Does not check whether date would normally be
 emitted by this Schedule.)  Returns nil if self.expires is nil:  from
 the perspective of self.expires, tasks don't end.  This is NOT necessarily
 the last date something will appear:  it might also go away when the next
 scheduled item appears.

 Example:
 -  Feb 1, 2010 + 4 hours (P4H) = Feb 1, 2010, 23:59:59 (end of the same day)
 -  Feb 1, 2010 + 3 days  (P3D) = Feb 3, 2010, 23:59:59 (end of Feb 3, 3 full days later)

 Please use this method when adding expiration-time intervals to a date, in
 order to get consistent behavior when comparing such dates.

 Uses very similar logic to -computeDelayedStartDateFromDate:.  If you change
 one of these methods, please be sure to change the other, so the logic for
 handling ISO 8601 dates is consistent.

 This method simply calls the class-level method of the same name.
 */
- (NSDate *) computeExpirationDateForScheduledDate: (NSDate *) date;

/**
 Embodies our rules for "expiration periods" ("grace periods").

 Adds self.expires to date.  (Does not check whether date would normally be
 emitted by this Schedule.)  Returns nil if self.expires is nil:  from
 the perspective of self.expires, tasks don't end.  (This is NOT necessarily
 the last date something will appear:  it might also go away when the next
 scheduled item appears.)

 The rules are designed to give us this effect:
 -  Feb 1, 2010 + 4 hours (P4H)  = Feb 1, 2010, 23:59:59 (end of the same day)
 -  Feb 1, 2010 + 3 days  (P3D)  = Feb 3, 2010, 23:59:59 (end of Feb 3, 3 full days later)

 Please use this method when adding expiration-time intervals (self.expires) to
 various dates, in order to get consistent behavior when comparing such dates.

 Uses very similar logic to +computeDelayedStartDateFromDate:.  If you change
 one of these methods, please be sure to change the other, so the logic for
 handling ISO 8601 dates is consistent.

 This method is called by the instance method of the same name.
 */
+ (NSDate *) computeExpirationDateForScheduledDate: (NSDate *) date
                       usingISO860ExpirationPeriod: (NSString *) expirationPeriod;

/**
 Extracts and returns the set of non-nil taskIDs from my tasks.
 The resulting set may be empty, but will never be nil.
 */
@property (readonly) NSSet *taskIds;

@end













