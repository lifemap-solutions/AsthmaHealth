//
//  APCActivitiesViewController.m 
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
 
#import "APCActivitiesViewController.h"
#import "APCAppCore.h"
#import "APCCircularProgressView.h"
#import "UIColor+APCAppearance.h"
#import "APCConstants.h"
#import "APCTaskGroup.h"
#import "APCActivitiesViewSection.h"
#import "APCUtilities.h"


static CGFloat kTintedCellHeight = 65;
static CGFloat kTableViewSectionHeaderHeight = 77;
static NSString * const kAPCSampleGlucoseLogTaskAndScheduleFileName = @"APHSampleGlucoseLogTaskAndSchedule.json";
static NSString * const kAPCListOfTimesMarker                       = @"LIST_OF_TIMES";
static NSString * const kAPCListOfWeekdaysMarker                    = @"LIST_OF_WEEKDAYS";
static NSString * const kAPCScheduleStringKey                       = @"scheduleString";
static NSString * const kReconsentTaskID                            = @"APHReconsentTaskViewController-27829fa5-d731-4372-ba30-a5859f655297";
NSDate* pageStart;

typedef NS_ENUM(NSUInteger, APCActivitiesSections)
{
    APCActivitiesSectionToday = 0,
    APCActivitiesSectionYesterday,
    APCActivitiesSectionsTotalNumberOfSections
};

//    static NSDateFormatter *debugDateLabelDateFormatter = nil;


@interface APCActivitiesViewController ()

@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, weak)   IBOutlet UILabel *noTasksLabel;

@property (readonly) APCAppDelegate *appDelegate;
@property (readonly) APCActivitiesViewSection *todaySection;
@property (readonly) NSUInteger countOfRequiredTasksToday;
@property (readonly) NSUInteger countOfCompletedTasksToday;
@property (readonly) NSUInteger countOfRemainingTasksToday;
@property (readonly) UITabBarItem *myTabBarItem;

@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) NSDate *lastKnownSystemDate;                  // to check for a change when we reappear
@property (nonatomic, strong) NSArray *sections;
@property (nonatomic, assign) BOOL isFetchingFromCoreDataRightNow;
@property (nonatomic, strong) UIRefreshControl *refreshControl;

@property (readonly) NSDate *dateWeAreUsingForToday;

@end


@implementation APCActivitiesViewController


#pragma mark - Lifecycle

- (void) viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.title = NSLocalizedString(@"Activities", @"Activities");

    self.tableView.backgroundColor = [UIColor appSecondaryColor4];

    NSString *headerViewNibName = NSStringFromClass ([APCActivitiesSectionHeaderView class]);

    UINib *nib = [UINib nibWithNibName: headerViewNibName
                                bundle: [NSBundle appleCoreBundle]];

    [self.tableView registerNib: nib forHeaderFooterViewReuseIdentifier: headerViewNibName];
    self.dateFormatter = [NSDateFormatter new];
    [self configureRefreshControl];

    // Set this to nil to trigger a refresh at the first
    // opportunity.
    self.lastKnownSystemDate = nil;
}

- (void) viewWillAppear: (BOOL) animated
{
    [super viewWillAppear: animated];

    [self setupNotifications];
    [self setUpNavigationBarAppearance];

    
    [self reloadTasksFromCoreData];
    [self checkForAndMaybeRespondToSystemDateChange];

    APCLogViewControllerAppeared();
}

- (void) viewDidDisappear: (BOOL) animated
{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    //Log Analytics event
    NSDate *now = [NSDate date];
    NSTimeInterval secondsBetween = [now timeIntervalSinceDate:pageStart];
    
    APCLogEventWithData(kAnalyticsPageEnded, (@{@"pageName" : NSStringFromClass(self.class), @"duration" : [NSString stringWithFormat:@"%d", (int)secondsBetween]}));

    [self cancelNotifications];
}

-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    //Log Analytics event
    pageStart = [NSDate date];
    APCAppDelegate * appDelegate = (APCAppDelegate*)[UIApplication sharedApplication].delegate;
    APCLogEventWithData(kAnalyticsPageStarted, (@{@"pageName" : NSStringFromClass(self.class),
                                           @"time" : [appDelegate getStringFromDate:pageStart]}));
}

