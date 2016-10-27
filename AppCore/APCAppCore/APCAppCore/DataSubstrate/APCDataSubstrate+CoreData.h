// 
//  APCDataSubstrate+CoreData.h 
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

@interface APCDataSubstrate (CoreData)

/*********************************************************************************/
#pragma mark - Core Data Public Methods
/*********************************************************************************/

- (void) resetCoreData; //EXERCISE CAUTION IN CALLING THIS METHOD



/*********************************************************************************/
#pragma mark - Helpers - ONLY RETURNS IN NSManagedObjects in mainContext
/*********************************************************************************/

/**
 Former name for -countOfTotalRequiredTasksForToday.
 Please use that method instead.

 This method used to run a CoreData query which counted
 today's total (completed + uncompleted) tasks.  The
 replacement method, in contrast, simply tracks the most
 recent stuff appearing on the Activities screen, which
 was the point.
 */
- (NSUInteger) countOfAllScheduledTasksForToday  __attribute__((deprecated("Please use -countOfTotalRequiredTasksForToday instead.")));

/**
 Former name for -countOfTotalCompletedTasksForToday.
 Please use that method instead.
 
 This method used to run a CoreData query which counted
 today's completed tasks.  The replacement method, in
 contrast, simply tracks the most recent stuff appearing
 on the Activities screen, which was the point.
 */
- (NSUInteger) countOfCompletedScheduledTasksForToday  __attribute__((deprecated("Please use -countOfTotalCompletedTasksForToday instead.")));


/*********************************************************************************/
#pragma mark - Methods meant only for Categories
/*********************************************************************************/
- (void) setUpCoreDataStackWithPersistentStorePath:(NSString*) storePath additionalModels: (NSManagedObjectModel*) mergedModels;

@end
