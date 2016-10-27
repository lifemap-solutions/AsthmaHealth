// 
//  APHAppDelegate.m 
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
 
@import APCAppCore;
#import "APHAppDelegate.h"
#import "APHConsentTaskViewController.h"
#import "APHBooleanQuestionStep.h"
#import "APHConsentTask.h"
#import "APHConstants.h"
#import <AWSCore/AWSCore.h>
#import "HealthKitUtils.h"
#import "APHReconsentTaskViewController.h"
#import "APHMedicationTaskViewController.h"
#import "APHCountryBasedConfig.h"
#import "APHLocationManager.h"
#import "APHScheduler.h"
#import "APHVersionUpdate.h"
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>
#import "APHConsentUpdate.h"
#import "APHAppInformation.h"
#import "APHTwentyThreeAndMeClient.h"
#import "APHConsent.h"
#import "APHDataSubstrate.h"
#import "HKWorkout+Metadata.h"



/*********************************************************************************/
#pragma mark - Initializations Options
/*********************************************************************************/
static NSString *const kStudyIdentifier                 = @"Asthma";
static NSString *const kAppPrefix                       = @"asthma";
static NSString *const kVideoShownKey                   = @"VideoShown";
static NSString *const kJsonSchedulesKey                = @"schedules";
static NSString *const kJsonScheduleStringKey           = @"scheduleString";
static NSString *const kJsonScheduleTaskIDKey           = @"taskID";
static NSString *const kJsonTasksKey                    = @"tasks";
static NSString *const kConsentPropertiesFileName       = @"APHConsentSection";
static NSString *const kPreviousVersionKey              = @"previousVersion";
/*********************************************************************************/
#pragma mark - Research Kit Controls Customisation
/*********************************************************************************/

@interface APHAppDelegate ( )

@property  (nonatomic, strong)  NSArray  *rkControlCusomisations;
@property  (nonatomic, strong)  ORKConsentDocument *consentDocument;
@property  (nonatomic, strong)  HKHealthStore *healthStore;
@property  (nonatomic, assign)  NSInteger environment;

@end



@interface APCAppDelegate (ShowPrivate)

- (BOOL) determineIfPeresistentStoreExists;
- (void) initializeAppleCoreStack;

@end

@implementation APHAppDelegate


BOOL didShowReconsent = NO;

/*********************************************************************************/
#pragma mark - App Specific Code
/*********************************************************************************/

- (BOOL)application:(UIApplication*) __unused application willFinishLaunchingWithOptions:(NSDictionary*) __unused launchOptions
{
    APHAppInformation *appInformation = [APHAppInformation new];
    [appInformation determineInstallationVersion];
    
    [super application:application willFinishLaunchingWithOptions:launchOptions];
    
    [self countryConfigReloaded:nil];
    
    NSArray* dataTypesWithReadPermission = self.initializationOptions[kHKReadPermissionsKey];
    
    if (dataTypesWithReadPermission)
    {
        for (id dataType in dataTypesWithReadPermission)
        {
            HKObjectType*   sampleType  = nil;
            
            if ([dataType isKindOfClass:[NSDictionary class]])
            {
                NSDictionary* categoryType = (NSDictionary*) dataType;
                
                //Distinguish
                if (categoryType[kHKWorkoutTypeKey])
                {
                    sampleType = [HKObjectType workoutType];
                }
                else if (categoryType[kHKCategoryTypeKey])
                {
                    sampleType = [HKObjectType categoryTypeForIdentifier:categoryType[kHKCategoryTypeKey]];
                }
            }
            else
            {
                sampleType = [HKObjectType quantityTypeForIdentifier:dataType];
            }
            
            if (sampleType)
            {
                [self.dataSubstrate.healthStore enableBackgroundDeliveryForType:sampleType
                                                                      frequency:HKUpdateFrequencyHourly
                                                                 withCompletion:^(BOOL success, NSError *error)
                 {
                     if (!success)
                     {
                         if (error)
                         {
                             APCLogError2(error);
                         }
                     }
                     else
                     {
                         APCLogDebug(@"Enabling background delivery for healthkit");
                     }
                 }];
            }
        }
    }
    [self uploadAwsClientId];
    
    return YES;
}


