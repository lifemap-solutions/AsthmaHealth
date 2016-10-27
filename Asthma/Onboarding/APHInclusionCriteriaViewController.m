// 
//  APHInclusionCriteriaViewController.m 
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
 


#import "APHInclusionCriteriaViewController.h"
#import "APHAppDelegate.h"
#import "APHCountryBasedConfig.h"

static float kCountryFontSize = 38.0f;

@interface APHInclusionCriteriaViewController () <APCSegmentedButtonDelegate, UIPickerViewDataSource, UIPickerViewDelegate>

//Outlets
@property (weak, nonatomic) IBOutlet UILabel *question1Label;   //Are you over 18?
@property (weak, nonatomic) IBOutlet UIButton *question1Option1;
@property (weak, nonatomic) IBOutlet UIButton *question1Option2;

@property (weak, nonatomic) IBOutlet UILabel *question2Label;   //Do you have asthma as confirmed by doc?
@property (weak, nonatomic) IBOutlet UIButton *question2Option1;
@property (weak, nonatomic) IBOutlet UIButton *question2Option2;

@property (weak, nonatomic) IBOutlet UILabel *question4Label; //Please select country you live in.

@property (weak, nonatomic) IBOutlet UILabel *question5Label; //Are you pregnant?
@property (weak, nonatomic) IBOutlet UIButton *question5Option1;
@property (weak, nonatomic) IBOutlet UIButton *question5Option2;
@property (weak, nonatomic) IBOutlet UIButton *question5Option3;



//Properties
@property (nonatomic, strong) NSArray * questions; //Of APCSegmentedButtons
@property (nonatomic, strong) NSString * selectedCountry;
@property (nonatomic, strong) NSArray * countries;

@end

@implementation APHInclusionCriteriaViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.selectedCountry = @"";
    self.countries = @[
                       @{@"label": @"Choose", @"value": @""},
                       @{@"label": @"United States", @"value": @"US"},
                       @{@"label": @"United Kingdom", @"value": @"UK"},
                       @{@"label": @"Ireland", @"value": @"IE"},
                       @{@"label": @"Other", @"value": @"OT"}];
    
    self.questions = @[
                       
                        [[APCSegmentedButton alloc] initWithButtons:@[self.question1Option1, self.question1Option2] normalColor:[UIColor appSecondaryColor3] highlightColor:[UIColor appPrimaryColor]],
                                              
                       [[APCSegmentedButton alloc] initWithButtons:@[self.question2Option1, self.question2Option2] normalColor:[UIColor appSecondaryColor3] highlightColor:[UIColor appPrimaryColor]],
                       
                       [[APCSegmentedButton alloc] initWithButtons:@[self.question5Option1, self.question5Option2, self.question5Option3] normalColor:[UIColor appSecondaryColor3] highlightColor:[UIColor appPrimaryColor]],
                       
                       ];
    [self.questions enumerateObjectsUsingBlock:^(APCSegmentedButton * obj, NSUInteger __unused idx, BOOL __unused *stop) {
        obj.delegate = self;
    }];
    [self setUpAppearance];
    
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    APCLogEventWithData(kAnalyticsEligibilityTest, (@{}));
}

- (void) setUpAppearance
{
    
    self.question1Label.textColor = [UIColor appSecondaryColor1];
    self.question1Label.font = [UIFont appQuestionLabelFont];
    
    self.question2Label.textColor = [UIColor appSecondaryColor1];
    self.question2Label.font = [UIFont appQuestionLabelFont];

    self.question4Label.textColor = [UIColor appSecondaryColor1];
    self.question4Label.font = [UIFont appQuestionLabelFont];

    self.question5Label.textColor = [UIColor appSecondaryColor1];
    self.question5Label.font = [UIFont appQuestionLabelFont];

    [self.question1Option1.titleLabel setFont:[UIFont appQuestionOptionFont]];
    [self.question1Option2.titleLabel setFont:[UIFont appQuestionOptionFont]];
    
    [self.question2Option1.titleLabel setFont:[UIFont appQuestionOptionFont]];
    [self.question2Option2.titleLabel setFont:[UIFont appQuestionOptionFont]];

    [self.question5Option1.titleLabel setFont:[UIFont appQuestionOptionFont]];
    [self.question5Option2.titleLabel setFont:[UIFont appQuestionOptionFont]];
    [self.question5Option3.titleLabel setFont:[UIFont appQuestionOptionFont]];
    
    self.question5Option3.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.question5Option3.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.question5Option3.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.question5Option3.titleLabel.minimumScaleFactor = 0.6;
    self.question5Option3.titleLabel.numberOfLines = 2;
    [self.question5Option3 setTitle:NSLocalizedString(@"N/A", @"Question Option") forState:UIControlStateNormal];
    
}
-(NSInteger)pickerView:(UIPickerView *)__unused pickerView numberOfRowsInComponent:(NSInteger)__unused component {
    return self.countries.count;
}
-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)__unused pickerView {
    return 1;
}
-(CGFloat)pickerView:(UIPickerView *)__unused pickerView rowHeightForComponent:(NSInteger)__unused component {
    return 50;
}

