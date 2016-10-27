// 
//  APHSettingsViewController.m
//  Asthma
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
 
#import "APHSettingsViewController.h"
#import "APHConstants.h"
#import "APHAppDelegate.h"
#import "APHAddReminderTableViewCell.h"
#import "APHDeleteReminderTableViewCell.h"
#import "APHTableViewItem.h"

@interface APHSettingsViewController ()
@property (strong, nonatomic) APCPermissionsManager *permissionManager;
@property (strong, nonatomic) NSArray* taskReminders;
@end

@implementation APHSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if(_isMedReminder)
    {
        APHAppDelegate* appDelegate = ((APHAppDelegate *)[UIApplication sharedApplication].delegate );
        [appDelegate.analytics logMessage:(@{kAnalyticsEventKey : kAnalyticsMedicationReminderView,
                                             @"time" : [appDelegate getStringFromDate:[NSDate date]]})];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}


- (void)prepareContent
{
    [self.items removeAllObjects];
    
    NSMutableArray *items = [NSMutableArray new];
    APCAppDelegate * appDelegate = (APCAppDelegate*) [UIApplication sharedApplication].delegate;
    BOOL reminderOnState = appDelegate.tasksReminder.reminderOn;
    
    if(!_isMedReminder)
    {
        {
        
            NSMutableArray *rowItems = [NSMutableArray new];
            
            {
                APCTableViewSwitchItem *field = [APCTableViewSwitchItem new];
                field.caption = NSLocalizedString(@"Enable Reminders", nil);
                field.identifier = kAPCSwitchCellIdentifier;
                field.editable = NO;
                
                field.on = reminderOnState;
                
                APCTableViewRow *row = [APCTableViewRow new];
                row.item = field;
                row.itemType = kAPCSettingsItemTypeReminderOnOff;
                [rowItems addObject:row];
            }
            

                APCTableViewCustomPickerItem *field = [APCTableViewCustomPickerItem new];
                field.caption = NSLocalizedString(@"Time", nil);
                field.pickerData = @[[APCTasksReminderManager reminderTimesArray]];
                field.textAlignnment = NSTextAlignmentRight;
                field.identifier = kAPCDefaultTableViewCellIdentifier;
                field.selectedRowIndices = @[@([[APCTasksReminderManager reminderTimesArray] indexOfObject:appDelegate.tasksReminder.reminderTime])];

                APCTableViewRow *row = [APCTableViewRow new];
                row.item = field;
                row.itemType = kAPCSettingsItemTypeReminderTime;
                [rowItems addObject:row];
            
         
            APCTableViewSection *section = [APCTableViewSection new];
            section.sectionTitle = NSLocalizedString(@"", nil);
            section.rows = [NSArray arrayWithArray:rowItems];
            [items addObject:section];
        }

    //The code below enables per task notifications section and rows.
        if (reminderOnState) {
            NSMutableArray *rowItems = [NSMutableArray new];
            APCAppDelegate * appDelegate = (APCAppDelegate*) [UIApplication sharedApplication].delegate;
            NSPredicate *predicate = [NSPredicate predicateWithFormat: @"reminderBody != %@ AND NOT (reminderBody CONTAINS %@)", kTakeMedicationKey, kTakeMedicationPrefix];
            _taskReminders = [appDelegate.tasksReminder.reminders filteredArrayUsingPredicate:predicate];
            
            for (APCTaskReminder *reminder in _taskReminders) {
                
                if([reminder.reminderBody isEqualToString:kTakeMedicationKey])
                {
                    continue; //Don't show take medication setting
                }
                
                APCTableViewSwitchItem *field = [APCTableViewSwitchItem new];
                field.caption = NSLocalizedString(reminder.reminderBody, nil);
                field.identifier = kAPCSwitchCellIdentifier;
                field.editable = NO;
                
                field.on = [[NSUserDefaults standardUserDefaults]objectForKey:reminder.reminderIdentifier] ? YES : NO;
                
                APCTableViewRow *row = [APCTableViewRow new];
                row.item = field;
                row.itemType = kAPCSettingsItemTypeReminderOnOff;
                [rowItems addObject:row];            
            }
            
            APCTableViewSection *section = [APCTableViewSection new];
            
            section.rows = [NSArray arrayWithArray:rowItems];
            [items addObject:section];
            

        }
    } else { //Only show take medication reminder settings
        {
            
            NSMutableArray *rowItems = [NSMutableArray new];
        
            NSPredicate *predicate = [NSPredicate predicateWithFormat: @"reminderBody == %@ OR resultsSummaryKey contains %@", kTakeMedicationKey, kTookMedicineKey];
            _taskReminders = [appDelegate.tasksReminder.reminders filteredArrayUsingPredicate:predicate];
            
            for (APCTaskReminder *reminder in _taskReminders) {
                
                {
                    //If take medication reminder does not have a reminder time set, then initialize it
                    if(![appDelegate.tasksReminder reminderHasSpecificTimeSet:reminder])
                    {
                        [appDelegate.tasksReminder setReminderTime:reminder.taskID subTaskId:reminder.resultsSummaryKey reminderTime:@"9:00 AM"];
                    }
                    
                    {
                        APHTableViewSwitchItem *field = [APHTableViewSwitchItem new];
                        field.caption = NSLocalizedString(reminder.reminderBody, nil);
                        field.identifier = kAPCSwitchCellIdentifier;
                        field.taskId = reminder.taskID;
                        field.editable = NO;
                        
                        field.on = [[NSUserDefaults standardUserDefaults]objectForKey:reminder.reminderIdentifier] ? YES : NO;
                        
                        APCTableViewRow *row = [APCTableViewRow new];
                        row.item = field;
                        row.itemType = kAPCSettingsItemTypeReminderOnOff;
                        [rowItems addObject:row];
                    }
                    {
                        APHTableViewCustomPickerItem *field = [APHTableViewCustomPickerItem new];
                        field.caption = NSLocalizedString(@"Time", nil);
                        field.pickerData = @[[APCTasksReminderManager reminderTimesArray]];
                        field.textAlignnment = NSTextAlignmentRight;
                        field.identifier = kAPCDefaultTableViewCellIdentifier;
                        field.selectedRowIndices = @[@([[APCTasksReminderManager reminderTimesArray] indexOfObject:[appDelegate.tasksReminder reminderTime:reminder.taskID subTaskId:reminder.resultsSummaryKey]])];
                        field.taskId = reminder.taskID;
                        
                        APCTableViewRow *row = [APCTableViewRow new];
                        row.item = field;
                        row.itemType = kAPCSettingsItemTypeReminderTime;
                        [rowItems addObject:row];
                    }
                    {
                        APHTableViewCustomPickerItem *field = [APHTableViewCustomPickerItem new];
                        if(reminder.customReminderMessage && reminder.customReminderMessage > 0)
                        {
                            field.caption = reminder.customReminderMessage;
                            field.detailText = @"update reminder text..";
                        }
                        else
                        {
                            field.caption = @"";
                            field.detailText = @"add reminder text..";
                        }
                        
                        field.selectionStyle = UITableViewCellSelectionStyleGray;
                        field.identifier = kAPCDefaultTableViewCellIdentifier;
                        field.editable = NO;
                        field.textAlignnment = NSTextAlignmentRight;
                        field.taskId = reminder.taskID;
                        
                        
                        APCTableViewRow *row = [APCTableViewRow new];
                        row.item = field;
                        row.itemType = kAPCSettingsItemTypeReminderCustomMessage;
                        [rowItems addObject:row];
                    }
                    
                    if(![reminder.taskID isEqualToString:kDailySurveyTaskID]){
                        APHTableViewDeleteReminderItem *field = [APHTableViewDeleteReminderItem new];
                        field.identifier = kAPHDeleteReminderTableViewCellIdentifier;
                        field.taskId = reminder.taskID;
                        
                        APCTableViewRow *row = [APCTableViewRow new];
                        row.item = field;
                        row.itemType = kAPCSettingsItemTypeDeleteMedReminder;
                        [rowItems addObject:row];
                    }
                }
            }
            
            //Add Reminder Button Section
            APCTableViewItem *field = [APCTableViewItem new];
            field.identifier = kAPHAddReminderTableViewCellIdentifier;
            
            APCTableViewRow *row = [APCTableViewRow new];
            row.item = field;
            row.itemType = kAPCSettingsItemTypeAddMedReminder;
            [rowItems addObject:row];
            
            APCTableViewSection *section = [APCTableViewSection new];
            section.sectionTitle = NSLocalizedString(@"", nil);
            section.rows = [NSArray arrayWithArray:rowItems];
            [items addObject:section];
        }
    }
    
    self.items = items;
}

