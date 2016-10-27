//
//  SBBConsentManager.h
//  BridgeSDK
//
//  Created by Erin Mounts on 9/23/14.
//
//	Copyright (c) 2014, Sage Bionetworks
//	All rights reserved.
//
//	Redistribution and use in source and binary forms, with or without
//	modification, are permitted provided that the following conditions are met:
//	    * Redistributions of source code must retain the above copyright
//	      notice, this list of conditions and the following disclaimer.
//	    * Redistributions in binary form must reproduce the above copyright
//	      notice, this list of conditions and the following disclaimer in the
//	      documentation and/or other materials provided with the distribution.
//	    * Neither the name of Sage Bionetworks nor the names of BridgeSDk's
//		  contributors may be used to endorse or promote products derived from
//		  this software without specific prior written permission.
//
//	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
//	ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//	WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//	DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
//	DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//	(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//	LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
//	ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//	(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//	SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#import <Foundation/Foundation.h>
@import UIKit;
#import "SBBBridgeAPIManager.h"

/*!
 * @typedef SBBConsentShareScope
 * @brief An enumeration of the choices for the scope of sharing collected data.
 * @constant SBBConsentShareScopeNone The user has not consented to sharing their data.
 * @constant SBBConsentShareScopeStudy The user has consented only to sharing their de-identified data with the sponsors and partners of the current research study.
 * @constant SBBConsentShareScopeAll The user has consented to sharing their de-identified data for current and future research, which may or may not involve the same institutions or investigators.
 */
typedef NS_ENUM(NSInteger, SBBConsentShareScope) {
    SBBConsentShareScopeNone = 0,
    SBBConsentShareScopeStudy,
    SBBConsentShareScopeAll
};

/*!
 Completion block for SBBConsentManagerProtocol methods.
 
 @param responseObject The JSON object returned in the HTTP response.
 @param error          An error that occurred during execution of the method for which this is a completion block, or nil.
 */
typedef void (^SBBConsentManagerCompletionBlock)(id responseObject, NSError *error);

/*!
 Completion block for retrieveConsentSignature.

 @param name           The user's name.
 @param birthdate      The user's birthday in the format "YYYY-MM-DD".
 @param signatureImage Image file of the user's signature. Should be less than 10kb. Optional, can be nil.
 @param error          An error that occurred during execution of the method for which this is a completion block, or
     nil.
 */
typedef void (^SBBConsentManagerRetrieveCompletionBlock)(NSString* name, NSString* birthdate, UIImage* signatureImage,
    NSError* error);

/*!
 Completion block for getConsentSignatureWithCompletion:.

 @param consentSignature If no error, by default this will be an SBBConsentSignature object, unless the ConsentSignature type has been mapped in SBBObjectManager setupMappingForType:toClass:fieldToPropertyMappings:. If the error code is SBBErrorCodeServerPreconditionNotMet, indicating a required consent has not been signed, by default this will be a SBBUserSessionInfo object, unless the UserSessionInfo type has been mapped to something else. For any other error code this will be nil.
 @param error            An error that occurred during execution of the method for which this is a completion block, or
 nil.
 */
typedef void (^SBBConsentManagerGetCompletionBlock)(id consentSignature, NSError *error);

/*!
 This protocol defines the interface to the SBBConsentManager's non-constructor, non-initializer methods. The interface is
 abstracted out for use in mock objects for testing, and to allow selecting among multiple implementations at runtime.
 */
@protocol SBBConsentManagerProtocol <SBBBridgeAPIManagerProtocol>

/*!
 *  Submit the user's "signature" and birthdate to indicate consent to participate in this research project.
 *
 *  @param name       The user's name.
 *  @param date       The user's birthday in the format "YYYY-MM-DD".
 *  @param signatureImage  Image file of the user's signature. Should be less than 10kb. Optional, can be nil.
 *  @param scope      The scope of data sharing to which the user has consented.
 *  @param completion An SBBConsentManagerCompletionBlock to be called upon completion.
 *
 *  @return An NSURLSessionDataTask object so you can cancel or suspend/resume the request.
 */
- (NSURLSessionDataTask *)consentSignature:(NSString *)name
                                 birthdate:(NSDate *)date
                            signatureImage:(UIImage*)signatureImage
                              dataSharing:(SBBConsentShareScope)scope
                                completion:(SBBConsentManagerCompletionBlock)completion;

/*!
 *  Submit the user's "signature" and birthdate to indicate consent to participate in this research project.
 *
 *  @param name       The user's name.
 *  @param subpopGuid The GUID of the subpopulation for which the consent is being signed.
 *  @param date       The user's birthday in the format "YYYY-MM-DD".
 *  @param signatureImage  Image file of the user's signature. Should be less than 10kb. Optional, can be nil.
 *  @param scope      The scope of data sharing to which the user has consented.
 *  @param completion An SBBConsentManagerCompletionBlock to be called upon completion.
 *
 *  @return An NSURLSessionDataTask object so you can cancel or suspend/resume the request.
 */
