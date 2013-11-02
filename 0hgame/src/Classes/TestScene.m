//
//  TestScene.m
//  0hgame
//
//  Created by Brian Ensor on 11/2/13.
//
//

#import "TestScene.h"

@implementation TestScene

- (instancetype)init {
    if ((self = [super init])) {
        SPQuad *testQuad = [SPQuad quadWithWidth:50 height:50 color:SPColorRed];
        [self addChild:testQuad];
    }
    return self;
}

@end