#pragma mark - UITableViewDataSource methods
- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    
    APCTableViewItem *field = [self itemForIndexPath:indexPath];

    APCTableViewItemType itemType = [self itemTypeForIndexPath:indexPath];
    
    if (field) {
        APCTableViewItem *tableViewItem = (APCTableViewItem *)field;
        if([tableViewItem.identifier isEqualToString:kAPHAddReminderTableViewCellIdentifier])
        {
            cell = [tableView dequeueReusableCellWithIdentifier:field.identifier];
            
            cell.selectionStyle = field.selectionStyle;
            cell.textLabel.text = field.caption;
            cell.detailTextLabel.text = field.detailText;
            APHAddReminderTableViewCell *addReminderCell = (APHAddReminderTableViewCell *)cell;
            addReminderCell.delegate = self;
            cell = addReminderCell;
        } else if ([tableViewItem.identifier isEqualToString:kAPHDeleteReminderTableViewCellIdentifier])
        {
            cell = [tableView dequeueReusableCellWithIdentifier:field.identifier];
            
            cell.selectionStyle = field.selectionStyle;
            cell.textLabel.text = field.caption;
            cell.detailTextLabel.text = field.detailText;
            APHDeleteReminderTableViewCell *deleteReminderCell = (APHDeleteReminderTableViewCell *)cell;
            deleteReminderCell.delegate = self;
            cell = deleteReminderCell;
        } else if (itemType == kAPCSettingsItemTypeReminderCustomMessage)
        {
            cell.textLabel.text = field.caption;
            cell.detailTextLabel.text = field.detailText;
            cell.detailTextLabel.textColor = [UIColor lightGrayColor];
        }
    }
    
    return cell;
}

