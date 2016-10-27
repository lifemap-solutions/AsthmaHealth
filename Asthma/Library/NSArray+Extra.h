//
//  NSArray+Extra.h
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

#import <Foundation/Foundation.h>



typedef BOOL(^NSArrayFilterBlock)(id _Nonnull item);
typedef id _Nullable(^NSArrayInjectBlock)(id _Nullable memo, id _Nonnull item);
typedef id _Nonnull(^NSArrayMapBlock)(id _Nonnull item);
typedef id _Nonnull(^NSArrayComputationBlock)(id _Nonnull item);



///
@interface NSArray (Extra)


/// Returns an array containing all elements for which the given block returns a true value.
- (NSArray * _Nonnull)filterWithBlock:(NSArrayFilterBlock _Nonnull)block;

/// Returns a new array with the results of running block once for every element in array.
- (NSArray * _Nonnull)mapWithBlock:(NSArrayMapBlock _Nonnull)block;

/// Combines all elements of array by applying a operation specified by a block.
- (id _Nullable)inject:(id _Nullable)initialValue withBlock:(NSArrayInjectBlock _Nonnull)block;

@end
