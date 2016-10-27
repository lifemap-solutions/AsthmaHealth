//
//  APCTaskGroupCacheEntry.h
//  APCAppCore
//
//  Copyright (c) 2015, Apple Inc. All rights reserved. 
//  
//  Redistribution and use in source and binary forms, with or without modification,
//  are permitted provided that the following conditions are met:
//  
//  1.  Redistributions of source code must retain the above copyright notice, this
//  list of conditions and the following disclaimer.
//  
//  2.  Redistributions in binary form must reproduce the above copyright notice, 
//  this list of conditions and the following disclaimer in the documentation and/or 
//  other materials provided with the distribution. 
//  
//  3.  Neither the name of the copyright holder(s) nor the names of any contributors 
//  may be used to endorse or promote products derived from this software without 
//  specific prior written permission. No license is granted to the trademarks of 
//  the copyright holders even if such marks are included in this software. 
//  
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
//  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE 
//  FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL 
//  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR 
//  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
//  CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, 
//  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE 
//  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. 
//

#import <Foundation/Foundation.h>



/**
 Caches the taskGroups retrieved from CoreData for a
 specific date range and filter.

 We need this because our main way of delivering lists of
 tasks to the UI involves walking through the list of
 active Schedules, and asking each schedule for the dates
 and times its tasks should appear.  At the lowest levels
 of these calls, some operations are invoked tens of
 thousands of times.  This cache means we only need to
 perform those operations a dozen times or so.  The cache
 is cleared when new schedules are retrieved from the
 server, loaded from disk, computed, or otherwise
 generated, as long as the call goes through our central
 -processSchedulesAndTasks method.
 */
@interface APCTaskGroupCacheEntry : NSObject

@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) NSPredicate *taskFilter;
@property (nonatomic, strong) NSArray *taskGroups;

- (instancetype) initWithDate: (NSDate *) date
                   taskFilter: (NSPredicate *) taskFilter
                   taskGroups: (NSArray *) taskGroups;

@end
