//
//  Tile.m
//  Random Dungeon Generator
//
//  Created by Spencer Williams on 12/28/14.
//  Copyright (c) 2014 Spencer Williams. All rights reserved.
//

#import "Tile.h"

@implementation Tile
- (BOOL)isDeadEnd
{
    return (self.tileType == TileTypeOpen
            && [self numOrthogonalOfType:TileTypeOpen] == 1);
}
- (BOOL)isUnwalled
{
    return (self.tileType == TileTypeOpen
            && [self numOrthogonalOfType:TileTypeOpen] == 4);
}

- (BOOL)isWall
{
    return ([self isOrthogonalWall]
            || [self isDiagonalWall]);
}
- (BOOL)isOrthogonalWall
{
    return (self.tileType == TileTypeClosed
            && [self numOrthogonalOfType:TileTypeOpen] > 0);
}
- (BOOL)isDiagonalWall
{
    return (self.tileType == TileTypeClosed
            && [self numDiagonalOfType:TileTypeOpen] > 0);
}

- (BOOL)isCorridor
{
    if ([self isDeadEnd]
        && [self numOrthogonalPassTest:^BOOL(Tile *t) {
            return [t isRoom];
        }] == 0) return YES;
    return (self.tileType == TileTypeOpen
            && [self numOrthogonalOfType:TileTypeOpen] > 1
            && ![self isRoom]);
}
- (BOOL)isCorridorJunction
{
    return (self.tileType == TileTypeOpen
            && [self numOrthogonalPassTest:^BOOL(Tile *t) {
                return [t isCorridor];
            }] > 2);
}
- (BOOL)isRoom
{
    return [self isRoomRecurse:YES];
}
- (BOOL)isRoomRecurse:(BOOL)recurse
{
    // obvs
    if (self.tileType != TileTypeOpen) return NO;
    
    // check the alcoves
    if ([self isDeadEnd]
        && [self numOrthogonalPassTest:^BOOL(Tile *t) {
            if (recurse) {
                return [t isRoomRecurse:NO];
            } else {
                return NO;
            }
    }]) return YES;
    
    // any diagonals (i can get to) a room?
    if (self.north && self.north.tileType == TileTypeOpen) {
        if (self.east && self.east.tileType == TileTypeOpen
            && self.east.north && self.east.north.tileType == TileTypeOpen) return YES;
        if (self.west && self.west.tileType == TileTypeOpen
            && self.west.north && self.west.north.tileType == TileTypeOpen) return YES;
    }
    if (self.south && self.south.tileType == TileTypeOpen) {
        if (self.east && self.east.tileType == TileTypeOpen
            && self.east.north && self.east.south.tileType == TileTypeOpen) return YES;
        if (self.west && self.west.tileType == TileTypeOpen
            && self.west.north && self.west.south.tileType == TileTypeOpen) return YES;
    }
    
    
    return NO;
}
- (BOOL)isDoorway
{
    return ([self isCorridor]
            && [self numOrthogonalPassTest:^BOOL(Tile *t) {
        return [t isRoom];
    }] > 0);
}

- (BOOL)isValidForMaze
{
    TileType oldTileType = self.tileType;
    self.tileType = TileTypeOpen;
    BOOL isValidForMaze = (![self isRoom]);
//                           [self numOrthogonalPassTest:^BOOL(Tile *t) {
//                               return [t isRoom];
//                           }]==0
//                           && [self numDiagonalPassTest:^BOOL(Tile *t) {
//                               return [t isRoom];
//                           }]==0);
    self.tileType = oldTileType;
    return isValidForMaze;
}
- (NSInteger)numOrthogonalOfType:(TileType)type
{
    return [self numOrthogonalPassTest:^BOOL(Tile *t) {
        return t.tileType == type;
    }];
}
- (NSInteger)numOrthogonalPassTest:(BOOL(^)(Tile *t))test
{
    NSMutableArray *orthogonals = [NSMutableArray new];
    if (self.north != nil) [orthogonals addObject:self.north];
    if (self.east != nil) [orthogonals addObject:self.east];
    if (self.south != nil) [orthogonals addObject:self.south];
    if (self.west != nil) [orthogonals addObject:self.west];
    
    return [self numOfTiles:orthogonals passTest:test];
}
- (NSInteger)numDiagonalOfType:(TileType)type
{
    return [self numDiagonalPassTest:^BOOL(Tile *t) {
        return t.tileType == type;
    }];
}
- (NSInteger)numDiagonalPassTest:(BOOL(^)(Tile *t))test
{
    NSMutableArray *diagonals = [NSMutableArray new];
    if (self.north != nil) {
        if (self.north.west != nil) {
            [diagonals addObject:self.north.west];
        }
        if (self.north.east != nil) {
            [diagonals addObject:self.north.east];
        }
    }
    if (self.south != nil) {
        if (self.south.west != nil) {
            [diagonals addObject:self.south.west];
        }
        if (self.south.east != nil) {
            [diagonals addObject:self.south.east];
        }
    }
    
    return [self numOfTiles:diagonals passTest:test];
}
- (NSInteger)numOfTiles:(NSArray *)tiles passTest:(BOOL(^)(Tile *t))test
{
    NSInteger count = 0;
    for (Tile *t in tiles) {
        if (test(t)) count++;
    }
    return count;
}
@end