- (void) initializeAppleCoreStack
{
    //Check if persistent store (db.sqlite file) exists
    self.persistentStoreExistence = [self determineIfPeresistentStoreExists];

    self.dataSubstrate = [[APCDataSubstrate alloc] initWithPersistentStorePath:[[self applicationDocumentsDirectory] stringByAppendingPathComponent:self.initializationOptions[kDatabaseNameKey]] additionalModels: nil studyIdentifier:self.initializationOptions[kStudyIdentifierKey]];

    [self performMigrationAfterDataSubstrateFrom:[self obtainPreviousVersion] currentVersion:kTheEntireDataModelOfTheApp];

    self.scheduler = [[APCScheduler alloc] initWithDataSubstrate:self.dataSubstrate];
    self.dataMonitor = [[APCDataMonitor alloc] initWithDataSubstrate:self.dataSubstrate scheduler:self.scheduler];

    //Setup AuthDelegate for SageSDK
    SBBAuthManager * manager = (SBBAuthManager*) SBBComponent(SBBAuthManager);
    manager.authDelegate = self.dataSubstrate.currentUser;


    self.scheduler = [[APHScheduler alloc] initWithDataSubstrate:self.dataSubstrate];
    
    self.countryConfig = [[APHCountryBasedConfig alloc] initWithUser:self.dataSubstrate.currentUser];
}

- (BOOL)application:(UIApplication *) __unused application didFinishLaunchingWithOptions:(NSDictionary *) launchOptions
{
    [Fabric with:@[[Crashlytics class]]];

    //Check if app was launched via notification, ie. user taps notification and app is launched
    UILocalNotification* notification = (UILocalNotification*)[launchOptions valueForKey:UIApplicationDidFinishLaunchingNotification];

    if(notification)
    {
        [self.analytics logMessage:(@{kAnalyticsEventKey: kAnalyticsNotificationActivatedEvent, @"Message" : notification.alertBody,
                                      @"Date" : [self getStringFromDate:[NSDate date]],
                                      @"CalledFrom" : @"didFinishLaunchingWithOptions"})];
    }
    
    //Log notification data
    NSMutableDictionary* data = [[NSMutableDictionary alloc] initWithDictionary:@{kAnalyticsEventKey : kAnalyticsCurrentNotificationData,
                                                                                  @"Date" : [self getStringFromDate:[NSDate date]]}];
    
    NSArray* notifications = [self.tasksReminder existingLocalNotifications];
    
    [data setObject:[NSString stringWithFormat:@"%lu",(unsigned long)notifications.count] forKey:@"Count"];
    
    NSMutableString* notificationsData = [NSMutableString new];
    [notificationsData appendString:@"{"];
    for (UILocalNotification *notification in notifications) {
        //Calculate the reminderOffset to determine when next notification will fire
        NSTimeInterval reminderOffset = ([[APCTasksReminderManager reminderTimesArray] indexOfObject:self.tasksReminder.reminderTime]) * 60 * 60;
        
        NSDate* nextFireDate = [notification.fireDate dateByAddingTimeInterval:reminderOffset];
        
        BOOL isPastDue =  [nextFireDate isEarlierThanDate:[NSDate date]];
        
        NSString* json = [NSString stringWithFormat:@"{\"alertBody\":\"%@\",\"fireDate\":\"%@\",\"nextFireDate\":\"%@\",\"isPastDue\":\"%i\"},", notification.alertBody, [self getStringFromDate:notification.fireDate], [self getStringFromDate:nextFireDate], isPastDue];
        
        [notificationsData appendString:json];
    }
    
    [notificationsData appendString:@"}"];
    [data setObject:notificationsData forKey:@"NotificationJson"];
    
    [self.analytics logMessage:data];
    //End log
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(countryConfigReloaded:)
     name:kCountryConfigReloaded
     object:nil];
    
    return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

-(void) countryConfigReloaded: (NSNotification*)__unused notification {
    [self.scheduler loadTasksAndSchedulesFromDiskAndThenUseThisQueue: nil
                                                    toDoThisWhenDone: nil];
}


//Runs when a running app receives a local notification.
- (void)application:(UIApplication *)__unused application didReceiveLocalNotification:(UILocalNotification *)notification
{
    if(notification)
    {
        [self.analytics logMessage:(@{kAnalyticsEventKey : kAnalyticsNotificationActivatedEvent, @"Message" : notification.alertBody,
                                      @"Date" : [self getStringFromDate:[NSDate date]],
                                      @"CalledFrom" : @"didReceiveLocalNotification"})];
    }
}