- (void) setupNotifications
{
    // Fires when one day rolls over to the next.
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector (checkForAndMaybeRespondToSystemDateChange)
                                                 name: APCDayChangedNotification
                                               object: nil];

    // ...but that only happens every minute or so.  This lets us respond much faster.
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector (checkForAndMaybeRespondToSystemDateChange)
                                                 name: UIApplicationWillEnterForegroundNotification
                                               object: nil];

    // ...but that only happens every minute or so.  This lets us respond much faster.
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector (checkForAndMaybeRespondToSystemDateChange)
                                                 name: UIApplicationDidBecomeActiveNotification
                                               object: nil];
    
    // Fires when schedules have been changed programmatically
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector (reloadTasksFromCoreData)
                                                 name: APCActivitiesChanged
                                               object: nil];
}

- (void) cancelNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

/**
 Sets up the pull-to-refresh control at the top of the TableView.
 If/when we go back to being a subclass of UITableViewController,
 we can remove this.
 */
- (void) configureRefreshControl
{
    self.refreshControl = [UIRefreshControl new];

    [self.refreshControl addTarget: self
                            action: @selector (fetchNewestSurveysAndTasksFromServer:)
                  forControlEvents: UIControlEventValueChanged];

    [self.tableView addSubview: self.refreshControl];
}

- (void) setUpNavigationBarAppearance
{
    [self.navigationController.navigationBar setBarTintColor: [UIColor whiteColor]];

    self.navigationController.navigationBar.translucent = NO;
}



// ---------------------------------------------------------
#pragma mark - Responding to changes in system state
// ---------------------------------------------------------

- (void) checkForAndMaybeRespondToSystemDateChange
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{

        NSDate *now = self.dateWeAreUsingForToday;

        if (self.lastKnownSystemDate == nil || ! [now isSameDayAsDate: self.lastKnownSystemDate])
        {
            APCLogDebug (@"Handling date changes (Activities): Last-known date has changed. Resetting dates, refreshing server content, and refreshing UI.");

            self.lastKnownSystemDate = now;

            // First, get the current stuff from CoreData.
            // Then we'll also check with the server.
            [self reloadTasksFromCoreData];

//            // When we get a date change:  make sure our internal
//            // date-range stuff reflects this.  This is a debugging
//            // feature, so simply clearing it is good enough for now:
//            [self resetDateRangeToTodayAndTomorrow];

            // And now go grab the newest copy of data from the world.
            [self fetchNewestSurveysAndTasksFromServer: nil];
        }
    }];
}



// ---------------------------------------------------------
#pragma mark - Displaying the table cells
// ---------------------------------------------------------

- (NSInteger) numberOfSectionsInTableView: (UITableView *) __unused tableView
{
    return self.sections.count;
}

- (NSInteger) tableView: (UITableView *) __unused tableView
  numberOfRowsInSection: (NSInteger) sectionNumber
{
    APCActivitiesViewSection *section = [self sectionForSectionNumber: sectionNumber];
    NSInteger count = section.taskGroups.count;
    return count;
}

- (UITableViewCell *) tableView: (UITableView *) tableView
          cellForRowAtIndexPath: (NSIndexPath *) indexPath
{
    APCActivitiesViewSection *section = [self sectionForCellAtIndexPath: indexPath];
    APCTaskGroup *taskGroupForThisRow = [self taskGroupForCellAtIndexPath: indexPath];
    APCActivitiesTintedTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: kAPCActivitiesTintedTableViewCellIdentifier];

    [cell configureWithTaskGroup: taskGroupForThisRow
                     isTodayCell: section.isTodaySection
               showDebuggingInfo: NO        // self.debugShowExtraCellInfo
     ];

    return cell;
}

- (CGFloat)       tableView: (UITableView *) __unused tableView
    heightForRowAtIndexPath: (NSIndexPath *) __unused indexPath
{
    return  kTintedCellHeight;
}

- (CGFloat)        tableView: (UITableView *) __unused tableView
    heightForHeaderInSection: (NSInteger) __unused section
{
    return kTableViewSectionHeaderHeight;
}

- (UIView *)     tableView: (UITableView *) tableView
    viewForHeaderInSection: (NSInteger) sectionNumber
{
    NSString *headerViewIdentifier = NSStringFromClass ([APCActivitiesSectionHeaderView class]);
    APCActivitiesSectionHeaderView *headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier: headerViewIdentifier];
    APCActivitiesViewSection *section = [self sectionForSectionNumber: sectionNumber];

    headerView.titleLabel.text = section.title;
    headerView.subTitleLabel.text = section.subtitle;
    
    return headerView;
}

- (BOOL)                tableView: (UITableView *) __unused tableView
    shouldHighlightRowAtIndexPath: (NSIndexPath *) indexPath
{
    return [self allowSelectionAtIndexPath: indexPath];
}