-(UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    
    UITableViewHeaderFooterView *footerView;

    BOOL hasresultsSummaryKey = NO;
    NSString *subtaskTitle;
    for (APCTaskReminder *reminder in _taskReminders) {
        if([reminder.reminderBody isEqualToString:kTakeMedicationKey])
        {
            continue; //Don't show take medication setting
        }
        
        BOOL on = [[NSUserDefaults standardUserDefaults]objectForKey:reminder.reminderIdentifier] ? YES : NO;
        if (on && reminder.resultsSummaryKey) {
            hasresultsSummaryKey = YES;
            subtaskTitle = reminder.reminderBody;
        }
    }
    
    if (section == 1 && hasresultsSummaryKey) {
        footerView = [[UITableViewHeaderFooterView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(tableView.frame), tableView.sectionHeaderHeight)];
        NSString *footerText = [NSString stringWithFormat:@"%@ reminder will be sent 2 hours later.", subtaskTitle];
        
        CGRect labelFrame = CGRectMake(20, 0, CGRectGetWidth(footerView.frame)-40, 50);
        footerView.textLabel.frame = labelFrame;
        
        UILabel *reminderLabel = [[UILabel alloc]initWithFrame:labelFrame];
        reminderLabel.numberOfLines = 2;
        reminderLabel.text = NSLocalizedString(footerText, nil);
        reminderLabel.textColor = [UIColor grayColor];
        reminderLabel.font = [UIFont appMediumFontWithSize:14.0];
        [footerView.contentView addSubview:reminderLabel];
    }
    
    return footerView == nil ? [UIView new] : footerView;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    APCTableViewItemType itemType = [self itemTypeForIndexPath:indexPath];
    
    switch (itemType) {
        case kAPCSettingsItemTypeDeleteMedReminder:
        {
            [self deleteReminder:indexPath];
        }
            break;
        case kAPCSettingsItemTypeReminderCustomMessage:
        {
            [self updateCustomMessage:indexPath];
        }
            break;
        default:
            [super tableView:tableView didSelectRowAtIndexPath:indexPath];
            break;
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - APCPickerTableViewCellDelegate methods

- (void)pickerTableViewCell:(APCPickerTableViewCell *)cell pickerViewDidSelectIndices:(NSArray *)selectedIndices
{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    
    if (self.pickerShowing && indexPath) {
        
        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
        
        APCTableViewCustomPickerItem *field = (APCTableViewCustomPickerItem *)[self itemForIndexPath:indexPath];
        field.selectedRowIndices = selectedIndices;
        
        UITableViewCell *dateCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row-1 inSection:indexPath.section]];
        dateCell.detailTextLabel.text = field.stringValue;
    }
    
    APHAppDelegate * appDelegate = (APHAppDelegate*) [UIApplication sharedApplication].delegate;
    NSInteger index = ((NSNumber *)selectedIndices[0]).integerValue;
    if(!_isMedReminder)
    {
        if (indexPath.section == 0 && indexPath.row == 2) {
            appDelegate.tasksReminder.reminderTime = [APCTasksReminderManager reminderTimesArray][index];
        }
    } else {
        APHTableViewCustomPickerItem *field = (APHTableViewCustomPickerItem *)[self itemForIndexPath:indexPath];
        APCTaskReminder *reminder = [appDelegate.tasksReminder taskReminder:field.taskId hasResultSummary:YES];
        if(reminder){
            [appDelegate.tasksReminder setReminderTime:reminder.taskID subTaskId:reminder.resultsSummaryKey reminderTime:[APCTasksReminderManager reminderTimesArray][index]];
        }
    }
}