- (void) setUpInitializationOptions
{
    
    [APCUtilities setRealApplicationName:@"Asthma Health"];
    
    NSDictionary *permissionsDescriptions = @{
                                              @(kAPCSignUpPermissionsTypeLocation) : NSLocalizedString(@"Using your GPS will allow the app to advise you of air quality in your area. Your actual location will never be shared outside this research.", @""),
                                              @(kAPCSignUpPermissionsTypeCoremotion) : NSLocalizedString(@"Using the motion co-processor allows the app to determine your activity, helping the study better understand how activity level may influence disease.", @""),
                                              @(kAPCSignUpPermissionsTypeMicrophone) : NSLocalizedString(@"Access to microphone is required for your Voice Recording Activity.", @""),
                                              @(kAPCSignUpPermissionsTypeLocalNotifications) : NSLocalizedString(@"Allowing notifications enables the app to show you reminders.", @""),
                                              @(kAPCSignUpPermissionsTypeHealthKit) : NSLocalizedString(@"On the next screen, you will be prompted to grant Asthma access to read and write some of your general and health information, such as height, weight and steps taken so you don't have to enter it again.", @""),
                                              };
    
    NSMutableDictionary * dictionary = [super defaultInitializationOptions];
    
#ifdef DEBUG
    self.environment = SBBEnvironmentStaging;
#else
    self.environment = SBBEnvironmentProd;
#endif

    //If the HK permissions keys are updated, the HK Permissions View Controller will be shown on launch.
    [dictionary addEntriesFromDictionary:@{
                                           kStudyIdentifierKey                  : kStudyIdentifier,
                                           kAppPrefixKey                        : kAppPrefix,
                                           kBridgeEnvironmentKey                : @(self.environment),
                                           kNewsFeedTabKey                      : @(YES),
                                           kHKReadPermissionsKey                : @[
                                                   HKQuantityTypeIdentifierBodyMass,
                                                   HKQuantityTypeIdentifierHeight,
                                                   HKQuantityTypeIdentifierStepCount,
                                                   HKQuantityTypeIdentifierPeakExpiratoryFlowRate,
                                                   HKQuantityTypeIdentifierInhalerUsage,
                                                   HKQuantityTypeIdentifierHeartRate,
                                                   HKQuantityTypeIdentifierRespiratoryRate,
                                                   HKQuantityTypeIdentifierOxygenSaturation,
                                                   HKQuantityTypeIdentifierActiveEnergyBurned,
                                                   HKQuantityTypeIdentifierDistanceCycling,
                                                   HKQuantityTypeIdentifierFlightsClimbed,
                                                   HKQuantityTypeIdentifierBasalEnergyBurned,
                                                   HKQuantityTypeIdentifierDistanceWalkingRunning,
                                                   @{kHKWorkoutTypeKey  : HKWorkoutTypeIdentifier},
                                                   @{kHKCategoryTypeKey : HKCategoryTypeIdentifierSleepAnalysis}
                                                   ],
                                           kHKWritePermissionsKey                : @[
                                                   HKQuantityTypeIdentifierBodyMass,
                                                   HKQuantityTypeIdentifierHeight,
                                                   HKQuantityTypeIdentifierPeakExpiratoryFlowRate,
                                                   HKQuantityTypeIdentifierInhalerUsage
                                                   ],
                                           kAppServicesListRequiredKey           : @[
                                                   @(kAPCSignUpPermissionsTypeLocation),
                                                   @(kAPCSignUpPermissionsTypeLocalNotifications)
                                                   ],
                                           kAppServicesDescriptionsKey : permissionsDescriptions,
                                           kAppProfileElementsListKey            : @[
                                                   @(kAPCUserInfoItemTypeEmail),
                                                   @(kAPCUserInfoItemTypeDateOfBirth),
                                                   @(kAPCUserInfoItemTypeBiologicalSex),
                                                   @(kAPCUserInfoItemTypeHeight),
                                                   @(kAPCUserInfoItemTypeWeight)
                                                   ]
                                           }];
    self.initializationOptions = dictionary;
    
    self.analytics = [APHAnalytics alloc];
    [self.analytics initAnalytics];
}


