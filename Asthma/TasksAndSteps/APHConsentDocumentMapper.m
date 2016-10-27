//
//  APHConsentSection.m
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
//

#import "APHConsentDocumentMapper.h"

NSString * const kDocumentPropertiesKey              = @"documentProperties";
NSString * const kDocumentSectionsKey                = @"sections";
NSString * const kDocumentHtmlKey                    = @"htmlDocument";
NSString * const kInvestigatorShortDescriptionKey    = @"investigatorShortDescription";
NSString * const kInvestigatorLongDescriptionKey     = @"investigatorLongDescription";
NSString * const kHtmlContentKey                     = @"htmlContent";

NSString * const kSectionType            = @"sectionType";
NSString * const kSectionTitle           = @"sectionTitle";
NSString * const kSectionFormalTitle     = @"sectionFormalTitle";
NSString * const kSectionSummary         = @"sectionSummary";
NSString * const kSectionContent         = @"sectionContent";
NSString * const kSectionHtmlContent     = @"sectionHtmlContent";
NSString * const kSectionImage           = @"sectionImage";
NSString * const kSectionImageTint       = @"sectionImageTint";
NSString * const kSectionAnimationUrl    = @"sectionAnimationUrl";

NSString * const kDefaultContentDirectory = @"HTMLContent";

@interface APHConsentDocumentMapper ()

@property (nonatomic, strong) NSDictionary *documentDictionary;
@property (nonatomic, strong) NSBundle *bundle;
@property (nonatomic, strong) NSString *contentDirectory;

@end

@implementation APHConsentDocumentMapper

@synthesize sections = _sections;
@synthesize htmlReviewContent = _htmlReviewContent;

- (instancetype)initWithDocument:(NSString *)filename {
    return [self initWithDocument:filename bundle:[NSBundle mainBundle] contentDirectory:kDefaultContentDirectory];
}

- (instancetype)initWithDocument:(NSString *)filename bundle:(NSBundle *)bundle contentDirectory:(NSString *)contentDirectory {
    self = [super init];
    if (!self) return nil;
    
    _bundle = bundle;
    _contentDirectory = contentDirectory;
    
    NSString *path = [self.bundle pathForResource:[filename stringByDeletingPathExtension] ofType:[filename pathExtension]];
    
    NSData *data = [NSData dataWithContentsOfFile:path];
    
    if (!data) return nil;
    
    NSError *error;
    _documentDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
    
    if (error) {
        NSLog(@"%@ error: %@", [self class], error);
        return nil;
    }
    
    return self;
}


- (NSString *)htmlReviewContent {
    
    if (_htmlReviewContent) return _htmlReviewContent;
    
    NSDictionary *properties = [self.documentDictionary objectForKey:kDocumentPropertiesKey];
    
    NSString *path = [self.bundle pathForResource:properties[kDocumentHtmlKey] ofType:@"html" inDirectory:self.contentDirectory];
    
    NSError *error = nil;
    _htmlReviewContent = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    
    if (error) {
        NSLog(@"%@ Error: %@", [self class], error);
    }
    
    return _htmlReviewContent;
}