- (BOOL) allowSelectionAtIndexPath: (NSIndexPath *) indexPath
{
    APCActivitiesViewSection *section = [self sectionForCellAtIndexPath: indexPath];
    BOOL allowSelection = section.isTodaySection || section.isKeepGoingSection;
    return allowSelection;
}



// ---------------------------------------------------------
#pragma mark - Handling taps in the table
// ---------------------------------------------------------

- (void)          tableView: (UITableView *) tableView
    didSelectRowAtIndexPath: (NSIndexPath *) indexPath
{
    [tableView deselectRowAtIndexPath: indexPath
                             animated: YES];

    if ([self allowSelectionAtIndexPath: indexPath])
    {
        APCBaseTaskViewController *viewControllerToShowNext = [self viewControllerToShowForCellAtIndexPath: indexPath];

        if (viewControllerToShowNext != nil)
        {
            [self presentViewController: viewControllerToShowNext
                               animated: YES
                             completion: nil];
        }
    }
}



// ---------------------------------------------------------
#pragma mark - The *real* data-source methods
// ---------------------------------------------------------

/*
 The methods in this section describe the *concepts* being
 represented by cells and rows in the TableView which is
 the main point of this screen.  Many methods in this file
 use these methods, not just -cellForRowAtIndexPath:.
 */

- (APCBaseTaskViewController *) viewControllerToShowForCellAtIndexPath: (NSIndexPath *) indexPath
{
    APCBaseTaskViewController *viewController   = nil;
    APCTaskGroup *taskGroup                     = [self taskGroupForCellAtIndexPath: indexPath];
    APCTask *task                               = taskGroup.task;
    NSString *viewControllerClassName           = task.taskClassName;

    // This call is safe, because it returns nil if such a class doesn't exist:
    Class viewControllerClass = NSClassFromString (viewControllerClassName);

    if (viewControllerClass != nil &&
        viewControllerClass != [NSNull class] &&
        [viewControllerClass isSubclassOfClass: [APCBaseTaskViewController class]])
    {
        viewController = [viewControllerClass configureTaskViewController:taskGroup];
    }

    return viewController;
}

- (APCActivitiesViewSection *) todaySection
{
    APCActivitiesViewSection *foundSection = nil;

    for (APCActivitiesViewSection *section in self.sections)
    {
        if (section.isTodaySection)
        {
            foundSection = section;
            break;
        }
    }

    return foundSection;
}

- (APCActivitiesViewSection *) sectionForCellAtIndexPath: (NSIndexPath *) indexPath
{
    return [self sectionForSectionNumber: indexPath.section];
}

- (APCActivitiesViewSection *) sectionForSectionNumber: (NSUInteger) sectionNumber
{
    APCActivitiesViewSection *section = nil;

    if (self.sections.count > sectionNumber)
    {
        section = self.sections [sectionNumber];
    }

    return section;
}

- (APCTaskGroup *) taskGroupForCellAtIndexPath: (NSIndexPath *) indexPath
{
    APCTaskGroup *taskGroup             = nil;
    NSUInteger indexOfTaskGroupWeWant   = indexPath.row;
    NSUInteger indexOfSectionWeWant     = indexPath.section;
    APCActivitiesViewSection *section   = [self sectionForSectionNumber: indexOfSectionWeWant];

    if (section.taskGroups.count > indexOfTaskGroupWeWant)
    {
        taskGroup = section.taskGroups [indexOfTaskGroupWeWant];
    }

    return taskGroup;
}

- (NSUInteger) countOfRequiredTasksToday
{
    NSUInteger result = 0;
    APCActivitiesViewSection *section = self.todaySection;

    for (APCTaskGroup *group in section.taskGroups)
    {
        result += group.totalRequiredTasksForThisTimeRange;
    }

    return result;
}

- (NSUInteger) countOfCompletedTasksToday
{
    NSUInteger result = 0;
    APCActivitiesViewSection *section = self.todaySection;

    for (APCTaskGroup *group in section.taskGroups)
    {
        result += group.requiredCompletedTasks.count;
    }

    return result;
}

- (NSUInteger) countOfRemainingTasksToday
{
    NSUInteger result = 0;
    APCActivitiesViewSection *section = self.todaySection;

    for (APCTaskGroup *group in section.taskGroups)
    {
        result += group.requiredRemainingTasks.count;
    }

    return result;
}



// ---------------------------------------------------------
#pragma mark - Outbound messages
// ---------------------------------------------------------

