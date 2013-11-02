//
//  Game.m
//  AppScaffold
//

#import "Game.h"
#import "TestScene.h"

@implementation Game {
    SPSprite *_currentScene;
}

- (instancetype)init {
    if ((self = [super init])) {
        TestScene *testScene = [TestScene new];
        [self showScene:testScene];
    }
    return self;
}

- (void)showScene:(SPSprite *)scene {
    if ([self containsChild:_currentScene]) [self removeChild:_currentScene];
    [self addChild:scene];
    _currentScene = scene;
}

@end
