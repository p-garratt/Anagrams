//
//  CounterLabelView.h
//  Anagrams
//
//  Created by Paige Garratt on 5/30/13.
//  Copyright (c) 2013 Underplot ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CounterLabelView : UILabel

@property (assign, nonatomic) int value;

+(instancetype)labelWithFont:(UIFont*)font frame:(CGRect)r andValue:(int)v;
-(void)countTo:(int)to withDuration:(float)t;

@end
