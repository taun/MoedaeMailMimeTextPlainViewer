//
//  MBEnrichedTextParser.m
//  MoedaeMailMimeTextPlainViewer
//
//  Created by Taun Chapman on 03/03/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MBEnrichedTextParser.h"
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <MoedaeMailPlugins/NSObject+TokenDispatch.h>


@interface MBEnrichedTextParser ()

@property (nonatomic,strong) NSXMLParser*               parser;
@property (nonatomic,strong) NSMutableArray*            enrichedCodesStack;
@property (nonatomic,strong) NSMutableArray*            attributeStack;
//@property (nonatomic,strong) NSMutableArray*            stringStack;
@property (nonatomic,strong) NSMutableArray*            attStringStack;
@property (nonatomic,strong) NSMutableString*           contentString;
@property (nonatomic,strong) NSMutableAttributedString* currentOutput;

@end

static NSDictionary* ColorMap;

#define MBKFontSizeFactor 1.2
#define MBKIndentFactor 32.0

@implementation MBEnrichedTextParser

+(void) initialize {
    ColorMap = @{@"red":    [NSColor redColor],
                 @"blue":   [NSColor blueColor],
                 @"green":  [NSColor greenColor],
                 @"yellow": [NSColor yellowColor],
                 @"cyan":   [NSColor cyanColor],
                 @"magenta":[NSColor magentaColor],
                 @"black":  [NSColor blackColor],
                 @"white":  [NSColor whiteColor]};
}

+(instancetype) parserWithData:(NSData *)data attributes: (NSDictionary*) attributes {
    return [[self alloc] initWithData: data attributes: attributes];
}

-(instancetype) initWithData:(NSData *)data attributes: (NSDictionary*) attributes {
    self = [super init];
    
    if (self) {
        _parser = [[NSXMLParser alloc] initWithData: [self cleanAndWrapData: data]];
        [_parser setDelegate: self];
        _enrichedCodesStack = [NSMutableArray new];
//        _stringStack = [NSMutableArray new];
        _currentOutput = [NSMutableAttributedString new];
        _contentString = [NSMutableString new];
        _attributeStack = [NSMutableArray new];
        if (!attributes) {
            attributes = [NSMutableDictionary new];
            [_attributeStack addObject: attributes];
        } else {
            [_attributeStack addObject: [attributes mutableCopy]];
        }
        
//        NSLog(@"%@", [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding]);
    }
    return self;
}

- (id)init {
    return [self initWithData: nil attributes: nil];
}

-(NSAttributedString*) parse {
    [self.parser parse];
    return [self.currentOutput copy];
}

#pragma mark - delegate

-(void) parserDidStartDocument:(NSXMLParser *)parser {
//    NSLog(@"%@", parser);
    [self.currentOutput deleteCharactersInRange: NSMakeRange(0, self.currentOutput.length)];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

-(void) parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
    NSString* cleanElementName = [elementName stringByReplacingOccurrencesOfString: @"-" withString: @""];
    [self.enrichedCodesStack addObject: cleanElementName];

    [self performCleanedSelectorString: elementName prefixedBy: @"codeStart" fallbackSelector: @"codeStartUnknown"];
}


-(void) parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
//    NSLog(@"%@", parser);
    [self.contentString appendString: string];
}


-(void) parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    [self popCode];
    
    [self performCleanedSelectorString: elementName prefixedBy: @"codeEnd" fallbackSelector: @"codeEndUnknown"];
}
#pragma clang diagnostic pop

-(void) parserDidEndDocument:(NSXMLParser *)parser {
//    NSLog(@"%@", parser);
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
//    NSLog(@"%@; %@", parser, parseError);
}

#pragma mark - enriched code transforms
#pragma message "ToDo: codes Excerpt, NoFill, Fill, RGB colors"

-(void) codeStartUnknown {
    [self dupLastAttribute];
}
-(void) codeEndUnknown {
    // add current string
    [self popAttributes];
}
-(void) codeStartIgnoreme {
    [self dupLastAttribute];
}

-(void) codeStartFixed {
    NSMutableDictionary* newAttributes = [self dupLastAttribute];
    // change to bold
    NSFontManager* aFontManager = [NSFontManager sharedFontManager];
    NSFont* font = [self getFont];
    NSFont* fixedFont = [aFontManager convertFont: font toFamily: @"Menlo"];
    [newAttributes setObject: fixedFont forKey: NSFontAttributeName];
}

