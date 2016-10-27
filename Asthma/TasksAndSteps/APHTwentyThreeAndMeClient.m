//
//  APHTwentyThreeAndMeClient.m
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

#import "APHTwentyThreeAndMeClient.h"
#import "APHTwentyThreeAndMeUser.h"
#import "APHAppDelegate.h"
#import "APHTwentyThreeAndMeUploader.h"

NSString *kTwentyThreeAndMeBackgroundSessionIdentifier = @"edu.mssm.twentythreeandme.backgroundsession";
NSString *const k23andmeDomain = @"com.23andme";
NSString *const k23andmeUrlKey = @"23andmeUrl";

@interface APHTwentyThreeAndMeClient () <NSURLSessionDelegate, NSURLSessionDownloadDelegate>

@property (strong, atomic) NSURL *userEndpoint;
@property (strong, atomic) NSURL *genomeEndpoint;
@property (strong, atomic) NSURLSession *dataSession;
@property (strong, atomic) NSURLSession *backgroundSession;

@end

@implementation APHTwentyThreeAndMeClient

- (instancetype)init {
    self = [super init];
    if (self) {
        _baseUrl = [[NSBundle mainBundle] objectForInfoDictionaryKey:k23andmeUrlKey];
        _userEndpoint = [NSURL URLWithString:[[NSString alloc] initWithFormat:@"%@%@", _baseUrl, @"/1/user/"]];
        _genomeEndpoint = [NSURL URLWithString:[[NSString alloc] initWithFormat:@"%@%@", _baseUrl, @"/1/genomes/"]];
        _dataSession = [self createDataSession];
        _backgroundSession = [self createBackgroundSession];
    }
    return self;
}

+ (instancetype) sharedClient {
    static APHTwentyThreeAndMeClient *sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedClient = [[APHTwentyThreeAndMeClient alloc] init];
    });
    return sharedClient;
}

-(NSURLSession*) createDataSession {
    static NSURLSession *session = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        
        session = [NSURLSession sessionWithConfiguration:sessionConfiguration delegate:self delegateQueue:nil];
    });
    return session;
}

-(NSURLSession*) createBackgroundSession {
    static NSURLSession *backgroundSession = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:kTwentyThreeAndMeBackgroundSessionIdentifier];
        
        backgroundSession = [NSURLSession sessionWithConfiguration:sessionConfiguration delegate:self delegateQueue:nil];
    });
    return backgroundSession;
}

-(void) getUser: (NSString*) token completionHandler:(void (^) (APHTwentyThreeAndMeUser *user, NSError *error)) handler {
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.userEndpoint];
    [request setHTTPMethod:@"GET"];
    [request setTimeoutInterval:20];
    [self addAuthorizationHeader:request forToken:token];
    
    [[_dataSession dataTaskWithRequest: request
                     completionHandler:^(NSData *data,
                                         NSURLResponse *response,
                                         NSError *error) {
                         
                         if (!handler) {
                             APCLogError(@"handler shouldn't be nil");
                             return;
                         }
                         
                         if (error) {
                             handler(nil, error);
                             return;
                         }
                         
                         NSHTTPURLResponse *httpResp = (NSHTTPURLResponse*) response;
                         if (httpResp.statusCode != 200) {
                             handler(nil, [APHTwentyThreeAndMeClient handleError:httpResp.statusCode data:data]);
                             return;
                         }
                         
                         NSError *jsonError;
                         NSDictionary *userData = [NSJSONSerialization JSONObjectWithData:data
                                                                                  options:NSJSONReadingAllowFragments
                                                                                    error:&jsonError];
                         if (jsonError) {
                             handler(nil, jsonError);
                         } else {
                             handler([[APHTwentyThreeAndMeUser alloc] initWithData:userData token:token], nil);
                         }
                             
                         
                     }] resume];
    
}

-(void) addAuthorizationHeader:(NSMutableURLRequest*) request forToken: (NSString*) token {
    [request setValue:[[NSString alloc] initWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
}

-(void) downloadGenome: (APHTwentyThreeAndMeUser*) user {
    NSURL *genomeProfileEndpoint =  [self.genomeEndpoint URLByAppendingPathComponent:[user.profileId stringByAppendingString:@"/"]];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:genomeProfileEndpoint];
    [request setHTTPMethod:@"GET"];
    [self addAuthorizationHeader:request forToken:user.token];
    
    
    NSURLSessionDownloadTask *task = [_backgroundSession downloadTaskWithRequest:request];
    task.taskDescription = [NSString stringWithFormat:@"%@,%@", user.userId, user.profileId];
    [task resume];
    
}
-(void)URLSession:(NSURLSession *) __unused session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    [APHTwentyThreeAndMeUploader upload:downloadTask fromLocation:location];
}

-(void)URLSession:(NSURLSession *) __unused session didBecomeInvalidWithError:(NSError *)error {
    [APHTwentyThreeAndMeClient logError:error forLocation:@"BecomeInvalidWithError"];
}

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *) __unused session
{
    APHAppDelegate *appDelegate = (APHAppDelegate*)[UIApplication sharedApplication].delegate;

  if (appDelegate.twentyThreeAndMeBackgroundCompletionHandler) {
      appDelegate.twentyThreeAndMeBackgroundCompletionHandler();
      appDelegate.twentyThreeAndMeBackgroundCompletionHandler = nil;
  }
  
}

+(void) logError:(NSError*) error forLocation:(NSString*) location {
    APCLogEventWithData(@"23andmeError", (@{@"location": location,
                                            @"code": error.code ? [@(error.code) stringValue] : @"",
                                            @"domain": error.domain ? error.domain : @"",
                                            @"message" : error.message ? error.message : @"" }));
    
}

+(NSError*) handleError:(NSInteger) statusCode data: (NSData*) data {
    
    NSError *jsonError;
    NSDictionary *errorInfo = [NSJSONSerialization JSONObjectWithData:data
                                                             options:NSJSONReadingAllowFragments
                                                               error:&jsonError];
    if (jsonError) {
        return jsonError;
    } else {
        return [NSError errorWithDomain:k23andmeDomain code:statusCode userInfo:errorInfo];
    }
    
}

@end
