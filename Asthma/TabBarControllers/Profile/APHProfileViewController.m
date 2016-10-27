// 
//  APHProfileViewController.m
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
 
#import "APHProfileViewController.h"
#import "APHSettingsViewController.h"

@interface APHProfileViewController ()


@end

@implementation APHProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [super numberOfSectionsInTableView:tableView];
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [super tableView:tableView numberOfRowsInSection:section];
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

#pragma mark - Prepare Content

- (NSArray *)prepareContent
{
    NSDictionary *initialOptions = ((APCAppDelegate *)[UIApplication sharedApplication].delegate).initializationOptions;
    NSArray *profileElementsList = initialOptions[kAppProfileElementsListKey];
    
    NSMutableArray *items = [NSMutableArray new];
    
    {
        NSMutableArray *rowItems = [NSMutableArray new];
        
        for (NSNumber *type in profileElementsList) {
            
            APCUserInfoItemType itemType = type.integerValue;
            
            switch (itemType) {
                case kAPCUserInfoItemTypeBiologicalSex:
                {
                    APCTableViewItem *field = [APCTableViewItem new];
                    field.caption = NSLocalizedString(@"Biological Sex", @"");
                    field.identifier = kAPCDefaultTableViewCellIdentifier;
                    field.editable = NO;
                    field.textAlignnment = NSTextAlignmentRight;
                    field.detailText = [APCUser stringValueFromSexType:self.user.biologicalSex];
                    field.selectionStyle = self.isEditing ? UITableViewCellSelectionStyleGray : UITableViewCellSelectionStyleNone;
                    
                    APCTableViewRow *row = [APCTableViewRow new];
                    row.item = field;
                    row.itemType = kAPCUserInfoItemTypeBiologicalSex;
                    [rowItems addObject:row];
                }
                    break;
                    
                    
                case kAPCUserInfoItemTypeDateOfBirth:
                {
                    APCTableViewItem *field = [APCTableViewItem new];
                    field.caption = NSLocalizedString(@"Birthdate", @"");
                    field.identifier = kAPCDefaultTableViewCellIdentifier;
                    field.editable = NO;
                    field.textAlignnment = NSTextAlignmentRight;
                    field.detailText = [self.user.birthDate toStringWithFormat:NSDateDefaultDateFormat];
                    field.selectionStyle = self.isEditing ? UITableViewCellSelectionStyleGray : UITableViewCellSelectionStyleNone;
                    
                    APCTableViewRow *row = [APCTableViewRow new];
                    row.item = field;
                    row.itemType = kAPCUserInfoItemTypeDateOfBirth;
                    [rowItems addObject:row];
                    
                }
                    break;
                    
                case kAPCUserInfoItemTypeCustomSurvey:
                {
                    APCTableViewTextFieldItem *field = [APCTableViewTextFieldItem new];
                    field.textAlignnment = NSTextAlignmentLeft;
                    field.placeholder = NSLocalizedString(@"custom question", @"");
                    field.caption = @"Daily Scale";
                    if (self.user.customSurveyQuestion) {
                        field.value = self.user.customSurveyQuestion;
                    }
                    field.keyboardType = UIKeyboardTypeAlphabet;
                    field.identifier = kAPCTextFieldTableViewCellIdentifier;
                    field.selectionStyle = self.isEditing ? UITableViewCellSelectionStyleGray : UITableViewCellSelectionStyleNone;
                    
                    field.style = UITableViewStylePlain;
                    
                    APCTableViewRow *row = [APCTableViewRow new];
                    row.item = field;
                    row.itemType = kAPCUserInfoItemTypeCustomSurvey;
                    [rowItems addObject:row];

                }
                    break;
                case kAPCUserInfoItemTypeMedicalCondition:
                {
                    APCTableViewCustomPickerItem *field = [APCTableViewCustomPickerItem new];
                    field.caption = NSLocalizedString(@"Medical Conditions", @"");
                    field.pickerData = @[[APCUser medicalConditions]];
                    field.textAlignnment = NSTextAlignmentRight;
                    field.identifier = kAPCDefaultTableViewCellIdentifier;
                    field.selectionStyle = self.isEditing ? UITableViewCellSelectionStyleGray : UITableViewCellSelectionStyleNone;
                    field.editable = NO;
                    
                    if (self.user.medications) {
                        field.selectedRowIndices = @[ @([field.pickerData[0] indexOfObject:self.user.medicalConditions]) ];
                    }
                    else {
                        field.selectedRowIndices = @[ @(0) ];
                    }
                    
                    APCTableViewRow *row = [APCTableViewRow new];
                    row.item = field;
                    row.itemType = kAPCUserInfoItemTypeMedicalCondition;
                    [rowItems addObject:row];
                }
                    
                    break;
                    
                case kAPCUserInfoItemTypeMedication:
                {
                    APCTableViewCustomPickerItem *field = [APCTableViewCustomPickerItem new];
                    field.caption = NSLocalizedString(@"Medications", @"");
                    field.pickerData = @[[APCUser medications]];
                    field.textAlignnment = NSTextAlignmentRight;
                    field.identifier = kAPCDefaultTableViewCellIdentifier;
                    field.selectionStyle = self.isEditing ? UITableViewCellSelectionStyleGray : UITableViewCellSelectionStyleNone;
                    field.editable = NO;
                    
                    if (self.user.medications) {
                        field.selectedRowIndices = @[ @([field.pickerData[0] indexOfObject:self.user.medications]) ];
                    }
                    else {
                        field.selectedRowIndices = @[ @(0) ];
                    }
                    
                    APCTableViewRow *row = [APCTableViewRow new];
                    row.item = field;
                    row.itemType = kAPCUserInfoItemTypeMedication;
                    [rowItems addObject:row];
                }
                    break;
                    
                case kAPCUserInfoItemTypeHeight:
                {

                    APCTableViewCustomPickerItem *field = [APCTableViewCustomPickerItem new];
                    field.caption = NSLocalizedString(@"Height", @"");
                    field.identifier = kAPCDefaultTableViewCellIdentifier;
                    field.detailDiscloserStyle = YES;
                    field.textAlignnment = NSTextAlignmentRight;
                    field.pickerData = [APCUser heights];
                    field.selectionStyle = self.isEditing ? UITableViewCellSelectionStyleGray : UITableViewCellSelectionStyleNone;
                    field.editable = NO;
                    
                    NSInteger defaultIndexOfMyHeightInFeet = 5;
                    NSInteger defaultIndexOfMyHeightInInches = 0;
                    NSInteger indexOfMyHeightInFeet = defaultIndexOfMyHeightInFeet;
                    NSInteger indexOfMyHeightInInches = defaultIndexOfMyHeightInInches;
                    
                    double usersHeight = [APCUser heightInInches:self.user.height];
                    
                    if (usersHeight) {
                        double heightInInches = round(usersHeight);
                        NSString *feet = [NSString stringWithFormat:@"%i'", (int)heightInInches/12];
                        NSString *inches = [NSString stringWithFormat:@"%i''", (int)heightInInches%12];
                        
                        NSArray *allPossibleHeightsInFeet = field.pickerData [0];
                        NSArray *allPossibleHeightsInInches = field.pickerData [1];
                        
                        indexOfMyHeightInFeet = [allPossibleHeightsInFeet indexOfObject: feet];
                        indexOfMyHeightInInches = [allPossibleHeightsInInches indexOfObject: inches];
                        
                        if (indexOfMyHeightInFeet == NSNotFound)
                        {
                            indexOfMyHeightInFeet = defaultIndexOfMyHeightInFeet;
                        }
                        
                        if (indexOfMyHeightInInches == NSNotFound)
                        {
                            indexOfMyHeightInInches = defaultIndexOfMyHeightInInches;
                        }
                        
                        field.selectedRowIndices = @[ @(indexOfMyHeightInFeet), @(indexOfMyHeightInInches) ];

                    }
                    
                    APCTableViewRow *row = [APCTableViewRow new];
                    row.item = field;
                    row.itemType = kAPCUserInfoItemTypeHeight;
                    [rowItems addObject:row];
                }
                    break;
                    
                case kAPCUserInfoItemTypeWeight:
                {
                    APCTableViewTextFieldItem *field = [APCTableViewTextFieldItem new];
                    field.caption = NSLocalizedString(@"Weight", @"");
                    field.placeholder = NSLocalizedString(@"add weight (lb)", @"");
                    field.regularExpression = kAPCMedicalInfoItemWeightRegEx;
                    
                    double userWeight = [APCUser weightInPounds:self.user.weight];
                    
                    if (userWeight) {
                        field.value = [NSString stringWithFormat:@"%.0f", userWeight];
                    }
                    
                    field.keyboardType = UIKeyboardTypeDecimalPad;
                    field.textAlignnment = NSTextAlignmentRight;
                    field.identifier = kAPCTextFieldTableViewCellIdentifier;
                    field.selectionStyle = self.isEditing ? UITableViewCellSelectionStyleGray : UITableViewCellSelectionStyleNone;
                    
                    APCTableViewRow *row = [APCTableViewRow new];
                    row.item = field;
                    row.itemType = kAPCUserInfoItemTypeWeight;
                    [rowItems addObject:row];
                }
                    break;
                    
                case kAPCUserInfoItemTypeWakeUpTime:
                {
                    APCTableViewDatePickerItem *field = [APCTableViewDatePickerItem new];
                    field.style = UITableViewCellStyleValue1;
                    field.caption = NSLocalizedString(@"What time do you generally wake up?", @"");
                    field.placeholder = NSLocalizedString(@"7:00 AM", @"");
                    field.identifier = kAPCDefaultTableViewCellIdentifier;
                    field.datePickerMode = UIDatePickerModeTime;
                    field.dateFormat = kAPCMedicalInfoItemSleepTimeFormat;
                    field.textAlignnment = NSTextAlignmentRight;
                    field.detailDiscloserStyle = YES;
                    field.selectionStyle = self.isEditing ? UITableViewCellSelectionStyleGray : UITableViewCellSelectionStyleNone;
                    field.editable = NO;
                    
                    if (self.user.wakeUpTime) {
                        field.date = self.user.wakeUpTime;
                        field.detailText = [field.date toStringWithFormat:kAPCMedicalInfoItemSleepTimeFormat];
                    }
                    
                    APCTableViewRow *row = [APCTableViewRow new];
                    row.item = field;
                    row.itemType = kAPCUserInfoItemTypeWakeUpTime;
                    [rowItems addObject:row];
                }
                    break;
                    
                case kAPCUserInfoItemTypeSleepTime:
                {
                    APCTableViewDatePickerItem *field = [APCTableViewDatePickerItem new];
                    field.style = UITableViewCellStyleValue1;
                    field.caption = NSLocalizedString(@"What time do you generally go to sleep?", @"");
                    field.placeholder = NSLocalizedString(@"9:30 PM", @"");
                    field.identifier = kAPCDefaultTableViewCellIdentifier;
                    field.datePickerMode = UIDatePickerModeTime;
                    field.dateFormat = kAPCMedicalInfoItemSleepTimeFormat;
                    field.textAlignnment = NSTextAlignmentRight;
                    field.detailDiscloserStyle = YES;
                    field.selectionStyle = self.isEditing ? UITableViewCellSelectionStyleGray : UITableViewCellSelectionStyleNone;
                    field.editable = NO;
                    
                    if (self.user.sleepTime) {
                        field.date = self.user.sleepTime;
                        field.detailText = [field.date toStringWithFormat:kAPCMedicalInfoItemSleepTimeFormat];
                    }
                    
                    APCTableViewRow *row = [APCTableViewRow new];
                    row.item = field;
                    row.itemType = kAPCUserInfoItemTypeSleepTime;
                    [rowItems addObject:row];
                }
                    break;
                default:
                    break;
            }
        }
        APCTableViewSection *section = [APCTableViewSection new];
        section.rows = [NSArray arrayWithArray:rowItems];
        [items addObject:section];
    }
    
    /*
     Share is disabled for now.
    {
        NSMutableArray *rowItems = [NSMutableArray new];
        
        {
            APCTableViewItem *field = [APCTableViewItem new];
            field.caption = NSLocalizedString(@"Share this Study", @"");
            field.identifier = kAPCDefaultTableViewCellIdentifier;
            field.editable = YES;
            
            APCTableViewRow *row = [APCTableViewRow new];
            row.item = field;
            row.itemType = kAPCTableViewStudyItemTypeShare;
            [rowItems addObject:row];
        }
        
        APCTableViewSection *section = [APCTableViewSection new];
        section.rows = [NSArray arrayWithArray:rowItems];
        section.sectionTitle = NSLocalizedString(@"Help us Spread the Word", @"");
        [items addObject:section];
    }
    */
    
    
     {
     NSMutableArray *rowItems = [NSMutableArray new];
     
     {
         APCTableViewItem *field = [APCTableViewItem new];
         field.caption = NSLocalizedString(@"Activity Reminders", @"");
         field.identifier = kAPCDefaultTableViewCellIdentifier;
         field.editable = NO;
         field.showChevron = YES;
         field.selectionStyle = self.isEditing ? UITableViewCellSelectionStyleNone : UITableViewCellSelectionStyleGray;
         
         APCTableViewRow *row = [APCTableViewRow new];
         row.item = field;
         row.itemType = kAPCSettingsItemTypeReminderOnOff;
         [rowItems addObject:row];
         
         APCTableViewItem *medReminderField = [APCTableViewItem new];
         medReminderField.caption = NSLocalizedString(@"Medication Reminders", @"");
         medReminderField.identifier = kAPCDefaultTableViewCellIdentifier;
         medReminderField.editable = NO;
         medReminderField.showChevron = YES;
         medReminderField.selectionStyle = self.isEditing ? UITableViewCellSelectionStyleNone : UITableViewCellSelectionStyleGray;
         
         APCTableViewRow *medReminderRow = [APCTableViewRow new];
         medReminderRow.item = medReminderField;
         medReminderRow.itemType = kAPCSettingsItemTypeMedReminderOnOff;
         [rowItems addObject:medReminderRow];
     }


     APCTableViewSection *section = [APCTableViewSection new];

     section.rows = [NSArray arrayWithArray:rowItems];
     [items addObject:section];
     }
    
    {
        NSMutableArray *rowItems = [NSMutableArray new];
        
        {
            APCTableViewCustomPickerItem *field = [APCTableViewCustomPickerItem new];
            field.identifier = kAPCDefaultTableViewCellIdentifier;
            field.selectionStyle = self.isEditing ? UITableViewCellSelectionStyleGray : UITableViewCellSelectionStyleNone;
            field.caption = NSLocalizedString(@"Auto-Lock", @"");
            field.detailDiscloserStyle = YES;
            field.textAlignnment = NSTextAlignmentRight;
            field.pickerData = @[[APCProfileViewController autoLockOptionStrings]];
            field.editable = YES;
            field.selectionStyle = UITableViewCellSelectionStyleGray;
            
            NSNumber *numberOfMinutes = [[NSUserDefaults standardUserDefaults] objectForKey:kNumberOfMinutesForPasscodeKey];
            
            if ( numberOfMinutes != nil)
            {
                NSInteger index = [[APCProfileViewController autoLockValues] indexOfObject:numberOfMinutes];
                field.selectedRowIndices = @[@(index)];
            }

            APCTableViewRow *row = [APCTableViewRow new];
            row.item = field;
            row.itemType = kAPCSettingsItemTypeAutoLock;
            [rowItems addObject:row];
        }
        
        {
            APCTableViewItem *field = [APCTableViewItem new];
            field.caption = NSLocalizedString(@"Change Passcode", @"");
            field.identifier = kAPCDefaultTableViewCellIdentifier;
            field.textAlignnment = NSTextAlignmentLeft;
            field.editable = NO;
            field.selectionStyle = UITableViewCellSelectionStyleGray;
            
            APCTableViewRow *row = [APCTableViewRow new];
            row.item = field;
            row.itemType = kAPCSettingsItemTypePasscode;
            [rowItems addObject:row];
        }
        
        if (self.user.sharedOptionSelection != [NSNumber numberWithInteger:SBBConsentShareScopeNone])
        {
            APCTableViewItem *field = [APCTableViewItem new];
            field.caption = NSLocalizedString(@"Sharing Options", @"");
            field.identifier = kAPCDefaultTableViewCellIdentifier;
            field.textAlignnment = NSTextAlignmentLeft;
            field.editable = NO;
            field.selectionStyle = UITableViewCellSelectionStyleGray;
            
            APCTableViewRow *row = [APCTableViewRow new];
            row.item = field;
            row.itemType = kAPCSettingsItemTypeSharingOptions;
            [rowItems addObject:row];
        }
        
        APCTableViewSection *section = [APCTableViewSection new];
        section.rows = [NSArray arrayWithArray:rowItems];
        [items addObject:section];
    }

    {
        NSMutableArray *rowItems = [NSMutableArray new];
        
        {
            APCTableViewItem *field = [APCTableViewItem new];
            field.caption = NSLocalizedString(@"Permissions", @"");
            field.identifier = kAPCDefaultTableViewCellIdentifier;
            field.textAlignnment = NSTextAlignmentRight;
            field.editable = NO;
            field.showChevron = YES;
            field.selectionStyle = UITableViewCellSelectionStyleGray;
            
            APCTableViewRow *row = [APCTableViewRow new];
            row.item = field;
            row.itemType = kAPCSettingsItemTypePermissions;
            [rowItems addObject:row];
        }
        
        {
            APCTableViewItem *field = [APCTableViewItem new];
            field.caption = NSLocalizedString(@"Review Consent", @"");
            field.identifier = kAPCDefaultTableViewCellIdentifier;
            field.textAlignnment = NSTextAlignmentRight;
            field.editable = NO;
            field.selectionStyle = UITableViewCellSelectionStyleGray;
            
            APCTableViewRow *row = [APCTableViewRow new];
            row.item = field;
            row.itemType = kAPCUserInfoItemTypeReviewConsent;
            [rowItems addObject:row];
        }
        
        {
            APCTableViewItem *field = [APCTableViewItem new];
            field.caption = NSLocalizedString(@"Export Data", @"");
            field.identifier = kAPCDefaultTableViewCellIdentifier;
            field.textAlignnment = NSTextAlignmentRight;
            field.editable = NO;
            field.selectionStyle = UITableViewCellSelectionStyleGray;
            
            APCTableViewRow *row = [APCTableViewRow new];
            row.item = field;
            row.itemType = kAPCSettingsItemTypeExportData;
            [rowItems addObject:row];
        }
        
        APCTableViewSection *section = [APCTableViewSection new];
        section.rows = [NSArray arrayWithArray:rowItems];
        section.sectionTitle = @"";
        [items addObject:section];
    }
    
    {
        NSMutableArray *rowItems = [NSMutableArray new];
        
        {
            APCTableViewItem *field = [APCTableViewItem new];
            field.caption = NSLocalizedString(@"Privacy Policy", @"");
            field.identifier = kAPCDefaultTableViewCellIdentifier;
            field.textAlignnment = NSTextAlignmentRight;
            field.editable = NO;
            field.selectionStyle = UITableViewCellSelectionStyleGray;
            
            APCTableViewRow *row = [APCTableViewRow new];
            row.item = field;
            row.itemType = kAPCSettingsItemTypePrivacyPolicy;
            [rowItems addObject:row];
        }
        
        {
            APCTableViewItem *field = [APCTableViewItem new];
            field.caption = NSLocalizedString(@"License Information", @"");
            field.identifier = kAPCDefaultTableViewCellIdentifier;
            field.textAlignnment = NSTextAlignmentRight;
            field.editable = NO;
            field.showChevron = YES;
            field.selectionStyle = UITableViewCellSelectionStyleGray;
            
            APCTableViewRow *row = [APCTableViewRow new];
            row.item = field;
            row.itemType = kAPCSettingsItemTypeLicenseInformation;
            [rowItems addObject:row];
        }
        
        APCTableViewSection *section = [APCTableViewSection new];
        section.rows = [NSArray arrayWithArray:rowItems];
        section.sectionTitle = @"";
        [items addObject:section];
    }
    
    {
        NSMutableArray *rowItems = [NSMutableArray new];
        
        {
            APCTableViewItem *field = [APCTableViewItem new];
            field.caption = NSLocalizedString(@"23andMe", nil);
            field.identifier = kAPCDefaultTableViewCellIdentifier;
            field.textAlignnment = NSTextAlignmentRight;
            field.editable = NO;
            field.selectionStyle = UITableViewCellSelectionStyleGray;
            
            APCTableViewRow *row = [APCTableViewRow new];
            row.item = field;
            row.itemType = kAPCSettingsItemType23andMe;
            [rowItems addObject:row];
        }
        
        APCTableViewSection *section = [APCTableViewSection new];
        section.rows = [NSArray arrayWithArray:rowItems];
        section.sectionTitle = @"";
        [items addObject:section];
    }

    NSArray *newArray = nil;
    if ([self.delegate respondsToSelector:@selector(preparedContent:)])
    {
        newArray = [self.delegate preparedContent:[NSArray arrayWithArray:items]];
    }
    
    return newArray ? newArray : [NSArray arrayWithArray:items];
}