/*
 This view does a query that other people need.
 One thing they need is the number of required and
 completed tasks for "today."  Update them.
 */
- (void) reportNewTaskTotals
{
    NSUInteger requiredTasks = self.countOfRequiredTasksToday;
    NSUInteger completedTasks = self.countOfCompletedTasksToday;

    [self.appDelegate.dataSubstrate updateCountOfTotalRequiredTasksForToday: requiredTasks
                                                andTotalCompletedTasksToday: completedTasks];
}



// ---------------------------------------------------------
#pragma mark - Reloading data from Sage
// ---------------------------------------------------------

/**
 The method called by this method sends a notification 
 which has us update the screen.
 */
- (void) fetchNewestSurveysAndTasksFromServer: (id) __unused sender
{
    if(!self.appDelegate.dataSubstrate.currentUser.isConsented) //Don't load any tasks if consent has expired
    {
        NSLog(@"fetchNewestSurveysAndTasksFromServer - User is not consented");
        return;
    }
    
    __weak APCActivitiesViewController * weakSelf = self;

    [self.appDelegate.dataMonitor refreshFromBridgeOnCompletion: ^(NSError *error) {

//        [weakSelf.refreshControl endRefreshing];

        if (error != nil)
        {
            // TODO:  handle this error alert more intelligently.
            UIAlertController * alert = [UIAlertController simpleAlertWithTitle: @"Error"
                                                                        message: error.localizedDescription];

            [weakSelf presentViewController: alert
                                   animated: YES
                                 completion: NULL];
        }

        [weakSelf reloadTasksFromCoreData];
    }];
}



// ---------------------------------------------------------
#pragma mark - Repainting the UI
// ---------------------------------------------------------

/**
 This is just the "reload the UI" bit.  It gets called when the view loads
 (or will soon) and after each server load.  It does NOT do a server call
 itself (or, by the time I'm done with it, a database call).
 */
- (void) updateWholeUI
{
    [self.refreshControl endRefreshing];
    [self performSelector:@selector(dismiss) withObject:self afterDelay:0.5];
    [self configureNoTasksView];
    [self updateBadge];
    
    [self.tableView reloadData];
    
}

- (void)dismiss
{
    UIViewController *presentedViewController = self.presentedViewController;
    
    if ([presentedViewController isKindOfClass:[APCSpinnerViewController class]]) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void) updateBadge
{
    NSString *badgeValue = nil;
    NSUInteger remainingTasks = self.countOfRemainingTasksToday;

    if (remainingTasks > 0)
    {
        badgeValue = @(remainingTasks).stringValue;
    }

    self.myTabBarItem.badgeValue = badgeValue;
}



// ---------------------------------------------------------
#pragma mark - The "no tasks at this time" view.
// ---------------------------------------------------------

- (void) configureNoTasksView
{
    //only add the noTasksView if there are no activities to show
    if (self.sections.count == 0 && ! self.isFetchingFromCoreDataRightNow) {
        [self.view bringSubviewToFront:self.noTasksLabel];
        [self.noTasksLabel setHidden:NO];
    }else{
        [self.noTasksLabel setHidden:YES];
    }
    
}

// ---------------------------------------------------------
#pragma mark - Fetching current tasks from CoreData (NOT from server)
// ---------------------------------------------------------