-(void)setUpTasksReminder{
    //Reminders
    APCTaskReminder *dailySurveyReminder = [[APCTaskReminder alloc]initWithTaskID:kDailySurveyTaskID reminderBody:NSLocalizedString(@"Daily Survey", nil)];
    APCTaskReminder *weeklySurveyReminder = [[APCTaskReminder alloc]initWithTaskID:kWeeklySurveyTaskID reminderBody:NSLocalizedString(@"Weekly Survey", nil)];
    
    //define completion as defined in resultsSummary
    NSPredicate *medicationPredicate = [NSPredicate predicateWithFormat:@"SELF.integerValue == 1"];
    APCTaskReminder *medicationReminder = [[APCTaskReminder alloc]initWithTaskID:kDailySurveyTaskID resultsSummaryKey:kTookMedicineKey completedTaskPredicate:medicationPredicate reminderBody:kTakeMedicationKey];
    
    medicationReminder.customReminderMessage = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat: @"%@%@", medicationReminder.taskID,kUserMedicationReminderCustomMessageKey]];
    
    //If take medication reminder does not have a reminder time set, then initialize it
    if(![self.tasksReminder reminderHasSpecificTimeSet:medicationReminder])
    {
        [self.tasksReminder setReminderTime:medicationReminder.taskID subTaskId:medicationReminder.resultsSummaryKey reminderTime:@"9:00 AM"];
    }
    
    //Setup user defined medication reminders
    NSMutableArray* userDefinedMedReminders = [[NSUserDefaults standardUserDefaults] objectForKey:kUserMedicationReminderKey];
    if(!userDefinedMedReminders){
        userDefinedMedReminders = [NSMutableArray new];
        [[NSUserDefaults standardUserDefaults] setObject:userDefinedMedReminders forKey:kUserMedicationReminderKey];
        [[NSUserDefaults standardUserDefaults]synchronize];
    }
    
    [self.tasksReminder.reminders removeAllObjects];
    
    for (NSString* medReminder in userDefinedMedReminders) {
        NSPredicate *userDefinedPredicate = [NSPredicate predicateWithFormat:@"SELF.integerValue == 1"];
        APCTaskReminder *userDefinedReminder = [[APCTaskReminder alloc]initWithTaskID:[NSString stringWithFormat: @"%@%@", kUserMedicationReminderPrefix,medReminder] resultsSummaryKey:[NSString stringWithFormat: @"%@_%@", kTookMedicineKey,medReminder] completedTaskPredicate:userDefinedPredicate reminderBody:[NSString stringWithFormat: @"%@ : %@", kTakeMedicationKey,medReminder]];
        
        userDefinedReminder.customReminderMessage = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat: @"%@%@", userDefinedReminder.taskID,kUserMedicationReminderCustomMessageKey]];
        
        userDefinedReminder.isCustomMedReminder = YES;
        
        [self.tasksReminder manageTaskReminder:userDefinedReminder];
        
        if(![self.tasksReminder reminderHasSpecificTimeSet:userDefinedReminder])
        {
            [self.tasksReminder setReminderTime:userDefinedReminder.taskID subTaskId:userDefinedReminder.resultsSummaryKey reminderTime:@"9:00 AM"];
        }
    }
    
    
    [self.tasksReminder manageTaskReminder:dailySurveyReminder];
    [self.tasksReminder manageTaskReminder:weeklySurveyReminder];
    [self.tasksReminder manageTaskReminder:medicationReminder];
    
    if ([self doesPersisteStoreExist] == NO)
    {
        APCLogEvent(@"This app is being launched for the first time. Turn all reminders on");
        for (APCTaskReminder *reminder in self.tasksReminder.reminders) {
            //Do not turn on the medication reminder by default, turn on all others
            if(![reminder.reminderBody isEqualToString:kTakeMedicationKey])
                [[NSUserDefaults standardUserDefaults]setObject:reminder.reminderBody forKey:reminder.reminderIdentifier];
        }
        
        if ([[UIApplication sharedApplication] currentUserNotificationSettings].types != UIUserNotificationTypeNone){
            [self.tasksReminder setReminderOn:YES];
        }
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void) loadReconsentSurvey {

    NSPredicate *filterForRequiredTasks = [NSPredicate predicateWithFormat: @"%K == %@",
                                           NSStringFromSelector(@selector(taskID)),
                                           kReconsentTaskID];
    NSDate *date = [NSDate date];

    [[APCScheduler defaultScheduler] fetchTaskGroupsFromDate: date.startOfDay
                                                      toDate: date.endOfDay
                                      forTasksMatchingFilter: filterForRequiredTasks
                                                  usingQueue: [NSOperationQueue mainQueue]
                                             toReportResults: ^(NSDictionary *taskGroups, NSError * __unused queryError) {

                                        APCTaskGroup *taskGroup = taskGroups.allValues[0][0];
                                        APHReconsentTaskViewController *taskViewController = [APHReconsentTaskViewController configureTaskViewController:taskGroup];

                                        [self.window.rootViewController presentViewController:taskViewController animated:YES completion:nil];

    }];


}


#pragma mark - PasscodeViewControllerDelegate

- (void) passcodeViewControllerDidSucceed:(APCPasscodeViewController *)__unused viewController {

    APHConsent *consent = [[APHConsent alloc] initWithScheduler:self.scheduler dataSubtrate:self.dataSubstrate analytics:self.analytics];
    BOOL displayReconsent = [consent shouldShowReconsent];

    if (displayReconsent) {
        [self loadReconsentSurvey];
        return;
    }

    if ([consent hasConsentExpired]) {
        [self disableAppActivities];
    } else {
        [self enableAppActivities];
    }
    
    //set the tabbar controller as the rootViewController
    [super passcodeViewControllerDidSucceed:viewController];
    
    APHConsentUpdate *consentUpdate = [APHConsentUpdate new];
    if ([consentUpdate checkConsentUpdate]) {
        
        [APHConsentUpdate showConsentUpdateAlert:self.window.rootViewController completion:^{
            
            [[APHVersionUpdate sharedInstance] checkVersion];
        }];
    } else {
        
        [[APHVersionUpdate sharedInstance] checkVersion];
    }
}


#pragma mark -

