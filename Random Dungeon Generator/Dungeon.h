//
//  Dungeon.h
//  Random Dungeon Generator
//
//  Created by Spencer Williams on 12/28/14.
//  Copyright (c) 2014 Spencer Williams. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Tile.h"

// For explanation of what all this means, check out
// see http://www.astrolog.org/labyrnth/algrithm.htm

typedef NS_ENUM(NSInteger, MazeGenerationAlgorithm) {
    MazeGenerationAlgorithmGrowingTree,
    // recursive backtracker
    // prim's
    // kruskal's
    // aldous-broder
    // wilson's
    // hunt and kill
    // eller's
    // recursive division
    // binary tree
    // sidewinder
};

/// The "shape" of the maze
typedef NS_ENUM(NSInteger, MazeTesellation) {
    MazeTesellationOrthogonal,  // "normal", "rectilinear", "square", "Cartesian"
//    MazeTesellationDelta,       // "triangular"
//    MazeTesellationSigma,       // "hexagonal"
//    MazeTesellationTheta,       // "concentric rings", "minotaur-style"
//    MazeTesellationUpsilon,     // "octagons and squares"
//    MazeTesellationZeta,        // "square grid but with orthogonal and diagonal passages"
};
// leaves out "Crack", where there's no discernable order (requires too many pixels),
// and "Fractal", where the maze is a fractal! (too tedious...)

typedef NS_ENUM(NSInteger, MazePickType) {
    MazePickTypeRiver,
    MazePickTypeNewest,
    MazePickTypeRandom,
    MazePickTypeRandomNew,
    MazePickTypeRandomOld,
    MazePickTypeOldest
};

@interface Dungeon : NSView

@property (nonatomic, assign) MazeGenerationAlgorithm algorithm;
@property (nonatomic, assign) MazeTesellation tesellation;
@property (nonatomic, assign) MazePickType pickType;
@property (nonatomic, assign) BOOL detailedDraw;
@property (nonatomic, assign) float roomDensity;
@property (nonatomic, assign) float roomMaxAspectRatio;
@property (nonatomic, assign) int roomBallparkCount;

- (void)createWithTileSize:(NSSize)newTileSize rows:(NSInteger)newRows columns:(NSInteger)newColumns reframePerTile:(BOOL)reframePerTile;

- (void)generateRoomsRedrawPerRoom:(BOOL)redrawPerRoom;;
- (void)generateMazeRedrawPerTile:(BOOL)redrawPerTile;
- (void)generateDoors;
- (void)pruneDeadEndsRedrawPerTile:(BOOL)redrawPerTile;
@end