-(void) codeStartBold {
    NSMutableDictionary* newAttributes = [self dupLastAttribute];
    // change to bold
    NSFontManager* aFontManager = [NSFontManager sharedFontManager];
    NSFont* font = [self getFont];
    NSFont* boldFont = [aFontManager convertFont: font toHaveTrait: NSBoldFontMask];
    [newAttributes setObject: boldFont forKey: NSFontAttributeName];
}

-(void) codeStartItalic {
    NSMutableDictionary* newAttributes = [self dupLastAttribute];
    // change to italic
    NSFontManager* aFontManager = [NSFontManager sharedFontManager];
    NSFont* font = [self getFont];
    NSFont* italicFont = [aFontManager convertFont: font toHaveTrait: NSItalicFontMask];
    [newAttributes setObject: italicFont forKey: NSFontAttributeName];
}

-(void) codeStartBigger {
    NSMutableDictionary* newAttributes = [self dupLastAttribute];
    // change to italic
    NSFontManager* aFontManager = [NSFontManager sharedFontManager];
    NSFont* font = [self getFont];
    NSFont* biggerFont = [aFontManager convertFont: font toSize: [font pointSize] * MBKFontSizeFactor];
    [newAttributes setObject: biggerFont forKey: NSFontAttributeName];
}

-(void) codeStartSmaller {
    NSMutableDictionary* newAttributes = [self dupLastAttribute];
    // change to italic
    NSFontManager* aFontManager = [NSFontManager sharedFontManager];
    NSFont* font = [self getFont];
    NSFont* smallerFont = [aFontManager convertFont: font toSize: [font pointSize] / MBKFontSizeFactor];
    [newAttributes setObject: smallerFont forKey: NSFontAttributeName];
}

-(void) codeStartUnderline {
    NSMutableDictionary* newAttributes = [self dupLastAttribute];
    // change to italic
    [newAttributes setObject: [NSNumber numberWithInt: NSUnderlineStyleSingle] forKey: NSUnderlineStyleAttributeName];
}

-(void) codeStartParam {
    // there should never be content between the tag and param for the tag but we push the content anyhow.
    [self dupLastAttribute];
}
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

-(void) codeEndParam {
    NSString* previousCode = [self.enrichedCodesStack lastObject];
    NSString* codeMethod = [NSString stringWithFormat:@"code%@:",[previousCode capitalizedString]];
    NSString* param = [self.contentString copy]; [self.contentString deleteCharactersInRange: NSMakeRange(0, self.contentString.length)];
    
    // pop must be called after the param is gotten above
    [self popAttributes];

    if ([self respondsToSelector: NSSelectorFromString(codeMethod)]) {
        [self performSelector: NSSelectorFromString(codeMethod) withObject: param];
    }
}

#pragma clang diagnostic pop

-(void) codeStartFontfamily {
    // do nothing until we have the param
    [self dupLastAttribute];
}
-(void) codeFontfamily: (NSString*) param {
    NSMutableDictionary* newAttributes = [self.attributeStack lastObject];

    NSFontManager* aFontManager = [NSFontManager sharedFontManager];
    NSFont* font = [aFontManager fontWithFamily: param traits: (NSUnboldFontMask | NSUnitalicFontMask) weight: 5 size: 12];
    
    if (font) {
        [newAttributes setObject: font forKey: NSFontAttributeName];
    }
}

-(void) codeStartColor {
    // do nothing until we have the param
    [self dupLastAttribute];
}
-(void) codeColor: (NSString*) param {
    NSMutableDictionary* newAttributes = [self.attributeStack lastObject];
    
    NSColor* color = [ColorMap objectForKey: [param lowercaseString]];
    
    if (color) {
        [newAttributes setObject: color forKey: NSForegroundColorAttributeName];
    }
}

-(void) changeAlignmentTo: (NSTextAlignment) alignment {
    NSMutableDictionary* newAttributes = [self dupLastAttribute];
    
    NSParagraphStyle* currentStyle = [newAttributes objectForKey: NSParagraphStyleAttributeName];
    
    NSMutableParagraphStyle* style;
    
    
    if (currentStyle) {
        style = [currentStyle mutableCopy];
    } else {
        style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    }
    
    [style setAlignment: alignment];
    
    
    if (style) {
        [newAttributes setObject: style forKey: NSParagraphStyleAttributeName];
    }
}

