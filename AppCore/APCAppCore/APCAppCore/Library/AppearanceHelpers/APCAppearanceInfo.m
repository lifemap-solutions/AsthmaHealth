// 
//  APCAppearanceInfo.m 
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
 
#import "APCAppearanceInfo.h"
#import "UIColor+APCAppearance.h"
#import "APCConstants.h"



static NSDictionary * localAppearanceDictionary   = nil;
static NSDictionary * defaultAppearanceDictionary = nil;



@implementation APCAppearanceInfo

/**
 Set global, static values the first time anyone calls this class.

 By definition, this method is called once per class, in a thread-safe
 way, the first time the class is sent a message -- basically, the first
 time we refer to the class.  That means we can use this to set up stuff
 that applies to all objects (instances) of this class.

 Documentation:  See +initialize in the NSObject Class Reference.  Currently, that's here:
 https://developer.apple.com/library/ios/documentation/Cocoa/Reference/Foundation/Classes/NSObject_Class/index.html#//apple_ref/occ/clm/NSObject/initialize
 */
+ (void) initialize
{
    defaultAppearanceDictionary = @{
                                    // Fonts
                                    kRegularFontNameKey                : @"HelveticaNeue",
                                    kMediumFontNameKey                 : @"HelveticaNeue-Medium",
                                    kLightFontNameKey                  : @"HelveticaNeue-Light",

                                    // Colors
                                    kPrimaryAppColorKey                : [UIColor colorWithRed:   0.176       green: 0.706        blue: 0.980       alpha: 1.000],  // #2db4fa

                                    kSecondaryColor1Key                : [UIColor blackColor],                                                                      // #000000
                                    kSecondaryColor2Key                : [UIColor colorWithWhite: 0.392       alpha: 1.000],                                        // #646464
                                    kSecondaryColor3Key                : [UIColor colorWithRed:   0.557       green: 0.557        blue: 0.573       alpha: 1.000],  // #8e8e93
                                    kSecondaryColor4Key                : [UIColor colorWithWhite: 0.973       alpha: 1.000],                                        // #f8f8f8

                                    kTertiaryColor1Key                 : [UIColor colorWithRed:   0.267       green: 0.824        blue: 0.306       alpha:1.000],   // #44d24e
                                    kTertiaryColor2Key                 : [UIColor blackColor],                                                                      // #000000

                                    kTertiaryGreenColorKey             : [UIColor colorWithRed:   0.195       green: 0.830        blue: 0.443       alpha: 1.000],
                                    kTertiaryBlueColorKey              : [UIColor colorWithRed:   0.132       green: 0.684        blue: 0.959       alpha: 1.000],
                                    kTertiaryRedColorKey               : [UIColor colorWithRed:   0.919       green: 0.226        blue: 0.342       alpha: 1.000],
                                    kTertiaryBrightRedColorKey         : [UIColor colorWithRed:   232/255.0f  green: 87/255.0f    blue: 28/255.0f   alpha: 1.000],
                                    kTertiaryYellowColorKey            : [UIColor colorWithRed:   0.994       green: 0.709        blue: 0.278       alpha: 1.000],
                                    kTertiaryPurpleColorKey            : [UIColor colorWithRed:   0.574       green: 0.252        blue: 0.829       alpha: 1.000],
                                    kTertiaryGrayColorKey              : [UIColor colorWithRed:   157/255.0f  green: 157/255.0f   blue: 157/255.0f  alpha: 1.000],

                                    kBorderLineColor                   : [UIColor colorWithWhite: 0.749       alpha: 1.000]
                                    };
}

+ (void) setAppearanceDictionary: (NSDictionary*) appearanceDictionary
{
    localAppearanceDictionary = appearanceDictionary;
}

+ (id) valueForAppearanceKey: (NSString *) key
{
    return localAppearanceDictionary [key] ?: defaultAppearanceDictionary [key];
}

@end