/*********************************************************************************/
#pragma mark - Switch Cell Delegate
/*********************************************************************************/

- (void)switchTableViewCell:(APCSwitchTableViewCell *)cell switchValueChanged:(BOOL)on
{
    if(!_isMedReminder)
    {
        [self handleActivityViewSwitch:cell switchValueChanged:on];
    } else { //Handle medication reminder specifically
        //add or remove the reminder.taskID to/from NSUserDefaults and set to on/off
        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
        APHAppDelegate * appDelegate = (APHAppDelegate*) [UIApplication sharedApplication].delegate;
        APHTableViewSwitchItem *field = (APHTableViewSwitchItem *)[self itemForIndexPath:indexPath];
        APCTaskReminder *reminder = [appDelegate.tasksReminder taskReminder:field.taskId hasResultSummary:YES];
        if(reminder){
            if (on == YES) {
                //turn the reminder on by adding to NSUserDefaults
                [[NSUserDefaults standardUserDefaults]setObject:reminder.reminderBody forKey:reminder.reminderIdentifier];
            }else{
                //turn the reminder off by removing from NSUserDefaults
                if ([[NSUserDefaults standardUserDefaults]objectForKey:reminder.reminderIdentifier]) {
                    [[NSUserDefaults standardUserDefaults]removeObjectForKey:reminder.reminderIdentifier];
                }
            }
            [[NSUserDefaults standardUserDefaults]synchronize];
            
            
            [self prepareContent];
            [self.tableView reloadData];
            //reschedule based on the new on/off state
            [[NSNotificationCenter defaultCenter]postNotificationName:APCUpdateTasksReminderNotification object:nil];

            [appDelegate.analytics logMessage:(@{kAnalyticsEventKey : kAnalyticsMedicationReminderChanged,
                                                 @"time" : [appDelegate getStringFromDate:[NSDate date]]})];
        }
    }
}

