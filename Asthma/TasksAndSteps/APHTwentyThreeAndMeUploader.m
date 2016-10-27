//
//  APHTwentyThreeAndMeUploader.m
//  Asthma
//
// Copyright (c) 2016, Icahn School of Medicine at Mount Sinai. All rights reserved.
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

#import "APHTwentyThreeAndMeUploader.h"
#import "APHLocationBasedDataModel.h"
#import "APHTwentyThreeAndMeClient.h"
@import APCAppCore;

NSString *const kUploadReference     = @"23andmeData";
NSString *const kUserDetailsFileName = @"UserDetails";
NSString *const kGenomeFileName      = @"Genome";

@implementation APHTwentyThreeAndMeUploader

+(void) upload:(NSURLSessionDownloadTask*) downloadTask fromLocation: (NSURL*) location {
    
    NSHTTPURLResponse *httpResp = (NSHTTPURLResponse*) downloadTask.response;
    BOOL fileExist = [[NSFileManager defaultManager] fileExistsAtPath:[location path]];
    
    if (fileExist) {
        
        NSError *error;
        NSString *content = [NSString stringWithContentsOfFile:[location path] encoding:NSUTF8StringEncoding error:&error];
        NSData *data = [content dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *dictContent = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
        [[NSFileManager defaultManager] removeItemAtPath:[location path] error:nil];
        
        if (error) {
            [APHTwentyThreeAndMeClient logError:error forLocation:@"ReadingGenomeFile"];
            return;
        }
        
        
        if (httpResp.statusCode == 200 && [dictContent valueForKey:@"genome"]) {
            
            APCDataUploader *uploader = [[APCDataUploader alloc] initWithUploadReference:kUploadReference];
            [uploader insertIntoZipArchive:[APHTwentyThreeAndMeUploader buildUserDetails:[downloadTask taskDescription]] filename:kUserDetailsFileName];
            
            NSError * encryptionError;
            NSData *encryptedData = cmsEncrypt(data, [APHLocationBasedDataModel pemPath], &encryptionError);
            
            if (encryptionError) {
                [APHTwentyThreeAndMeClient logError:error forLocation:@"EncryptingGenomeData"];
            } else {
                [uploader insertJSONDataIntoZipArchive:encryptedData filename:kGenomeFileName];
            }
            
            
            NSDate * uploadGenomeStart = [NSDate date];
            [uploader uploadWithCompletion:^{
                
                NSTimeInterval duration = [[NSDate date] timeIntervalSinceDate:uploadGenomeStart];
                APCLogEventWithData(@"23andmeGenomeUploaded", (@{ @"duration": [NSString stringWithFormat:@"%f", duration]}));
            }];
            
        } else {
            
            NSString *errorCode = [@(httpResp.statusCode) stringValue];
            NSString *error = [dictContent valueForKey:@"error"];
            NSString *errorDescription = [dictContent valueForKey:@"error_description"];
            
            APCLogEventWithData(@"23andmeFailedDownloadingGenome", (@{@"error": error ? error : @"undefined",
                                                                      @"error_code": errorCode ? errorCode : @"undefined",
                                                                      @"error_description": errorDescription ? errorDescription : @"undefined"}));
        }
    }
    
}

+(NSDictionary*) buildUserDetails: (NSString*) taskDescription {
    
    NSArray *userAndProfileId = [taskDescription componentsSeparatedByString:@","];
    
    NSMutableDictionary  *userDetails = [NSMutableDictionary dictionary];
    userDetails[@"userId"] = [userAndProfileId objectAtIndex:0];
    userDetails[@"profileId"] = [userAndProfileId objectAtIndex:1];
    
    return userDetails;
}

@end