- (void)setupSwitchCellAppearance:(APCSwitchTableViewCell *)cell
{
    [super setupSwitchCellAppearance:cell];
}

/*********************************************************************************/
#pragma mark - Switch Cell Delegate
/*********************************************************************************/

- (void)switchTableViewCell:(APCSwitchTableViewCell *)cell switchValueChanged:(BOOL)on
{
    [super switchTableViewCell:cell switchValueChanged:on];
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if ((NSUInteger)indexPath.section < self.items.count) {
        APCTableViewItemType type = [self itemTypeForIndexPath:indexPath];

        switch (type) {
            case kAPCSettingsItemTypeReminderOnOff:
            {
                if (!self.isEditing){
                    APHSettingsViewController *remindersTableViewController = [[UIStoryboard storyboardWithName:@"APHProfile" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"APHSettingsViewController"];
                    
                    remindersTableViewController.isMedReminder = NO;
                    
                    [self.navigationController pushViewController:remindersTableViewController animated:YES];
                    return;
                }
                
            }
                break;
            case kAPCSettingsItemTypeMedReminderOnOff:
            {
                if (!self.isEditing){
                    APHSettingsViewController *remindersTableViewController = [[UIStoryboard storyboardWithName:@"APHProfile" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"APHSettingsViewController"];
                    
                    remindersTableViewController.isMedReminder = YES;
                    
                    [self.navigationController pushViewController:remindersTableViewController animated:YES];
                    return;
                }
                
            }
                break;
            case kAPCSettingsItemType23andMe:
            {
                if (!self.isEditing){
                    [self show23andMe];
                }
            }
                break;
        }
    }
    
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
}

#pragma mark - 23andMe

- (void)show23andMe {
    UITableViewController *profile23andMeController = [[UIStoryboard storyboardWithName:@"APHProfile" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"APHTwentyThreeAndMeProfileTableViewController"];
    
    [self.navigationController pushViewController:profile23andMeController animated:YES];
}

@end