-(void) codeStartCenter {
    // do nothing until we have the param
    [self changeAlignmentTo: NSCenterTextAlignment];
}

-(void) codeStartFlushleft {
    // do nothing until we have the param
    [self changeAlignmentTo: NSLeftTextAlignment];
}

-(void) codeStartFlushright {
    // do nothing until we have the param
    [self changeAlignmentTo: NSRightTextAlignment];
}

-(void) codeStartFlushboth {
    // do nothing until we have the param
    [self changeAlignmentTo: NSJustifiedTextAlignment];
}



-(void) codeStartParaindent {
    // do nothing until we have the param
    [self dupLastAttribute];
}
-(void) codeParaindent: (NSString*) param {
    
    // according to rfc, there should be a line break for ParaIndent
    NSString* lineEnd = @"\n";
    NSUInteger lineEndLocation = [self.currentOutput.string rangeOfString: lineEnd options: (NSAnchoredSearch | NSBackwardsSearch)].location;
    if (lineEndLocation == NSNotFound ) {
        [self.contentString appendString: lineEnd];
        [self pushContent];
    }
    
    NSMutableDictionary* newAttributes = [self.attributeStack lastObject];
    
    NSParagraphStyle* currentStyle = [newAttributes objectForKey: NSParagraphStyleAttributeName];
    
    NSMutableParagraphStyle* style;
    
    if (currentStyle) {
        style = [currentStyle mutableCopy];
    } else {
        style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    }
    
    // Comma separated list
    NSArray* params = [param componentsSeparatedByString: @","];
    
    for (NSString* indent in params) {
        NSString* cleanIndent = [[indent stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]] lowercaseString];
        
        if ([cleanIndent isEqualToString: @"left"]) {
            CGFloat currentHeadIndent = [style headIndent];
            [style setHeadIndent: currentHeadIndent + MBKIndentFactor];
            [style setFirstLineHeadIndent: currentHeadIndent + MBKIndentFactor];
            
        } else if ([cleanIndent isEqualToString: @"right"]) {
            [style setTailIndent: [style tailIndent] - MBKIndentFactor];
            
        } else if ([cleanIndent isEqualToString: @"in"]) {
            [style setFirstLineHeadIndent: [style headIndent] + MBKIndentFactor];
            
        } else if ([cleanIndent isEqualToString: @"out"]) {
            [style setFirstLineHeadIndent: [style headIndent] - MBKIndentFactor];
        }
    }
    
    if (style) {
        [newAttributes setObject: style forKey: NSParagraphStyleAttributeName];
    }
}

#pragma mark - legacy, deprecated codes

-(void) codeStartIndent {
    [self dupLastAttribute];
    [self codeParaindent: @"left"];
}

-(void) codeStartIndentright {
    [self dupLastAttribute];
    [self codeParaindent: @"right"];
}

-(void) codeStartXcolor {
    [self dupLastAttribute];
}

-(void) codeXcolor: (NSString*) param {
    [self codeColor: param];
}

-(void) codeStartXbgcolor {
    [self dupLastAttribute];
}
-(void) codeXbgcolor: (NSString*) param {
    NSMutableDictionary* newAttributes = [self.attributeStack lastObject];
    
    NSColor* color = [ColorMap objectForKey: [param lowercaseString]];
    
    if (color) {
        [newAttributes setObject: color forKey: NSBackgroundColorAttributeName];
    }
}