- (void) setUpAppAppearance
{
    [APCAppearanceInfo setAppearanceDictionary:@{
                                                 kPrimaryAppColorKey : [UIColor colorWithRed:0.133 green:0.122 blue:0.447 alpha:1.000],
                                                 kDailySurveyTaskID : [UIColor appTertiaryGreenColor],
                                                 kWeeklySurveyTaskID : [UIColor appTertiaryGreenColor],
                                                 kMilestonev1SurveyTaskID: [UIColor appTertiaryRedColor],
                                                 kMilestonev2SurveyTaskID: [UIColor appTertiaryRedColor],
                                                 kFeedbackv1SurveyTaskID: [UIColor appTertiaryGreenColor],
                                                 kFeedbackv2SurveyTaskID: [UIColor appTertiaryGreenColor],
                                                 kMedicalHistorySurveyTaskID: [UIColor appTertiaryPurpleColor],
                                                 kMedicationSurveyTaskID: [UIColor appTertiaryPurpleColor],
                                                 kUKMedicationSurveyTaskID: [UIColor appTertiaryPurpleColor],
                                                 kIEMedicationSurveyTaskID: [UIColor appTertiaryPurpleColor],
                                                 kYourAsthmaSurveyTaskID : [UIColor appTertiaryPurpleColor],
                                                 kAsthmaHistorySurveyTaskID : [UIColor appTertiaryPurpleColor],
                                                 kEnrollmentSurveyTaskID : [UIColor appTertiaryPurpleColor],
                                                 kAboutYouSurveyTaskID : [UIColor appTertiaryPurpleColor],
                                                 kUKAboutYouSurveyTaskID : [UIColor appTertiaryPurpleColor],
                                                 kIEAboutYouSurveyTaskID : [UIColor appTertiaryPurpleColor]
                                                 }];
    
    [[UINavigationBar appearance] setBackgroundColor:[UIColor whiteColor]];
    [[UINavigationBar appearance] setTitleTextAttributes: @{
                                                            NSForegroundColorAttributeName : [UIColor appSecondaryColor1],
                                                            NSFontAttributeName : [UIFont appNavBarTitleFont]
                                                            }];
    [[UIView appearance] setTintColor:[UIColor appPrimaryColor]];
    self.dataSubstrate.parameters.hideExampleConsent = YES;
}

- (void) showOnBoarding
{
    APCStudyOverviewViewController *studyController = [[UIStoryboard storyboardWithName:@"APCOnboarding" bundle:[NSBundle appleCoreBundle]] instantiateViewControllerWithIdentifier:@"StudyOverviewVC"];
    [self setUpRootViewController:studyController];
}

- (BOOL) isVideoShown
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:kVideoShownKey];
}

- (void)instantiateOnboardingForType:(APCOnboardingTaskType)type
{
    [super instantiateOnboardingForType:type];

    // Custom Ineligible Screen
    APCScene *scene = [APCScene new];

    scene.name = @"APHInEligibleViewController";
    scene.storyboardName = @"APHOnboarding";
    scene.bundle = [NSBundle mainBundle];

    [self.onboarding setScene:scene forIdentifier:kAPCSignUpIneligibleStepIdentifier];
}

- (NSArray *)offsetForTaskSchedules
{
    return @[
             @{
                 kScheduleOffsetTaskIdKey: kYourAsthmaSurveyTaskID,
                 kScheduleOffsetOffsetKey: @(1)
                 },
             @{
                 kScheduleOffsetTaskIdKey: kAboutYouSurveyTaskID,
                 kScheduleOffsetOffsetKey: @(2)
                 },
             @{
                 kScheduleOffsetTaskIdKey: kMedicalHistorySurveyTaskID,
                 kScheduleOffsetOffsetKey: @(3)
                 }
             ];
}

- (void) signedInNotification: (NSNotification*) notification
{
    APHConsent *consent = [[APHConsent alloc] initWithScheduler:self.scheduler dataSubtrate:self.dataSubstrate analytics:self.analytics];
    BOOL displayReconsent = [consent shouldShowReconsent];
    
    if (displayReconsent) {
        [self loadReconsentSurvey];
    } else {
        if ([consent hasConsentExpired]) {
            [self disableAppActivities];
        } else {
            [self enableAppActivities];
        }
        [super signedInNotification:notification];
        [self uploadAwsClientId];
    }
}

- (void)disableAppActivities
{
    //•	The scheduler should shut down. No activities should appear with surveys.
    //•	Location and HealthKit data should stop getting sent to the server
    [self.passiveDataCollector stopCollecting];
    [self.locationManager stopUpdatingLocation];
    [self.dataSubstrate.currentUser setConsented:NO];
}

- (void)enableAppActivities
{
    //•	The scheduler should start again. Activities should back appear in the list.
    //•	Location and HealthKit data should start getting sent to the server
    [self.passiveDataCollector startCollecting];
    [self.locationManager startUpdatingLocation];
    [self.dataSubstrate.currentUser setConsented:YES];
}

