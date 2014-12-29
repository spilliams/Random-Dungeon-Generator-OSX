//
//  Dungeon.m
//  Random Dungeon Generator
//
//  Created by Spencer Williams on 12/28/14.
//  Copyright (c) 2014 Spencer Williams. All rights reserved.
//

#import "Dungeon.h"

@interface Dungeon ()
@property (nonatomic, strong) NSMutableArray *rows;
@property (nonatomic, assign) NSInteger width;
@property (nonatomic, assign) NSInteger height;

@property (nonatomic, assign) NSSize tileSize;

@property (nonatomic, strong) NSClickGestureRecognizer *clickGR;
- (void)handleClickGesture:(NSGestureRecognizer *)clickGR;
@end

#define kColorOpen
#define kColorClosed

@implementation Dungeon

- (void)awakeFromNib
{
    [super awakeFromNib];
    if (self.clickGR == nil) {
        self.clickGR = [[NSClickGestureRecognizer alloc] initWithTarget:self action:@selector(handleClickGesture:)];
        [self addGestureRecognizer:self.clickGR];
    }
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
    for (int r=0; r<self.height; r++) {
        for (int c=0; c<self.width; c++) {
            Tile *t = ((Tile *)self.rows[r][c]);
            BOOL colored = NO;
            
            if (t.tileType == TileTypeClosed) {
                [[NSColor blackColor] setFill];
                colored = YES;
            }
            
            if ([t isWall]) {
                [[NSColor darkGrayColor] setFill];
                colored = YES;
            }
            
            if ([t isRoom]) {
                if (colored) { NSLog(@"[DV] wall is room"); [[NSColor magentaColor] setFill];}
                else [[NSColor blueColor] setFill];
                colored = YES;
            }
            if ([t isCorridor]) {
                if (colored) { NSLog(@"[DV] corridor is room or wall"); [[NSColor magentaColor] setFill];}
                else [[NSColor cyanColor] setFill];
                colored = YES;
            }
            
            if (!colored) {
                [[NSColor redColor] setFill];
            }
            NSRect tileRect = [self rectForTileAtRow:r column:c];
            [NSBezierPath fillRect:tileRect];
            
            BOOL drawHalf = NO;
            
            if ([t isCorridorJunction]) {
                [[NSColor whiteColor] setFill];
                drawHalf = YES;
            }
            if ([t isDeadEnd]) {
                [[NSColor purpleColor] setFill];
                drawHalf = YES;
            }
            if ([t isDoorway]) {
                [[NSColor brownColor] setFill];
                drawHalf = YES;
            }
            
            if (drawHalf) {
                NSBezierPath *path = [NSBezierPath bezierPath];
                [path moveToPoint:tileRect.origin];
                [path lineToPoint:NSMakePoint(tileRect.origin.x + tileRect.size.width,
                                              tileRect.origin.y + tileRect.size.height)];
                [path lineToPoint:NSMakePoint(tileRect.origin.x + tileRect.size.width,
                                              tileRect.origin.y)];
                [path closePath];
                [path fill];
            }
        }
    }
}

- (void)createWithDungeonTileSize:(NSSize)newTileSize rows:(NSInteger)newRows columns:(NSInteger)newColumns reframePerTile:(BOOL)reframePerTile
{
    self.width = newColumns;
    self.height = newRows;
    self.tileSize = newTileSize;
    
    [self setFrameSize:NSMakeSize(self.width*self.tileSize.width, self.height*self.tileSize.height)];
    
    self.rows = [[NSMutableArray alloc] initWithCapacity:self.height];
    
    for (int r=0; r<self.height; r++) {
        NSMutableArray *row = [[NSMutableArray alloc] initWithCapacity:self.width];
        [self.rows addObject:row];
        
        for (int c=0; c<self.width; c++) {
            Tile *t = [Tile new];
            [self.rows[r] addObject:t];
            [self updateTileAtRow:r column:c withTile:t redraw:reframePerTile];
        }
    }
    
    [self setNeedsDisplay:YES];
}

