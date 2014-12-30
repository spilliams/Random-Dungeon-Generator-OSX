//
//  Dungeon.m
//  Random Dungeon Generator
//
//  Created by Spencer Williams on 12/28/14.
//  Copyright (c) 2014 Spencer Williams. All rights reserved.
//

#import "Dungeon.h"

@interface Dungeon () {
    unsigned int seed;
}
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
            
            BOOL drawLowerHalf = NO;
            
            if ([t isCorridorJunction]) {
                [[NSColor whiteColor] setFill];
                drawLowerHalf = YES;
            }
            if ([t isDeadEnd]) {
                [[NSColor purpleColor] setFill];
                drawLowerHalf = YES;
            }
            if ([t isDoorway]) {
                [[NSColor brownColor] setFill];
                drawLowerHalf = YES;
            }
            
            if (drawLowerHalf) {
                NSBezierPath *path = [NSBezierPath bezierPath];
                [path moveToPoint:tileRect.origin];
                [path lineToPoint:NSMakePoint(tileRect.origin.x + tileRect.size.width,
                                              tileRect.origin.y + tileRect.size.height)];
                [path lineToPoint:NSMakePoint(tileRect.origin.x + tileRect.size.width,
                                              tileRect.origin.y)];
                [path closePath];
                [path fill];
            }
            
            if (t.mazeUnsolved) {
                [[NSColor redColor] setFill];
                [[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(tileRect.origin.x + tileRect.size.width/4.0,
                                                                   tileRect.origin.y + tileRect.size.height/4.0,
                                                                   tileRect.size.width/2.0,
                                                                   tileRect.size.height/2.0)] fill];
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
    
    newTile.x = column;
    newTile.y = row;
    
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
    ((Tile *)self.rows[0][55]).tileType = TileTypeOpen;
    ((Tile *)self.rows[0][57]).tileType = TileTypeOpen;
    ((Tile *)self.rows[0][56]).tileType = TileTypeOpen;
    ((Tile *)self.rows[0][56]).tileType = TileTypeOpen;
    ((Tile *)self.rows[1][55]).tileType = TileTypeOpen;
    ((Tile *)self.rows[1][56]).tileType = TileTypeOpen;
    ((Tile *)self.rows[1][57]).tileType = TileTypeOpen;
    ((Tile *)self.rows[0][56]).tileType = TileTypeOpen;
    ((Tile *)self.rows[0][58]).tileType = TileTypeOpen;
    ((Tile *)self.rows[0][59]).tileType = TileTypeOpen;
    ((Tile *)self.rows[0][60]).tileType = TileTypeOpen;
    ((Tile *)self.rows[0][54]).tileType = TileTypeOpen;
    ((Tile *)self.rows[0][53]).tileType = TileTypeOpen;
    ((Tile *)self.rows[0][52]).tileType = TileTypeOpen;

    [self setNeedsDisplay:YES];
}

- (void)generateRooms
{
    // TODO: implement me!
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
    BOOL hellaJunctions = YES;
    
    // pick origin
    Tile *mazeOrigin;
    while (mazeOrigin == nil) {
        seed = (unsigned int)[NSNumber numberWithDouble:[NSDate timeIntervalSinceReferenceDate]];
        seed = rand_r(&seed);
        long rowIndex = seed%self.rows.count;
        NSAssert(rowIndex < self.rows.count, @"Row index too large!");
        NSAssert(rowIndex >= 0, @"Row index too small!");
        NSArray *randomRow = self.rows[rowIndex];
        seed = rand_r(&seed);
        long columnIndex = seed%randomRow.count;
        NSAssert(columnIndex < randomRow.count, @"Column index too large!");
        NSAssert(columnIndex >= 0, @"Column index too small!");
        Tile *candidate = randomRow[columnIndex];
        if ([candidate isValidForMaze]) {
            mazeOrigin = candidate;
        }
    }
    NSLog(@"[DV] picked maze origin");
    mazeOrigin.tileType = TileTypeOpen;
    mazeOrigin.mazeUnsolved = YES;
    if (redrawPerTile) [self setNeedsDisplay:YES];
    
    // set up list of unsolved endpoints
    NSMutableArray *unsolved = [@[mazeOrigin] mutableCopy];
    
    // we can expect to do AT MOST width*height operations
    int operations = 0;
    while (unsolved.count > 0 && operations < self.width * self.height * 4) {
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
                seed = rand_r(&seed);
                tileIndex = (int)(seed%unsolved.count);
                break;
            case MazePickTypeOldest:
                tileIndex = (int)(unsolved.count-1);
                break;
            case MazePickTypeRandomNew:
                seed = rand_r(&seed);
                tileIndex = (int)(seed%(int)(unsolved.count*newOldThreshold));
                break;
            case MazePickTypeRandomOld:
                seed = rand_r(&seed);
                tileIndex = (int)unsolved.count - (int)(seed%(int)(unsolved.count*newOldThreshold));
                break;
        }
        NSAssert(tileIndex >= 0, @"Tile index too small!");
        NSAssert(tileIndex < unsolved.count, @"Tile index too large!");
        Tile *t = unsolved[tileIndex];
        
        // carve an unmade cell next to it
        // assume t is open, and will return YES to `-isCorridor`.
        // assume nothing about its orthogonals though
        NSMutableArray *nextCandidates = [NSMutableArray new];
        NSMutableArray *toCheck = [NSMutableArray new];
        if (t.north) [toCheck addObject:t.north];
        if (t.south && t.south.tileType == TileTypeClosed) [toCheck addObject:t.south];
        if (t.east  && t.east.tileType  == TileTypeClosed) [toCheck addObject:t.east];
        if (t.west  && t.west.tileType  == TileTypeClosed) [toCheck addObject:t.west];
        for (Tile *ortho in toCheck) {
            if (hellaJunctions) {
                if (ortho.tileType == TileTypeClosed
                    && [ortho isValidForMaze]) {
                    [nextCandidates addObject:ortho];
                }
            } else {
                if (ortho.tileType == TileTypeClosed
                    && [ortho numOrthogonalOfType:TileTypeOpen] == 1) {
                    [nextCandidates addObject:ortho];
                }
            }
            
        }
        if (nextCandidates.count == 0) {
            // no candidates for continuing, so this tile is solved
            [unsolved removeObject:t];
            t.mazeUnsolved = NO;
        } else {
            seed = rand_r(&seed);
            Tile *next = nextCandidates[seed%nextCandidates.count];
            [next setTileType:TileTypeOpen];
            next.mazeUnsolved = YES;
            [unsolved insertObject:next atIndex:0];
        }
        
        if (![t isValidForMaze]) {
            [unsolved removeObject:t];
            t.mazeUnsolved = NO;
        }
        
        if (redrawPerTile) {
            [self displayRect:NSMakeRect(self.tileSize.width * (t.x-1),
                                         self.tileSize.height * (t.y-1),
                                         self.tileSize.width * 3.0,
                                         self.tileSize.height * 3.0)];
        }
        operations++;
    }
    // maze should be solved!
    NSLog(@"solve loop finished. %i unsolved", (int)unsolved.count);
    
    // in case it wasn't, light up the unsolved ones...
    for (Tile *t in unsolved) {
        t.mazeUnsolved = YES;
    }
    [self setNeedsDisplay:YES];
}

@end