/*********************************************************************************/
#pragma mark - Datasubstrate Delegate Methods
/*********************************************************************************/
- (void) setUpCollectors
{
    if (self.dataSubstrate.currentUser.userConsented)
    {
        if (!self.passiveDataCollector)
        {
            self.passiveDataCollector = [[APCPassiveDataCollector alloc] init];
        }

        self.locationManager = [[APHLocationManager alloc] init];
        [self configureObserverQueries];
    }
}

- (void)configureObserverQueries
{
    NSDate* (^LaunchDate)() = ^
    {
        APHConsent *consent = [[APHConsent alloc] initWithScheduler:self.scheduler dataSubtrate:self.dataSubstrate analytics:self.analytics];
        NSDate *consentDate = [consent determineConsentDate];
        return consentDate;
    };
    
    NSString *(^determineQuantitySource)(NSString *) = ^(NSString  *source)
    {
        NSString  *answer = nil;
        if (source == nil) {
            answer = @"not available";
        } else if ([UIDevice.currentDevice.name isEqualToString:source] == YES) {
            if ([APCDeviceHardware platformString] != nil) {
                answer = [APCDeviceHardware platformString];
            } else {
                answer = @"iPhone";    //    theoretically should not happen
            }
        }
        return answer;
    };
    
    NSString*(^QuantityDataSerializer)(id, HKUnit*) = ^NSString*(id dataSample, HKUnit* unit)
    {
        HKQuantitySample*   qtySample           = (HKQuantitySample *)dataSample;
        NSString*           startDateTimeStamp  = [qtySample.startDate toStringInISO8601Format];
        NSString*           endDateTimeStamp    = [qtySample.endDate toStringInISO8601Format];
        NSString*           healthKitType       = qtySample.quantityType.identifier;
        NSNumber*           quantityValue       = @([qtySample.quantity doubleValueForUnit:unit]);
        NSString*           quantityUnit        = unit.unitString;
        NSString*           sourceIdentifier    = qtySample.source.bundleIdentifier;
        NSString*           quantitySource      = qtySample.source.name;
        
        quantitySource = determineQuantitySource(quantitySource);
        
        NSString *stringToWrite = [NSString stringWithFormat:@"%@,%@,%@,%@,%@,%@,%@\n",
                                   startDateTimeStamp,
                                   endDateTimeStamp,
                                   healthKitType,
                                   quantityValue,
                                   quantityUnit,
                                   quantitySource,
                                   sourceIdentifier];
        
        return stringToWrite;
    };
    
    NSString*(^WorkoutDataSerializer)(id) = ^(id dataSample)
    {
        HKWorkout*  sample                      = (HKWorkout*)dataSample;
        NSString*   startDateTimeStamp          = [sample.startDate toStringInISO8601Format];
        NSString*   endDateTimeStamp            = [sample.endDate toStringInISO8601Format];
        NSString*   healthKitType               = sample.sampleType.identifier;
        NSString*   activityType                = [HKWorkout apc_workoutActivityTypeStringRepresentation:(int)sample.workoutActivityType];
        double      energyConsumedValue         = [sample.totalEnergyBurned doubleValueForUnit:[HKUnit kilocalorieUnit]];
        NSString*   energyConsumed              = [NSString stringWithFormat:@"%f", energyConsumedValue];
        NSString*   energyUnit                  = [HKUnit kilocalorieUnit].description;
        double      totalDistanceConsumedValue  = [sample.totalDistance doubleValueForUnit:[HKUnit meterUnit]];
        NSString*   totalDistance               = [NSString stringWithFormat:@"%f", totalDistanceConsumedValue];
        NSString*   distanceUnit                = [HKUnit meterUnit].description;
        NSString*   sourceIdentifier            = sample.source.bundleIdentifier;
        NSString*   quantitySource              = sample.source.name;
        
        quantitySource = determineQuantitySource(quantitySource);
        
        NSError*    error                       = nil;
        NSString*   metaData                    = [NSDictionary apc_stringFromDictionary:sample.serializableMetadata error:&error];
        
        if (!metaData)
        {
            if (error)
            {
                APCLogError2(error);
            }
            
            metaData = @"";
        }
        
        NSString*   metaDataStringified         = [NSString stringWithFormat:@"\"%@\"", metaData];
        NSString*   stringToWrite               = [NSString stringWithFormat:@"%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@\n",
                                                   startDateTimeStamp,
                                                   endDateTimeStamp,
                                                   healthKitType,
                                                   activityType,
                                                   totalDistance,
                                                   distanceUnit,
                                                   energyConsumed,
                                                   energyUnit,
                                                   quantitySource,
                                                   sourceIdentifier,
                                                   metaDataStringified];
        
        return stringToWrite;
    };
    
    NSString*(^CategoryDataSerializer)(id) = ^NSString*(id dataSample)
    {
        HKCategorySample*   catSample       = (HKCategorySample *)dataSample;
        NSString*           stringToWrite   = nil;
        
        if ([catSample.categoryType.identifier isEqualToString:HKCategoryTypeIdentifierSleepAnalysis])
        {
            NSString*           startDateTime   = [catSample.startDate toStringInISO8601Format];
            NSString*           healthKitType   = catSample.sampleType.identifier;
            NSString*           categoryValue   = nil;
            
            if (catSample.value == HKCategoryValueSleepAnalysisAsleep)
            {
                categoryValue = @"HKCategoryValueSleepAnalysisAsleep";
            }
            else
            {
                categoryValue = @"HKCategoryValueSleepAnalysisInBed";
            }
            
            NSString*           quantityUnit        = [[HKUnit secondUnit] unitString];
            NSString*           sourceIdentifier    = catSample.source.bundleIdentifier;
            NSString*           quantitySource      = catSample.source.name;
            
            quantitySource = determineQuantitySource(quantitySource);
            
            // Get the difference in seconds between the start and end date for the sample
            NSDateComponents* secondsSpentInBedOrAsleep = [[NSCalendar currentCalendar] components:NSCalendarUnitSecond
                                                                                          fromDate:catSample.startDate
                                                                                            toDate:catSample.endDate
                                                                                           options:NSCalendarWrapComponents];
            NSString*           quantityValue   = [NSString stringWithFormat:@"%ld", (long)secondsSpentInBedOrAsleep.second];
            
            stringToWrite = [NSString stringWithFormat:@"%@,%@,%@,%@,%@,%@,%@\n",
                             startDateTime,
                             healthKitType,
                             categoryValue,
                             quantityValue,
                             quantityUnit,
                             sourceIdentifier,
                             quantitySource];
        }
        
        return stringToWrite;
    };
    
    NSArray* dataTypesWithReadPermission = self.initializationOptions[kHKReadPermissionsKey];
    
    if (!self.passiveDataCollector)
    {
        self.passiveDataCollector = [[APCPassiveDataCollector alloc] init];
    }
    
    // Just a note here that we are using n collectors to 1 data sink for quantity sample type data.
    NSArray*                    quantityColumnNames = @[@"startTime,endTime,type,value,unit,source,sourceIdentifier"];
    APCPassiveDataSink*         quantityreceiver    =[[APCPassiveDataSink alloc] initWithQuantityIdentifier:@"HealthKitDataCollector"
                                                                                                columnNames:quantityColumnNames
                                                                                         operationQueueName:@"APCHealthKitQuantity Activity Collector"
                                                                                              dataProcessor:QuantityDataSerializer
                                                                                          fileProtectionKey:NSFileProtectionCompleteUnlessOpen];
    NSArray*                    workoutColumnNames  = @[@"startTime,endTime,type,workoutType,total distance,unit,energy consumed,unit,source,sourceIdentifier,metadata"];
    APCPassiveDataSink*         workoutReceiver     = [[APCPassiveDataSink alloc] initWithIdentifier:@"HealthKitWorkoutCollector"
                                                                                         columnNames:workoutColumnNames
                                                                                  operationQueueName:@"APCHealthKitWorkout Activity Collector"
                                                                                       dataProcessor:WorkoutDataSerializer
                                                                                   fileProtectionKey:NSFileProtectionCompleteUnlessOpen];
    NSArray*                    categoryColumnNames = @[@"startTime,type,category value,value,unit,source,sourceIdentifier"];
    APCPassiveDataSink*         sleepReceiver       = [[APCPassiveDataSink alloc] initWithIdentifier:@"HealthKitSleepCollector"
                                                                                         columnNames:categoryColumnNames
                                                                                  operationQueueName:@"APCHealthKitSleep Activity Collector"
                                                                                       dataProcessor:CategoryDataSerializer
                                                                                   fileProtectionKey:NSFileProtectionCompleteUnlessOpen];
    
    if (dataTypesWithReadPermission)
    {
        for (id dataType in dataTypesWithReadPermission)
        {
            HKSampleType* sampleType = nil;
            
            if ([dataType isKindOfClass:[NSDictionary class]])
            {
                NSDictionary* categoryType = (NSDictionary *) dataType;
                
                //Distinguish
                if (categoryType[kHKWorkoutTypeKey])
                {
                    sampleType = [HKObjectType workoutType];
                }
                else if (categoryType[kHKCategoryTypeKey])
                {
                    sampleType = [HKObjectType categoryTypeForIdentifier:categoryType[kHKCategoryTypeKey]];
                }
            }
            else
            {
                sampleType = [HKObjectType quantityTypeForIdentifier:dataType];
            }
            
            if (sampleType)
            {
                // This is really important to remember that we are creating as many user defaults as there are healthkit permissions here.
                NSString*                               uniqueAnchorDateName    = [NSString stringWithFormat:@"APCHealthKit%@AnchorDate", dataType];
                APCHealthKitBackgroundDataCollector*    collector               = nil;
                
                //If the HKObjectType is a HKWorkoutType then set a different receiver/data sink.
                if ([sampleType isKindOfClass:[HKWorkoutType class]])
                {
                    collector = [[APCHealthKitBackgroundDataCollector alloc] initWithIdentifier:sampleType.identifier
                                                                                     sampleType:sampleType anchorName:uniqueAnchorDateName
                                                                               launchDateAnchor:LaunchDate
                                                                                    healthStore:self.dataSubstrate.healthStore];
                    [collector setReceiver:workoutReceiver];
                    [collector setDelegate:workoutReceiver];
                }
                else if ([sampleType isKindOfClass:[HKCategoryType class]])
                {
                    collector = [[APCHealthKitBackgroundDataCollector alloc] initWithIdentifier:sampleType.identifier
                                                                                     sampleType:sampleType anchorName:uniqueAnchorDateName
                                                                               launchDateAnchor:LaunchDate
                                                                                    healthStore:self.dataSubstrate.healthStore];
                    [collector setReceiver:sleepReceiver];
                    [collector setDelegate:sleepReceiver];
                }
                else
                {
                    NSDictionary* hkUnitKeysAndValues = [[HealthKitUtils sharedManager] supportedQuantityTypeMetricsToQuanityUnitsMap];
                    
                    collector = [[APCHealthKitBackgroundDataCollector alloc] initWithQuantityTypeIdentifier:sampleType.identifier
                                                                                                 sampleType:sampleType anchorName:uniqueAnchorDateName
                                                                                           launchDateAnchor:LaunchDate
                                                                                                healthStore:self.dataSubstrate.healthStore
                                                                                                       unit:[hkUnitKeysAndValues objectForKey:sampleType.identifier]];
                    [collector setReceiver:quantityreceiver];
                    [collector setDelegate:quantityreceiver];
                }
                
                [collector start];
                [self.passiveDataCollector addDataSink:collector];
            }
        }
    }
}

