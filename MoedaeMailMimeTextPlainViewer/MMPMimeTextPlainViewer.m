//
//  MMPMimeTextPlainViewer.m
//  MailBoxes
//
//  Created by Taun Chapman on 10/28/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import "MMPMimeTextPlainViewer.h"
#import <WebKit/WebKit.h>

@interface MMPMimeTextPlainViewer ()

@end

@implementation MMPMimeTextPlainViewer

+(NSSet*) contentTypes {
    return [NSSet setWithObjects:@"TEXT/PLAIN", @"TEXT/HTML", @"TEXT/ENRICHED", @"APPLICATION/MSWORD",nil];
}


-(void) loadData {
    NSAttributedString* composition;
    
    if (self.node.isDecoded && self.node.decoded) {
        if ([self.node.subtype isEqualToString: @"PLAIN"]) {
            composition = [self loadPlainData];
            
        } else if ([self.node.subtype isEqualToString: @"ENRICHED"]) {
            composition = [self loadEnrichedData];
            
        } else if ([self.node.subtype isEqualToString: @"HTML"]) {
            composition = [self loadHTMLData];
            
        } else if (([self.node.type isEqualToString: @"APPLICATION"]) && [self.node.subtype isEqualToString: @"MSWORD"]) {
            composition = [self loadMSWord];
            
        }
    }

    
    if (!composition) {
        composition = [[NSAttributedString alloc] initWithString: @"Loading..." attributes: self.attributes];
    }
    
    [[(NSTextView*)(self.mimeView) textStorage] setAttributedString: composition];
    
    [self setNeedsUpdateConstraints: YES];
}

-(NSAttributedString*) loadPlainData {
    NSDictionary* documentConversionAttributes = [NSDictionary new];
    
    return [[NSAttributedString alloc] initWithData: self.node.decoded options: nil documentAttributes: &documentConversionAttributes error: nil];
}

-(NSAttributedString*) loadEnrichedData {
    NSDictionary* documentConversionAttributes = [NSDictionary new];

    return [[NSAttributedString alloc] initWithData: self.node.decoded options: nil documentAttributes: &documentConversionAttributes error: nil];
}

-(NSAttributedString*) loadHTMLData {
    NSDictionary* documentConversionAttributes = [NSDictionary new];
    
    return [[NSAttributedString alloc] initWithHTML: self.node.decoded documentAttributes: &documentConversionAttributes];
}

-(NSAttributedString*) loadMSWord {
    NSDictionary* documentConversionAttributes = [NSDictionary new];
    
    return [[NSAttributedString alloc] initWithDocFormat: self.node.decoded documentAttributes: &documentConversionAttributes];
}

@end
