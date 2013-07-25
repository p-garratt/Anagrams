//
//  AudioController.h
//  Anagrams
//
//  Created by Paige Garratt on 5/30/13.
//  Copyright (c) 2013 Underplot ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AudioController : NSObject

-(void)playEffect:(NSString*)name;
-(void)preloadAudioEffects:(NSArray*)effectFileNames;

@end