- (void) handleActivityViewSwitch:(APCSwitchTableViewCell*)cell switchValueChanged:(BOOL)on
{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    BOOL allReminders = indexPath.section == 0 && indexPath.row == 0;
    if (allReminders) {
        
        __block APCAppDelegate * appDelegate = (APCAppDelegate*) [UIApplication sharedApplication].delegate;
        __weak APHSettingsViewController *weakSelf = self;
        //if on == TRUE && notification permission denied, request notification permission
        if (on && [[UIApplication sharedApplication] currentUserNotificationSettings].types == 0) {
            _permissionManager = [[APCPermissionsManager alloc]init];
            [_permissionManager requestForPermissionForType:kAPCSignUpPermissionsTypeLocalNotifications withCompletion:^(BOOL granted, NSError *error) {
                if (!granted) {
                    [weakSelf presentSettingsAlert:error];
                }else{
                    [appDelegate.tasksReminder setReminderOn:NO];
                    [weakSelf prepareContent];
                    [weakSelf.tableView reloadData];
                }
            }];
            
        }else{
            appDelegate.tasksReminder.reminderOn = on;
        }
        
        //turn off each reminder if all reminders off
        if (on == NO) {
            for (APCTaskReminder *reminder in _taskReminders) {
                if ([[NSUserDefaults standardUserDefaults]objectForKey:reminder.reminderIdentifier]) {
                    [[NSUserDefaults standardUserDefaults]removeObjectForKey:reminder.reminderIdentifier];
                }
            }
        }else{
            for (APCTaskReminder *reminder in _taskReminders) {
                [[NSUserDefaults standardUserDefaults]setObject:reminder.reminderBody forKey:reminder.reminderIdentifier];
            }
        }
        
        [[NSUserDefaults standardUserDefaults]synchronize];
        
        if (self.pickerShowing) {
            [self hidePickerCell];
        }
    }else {
        //manage individual task reminders
        
        //add or remove the reminder.taskID to/from NSUserDefaults and set to on/off
        APCAppDelegate * appDelegate = (APCAppDelegate*) [UIApplication sharedApplication].delegate;
        APCTaskReminder *reminder = [_taskReminders objectAtIndex:indexPath.row];
        
        if (on == YES) {
            //turn the reminder on by adding to NSUserDefaults
            [[NSUserDefaults standardUserDefaults]setObject:reminder.reminderBody forKey:reminder.reminderIdentifier];
        }else{
            //turn the reminder off by removing from NSUserDefaults
            if ([[NSUserDefaults standardUserDefaults]objectForKey:reminder.reminderIdentifier]) {
                [[NSUserDefaults standardUserDefaults]removeObjectForKey:reminder.reminderIdentifier];
            }
            
            //if all reminders are turned off, switch Enable Reminders switch to off
            BOOL remindersOn = NO;
            for (APCTaskReminder *reminder in _taskReminders) {
                if ([[NSUserDefaults standardUserDefaults]objectForKey:reminder.reminderIdentifier]){
                    remindersOn = YES;
                }
            }
            
            if (!remindersOn) {
                appDelegate.tasksReminder.reminderOn = NO;
                [self prepareContent];
                [self.tableView reloadData];
            }
            
            
        }
        [[NSUserDefaults standardUserDefaults]synchronize];
        
    }
    [self prepareContent];
    [self.tableView reloadData];
    //reschedule based on the new on/off state
    [[NSNotificationCenter defaultCenter]postNotificationName:APCUpdateTasksReminderNotification object:nil];
}

#pragma mark - APHAddReminderTableViewCellDelegate

