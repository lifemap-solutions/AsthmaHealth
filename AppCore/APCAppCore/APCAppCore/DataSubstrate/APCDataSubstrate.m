// 
//  APCDataSubstrate.m 
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
 
#import "APCDataSubstrate.h"
#import "APCDataSubstrate+ResearchKit.h"
#import "APCDataSubstrate+CoreData.h"
#import "APCDataSubstrate+HealthKit.h"
#import "APCModel.h"

static NSTimeInterval dateCheckTimeInterval = 60;

@interface APCDataSubstrate ()
@property (strong, nonatomic) NSTimer *dateChangeTestTimer;
@property (strong, nonatomic) NSDate *lastKnownDate;
@property (nonatomic, assign) NSUInteger countOfTotalRequiredTasksForToday;
@property (nonatomic, assign) NSUInteger countOfTotalCompletedTasksForToday;
@end

@implementation APCDataSubstrate

- (instancetype) initWithPersistentStorePath: (NSString*) storePath
                            additionalModels: (NSManagedObjectModel *) mergedModels
                             studyIdentifier: (NSString *) __unused studyIdentifier
{
    self = [super init];

    if (self)
    {
        _dateChangeTestTimer = nil;
        _lastKnownDate = [NSDate date];
        _countOfTotalCompletedTasksForToday = 0;
        _countOfTotalCompletedTasksForToday = 0;

        [self setUpCoreDataStackWithPersistentStorePath:storePath additionalModels:mergedModels];
        [self setUpCurrentUser:self.persistentContext];
        [self setUpHealthKit];
        [self setupParameters];
        [self setupNotifications];
        [self setupNewsFeedManager];
    }
    
    return self;
}

- (void) setUpCurrentUser: (NSManagedObjectContext*) context
{
    if (!_currentUser) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            _currentUser = [[APCUser alloc] initWithContext:context];
        });
    }
}

- (void) setupParameters {
    self.parameters = [[APCParameters alloc] initWithFileName:@"APCParameters.json"];
    [self.parameters setDelegate:self];
}

- (void) setupNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector (appCameToForeground:)
                                                 name: UIApplicationDidFinishLaunchingNotification
                                               object: nil];

    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector (appCameToForeground:)
                                                 name: UIApplicationWillEnterForegroundNotification
                                               object: nil];

    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector (appWentToBackground:)
                                                 name: UIApplicationDidEnterBackgroundNotification
                                               object: nil];
}

- (void)setupNewsFeedManager
{
    _newsFeedManager = [[APCNewsFeedManager alloc] init];
    [self.newsFeedManager performSelectorInBackground:@selector(fetchFeedWithCompletion:) withObject:nil];
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}



// ---------------------------------------------------------
#pragma mark - Properties & Methods meant only for Categories
// ---------------------------------------------------------

- (void) parameters: (APCParameters *) __unused parameters
   didFailWithError: (NSError *) error
{
    NSAssert(error, @"parameters are not loaded");
}



// ---------------------------------------------------------
#pragma mark - Date-Change Test Timer
// ---------------------------------------------------------

- (void) appCameToForeground: (NSNotification *) __unused notification
{
    APCLogDebug (@"Handling date changes (DataSubstrate): The app is back in the foreground. Restarting the date-change timer, and checking immediately for a date change.");

    [self hootAndHollerIfTheDateCrossedMidnight];
    [self startTimer];
}

- (void) appWentToBackground: (NSNotification *) __unused notification
{
    APCLogDebug (@"Handling date changes (DataSubstrate): The app has moved to the background. Cancelling the date-change timer.");

    [self stopTimer];
}

- (void) startTimer
{
    /*
     We can only stop a timer on the thread from which
     we started it.  Since this block of code is
     very small, the main thread is fine.
     */
    [[NSOperationQueue mainQueue] addOperationWithBlock: ^{

        [self stopTimerInternal];

        self.dateChangeTestTimer = [NSTimer scheduledTimerWithTimeInterval: dateCheckTimeInterval
                                                                    target: self
                                                                  selector: @selector (hootAndHollerIfTheDateCrossedMidnight)
                                                                  userInfo: nil
                                                                   repeats: YES];
    }];
}

- (void) stopTimer
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{

        [self stopTimerInternal];

    }];
}

/**
 Intended to be called only from within the above
 -startTimer and -stopTimer methods, above.
 */
- (void) stopTimerInternal
{
    if (self.dateChangeTestTimer != nil)
    {
        [self.dateChangeTestTimer invalidate];
        self.dateChangeTestTimer = nil;
    }
}

- (void) hootAndHollerIfTheDateCrossedMidnight
{
    [[NSOperationQueue mainQueue] addOperationWithBlock: ^{

        NSDate *now = [NSDate date];

        /**
         This calcluation handles the date moving both
         forward and backward, so it handles normal
         calendar-day turnovers as well as debugging
         situations.
         */
        if (! [now isSameDayAsDate: self.lastKnownDate])
        {
            APCLogDebug (@"Handling date changes (DataSubstrate): The date has changed. Sending notification.");

            self.lastKnownDate = now;

            [[NSNotificationCenter defaultCenter] postNotificationName: APCDayChangedNotification
                                                                object: nil];
        }
    }];
}



// ---------------------------------------------------------
#pragma mark - The count of required tasks
// ---------------------------------------------------------

/**
 Called by the Activities screen, or the CoreData method
 called by that screen, whenever appropriate.  Updates the
 two -count properties on this object, so objects that
 need the count can read it without running a CoreData
 query and lots of calendar math.
 */
- (void) updateCountOfTotalRequiredTasksForToday: (NSUInteger) countOfRequiredTasks
                     andTotalCompletedTasksToday: (NSUInteger) countOfCompletedTasks
{
    self.countOfTotalRequiredTasksForToday = countOfRequiredTasks;
    self.countOfTotalCompletedTasksForToday = countOfCompletedTasks;
}


@end
