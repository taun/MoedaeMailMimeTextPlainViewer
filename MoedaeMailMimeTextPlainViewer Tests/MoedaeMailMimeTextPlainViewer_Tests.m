//
//  MoedaeMailMimeTextPlainViewer_Tests.m
//  MoedaeMailMimeTextPlainViewer Tests
//
//  Created by Taun Chapman on 03/04/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "MBEnrichedTextParser.h"

@interface MoedaeMailMimeTextPlainViewer_Tests : XCTestCase

@property(nonatomic, strong) NSBundle                       *testBundle;

@end



@implementation MoedaeMailMimeTextPlainViewer_Tests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    _testBundle = [NSBundle bundleWithIdentifier: @"com.moedae.MoedaeMailMimeTextPlainViewer-Tests"];
    
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testSample0 {
//    NSError* error;
    
    NSString *path = [self.testBundle pathForResource: @"EnrichedSample0" ofType: @"txt" inDirectory: nil];
    
//    NSString* sampleContent = [NSString stringWithContentsOfFile: path encoding: NSASCIIStringEncoding error: &error];
    
    NSData* data = [NSData dataWithContentsOfFile: path];
    
    MBEnrichedTextParser* parser = [MBEnrichedTextParser parserWithData: data attributes: nil];
    
    NSAttributedString* output = [parser parse];

    XCTAssertNotNil(output, @"");
}

- (void)testSample1 {
    //    NSError* error;
    
    NSString *path = [self.testBundle pathForResource: @"EnrichedSample1" ofType: @"txt" inDirectory: nil];
    
    //    NSString* sampleContent = [NSString stringWithContentsOfFile: path encoding: NSASCIIStringEncoding error: &error];
    
    NSData* data = [NSData dataWithContentsOfFile: path];
    
    MBEnrichedTextParser* parser = [MBEnrichedTextParser parserWithData: data attributes: nil];
    
    NSAttributedString* output = [parser parse];
    
    XCTAssertNotNil(output, @"");
}

@end