- (void)medicationReminderDidTapAddReminderCell:(APHAddReminderTableViewCell *) __unused cell
{
    NSLog(@"Add Med Reminder!!!");
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:@"Add Reminder"
                                          message:@"Name of Medication"
                                          preferredStyle:UIAlertControllerStyleAlert];
    
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField)
     {
         textField.placeholder = NSLocalizedString(@"Medication", @"");
         [textField addTarget:self action:@selector(alertTextFieldDidChange:)
             forControlEvents:UIControlEventEditingChanged];
     }];
    
    UIAlertAction *okAction = [UIAlertAction
                               actionWithTitle:NSLocalizedString(@"OK", @"OK action")
                               style:UIAlertActionStyleDefault
                               handler:^(__unused UIAlertAction *action)
                               {
                                   UITextField *medication = alertController.textFields.firstObject;
                                   NSLog(@"Medication reminder : %@", medication.text);
                                   
                                   if(medication.text.length > 0)
                                   {
                                       //Add user defined med reminder
                                       NSMutableArray* userDefinedMedReminders = [[NSMutableArray alloc] initWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:kUserMedicationReminderKey]];
                                       [userDefinedMedReminders addObject:medication.text];
                                       
                                       [[NSUserDefaults standardUserDefaults] setObject:userDefinedMedReminders forKey:kUserMedicationReminderKey];

                                       //create the task reminder
                                       APCAppDelegate * appDelegate = (APCAppDelegate*) [UIApplication sharedApplication].delegate;
                                       
                                       NSPredicate *userDefinedPredicate = [NSPredicate predicateWithFormat:@"SELF.integerValue == 1"];
                                       
                                       APCTaskReminder *userDefinedReminder = [[APCTaskReminder alloc]initWithTaskID:[NSString stringWithFormat: @"%@%@", kUserMedicationReminderPrefix,medication.text] resultsSummaryKey:[NSString stringWithFormat: @"%@_%@", kTookMedicineKey,medication.text] completedTaskPredicate:userDefinedPredicate reminderBody:[NSString stringWithFormat: @"%@ : %@", kTakeMedicationKey,medication.text]];
                                       
                                       userDefinedReminder.isCustomMedReminder = YES;
                                       
                                       [appDelegate.tasksReminder manageTaskReminder:userDefinedReminder];
                                       
                                       [appDelegate.tasksReminder setReminderTime:userDefinedReminder.taskID subTaskId:userDefinedReminder.resultsSummaryKey reminderTime:@"9:00 AM"];
                                       
                                       //default reminder to on
                                       [[NSUserDefaults standardUserDefaults]setObject:userDefinedReminder.reminderBody forKey:userDefinedReminder.reminderIdentifier];
                                       
                                       [[NSUserDefaults standardUserDefaults]synchronize];
                                       
                                       [self prepareContent];
                                       [self.tableView reloadData];
                                   }
                               }];
    
    UIAlertAction *cancelAction = [UIAlertAction
                                   actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel action")
                                   style:UIAlertActionStyleCancel
                                   handler:^(__unused UIAlertAction *action)
                                   {
                                       NSLog(@"Cancel add med reminder");
                                   }];
    
    
    [alertController addAction:cancelAction];
    [alertController addAction:okAction];
    okAction.enabled = NO; //default to disabled
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)alertTextFieldDidChange:(UITextField *) __unused sender
{
    UIAlertController *alertController = (UIAlertController *)self.presentedViewController;

    if (alertController)
    {
        UITextField *medication = alertController.textFields.firstObject;
        UIAlertAction *okAction = alertController.actions.lastObject;

        okAction.enabled = medication.text.length > 0;
    }
}

- (void)presentSettingsAlert:(NSError *)error
{
    UIAlertController *alertContorller = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Permissions Denied", @"") message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *dismiss = [UIAlertAction actionWithTitle:NSLocalizedString(@"Dismiss", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *__unused action) {
        
    }];
    [alertContorller addAction:dismiss];
    UIAlertAction *settings = [UIAlertAction actionWithTitle:NSLocalizedString(@"Settings", @"") style:UIAlertActionStyleCancel handler:^(UIAlertAction * __unused action) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    }];
    [alertContorller addAction:settings];
    
    [self.navigationController presentViewController:alertContorller animated:YES completion:nil];
}

- (void)medicationReminderDidTapDeleteReminderCell:(APHAddReminderTableViewCell *) __unused cell
{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    [self deleteReminder:indexPath];
}

