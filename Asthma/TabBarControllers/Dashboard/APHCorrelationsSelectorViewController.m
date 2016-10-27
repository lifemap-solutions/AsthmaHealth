//
//  APHCorrelationsSelectorViewController.m
//  Asthma
//

#import "APHCorrelationsSelectorViewController.h"
#import "APHScoring.h"

@interface APHCorrelationsSelectorViewController ()
@property (weak, nonatomic) APCScoring *series1SelectedObject;
@property (weak, nonatomic) APCScoring *series2SelectedObject;
@property (assign, nonatomic) BOOL section0Selected;
@property (strong, nonatomic) APHScoring *scoring;
@property (strong, nonatomic) NSArray *scoringObjects;
@end

@implementation APHCorrelationsSelectorViewController

@dynamic series1SelectedObject;
@dynamic series2SelectedObject;
@dynamic section0Selected;
@dynamic scoringObjects;
@dynamic scoring;
@dynamic delegate;

- (id)initWithScoringObjects:(NSArray *)scoringObjects
            withSelectedObj1:(APCScoring *)selectedObj1
             andSelectedObj2:(APCScoring*)selectedObj2{
    
    self = [super initWithScoringObjects:scoringObjects];
    
    self.series1SelectedObject = selectedObj1;
    self.series2SelectedObject = selectedObj2;
    
    return self;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    
    APCScoring *scoring = self.scoringObjects[indexPath.row];
    [cell setAccessoryType:UITableViewCellAccessoryNone];
    
    switch (self.seriesNumber) {
        case 1:
            if ([scoring.caption isEqualToString:self.series1SelectedObject.caption]){
                [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
            }
            break;
            
        case 2:
            if ([scoring.caption isEqualToString:self.series2SelectedObject.caption]){
                [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
            }
            break;
        default:
            [cell setAccessoryType:UITableViewCellAccessoryNone];
            break;
    }

    return cell;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)__unused tableView
{
    return 1;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    APCScoring *referenceScoring = [self.scoringObjects objectAtIndex:indexPath.row];
    [self updateSelectedScoringObject:referenceScoring];
    
    [tableView reloadData];
}

- (UIView *)tableView:(UITableView *)__unused tableView viewForHeaderInSection:(NSInteger) __unused section
{
    NSString *headerTitle = [NSString stringWithFormat:@"Select Series %lu", self.seriesNumber];
    UITableViewHeaderFooterView *headerView = [[UITableViewHeaderFooterView alloc]init];
    headerView.textLabel.text = NSLocalizedString(headerTitle, nil);
    
    return headerView;
}

-(void)updateSelectedScoringObject:(APCScoring *)selectedObject{
    if (self.seriesNumber == 1) {
        self.series1SelectedObject = selectedObject;
    }else if (self.seriesNumber == 2){
        self.series2SelectedObject = selectedObject;
    }
    
    [self setSeriesScoringObject];
    
    if ([self.delegate respondsToSelector:@selector(viewController:didChangeCorrelatedScoringDataSource:)]) {
        [self.delegate viewController:self didChangeCorrelatedScoringDataSource:self.scoring];
    }
}

-(void)setSeriesScoringObject
{
    APCScoring *series1 = self.series1SelectedObject;
    APCScoring *series2 = self.series2SelectedObject;
    
    if (series1.quantityType) {
        //HK Data initializer
        self.scoring = [[APHScoring alloc] initWithHealthKitQuantityType:series1.quantityType unit:series1.unit numberOfDays:-kNumberOfDaysToDisplay];
        
    }else{
        //Task type initializer
        self.scoring = [[APHScoring alloc]initWithTask:series1.taskId numberOfDays:-kNumberOfDaysToDisplay valueKey:series1.valueKey];
    }
    
    self.scoring.seriesObject1 = self.series1SelectedObject;
    self.scoring.seriesObject2 = self.series2SelectedObject;
    
    self.scoring.series1Name = series1.caption;
    self.scoring.series2Name = series2.caption;
    
    [self.scoring correlateWithScoringObject:series2];
}

-(void)dismiss{
    [self dismissViewControllerAnimated:true completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