- (void) reloadTasksFromCoreData
{
    __weak typeof(self) weakSelf = self;
    
    if(!self.appDelegate.dataSubstrate.currentUser.isConsented) //Don't load any tasks if consent has expired
    {
        NSLog(@"reloadTasksFromCoreData - User is not consented");
        [weakSelf updateWholeUI];
        return;
    }

    self.isFetchingFromCoreDataRightNow = YES;
    APCSpinnerViewController *spinnerController = [[APCSpinnerViewController alloc] init];
    [self presentViewController:spinnerController animated:YES completion:nil];

    NSPredicate *filterForOptionalTasks = [NSPredicate predicateWithFormat: @"%K == %@",
                                           NSStringFromSelector(@selector(taskIsOptional)),
                                           @(YES)];

    NSPredicate *filterForRequiredTasks = [NSPredicate predicateWithFormat: @"%K != %@ && %K == nil || %K == %@",
                                           NSStringFromSelector(@selector(taskID)),
                                           kReconsentTaskID,
                                           NSStringFromSelector(@selector(taskIsOptional)),
                                           NSStringFromSelector(@selector(taskIsOptional)),
                                            @(NO)];

    NSDate *today = self.dateWeAreUsingForToday;
    NSDate *yesterday = today.dayBefore;
    NSDate *midnightThisMorning = today.startOfDay;
    BOOL sortNewestToOldest = YES;
    
    [[APCScheduler defaultScheduler] fetchTaskGroupsFromDate: yesterday
                                                      toDate: today
                                      forTasksMatchingFilter: filterForRequiredTasks
                                                  usingQueue: [NSOperationQueue mainQueue]
                                             toReportResults: ^(NSDictionary *taskGroups, NSError * __unused queryError)
     {
         
         APCActivitiesViewSection *todaySection = nil;
         NSUInteger indexOfTodaySection = NSNotFound;

         NSMutableArray *sections = [NSMutableArray new];

         NSArray *sortedDates = [taskGroups.allKeys sortedArrayUsingComparator: ^NSComparisonResult (NSDate *date1, NSDate *date2) {

             NSComparisonResult result = (sortNewestToOldest ?
                                          [date2 compare: date1] :
                                          [date1 compare: date2] );
             return result;
         }];

         for (NSUInteger dateIndex = 0; dateIndex < sortedDates.count; dateIndex ++)
         {
             NSDate *date = sortedDates [dateIndex];
             NSArray *taskGroupsForThisDate = taskGroups [date];
             APCActivitiesViewSection *section = [[APCActivitiesViewSection alloc] initWithDate: date
                                                                                          tasks: taskGroupsForThisDate
                                                                         usingDateForSystemDate: today];
             
             if (section.isTodaySection)
             {
                 todaySection = section;
             }
             else if (section.isYesterdaySection)
             {
                 [section reduceToIncompleteTasksOnTheirLastLegalDay];
             }
             
             if (section.taskGroups.count)
             {
                 [sections addObject: section];
             }

             if ([date isEqualToDate: midnightThisMorning])
             {
                 indexOfTodaySection = dateIndex;
             }
         }

         /*
          Now that we've gotten all tasks for all the dates we care about,
          get the "optional" tasks for "today" (or the date we formally
          believe is "today"), and insert them between "today" and
          "yesterday" (if available, or at the bottom of the list of
          sections, if not).
          */
         [[APCScheduler defaultScheduler] fetchTaskGroupsFromDate: today
                                                           toDate: today
                                           forTasksMatchingFilter: filterForOptionalTasks
                                                       usingQueue: [NSOperationQueue mainQueue]
                                                  toReportResults: ^(NSDictionary *taskGroups, NSError * __unused queryError)
         {
             /*
              There should be exactly one date in the list
              of groups, and thus one list of values.
              */
             NSArray *optionalTaskGroups = taskGroups.allValues.firstObject;

             if (optionalTaskGroups.count)
             {
                 APCActivitiesViewSection *section = [[APCActivitiesViewSection alloc] initAsKeepGoingSectionWithTasks: optionalTaskGroups];

                 if (indexOfTodaySection == NSNotFound)
                 {
                     [sections addObject: section];
                 }
                 else
                 {
                     [sections insertObject: section atIndex: indexOfTodaySection + 1];
                 }
             }


             //
             // Regardless of whether we got any optional
             // groups, show everything, now.
             //
             weakSelf.sections = sections;


             //
             // Regenerate reminders for all these things.
             //
             NSArray *taskGroupsForToday = todaySection.taskGroups;
             [weakSelf.appDelegate.tasksReminder handleActivitiesUpdateWithTodaysTaskGroups: taskGroupsForToday];


             //
             // Update central data points, so other screens
             // can draw their graphics and whatnot.
             //
             [weakSelf reportNewTaskTotals];
             
             //we always fetch optional tasks. When this second fetch is complete, updateWholeUI
             weakSelf.isFetchingFromCoreDataRightNow = NO;
             [weakSelf updateWholeUI];

         }];  // second fetch:  optional tasks
     }];  // first fetch:  required tasks, for a range of dates
}  // method reloadFromCoreData



// ---------------------------------------------------------
#pragma mark - Utilities
// ---------------------------------------------------------

- (APCAppDelegate *) appDelegate
{
    return [APCAppDelegate sharedAppDelegate];
}

- (NSDate *) dateWeAreUsingForToday
{
    return [NSDate date];
}

- (UITabBarItem *) myTabBarItem
{
    UITabBarItem *activitiesTab = nil;
    UITabBar *tabBar = self.appDelegate.tabBarController.tabBar;

    for (UITabBarItem *item in tabBar.items)
    {
        if (item.tag == (NSInteger) kAPCActivitiesTabIndex)
        {
            activitiesTab = item;
            break;
        }
    }

    return activitiesTab;
}

@end