-(void)deleteReminder:(NSIndexPath *)indexPath
{
    APHAppDelegate * appDelegate = (APHAppDelegate*) [UIApplication sharedApplication].delegate;
    APHTableViewDeleteReminderItem *field = (APHTableViewDeleteReminderItem *)[self itemForIndexPath:indexPath];
    __weak APCTaskReminder *reminder = [appDelegate.tasksReminder taskReminder:field.taskId hasResultSummary:YES];
    if(reminder){
        UIAlertController *alertController = [UIAlertController
                                              alertControllerWithTitle:@"Delete Reminder"
                                              message:@"Are you sure you want to delete this reminder?"
                                              preferredStyle:UIAlertControllerStyleAlert];
        
        
        UIAlertAction *okAction = [UIAlertAction
                                   actionWithTitle:NSLocalizedString(@"OK", @"OK action")
                                   style:UIAlertActionStyleDefault
                                   handler:^(__unused UIAlertAction *action)
                                   {
                                       NSString* taskKey = [reminder.taskID substringFromIndex:kUserMedicationReminderKey.length - 2];
                                       
                                       //Remove user defined med reminder
                                       NSMutableArray* userDefinedMedReminders = [[NSMutableArray alloc] initWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:kUserMedicationReminderKey]];
                                       [userDefinedMedReminders removeObject:taskKey];
                                       
                                       [[NSUserDefaults standardUserDefaults] setObject:userDefinedMedReminders forKey:kUserMedicationReminderKey];
                                       [[NSUserDefaults standardUserDefaults] removeObjectForKey:reminder.reminderIdentifier];
                                       
                                       //Remove customer reminder message if user added one
                                       [[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat: @"%@%@", reminder.taskID,kUserMedicationReminderCustomMessageKey]];
                                       
                                       [[NSUserDefaults standardUserDefaults]synchronize];
                                       
                                       //update the reminders
                                       APCAppDelegate * appDelegate = (APCAppDelegate*) [UIApplication sharedApplication].delegate;
                                       [appDelegate.tasksReminder removeTaskReminder:reminder];
                                       [appDelegate.tasksReminder updateTasksReminder];
                                       
                                       [self prepareContent];
                                       [self.tableView reloadData];
                                       
                                   }];
        
        UIAlertAction *cancelAction = [UIAlertAction
                                       actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel action")
                                       style:UIAlertActionStyleCancel
                                       handler:^(__unused UIAlertAction *action)
                                       {
                                           NSLog(@"Cancel add med reminder");
                                       }];
        
        
        [alertController addAction:cancelAction];
        [alertController addAction:okAction];
        
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

-(void)updateCustomMessage:(NSIndexPath *)indexPath
{
    APHAppDelegate * appDelegate = (APHAppDelegate*) [UIApplication sharedApplication].delegate;
    APHTableViewDeleteReminderItem *field = (APHTableViewDeleteReminderItem *)[self itemForIndexPath:indexPath];
    __weak APCTaskReminder *reminder = [appDelegate.tasksReminder taskReminder:field.taskId hasResultSummary:YES];

    if(reminder){
        UIAlertController *alertController = [UIAlertController
                                              alertControllerWithTitle:@"Reminder Message"
                                              message:@""
                                              preferredStyle:UIAlertControllerStyleAlert];
        
        
        [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField)
         {
             textField.placeholder = NSLocalizedString(@"Medication Reminder Message", customMsg ? customMsg : @"");
         }];
        
        UIAlertAction *okAction = [UIAlertAction
                                   actionWithTitle:NSLocalizedString(@"OK", @"OK action")
                                   style:UIAlertActionStyleDefault
                                   handler:^(__unused UIAlertAction *action)
                                   {
                                       UITextField *message = alertController.textFields.firstObject;
                                       if(message && message.text.length > 0)
                                       {
                                           [[NSUserDefaults standardUserDefaults] setObject:message.text forKey:[NSString stringWithFormat: @"%@%@", reminder.taskID,kUserMedicationReminderCustomMessageKey]];

                                           [[NSUserDefaults standardUserDefaults]synchronize];
                                           
                                           reminder.customReminderMessage = message.text;
                                           
                                           //update the reminders
                                           APCAppDelegate * appDelegate = (APCAppDelegate*) [UIApplication sharedApplication].delegate;
                                           [appDelegate.tasksReminder updateTasksReminder];
                                           
                                           [self prepareContent];
                                           [self.tableView reloadData];
                                        }
                                   }];
        
        UIAlertAction *cancelAction = [UIAlertAction
                                       actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel action")
                                       style:UIAlertActionStyleCancel
                                       handler:^(__unused UIAlertAction *action)
                                       {
                                           NSLog(@"Cancel add custom med reminder message");
                                       }];
        
        
        [alertController addAction:cancelAction];
        [alertController addAction:okAction];
        
        [self presentViewController:alertController animated:YES completion:nil];
    }

}
@end
