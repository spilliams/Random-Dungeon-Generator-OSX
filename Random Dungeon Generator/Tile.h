//
//  Tile.h
//  Random Dungeon Generator
//
//  Created by Spencer Williams on 12/28/14.
//  Copyright (c) 2014 Spencer Williams. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, SWTileType) {
    SWTileTypeClosed,
    SWTileTypeOpen
};

@interface Tile : NSObject
@property (nonatomic, assign) SWTileType tileType;

@property (nonatomic, weak) Tile *north;
@property (nonatomic, weak) Tile *south;
@property (nonatomic, weak) Tile *east;
@property (nonatomic, weak) Tile *west;

@end
