//
//  Dungeon.h
//  Random Dungeon Generator
//
//  Created by Spencer Williams on 12/28/14.
//  Copyright (c) 2014 Spencer Williams. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Tile.h"

@protocol DungeonDelegate <NSObject>
@optional
- (void)mazeFinishedInTime:(NSTimeInterval)time;

@end

@interface Dungeon : NSView
@property (nonatomic, weak) IBOutlet id<DungeonDelegate> delegate;
- (void)createWithDungeonTileSize:(NSSize)newTileSize rows:(NSInteger)newRows columns:(NSInteger)newColumns reframePerTile:(BOOL)reframePerTile;
- (void)updateTileAtRow:(NSInteger)row column:(NSInteger)column withTile:(Tile *)newTile redraw:(BOOL)redraw;

- (void)setupForTests;
- (void)generateRooms;
- (void)generateMaze;
@end
