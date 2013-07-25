//
//  GameController.m
//  Anagrams
//
//  Created by Paige Garratt on 5/30/13.
//  Copyright (c) 2013 Underplot ltd. All rights reserved.
//

#import "GameController.h"
#import "config.h"
#import "TileView.h"
#import "TargetView.h"
#import "ExplodeView.h"
#import "StarDustView.h"

@implementation GameController{
    //tile lists
    NSMutableArray* _tiles;
    NSMutableArray* _targets;
    
    //stopwatch variables
    int _secondsLeft;
    NSTimer* _timer;
}

-(instancetype)init
{
    self = [super init];
    if (self != nil) {
        //initialize
        self.data = [[GameData alloc] init];
        self.audioController = [[AudioController alloc] init];
        [self.audioController preloadAudioEffects: kAudioEffectFiles];
    }
    return self;
}

//fetches a random anagram, deals the letter tiles and creates the targets
-(void)dealRandomAnagram
{
    //Make sure a level is loaded
    NSAssert(self.level.anagrams, @"no level loaded");
    
    //Pick a random anagram
    int randomIndex = arc4random()%[self.level.anagrams count];
    NSArray* anaPair = self.level.anagrams[ randomIndex ];
    
    //Store the anagrams individually
    NSString* anagram1 = anaPair[0];
    NSString* anagram2 = anaPair[1];
    
    //Find the length of each anagram
    int ana1len = [anagram1 length];
    int ana2len = [anagram2 length];
    
    //calculate the tile size
    float tileSide = ceilf( kScreenWidth*0.9 / (float)MAX(ana1len, ana2len) ) - kTileMargin;
    //get the left margin for first tile
    float xOffset = (kScreenWidth - MAX(ana1len, ana2len) * (tileSide + kTileMargin))/2;
    
    //adjust for tile center (instead of the tile's origin)
    xOffset += tileSide/2;
    
    // initialize target list
    _targets = [NSMutableArray arrayWithCapacity: ana2len];
    
    // create targets
    for (int i=0;i<ana2len;i++) {
        NSString* letter = [anagram2 substringWithRange:NSMakeRange(i, 1)];
        
        if (![letter isEqualToString:@" "]) {
            TargetView* target = [[TargetView alloc] initWithLetter:letter andSideLength:tileSide];
            target.center = CGPointMake(xOffset + i*(tileSide + kTileMargin), kScreenHeight/4);
            
            [self.gameView addSubview:target];
            [_targets addObject: target];
        }
    }
    
    //1 initialize tile list
    _tiles = [NSMutableArray arrayWithCapacity: ana1len];
    
    //2 create tiles
    for (int i=0;i<ana1len;i++) {
        NSString* letter = [anagram1 substringWithRange:NSMakeRange(i, 1)];
        
        //3
        if (![letter isEqualToString:@" "]) {
            TileView* tile = [[TileView alloc] initWithLetter:letter andSideLength:tileSide];
            tile.center = CGPointMake(xOffset + i*(tileSide + kTileMargin), kScreenHeight/4*3);
            [tile randomize];
            tile.dragDelegate = self;
            
            //4
            [self.gameView addSubview:tile];
            [_tiles addObject: tile];
        }
    }
    [self startStopwatch];
    self.hud.btnHelp.enabled = YES;
}

//a tile was dragged, check if matches a target
-(void)tileView:(TileView*)tileView didDragToPoint:(CGPoint)pt
{
    TargetView* targetView = nil;
    
    for (TargetView* tv in _targets) {
        if (CGRectContainsPoint(tv.frame, pt)) {
            targetView = tv;
            break;
        }
    }
    //1 check if target was found
    if (targetView!=nil) {
        
        //2 check if letter matches
        if ([targetView.letter isEqualToString: tileView.letter]) {
            
            //run animations to set tile in place
            [self placeTile:tileView atTarget:targetView];
            
            //give points
            self.data.points += self.level.pointsPerTile;
            [self.audioController playEffect: kSoundDing];
            [self.hud.gamePoints countTo:self.data.points withDuration:1.5];
            
            //check for finished game
            [self checkForSuccess];
            
        } else {
            
            //visualize the mistake
            [tileView randomize];
            
            //2
            [UIView animateWithDuration:0.35
                                  delay:0.00
                                options:UIViewAnimationOptionCurveEaseOut
                             animations:^{
                                 tileView.center = CGPointMake(tileView.center.x + randomf(-20, 20),
                                                               tileView.center.y + randomf(20, 30));
                             } completion:nil];
            
            //take out points
            self.data.points -= self.level.pointsPerTile/2;
            [self.audioController playEffect:kSoundWrong];
            [self.hud.gamePoints countTo:self.data.points withDuration:.75];
        }
    }
}
-(void)placeTile:(TileView*)tileView atTarget:(TargetView*)targetView
{
    //1
    targetView.isMatched = YES;
    tileView.isMatched = YES;
    
    //2
    tileView.userInteractionEnabled = NO;
    
    //3
    [UIView animateWithDuration:0.35
                          delay:0.00
                        options:UIViewAnimationOptionCurveEaseOut
     //4
                     animations:^{
                         tileView.center = targetView.center;
                         tileView.transform = CGAffineTransformIdentity;
                     }
     //5
                     completion:^(BOOL finished){
                         targetView.hidden = YES;
                     }];
    ExplodeView* explode = [[ExplodeView alloc] initWithFrame:CGRectMake(tileView.center.x,tileView.center.y,10,10)];
    [tileView.superview addSubview: explode];
    [tileView.superview sendSubviewToBack:explode];
}

