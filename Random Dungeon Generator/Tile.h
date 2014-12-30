//
//  Tile.h
//  Random Dungeon Generator
//
//  Created by Spencer Williams on 12/28/14.
//  Copyright (c) 2014 Spencer Williams. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, TileType) {
    TileTypeClosed,
    TileTypeOpen
};

@interface Tile : NSObject
@property (nonatomic, assign) TileType tileType;

@property (nonatomic, weak) Tile *north;
@property (nonatomic, weak) Tile *south;
@property (nonatomic, weak) Tile *east;
@property (nonatomic, weak) Tile *west;

@property (nonatomic, assign) NSInteger x;
@property (nonatomic, assign) NSInteger y;

@property (nonatomic, assign) BOOL mazeUnsolved;

/// @return Whether this tile is a dead end
- (BOOL)isDeadEnd;
/// @return Whether this tile is a corridor
- (BOOL)isCorridor;
/// @return Whether this tile is an intersection of corridors
- (BOOL)isCorridorJunction;
/// @return Whether this tile has no surrounding walls
- (BOOL)isUnwalled;

/// @return Whether this tile is the wall of any size space
- (BOOL)isWall;
/// @return Whether this tile is part of a larger room (not a corridor)
- (BOOL)isRoom;
/// @return Whether this tile is a doorway of a room
- (BOOL)isDoorway;

- (BOOL)isValidForMaze;

- (NSInteger)numOrthogonalOfType:(TileType)type;
- (NSInteger)numOrthogonalPassTest:(BOOL(^)(Tile *t))test;
- (NSInteger)numDiagonalOfType:(TileType)type;
- (NSInteger)numDiagonalPassTest:(BOOL(^)(Tile *t))test;
- (NSInteger)numOfTiles:(NSArray *)tiles passTest:(BOOL(^)(Tile *t))test;
@end
