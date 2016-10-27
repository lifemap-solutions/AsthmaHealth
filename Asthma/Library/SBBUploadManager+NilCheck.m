//
//  SBBUploadManager+NilCheck.m
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

#import "SBBUploadManager+NilCheck.h"
#import "NSObject+APHSwizzle.h"
#import <APCAppCore/APCLog.h>



@interface SBBUploadManager (Private)
- (void)setUploadRequestJSON:(id)json forFile:(NSString *)fileURLString;
- (void)setUploadSessionJSON:(id)json forFile:(NSString *)fileURLString;
@end



@implementation SBBUploadManager (NilCheck)

+ (void)load {
    [super load];

    [self swizzleInstanceMethod:@selector(setUploadRequestJSON:forFile:) withMethod:@selector(swizzledSetUploadRequestJSON:forFile:)];
    [self swizzleInstanceMethod:@selector(setUploadSessionJSON:forFile:) withMethod:@selector(swizzledSetUploadSessionJSON:forFile:)];
}

- (void)swizzledSetUploadRequestJSON:(id)json forFile:(NSString *)fileURLString {
    if (!fileURLString) {
        NSError *error = [NSError errorWithDomain:SBB_ERROR_DOMAIN
                                             code:kSBBUnknownError
                                         userInfo:@{NSLocalizedDescriptionKey: @"Trying to set upload request for nil file"}];
        APCLogError2(error);
        return;
    }

    [self swizzledSetUploadRequestJSON:json forFile:fileURLString];
}


- (void)swizzledSetUploadSessionJSON:(id)json forFile:(NSString *)fileURLString {
    if (!fileURLString) {
        NSError *error = [NSError errorWithDomain:SBB_ERROR_DOMAIN
                                             code:kSBBUnknownError
                                         userInfo:@{NSLocalizedDescriptionKey: @"Trying to set upload request for nil file"}];
        APCLogError2(error);
        return;
    }

    [self swizzledSetUploadSessionJSON:json forFile:fileURLString];
}

@end