-(void)pickerView:(UIPickerView *)__unused pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)__unused component {
    NSDictionary *item = [self.countries objectAtIndex:row];
    self.selectedCountry = [item objectForKey:@"value"];
}

-(UIView *)pickerView:(UIPickerView *)__unused pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)__unused component reusingView:(UIView *)view {
    
    UILabel* pickerLabel = (UILabel*)view;
    
    if (!pickerLabel)
    {
        pickerLabel = [[UILabel alloc] init];
        
        pickerLabel.font = [UIFont appRegularFontWithSize:kCountryFontSize];
        pickerLabel.textColor = [UIColor appPrimaryColor];
        
        pickerLabel.textAlignment=NSTextAlignmentCenter;
    }
    NSDictionary *item = [self.countries objectAtIndex:row];
    [pickerLabel setText: [item objectForKey:@"label"]];
    
    return pickerLabel;
}

- (APCOnboarding *)onboarding
{
    return ((APHAppDelegate *)[UIApplication sharedApplication].delegate).onboarding;
}

-(CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

/*********************************************************************************/
#pragma mark - Misc Fix
/*********************************************************************************/
-(void)viewDidLayoutSubviews
{
    [self.tableView setSeparatorInset:UIEdgeInsetsZero];
    [self.tableView setLayoutMargins:UIEdgeInsetsZero];
}

-(void)tableView:(UITableView *)__unused tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)__unused indexPath
{
    [cell setSeparatorInset:UIEdgeInsetsZero];
    [cell setLayoutMargins:UIEdgeInsetsZero];
}

/*********************************************************************************/
#pragma mark - Segmented Button Delegate
/*********************************************************************************/
- (void)segmentedButtonPressed:(UIButton *)__unused button selectedIndex:(NSInteger)__unused selectedIndex
{
    self.navigationItem.rightBarButtonItem.enabled = [self isContentValid];
}

/*********************************************************************************/
#pragma mark - Overridden methods
/*********************************************************************************/

- (void)next
{
    [self onboarding].onboardingTask.eligible = [self isEligible];
    
    UIViewController *viewController = [[self onboarding] nextScene];
    [self.navigationController pushViewController:viewController animated:YES];
}



- (BOOL) isEligible
{
    BOOL retValue = NO;
    
    APCSegmentedButton *over18 = self.questions[0];
    APCSegmentedButton *hasAsthma = self.questions[1];
    APCSegmentedButton *pregnancy = self.questions[2];
    
    if (
        (over18.selectedIndex == 0) &&
        (hasAsthma.selectedIndex == 0) &&
        (pregnancy.selectedIndex != 0) &&
        ((![self.selectedCountry isEqualToString:@""]) && (![self.selectedCountry isEqualToString:@"OT"]))) {
            [self updateSelectedCountry];
            retValue = YES;
    }

    return retValue;
}
- (void)updateSelectedCountry {
    [self onboarding].onboardingTask.user.country = self.selectedCountry;
}

- (BOOL)isContentValid
{
    __block BOOL retValue = YES;
    [self.questions enumerateObjectsUsingBlock:^(APCSegmentedButton* obj, NSUInteger __unused idx, BOOL *stop) {
        if (obj.selectedIndex == -1) {
            retValue = NO;
            *stop = YES;
        }
    }];
    
    return retValue;
}

@end