- (nonnull NSURLSessionDataTask *)consentSignature:(nonnull NSString *)name
                              forSubpopulationGuid:(nonnull NSString *)subpopGuid
                                         birthdate:(nonnull NSDate *)date
                                    signatureImage:(nullable UIImage*)signatureImage
                                       dataSharing:(SBBConsentShareScope)scope
                                        completion:(nullable SBBConsentManagerCompletionBlock)completion;

/*!
 *  Retrieve the user's consent signature as previously submitted. If the user has not submitted a consent signature,
 *  this method throws an Entity Not Found error.
 *
 *  @param completion An SBBConsentManagerRetrieveCompletionBlock to be called upon completion.
 *
 *  @return An NSURLSessionDataTask object so you can cancel or suspend/resume the request.
 */
- (NSURLSessionDataTask*)retrieveConsentSignatureWithCompletion:(SBBConsentManagerRetrieveCompletionBlock)completion;

/*!
 Get the user's consent signature as previously submitted. If the user has not submitted a required consent
 signature, the SBBBridgeAppDelegate method handleUserNotConsentedError:sessionInfo:networkManager: will be
 called if it has been implemented in the app delegate, just before calling the completion handler.

 @param subpopGuid The GUID of the subpopulation for which the consent signature is being fetched.
 @param completion An SBBConsentManagerGetCompletionBlock to be called upon completion. See the documentation of that block type for details on what is passed to it under various circumstances.

 @return An NSURLSessionDataTask object so you can cancel or suspend/resume the request.
 */
- (nonnull NSURLSessionDataTask *)getConsentSignatureForSubpopulation:(nonnull NSString *)subpopGuid completion:(nullable SBBConsentManagerGetCompletionBlock)completion;

/*!
 Withdraw the user's consent signature previously submitted for a specific subpopulation.

 @param subpopGuid The GUID of the subpopulation for which the consent signature is being withdrawn.
 @param reason     A freeform text string entered by the participant describing their reasons for withdrawing from the study. Optional, can be nil or empty.
 @param completion An SBBConsentManagerCompletionBlock to be called upon completion.

 @return An NSURLSessionDataTask object so you can cancel or suspend/resume the request.
 */
- (nonnull NSURLSessionDataTask *)withdrawConsentForSubpopulation:(nonnull NSString *)subpopGuid withReason:(nullable NSString *)reason completion:(nullable SBBConsentManagerCompletionBlock)completion;

/*!
 Email (again) the consent document signed by the user when consenting as a member of a particular subpopulation.

 @param subpopGuid The GUID of the subpopulation for which the consent document is to be emailed.
 @param completion An SBBConsentManagerCompletionBlock to be called upon completion.

 @return An NSURLSessionDataTask object so you can cancel or suspend/resume the request.
 */
- (nonnull NSURLSessionDataTask *)emailConsentForSubpopulation:(nonnull NSString *)subpopGuid completion:(nullable SBBConsentManagerCompletionBlock)completion;

/*!
 *  DEPRECATED: Suspend the user's previously-given consent to participate.
 *
 *  @warning This method is deprecated as of BridgeSDK version 2. You should call the dataSharing: method instead. This method is equivalent to calling dataSharing: with a scope of SBBConsentShareScopeNone.
 *
 *  @param completion An SBBConsentManagerCompletionBlock to be called upon completion.
 *
 *  @return An NSURLSessionDataTask object so you can cancel or suspend/resume the request.
 */
- (NSURLSessionDataTask *)suspendConsentWithCompletion:(SBBConsentManagerCompletionBlock)completion __deprecated;

/*!
 *  DEPRECATED: Resume the user's previously-suspended consent to participate.
 *
 *  @warning This method is deprecated as of BridgeSDK version 2. You should call the dataSharing: method instead. This method is equivalent to calling dataSharing: with a scope of SBBConsentShareScopeStudy.
 *
 *  @param completion An SBBConsentManagerCompletionBlock to be called upon completion.
 *
 *  @return An NSURLSessionDataTask object so you can cancel or suspend/resume the request.
 */
- (NSURLSessionDataTask *)resumeConsentWithCompletion:(SBBConsentManagerCompletionBlock)completion __deprecated;

/**
 *  Change the scope of data sharing for this user.
 *  This should only be done in response to an explicit choice on the part of the user to change the sharing scope.
 *
 *  @param scope The scope of data sharing to set for this user.
 *
 *  @param completion An SBBConsentManagerCompletionBlock to be called upon completion.
 *
 *  @return An NSURLSessionDataTask object so you can cancel or suspend/resume the request.
 */
- (NSURLSessionDataTask *)dataSharing:(SBBConsentShareScope)scope completion:(SBBConsentManagerCompletionBlock)completion;

@end

/*!
 *  This class handles communication with the Bridge Consent API.
 */
@interface SBBConsentManager : SBBBridgeAPIManager<SBBComponent, SBBConsentManagerProtocol>

@end
