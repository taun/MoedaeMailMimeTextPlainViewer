//
//  MMPMimeTextPlainViewer.m
//  MailBoxes
//
//  Created by Taun Chapman on 10/28/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import "MMPMimeTextPlainViewer.h"
#import <WebKit/WebKit.h>

#import "MBEnrichedTextParser.h"

@interface MMPMimeTextPlainViewer ()

@property (nonatomic,strong) MBEnrichedTextParser*      parser;

@end

@implementation MMPMimeTextPlainViewer

+(NSSet*) contentTypes {
    return [NSSet setWithObjects: @"TEXT/ENRICHED", @"APPLICATION/MSWORD",nil]; // @"TEXT/PLAIN",
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
        composition = [[NSAttributedString alloc] initWithString: @"Loading..." attributes: self.options.attributes];
    }
    
    [[(NSTextView*)(self.mimeView) textStorage] setAttributedString: composition];
    
    [self setNeedsUpdateConstraints: YES];
}

-(NSAttributedString*) loadPlainData {
    NSDictionary* documentConversionAttributes = [NSDictionary new];
    
    return [[NSAttributedString alloc] initWithData: self.node.decoded options: nil documentAttributes: &documentConversionAttributes error: nil];
}

-(NSAttributedString*) loadEnrichedData {
    self.parser = [MBEnrichedTextParser parserWithData: self.node.decoded attributes: self.options.attributes];
    NSAttributedString* decodedAttributed = [self.parser parse];
//    NSString* enrichedString = [[NSString alloc] initWithData: self.node.decoded encoding: NSUTF8StringEncoding];
//    NSAttributedString* decodedAttributed = [NSAttributedString attributedStringFromTextEnrichedString: enrichedString attributes: self.options.attributes];
    
    return decodedAttributed;
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