#pragma mark - utility
-(NSString*) popCode {
    NSString* lastCode = [self.enrichedCodesStack lastObject];
    if (lastCode) {
        [self.enrichedCodesStack removeLastObject];
    }
    return lastCode;
}
-(NSMutableDictionary*) dupLastAttribute { // save content with old attributes first
    [self pushContent];
    
    NSMutableDictionary* newAttribute = [[self.attributeStack lastObject] mutableCopy];
    [self.attributeStack addObject: newAttribute];
    return newAttribute;
}
-(NSMutableDictionary*) popAttributes { // save content with current attributes first
    [self pushContent];
    
    NSMutableDictionary* lastAttribute = [self.attributeStack lastObject];
    if (lastAttribute) {
        [self.attributeStack removeLastObject];
    }
    return lastAttribute;
}
-(void) pushContent {
    NSDictionary* currentAttributes = [[self.attributeStack lastObject] copy];
    
    NSUInteger length = self.contentString.length;
    if (length > 0) {
        NSString* currentContent = [self.contentString copy]; [self.contentString deleteCharactersInRange: NSMakeRange(0, length)];
        
        [self.currentOutput appendAttributedString: [[NSAttributedString alloc] initWithString: currentContent attributes: currentAttributes]];
    }
}
-(NSFont*) getFont {
    NSMutableDictionary* attributes = [self.attributeStack lastObject];
    
    NSFont* font = [attributes objectForKey: NSFontAttributeName];
    if (!font) {
        // get default font
        NSFontManager* aFontManager = [NSFontManager sharedFontManager];
        font = [aFontManager fontWithFamily: @"Helvetica" traits: (NSUnboldFontMask | NSUnitalicFontMask) weight: 5 size: 12];
    }
    
    return font;
}
/*
 From the RFC1896:

 A minimal text/enriched implementation is one that converts "<<" to
 "<", removes everything between a <param> command and the next
 balancing </param> command, removes all other formatting commands
 (all text enclosed in angle brackets), and, outside of <nofill>
 environments, converts any series of n CRLFs to n-1 CRLFs, and
 converts any lone CRLF pairs to SPACE.
 */
-(NSData*) cleanAndWrapData: (NSData*) data {
    NSString* content = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
    NSString* unfoldedContent = [self unfold: content];
    NSString* escapedString = [unfoldedContent stringByReplacingOccurrencesOfString: @"<<" withString: @"&lt;"];
    NSString* wrappedContent = [NSString stringWithFormat: @"<enriched>%@</enriched>", escapedString];
    NSData* wrappedData = [wrappedContent dataUsingEncoding: NSUTF8StringEncoding];
//    NSLog(@"%@", wrappedContent);
    return wrappedData;
}
/*!
  From the RFC1896:
 
 @param foldedString isolated CRLF pairs are translated into a single SPACE character. Sequences of N consecutive CRLF pairs, however, are translated into N-1 actual line breaks
 
 @return unfolded NSString
 */
-(NSString*) unfold: (NSString*) foldedString {
    NSString* unfolded;
    
    NSString* lineEnd = @"\r\n";
    
    __block NSMutableString* unfoldingString = [NSMutableString new];
    
    __block NSUInteger blankLines = 0;
    
    [foldedString enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
        //
        if ([line length] > 0) {
            //
            if (blankLines == 0) {
                [unfoldingString appendString: @" "];
            }
            [unfoldingString appendString: line];
            blankLines = 0;
        } else {
            [unfoldingString appendString: lineEnd];
            blankLines++;
        }
    }];
    
    unfolded = [unfoldingString copy];
    
//    NSRange testRange = [foldedString rangeOfString: lineEnd options: (NSAnchoredSearch | NSBackwardsSearch)];
//    
//    if ([foldedString rangeOfString: lineEnd options: (NSAnchoredSearch | NSBackwardsSearch)].location == NSNotFound) {
//        lineEnd = @"\n";
//        if ([foldedString rangeOfString: lineEnd options: (NSAnchoredSearch | NSBackwardsSearch)].location == NSNotFound) {
//            lineEnd = @"\r";
//            if ([foldedString rangeOfString: lineEnd options: (NSAnchoredSearch | NSBackwardsSearch)].location == NSNotFound) {
//                lineEnd = @"\n\r";
//                if ([foldedString rangeOfString: lineEnd options: (NSAnchoredSearch | NSBackwardsSearch)].location == NSNotFound) {
//                    lineEnd = nil;
//                }
//            }
//        }
//    }
//    
//    if (lineEnd) {
//        NSArray* lines = [foldedString componentsSeparatedByString: lineEnd];
//        
//        NSUInteger blankLines = 0;
//        for (NSString* line in lines) {
//            //
//            if ([[line stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]] length] > 0) {
//                //
//                [unfoldingString appendString: line];
//                if (blankLines == 0) {
//                    [unfoldingString appendString: @" "];
//                }
//                blankLines = 0;
//            } else {
//                [unfoldingString appendString: lineEnd];
//                blankLines++;
//            }
//        }
//        
//        unfolded = [unfoldingString copy];
//    } else {
//        unfolded = foldedString;
//    }

    return unfolded;
}

@end