- (void)updateTileAtRow:(NSInteger)row column:(NSInteger)column withTile:(Tile *)newTile redraw:(BOOL)redraw
{
    NSAssert(self.rows!=nil, @"[DV] Rows can't be nil");
    NSAssert(self.rows.count>row,@"[DV] Row must exist");
    NSMutableArray *thisRow = ((NSMutableArray *)self.rows[row]);
    NSAssert(thisRow.count>column, @"[DV] Row must be long enough");
    
    // connect it to the north
    if (row > 0) {
        NSAssert(((NSMutableArray *)self.rows[row-1]) != nil, @"Row above must exist");
        NSAssert(((NSMutableArray *)self.rows[row-1]).count > column, @"Row above must be long enough");
        Tile *northTile = ((Tile *)((NSMutableArray *)self.rows[row-1])[column]);
        [newTile setNorth:northTile];
        [northTile setSouth:newTile];
    }
    // connect it to the south
    if (row < self.rows.count-1) {
        NSAssert(((NSMutableArray *)self.rows[row+1]) != nil, @"Row below must exist");
        NSAssert(((NSMutableArray *)self.rows[row+1]).count > column, @"Row below must be long enough");
        Tile *southTile = ((Tile *)((NSMutableArray *)self.rows[row+1])[column]);
        [newTile setSouth:southTile];
        [southTile setNorth:newTile];
    }
    // connect it to the west
    if (column > 0) {
        [newTile setWest:thisRow[column-1]];
        [thisRow[column-1] setEast:newTile];
    }
    // connect it to the east
    if (column < thisRow.count-1) {
        [newTile setEast:thisRow[column+1]];
        [thisRow[column+1] setWest:newTile];
    }
    
    [thisRow replaceObjectAtIndex:column withObject:newTile];
    
    if (redraw) [self setNeedsDisplay:YES];
}

- (void)setupForTests
{
    ((Tile *)self.rows[47][43]).tileType = TileTypeOpen;
    ((Tile *)self.rows[46][43]).tileType = TileTypeOpen;
    ((Tile *)self.rows[45][43]).tileType = TileTypeOpen;
    ((Tile *)self.rows[46][44]).tileType = TileTypeOpen;
    ((Tile *)self.rows[46][42]).tileType = TileTypeOpen;
    ((Tile *)self.rows[46][45]).tileType = TileTypeOpen;
    ((Tile *)self.rows[38][43]).tileType = TileTypeOpen;
    ((Tile *)self.rows[38][42]).tileType = TileTypeOpen;
    ((Tile *)self.rows[39][42]).tileType = TileTypeOpen;
    ((Tile *)self.rows[39][43]).tileType = TileTypeOpen;
    ((Tile *)self.rows[38][44]).tileType = TileTypeOpen;
    ((Tile *)self.rows[38][45]).tileType = TileTypeOpen;
    ((Tile *)self.rows[38][46]).tileType = TileTypeOpen;
    ((Tile *)self.rows[38][47]).tileType = TileTypeOpen;
    ((Tile *)self.rows[39][47]).tileType = TileTypeOpen;
    ((Tile *)self.rows[40][47]).tileType = TileTypeOpen;
    ((Tile *)self.rows[41][47]).tileType = TileTypeOpen;
    ((Tile *)self.rows[42][47]).tileType = TileTypeOpen;
    ((Tile *)self.rows[43][47]).tileType = TileTypeOpen;
    ((Tile *)self.rows[44][47]).tileType = TileTypeOpen;
    ((Tile *)self.rows[45][47]).tileType = TileTypeOpen;
    ((Tile *)self.rows[46][47]).tileType = TileTypeOpen;
    ((Tile *)self.rows[46][46]).tileType = TileTypeOpen;
    ((Tile *)self.rows[33][43]).tileType = TileTypeOpen;
    ((Tile *)self.rows[32][43]).tileType = TileTypeOpen;
    ((Tile *)self.rows[31][43]).tileType = TileTypeOpen;
    ((Tile *)self.rows[31][42]).tileType = TileTypeOpen;
    ((Tile *)self.rows[32][42]).tileType = TileTypeOpen;
    ((Tile *)self.rows[33][42]).tileType = TileTypeOpen;
    ((Tile *)self.rows[32][41]).tileType = TileTypeOpen;
    ((Tile *)self.rows[32][44]).tileType = TileTypeOpen;
    ((Tile *)self.rows[32][45]).tileType = TileTypeOpen;
    ((Tile *)self.rows[32][46]).tileType = TileTypeOpen;
    ((Tile *)self.rows[37][47]).tileType = TileTypeOpen;
    ((Tile *)self.rows[36][47]).tileType = TileTypeOpen;
    ((Tile *)self.rows[35][47]).tileType = TileTypeOpen;
    ((Tile *)self.rows[34][47]).tileType = TileTypeOpen;
    ((Tile *)self.rows[33][47]).tileType = TileTypeOpen;
    ((Tile *)self.rows[32][47]).tileType = TileTypeOpen;
    ((Tile *)self.rows[32][41]).tileType = TileTypeOpen;
    ((Tile *)self.rows[33][41]).tileType = TileTypeOpen;
    ((Tile *)self.rows[39][41]).tileType = TileTypeOpen;
    ((Tile *)self.rows[31][43]).tileType = TileTypeOpen;
    for (int r=24; r<35; r++) {
        for (int c=66; c<71; c++) {
            if (c != 68
                || r%2 != 1) {
                ((Tile *)self.rows[r][c]).tileType = TileTypeOpen;
            }
        }
    }
    [self setNeedsDisplay:YES];
}

- (void)generateRooms
{
    
}

- (void)generateMaze
{
    [self generateGrowingTreeMaze];
}

