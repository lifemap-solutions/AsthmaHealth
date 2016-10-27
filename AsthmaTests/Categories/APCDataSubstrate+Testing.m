//
//  APCDataSubstrate+Testing.m
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

#import "APCDataSubstrate+Testing.h"

@implementation APCDataSubstrate (Testing)

@dynamic dateChangeTestTimer, lastKnownDate, countOfTotalRequiredTasksForToday, countOfTotalCompletedTasksForToday;

- (instancetype)initWithInMemoryPersistentStore {
    return [self initWithInMemoryPersistentStoreAndUser:nil];
}

- (instancetype)initWithInMemoryPersistentStoreAndUser:(APCUser *)user {
    
    self = [super init];
    if (!self) return nil;
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    
    self.dateChangeTestTimer = nil;
    self.lastKnownDate = [NSDate date];
    self.countOfTotalCompletedTasksForToday = 0;
    self.countOfTotalCompletedTasksForToday = 0;
    
    // set up Core Data stack
    [self performSelector:@selector(loadManagedObjectModel:) withObject:nil];
    //initializePersistentStoreCoordinator
    self.persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
    NSError *error = nil;
    [self.persistentStoreCoordinator addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:&error];
    NSAssert(!error, [error localizedDescription]);
    [self performSelector:@selector(createManagedObjectContexts)];
    
    if (user) {
        self.currentUser = user;
    } else {
        [self performSelector:@selector(setUpCurrentUser:) withObject:self.persistentContext];
    }
    [self setUpHealthKit];
    [self performSelector:@selector(setupParameters)];
    [self performSelector:@selector(setupNotifications)];
    [self performSelector:@selector(setupNewsFeedManager)];
    
#pragma clang diagnostic pop
    
    return self;
}

@end