/*********************************************************************************/
#pragma mark - APCOnboardingDelegate Methods
/*********************************************************************************/

- (APCScene *)inclusionCriteriaSceneForOnboarding:(APCOnboarding *)__unused onboarding
{
    APCScene *scene = [APCScene new];
    scene.name = @"APHInclusionCriteriaViewController";
    scene.storyboardName = @"APHOnboarding";
    scene.bundle = [NSBundle mainBundle];
    
    return scene;
}


/*********************************************************************************/
#pragma mark - Consent
/*********************************************************************************/

- (ORKTaskViewController *)consentViewController
{
    APHBooleanQuestionStep* question1Step      = [[APHBooleanQuestionStep alloc]initWithIdentifier:@"question1" tag:1];
    question1Step.answer = true;
    APHBooleanQuestionStep* question2Step      = [[APHBooleanQuestionStep alloc]initWithIdentifier:@"question2" tag:2];
    question2Step.answer = true;
    APHBooleanQuestionStep* question3Step      = [[APHBooleanQuestionStep alloc]initWithIdentifier:@"question3" tag:3];
    question3Step.answer = true;
    ORKStep*                quizEvaluationStep = [[ORKStep alloc]initWithIdentifier:@"quizEvaluation"];
    
    NSArray*                        customSteps = @[question1Step, question2Step, question3Step, quizEvaluationStep];
    APCConsentTask*                 consentTask = [[APCConsentTask alloc] initWithIdentifier:@"consent"
                                                                          propertiesFileName:kConsentPropertiesFileName
                                                                                 customSteps:customSteps];
    APHConsentTaskViewController*   consentVC   = [[APHConsentTaskViewController alloc] initWithTask:consentTask
                                                                                         taskRunUUID:[NSUUID UUID]];
    
    APHConsentRedirector*   consentRedirector = [[APHConsentRedirector alloc] init];
    consentRedirector.failureCount      = 0;
    consentRedirector.maxAllowedFailure = 2;
    
    consentVC.consentRedirector  = consentRedirector;
    consentTask.redirector       = consentRedirector;
    consentTask.failedMessageTag = @"quizEvaluation";
    
    return consentVC;
}

- (NSString*) currentCountry {
    return [self.countryConfig countryCode];
}


-(void) uploadAwsClientId {
    [self.analytics uploadAwsClientId];
}

-(void)application:(UIApplication *) __unused application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler {
    if ([identifier isEqualToString:kTwentyThreeAndMeBackgroundSessionIdentifier]) {
        self.twentyThreeAndMeBackgroundCompletionHandler = completionHandler;
        [APHTwentyThreeAndMeClient sharedClient];
    }
}

@end
