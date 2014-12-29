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
    return (self.tileType == SWTileTypeOpen
            && [self numOrthogonalOfType:SWTileTypeOpen] == 1);
}
- (BOOL)isCorridor
{
    return (self.tileType == SWTileTypeOpen
            && [self numOrthogonalOfType:SWTileTypeOpen] == 2);
}
- (BOOL)isUnwalled
{
    return (self.tileType == SWTileTypeOpen
            && [self numOrthogonalOfType:SWTileTypeOpen] == 4);
}

- (BOOL)isWall
{
    return ([self isOrthogonalWall]
            || [self isDiagonalWall]);
}
- (BOOL)isOrthogonalWall
{
    return (self.tileType == SWTileTypeClosed
            && [self numOrthogonalOfType:SWTileTypeOpen] > 0);
}
- (BOOL)isDiagonalWall
{
    return (self.tileType == SWTileTypeClosed
            && [self numDiagonalOfType:SWTileTypeOpen] > 0);
}

- (NSInteger)numOrthogonalOfType:(SWTileType)type
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
- (NSInteger)numDiagonalOfType:(SWTileType)type
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