#pragma mark - Private Helpers

- (NSRect)rectForTileAtRow:(NSInteger)row column:(NSInteger)column
{
    return NSMakeRect(column*self.tileSize.width,
                      row*self.tileSize.height,
                      self.tileSize.width,
                      self.tileSize.height);
}

- (void)handleClickGesture:(NSGestureRecognizer *)clickGR
{
    NSPoint point = [clickGR locationInView:self];
    NSInteger row = point.y / self.tileSize.height;
    NSInteger column = point.x / self.tileSize.width;
    
    NSLog(@"click on tile at row %li column %li", row, column);
    Tile *t = self.rows[row][column];
    switch (t.tileType) {
        case TileTypeClosed:
            [t setTileType:TileTypeOpen];
            break;
        case TileTypeOpen:
            [t setTileType:TileTypeClosed];
            break;
    }
    [self setNeedsDisplay:YES];
}

- (void)generateGrowingTreeMaze
{
    // a little setup
    BOOL redrawPerTile = YES;
    float newOldThreshold = 0.25; // percentage of the unsolved cells that are "new" or "old"
    typedef NS_ENUM(NSInteger, MazePickType) {
        MazePickTypeNewest,
        MazePickTypeRandom,
        MazePickTypeRandomNew,
        MazePickTypeRandomOld,
        MazePickTypeOldest
    };
    // other pick types:
    // usually pick most recent, sometimes random: high "river" factor but short direct solution
    MazePickType pickType = MazePickTypeNewest;
    
    // pick origin
    Tile *mazeOrigin;
    while (mazeOrigin == nil) {
        long rowIndex = random()%self.rows.count;
        NSAssert(rowIndex < self.rows.count, @"Row index too large!");
        NSAssert(rowIndex >= 0, @"Row index too small!");
        NSArray *randomRow = self.rows[rowIndex];
        long columnIndex = random()%randomRow.count;
        NSAssert(columnIndex < randomRow.count, @"Column index too large!");
        NSAssert(columnIndex >= 0, @"Column index too small!");
        Tile *candidate = randomRow[columnIndex];
        if ([candidate isValidForMaze]) {
            mazeOrigin = candidate;
        }
    }
    NSLog(@"[DV] picked maze origin");
    mazeOrigin.tileType = TileTypeOpen;
    if (redrawPerTile) [self setNeedsDisplay:YES];
    
    // set up list of unsolved endpoints
    NSMutableArray *unsolved = [@[mazeOrigin] mutableCopy];
    
    while (unsolved.count > 0) {
        NSLog(@"  unsolved has %li", unsolved.count);
        // pick a tile from unsolved
        int tileIndex = 0;
        if (unsolved.count * newOldThreshold == 0
            && (pickType == MazePickTypeRandomNew
                || pickType == MazePickTypeRandomOld)) {
            pickType = MazePickTypeRandom;
        }
        switch (pickType) {
            case MazePickTypeNewest:
                // tile index is already 0
                break;
            case MazePickTypeRandom:
                tileIndex = (int)(random()%unsolved.count);
                break;
            case MazePickTypeOldest:
                tileIndex = (int)(unsolved.count-1);
                break;
            case MazePickTypeRandomNew:
                tileIndex = (int)(random()%(int)(unsolved.count*newOldThreshold));
                break;
            case MazePickTypeRandomOld:
                tileIndex = (int)unsolved.count - (int)(random()%(int)(unsolved.count*newOldThreshold));
                break;
        }
        NSAssert(tileIndex >= 0, @"Tile index too small!");
        NSAssert(tileIndex < unsolved.count, @"Tile index too large!");
        Tile *t = unsolved[tileIndex];
        NSLog(@"    picked %@", t.hash);
        
        // pick an orthogonal that's valid
        // ASK: should this be dynamic? are there other algorithms to pick the neighbor?
        NSMutableArray *candidates = [NSMutableArray new];
        if (t.north && [t.north isValidForMaze]) [candidates addObject:t.north];
        if (t.east && [t.east isValidForMaze]) [candidates addObject:t.east];
        if (t.west && [t.west isValidForMaze]) [candidates addObject:t.west];
        if (t.south && [t.south isValidForMaze]) [candidates addObject:t.south];
        if (candidates.count == 0) {
            NSLog(@"    no candidates, removing");
            [unsolved removeObject:t];
        } else {
            int nextIndex = (int)random()%candidates.count;
            Tile *nextTile = candidates[nextIndex];
            nextTile.tileType = TileTypeOpen;
            if (![unsolved containsObject:nextTile]) {
                NSLog(@"    adding candidate %i to unsolved", nextIndex);
                [unsolved insertObject:nextTile atIndex:0];
            } else {
                NSLog(@"    unsolved already has candidate %i", nextIndex);
            }
            if (redrawPerTile) [self setNeedsDisplay:YES];
        }
    }
    // maze should be solved!
}

@end