-(void)checkForSuccess
{
    for (TargetView* t in _targets) {
        //no success, bail out
        if (t.isMatched==NO) return;
    }
    
    self.hud.btnHelp.enabled = NO;
    [self stopStopwatch];
    self.data.points += self.level.pointsPerTile*3;
    [self.audioController playEffect:kSoundWin];
    [self.hud.gamePoints countTo:self.data.points withDuration:3];
    
    //win animation
    TargetView* firstTarget = _targets[0];
    int startX = 0;
    int endX = kScreenWidth + 300;
    int startY = firstTarget.center.y;
    StarDustView* stars = [[StarDustView alloc] initWithFrame:CGRectMake(startX, startY, 10, 10)];
    [self.gameView addSubview:stars];
    [self.gameView sendSubviewToBack:stars];
    [UIView animateWithDuration:3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         stars.center = CGPointMake(endX, startY);
                     } completion:^(BOOL finished) {
                         
                         //game finished
                         [stars removeFromSuperview];
                         
                         //when animation is finished, show menu
                         [self clearBoard];
                         self.onAnagramSolved();
                     }];
}

-(void)startStopwatch
{
    //initialize the timer HUD
    _secondsLeft = self.level.timeToSolve;
    [self.hud.stopwatch setSeconds:_secondsLeft];
    
    //schedule a new timer
    _timer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                              target:self
                                            selector:@selector(tick:)
                                            userInfo:nil
                                             repeats:YES];
}

//stop the watch
-(void)stopStopwatch
{
    [_timer invalidate];
    _timer = nil;
}

//stopwatch on tick
-(void)tick:(NSTimer*)timer
{
    _secondsLeft --;
    [self.hud.stopwatch setSeconds:_secondsLeft];
    
    if (_secondsLeft==0) {
        [self stopStopwatch];
        self.data.points -= self.level.pointsPerTile*2;
        [self.hud.gamePoints countTo:self.data.points withDuration:2];
    }
}

//connect the Hint button
-(void)setHud:(HUDView *)hud
{
    _hud = hud;
    [hud.btnHelp addTarget:self action:@selector(actionHint) forControlEvents:UIControlEventTouchUpInside];
    hud.btnHelp.enabled = NO;
}

//the user pressed the hint button
-(void)actionHint
{
    self.hud.btnHelp.enabled = NO;
    
    self.data.points -= self.level.pointsPerTile/2;
    [self.hud.gamePoints countTo: self.data.points withDuration: 1.5];
    
    //3 find the first target, not matched yet
    TargetView* target = nil;
    for (TargetView* t in _targets) {
        if (t.isMatched==NO) {
            target = t;
            break;
        }
    }
    
    //4 find the first tile, matching the target
    TileView* tile = nil;
    for (TileView* t in _tiles) {
        if (t.isMatched==NO && [t.letter isEqualToString:target.letter]) {
            tile = t;
            break;
        }
    }
    // don't want the tile sliding under other tiles
    [self.gameView bringSubviewToFront:tile];
    
    //6
    //show the animation to the user
    [UIView animateWithDuration:1.5
                          delay:0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         tile.center = target.center;
                     } completion:^(BOOL finished) {
                         //7 adjust view on spot
                         [self placeTile:tile atTarget:target];
                         
                         //8 re-enable the button
                         self.hud.btnHelp.enabled = YES;
                         
                         //9 check for finished game
                         [self checkForSuccess];                     
                     }];
}

//clear the tiles and targets
-(void)clearBoard
{
    [_tiles removeAllObjects];
    [_targets removeAllObjects];
    
    for (UIView *view in self.gameView.subviews) {
        [view removeFromSuperview];
    }
}

@end
