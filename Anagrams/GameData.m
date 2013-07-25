//
//  GameData.m
//  Anagrams
//
//  Created by Paige Garratt on 5/30/13.
//  Copyright (c) 2013 Underplot ltd. All rights reserved.
//

#import "GameData.h"

@implementation GameData

//custom setter - keep the score positive
-(void)setPoints:(int)points
{
    _points = MAX(points, 0);
}

@end
