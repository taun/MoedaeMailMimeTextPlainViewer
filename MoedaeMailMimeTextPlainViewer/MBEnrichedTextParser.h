//
//  MBEnrichedTextParser.h
//  MoedaeMailMimeTextPlainViewer
//
//  Created by Taun Chapman on 03/03/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MBEnrichedTextParser : NSObject <NSXMLParserDelegate>

+(instancetype) parserWithData: (NSData*) data attributes: (NSDictionary*) attributes;

-(instancetype) initWithData: (NSData*) data attributes: (NSDictionary*) attributes;

-(NSAttributedString*) parse;

@end