- (NSArray *)sections {
    
    if (_sections) return _sections;
    
    NSArray *sectionArray = [self.documentDictionary objectForKey:kDocumentSectionsKey];
    
    ORKConsentSectionType(^toSectionType)(NSString*) = ^(NSString* sectionTypeName)
    {
        ORKConsentSectionType   sectionType = ORKConsentSectionTypeCustom;
        
        if ([sectionTypeName isEqualToString:@"overview"])
        {
            sectionType = ORKConsentSectionTypeOverview;
        }
        else if ([sectionTypeName isEqualToString:@"privacy"])
        {
            sectionType = ORKConsentSectionTypePrivacy;
        }
        else if ([sectionTypeName isEqualToString:@"dataGathering"])
        {
            sectionType = ORKConsentSectionTypeDataGathering;
        }
        else if ([sectionTypeName isEqualToString:@"dataUse"])
        {
            sectionType = ORKConsentSectionTypeDataUse;
        }
        else if ([sectionTypeName isEqualToString:@"timeCommitment"])
        {
            sectionType = ORKConsentSectionTypeTimeCommitment;
        }
        else if ([sectionTypeName isEqualToString:@"studySurvey"])
        {
            sectionType = ORKConsentSectionTypeStudySurvey;
        }
        else if ([sectionTypeName isEqualToString:@"studyTasks"])
        {
            sectionType = ORKConsentSectionTypeStudyTasks;
        }
        else if ([sectionTypeName isEqualToString:@"withdrawing"])
        {
            sectionType = ORKConsentSectionTypeWithdrawing;
        }
        else if ([sectionTypeName isEqualToString:@"custom"])
        {
            sectionType = ORKConsentSectionTypeCustom;
        }
        else if ([sectionTypeName isEqualToString:@"onlyInDocument"])
        {
            sectionType = ORKConsentSectionTypeOnlyInDocument;
        }
        
        return sectionType;
    };
    
    NSMutableArray* consentSections = [NSMutableArray arrayWithCapacity:sectionArray.count];
    
    for (NSDictionary *section in sectionArray)
    {
        //  Custom typesdo not have predefiend title, summary, content, or animation
        NSAssert([section isKindOfClass:[NSDictionary class]], @"Improper section type");
        
        NSString*   typeName     = [section objectForKey:kSectionType];
        NSAssert(typeName != nil && [typeName isKindOfClass:[NSString class]],    @"Missing Section Type or improper type");
        
        ORKConsentSectionType   sectionType = toSectionType(typeName);
        
        NSString*   title        = [section objectForKey:kSectionTitle];
        NSString*   formalTitle  = [section objectForKey:kSectionFormalTitle];
        NSString*   summary      = [section objectForKey:kSectionSummary];
        NSString*   content      = [section objectForKey:kSectionContent];
        NSString*   htmlContent  = [section objectForKey:kSectionHtmlContent];
        NSString*   image        = [section objectForKey:kSectionImage];
        NSNumber*   imageTint    = [section objectForKey:kSectionImageTint];
        NSString*   animationUrl = [section objectForKey:kSectionAnimationUrl];
        
        NSAssert(title        == nil || title         != nil && [title isKindOfClass:[NSString class]],        @"Missing Section Title or improper type");
        NSAssert(formalTitle  == nil || formalTitle   != nil && [formalTitle isKindOfClass:[NSString class]],  @"Missing Section Formal title or improper type");
        NSAssert(summary      == nil || summary       != nil && [summary isKindOfClass:[NSString class]],      @"Missing Section Summary or improper type");
        NSAssert(content      == nil || content       != nil && [content isKindOfClass:[NSString class]],      @"Missing Section Content or improper type");
        NSAssert(htmlContent  == nil || htmlContent   != nil && [htmlContent isKindOfClass:[NSString class]],  @"Missing Section HTML Content or improper type");
        NSAssert(image        == nil || image         != nil && [image isKindOfClass:[NSString class]],        @"Missing Section Image or improper type");
        NSAssert(imageTint == nil || imageTint != nil && [imageTint isKindOfClass:[NSNumber class]], @"Missing Section Image Tint or improper type");
        NSAssert(animationUrl == nil || animationUrl  != nil && [animationUrl isKindOfClass:[NSString class]], @"Missing Animation URL or improper type");
        
        
        ORKConsentSection*  section = [[ORKConsentSection alloc] initWithType:sectionType];
        
        if (title != nil)
        {
            section.title = title;
        }
        
        if (formalTitle != nil)
        {
            section.formalTitle = formalTitle;
        }
        
        if (summary != nil)
        {
            section.summary = summary;
        }
        
        if (content != nil)
        {
            section.content = content;
        }
        
        if (htmlContent != nil)
        {
            NSString*   path    = [self.bundle pathForResource:htmlContent ofType:@"html" inDirectory:kHtmlContentKey];
            NSAssert(path != nil, @"Unable to locate HTML file: %@", htmlContent);
            
            NSError*    error   = nil;
            NSString*   content = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
            
            NSAssert(content != nil, @"Unable to load content of file \"%@\": %@", path, error);
            
            section.htmlContent = content;
        }
        
        if (image != nil)
        {
            section.customImage = [UIImage imageNamed:image];
            NSAssert(section.customImage != nil, @"Unable to load image: %@", image);
        }
        
        if (imageTint != nil)
        {
            section.shouldApplyTint = imageTint;
        }
        
        if (animationUrl != nil)
        {
            NSString * nameWithScaleFactor = animationUrl;
            if ([[UIScreen mainScreen] scale] >= 3)
            {
                nameWithScaleFactor = [nameWithScaleFactor stringByAppendingString:@"@3x"];
            }
            else
            {
                nameWithScaleFactor = [nameWithScaleFactor stringByAppendingString:@"@2x"];
            }
            NSURL*      url   = [self.bundle URLForResource:nameWithScaleFactor withExtension:@"m4v"];
            NSError*    error = nil;
            
            NSAssert([url checkResourceIsReachableAndReturnError:&error] == YES, @"Animation file--%@--not reachable: %@", animationUrl, error);
            section.customAnimationURL = url;
        }
        
        [consentSections addObject:section];
    }
    
    _sections = consentSections;
    
    return _sections;
}

@end
