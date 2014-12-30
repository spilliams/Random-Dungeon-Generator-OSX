//
//  Dungeon.m
//  Random Dungeon Generator
//
//  Created by Spencer Williams on 12/28/14.
//  Copyright (c) 2014 Spencer Williams. All rights reserved.
//

#import "Dungeon.h"

#define LOG_MAZE NO
#define kColorOpen
#define kColorClosed

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


@implementation Dungeon

- (instancetype)init {
    if (self = [super init]) {
        [self commonInit];
    }
    return self;
}
- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        [self commonInit];
    }
    return self;
}
- (instancetype)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        [self commonInit];
    }
    return self;
}
- (void)commonInit {
    self.algorithm = MazeGenerationAlgorithmGrowingTree;
    self.tesellation = MazeTesellationOrthogonal;
}

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
                else [[NSColor lightGrayColor] setFill];
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
            
//            if (drawLowerHalf) {
//                NSBezierPath *path = [NSBezierPath bezierPath];
//                [path moveToPoint:tileRect.origin];
//                [path lineToPoint:NSMakePoint(tileRect.origin.x + tileRect.size.width,
//                                              tileRect.origin.y + tileRect.size.height)];
//                [path lineToPoint:NSMakePoint(tileRect.origin.x + tileRect.size.width,
//                                              tileRect.origin.y)];
//                [path closePath];
//                [path fill];
//            }
            
            if (t.mazeUnsolved) {
                [[NSColor cyanColor] setFill];
                [NSBezierPath fillRect:tileRect];
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

- (void)setupForRooms
{
    [self makeRoomStartPoint:NSMakePoint(4, 5) endPoint:NSMakePoint(10, 10)];
    [self makeRoomStartPoint:NSMakePoint(21, 13) endPoint:NSMakePoint(16, 19)];
    [self makeRoomStartPoint:NSMakePoint(30, 22) endPoint:NSMakePoint(20, 25)];
    [self makeRoomStartPoint:NSMakePoint(10, 17) endPoint:NSMakePoint(4, 25)];
    [self makeRoomStartPoint:NSMakePoint(24, 1) endPoint:NSMakePoint(16, 6)];
    
    [self makeRoomStartPoint:NSMakePoint(27, 17) endPoint:NSMakePoint(33, 11)];
    [self makeRoomStartPoint:NSMakePoint(40, 23) endPoint:NSMakePoint(44, 14)];
    [self makeRoomStartPoint:NSMakePoint(51, 9) endPoint:NSMakePoint(38, 2)];
}
- (void)makeRoomStartPoint:(NSPoint)startPt endPoint:(NSPoint)endPt
{
    NSPoint origin = NSMakePoint(MIN(startPt.x, endPt.x),
                                 MIN(startPt.y, endPt.y));
    NSSize size = NSMakeSize(MAX(startPt.x, endPt.x) - origin.x,
                             MAX(startPt.y, endPt.y) - origin.y);
    origin.x = MAX(1, origin.x);
    origin.y = MAX(1, origin.y);
    size.width = MIN(size.width, self.width - origin.x - 2);
    size.height = MIN(size.height, self.height - origin.y - 2);
    [self makeRoomRect:NSMakeRect(origin.x, origin.y, size.width, size.height)];
}
- (void)makeRoomRect:(NSRect)rect
{
    for (int r=rect.origin.y; r<rect.origin.y+rect.size.height; r++) {
        for (int c=rect.origin.x; c<rect.origin.x+rect.size.width; c++) {
            ((Tile *)self.rows[r][c]).tileType = TileTypeOpen;
        }
    }
    [self display];
    [NSThread sleepForTimeInterval:0.5];
}

- (void)generateRooms
{
    // TODO: debug this. infinite loop right now?
    // I probably made this more complicated than it needed to be...
    
    // givens
    BOOL redrawPerRoom = YES;
    float roomDensity = 0.4; // the percentage of total floor space that should be room in the end
    int ballparkNRooms = 10; // determines the average size of the rooms (this number is just a ballpark of the final number of rooms!)
    float targetAspectRatio = 16/9.0; // ie the most oblong room's ratio of width:height. 1 means all square rooms, 0 and infinity are bad. Negative numbers are untested...
    int roomPlacementTriesMax = 15;
    
    // derived
    int totalRoomSquares = self.width * self.height * roomDensity;
    float squaresPerRoom = totalRoomSquares / ((float)ballparkNRooms);
    float minAspectRatio = MIN(targetAspectRatio, 1.0/targetAspectRatio);
    float maxAspectRatio = MAX(targetAspectRatio, 1.0/targetAspectRatio);
    
    int countRoomSquares = 0;
    
    NSMutableArray *rooms = [NSMutableArray new];
    
    while (countRoomSquares < totalRoomSquares) {
        
        if (seed == 0) seed = (unsigned int)[NSNumber numberWithDouble:[NSDate timeIntervalSinceReferenceDate]];
        seed = rand_r(&seed);
        float precision = 100.0;
        // basically, pick a random aspect ratio between min and max
        float roomAspectRatio = (seed%(int)((maxAspectRatio - minAspectRatio)*precision))/precision + minAspectRatio;
        
        // roomH * roomW ~= squaresPerRoom
        // if roomAspectRatio > 1, room is wider than it is tall
        // roomW = roomH * roomAspectRatio
        // roomH * (roomH * roomAspectRatio) ~= squaresPerRoom
        int roomH = (int)round(sqrt(squaresPerRoom / roomAspectRatio));
        int roomW = (int)ceil(squaresPerRoom / roomH);
        
        NSRect room = NSZeroRect;
        room.size = NSMakeSize(roomW, roomH);
        
        // attempt to place room
        BOOL roomPlaced = NO;
        int roomPlacementTries = 0;
        while (!roomPlaced && roomPlacementTries < roomPlacementTriesMax) {
            
            // pick an origin that allows the room to fit within the dungeon bounds
            int xMin = 1;
            int yMin = 1;
            int xMax = self.width - room.size.width - 1;
            int yMax = self.height - room.size.height - 1;
            seed = rand_r(&seed);
            room.origin.x = (seed%(xMax-xMin)) + xMin;
            room.origin.y = (seed%(yMax-yMin)) + yMin;
            
            // does room collide with any of the other rooms? Keep in mind we need to leave wall space between them
            BOOL collision = NO;
            for (NSValue *v in rooms) {
                NSRect collider = [v rectValue];
                int buffer = 2;
                collider = NSMakeRect(collider.origin.x-buffer,
                                      collider.origin.y-buffer,
                                      collider.size.width+buffer*2,
                                      collider.size.height+buffer*2);
                if (CGRectIntersectsRect(room, collider)) {
                    collision = YES;
                    continue;
                }
            }
            
            if (!collision) {
                // it's a go! carve out the room
                for (int r=room.origin.y; r<room.origin.y+room.size.height; r++) {
                    for (int c=room.origin.x; c<room.origin.x+room.size.width; c++) {
                        ((Tile *)self.rows[r][c]).tileType = TileTypeOpen;
                    }
                }
                if (redrawPerRoom) [self displayRect:NSMakeRect(room.origin.x-1, room.origin.y-1, room.size.width+2, room.size.height+2)];
                [rooms addObject:[NSValue valueWithRect:room]];
                roomPlaced = YES;
            }
            
            roomPlacementTries++;
        }
        if (roomPlaced) {
            countRoomSquares += roomH * roomW;
        }
    }
}

- (void)generateMaze
{
    NSDate *start = [NSDate date];
    
    switch (self.algorithm) {
        case MazeGenerationAlgorithmGrowingTree:
            [self generateGrowingTreeMaze];
            break;
    }
    
    NSTimeInterval elapsed = [[NSDate date] timeIntervalSinceDate:start];
    if (self.delegate
        && [self.delegate conformsToProtocol:@protocol(DungeonDelegate)]
        && [self.delegate respondsToSelector:@selector(mazeFinishedInTime:)]) {
        [self.delegate mazeFinishedInTime:elapsed];
    }
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
    
    // first, check to see if the origin has been picked by the user
    // pick the first non-room tile you find
    for (int r=0; r<self.height; r++) {
        for (int c=0; c<self.width; c++) {
            Tile *t = ((Tile *)self.rows[r][c]);
            if (t.tileType == TileTypeOpen
                && [t numAdjacentOfType:TileTypeOpen] == 0) {
                NSLog(@"[DV] using pre-selected maze origin %i,%i", (int)t.x, (int)t.y);
                mazeOrigin = t;
                continue;
            }
        }
        if (mazeOrigin != nil) continue;
    }
    
    if (mazeOrigin == nil) {
        int guesses = 0;
        while (mazeOrigin == nil && guesses < self.width*self.height) {
            if (seed == 0) seed = (unsigned int)[NSNumber numberWithDouble:[NSDate timeIntervalSinceReferenceDate]];
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
            if (candidate.tileType == TileTypeClosed
                && [candidate numAdjacentOfType:TileTypeOpen == 0]) {
                NSLog(@"[DV] picked random maze origin %i,%i", (int)candidate.x, (int)candidate.y);
                mazeOrigin = candidate;
            }
            
            guesses++;
        }
        if (mazeOrigin == nil) {
            NSLog(@"[DV] couldn't find a valid origin. aborting");
            return;
        }
    }
    
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
                if ((int)(unsolved.count*newOldThreshold) == 0) tileIndex = 0;
                else tileIndex = (int)(seed%(int)(unsolved.count*newOldThreshold));
                break;
            case MazePickTypeRandomOld:
                seed = rand_r(&seed);
                if ((int)(unsolved.count*newOldThreshold) == 0) tileIndex = (int)unsolved.count-1;
                else tileIndex = (int)unsolved.count - 1 - (int)(seed%(int)(unsolved.count*newOldThreshold));
                break;
        }
        NSAssert(tileIndex >= 0, @"Tile index too small!");
        NSAssert(tileIndex < unsolved.count, @"Tile index too large!");
        Tile *t = unsolved[tileIndex];
        if (LOG_MAZE) NSLog(@"[DV] picked unsolved %i,%i", (int)t.x, (int)t.y);
        
        // carve an unmade cell next to it
        // assume t is open, and will return YES to `-isCorridor`.
        // assume nothing about its orthogonals though
        NSMutableArray *nextCandidates = [NSMutableArray new];
        // first get all the non-nil orthogonals from t
        NSMutableArray *toCheck = [NSMutableArray new];
        if (t.north) [toCheck addObject:t.north];
        if (t.south) [toCheck addObject:t.south];
        if (t.east) [toCheck addObject:t.east];
        if (t.west) [toCheck addObject:t.west];
        
        // for each of them, determine if they're a candidate for expansion
        if (LOG_MAZE) {
            NSLog(@"  %i orthogonals (of t) to check for expansion candidacy", (int)toCheck.count);
        }
        
        for (Tile *ortho in toCheck) {
            TileType orthoTileType = ortho.tileType;
            if (orthoTileType != TileTypeClosed) continue;
            
            if (LOG_MAZE) NSLog(@"    checking orthogonal %i,%i", (int)ortho.x, (int)ortho.y);
            
            // only accept orthos who have exactly 0 diagonals that don't directly connect to t
            NSInteger nonConnectedDiagonals = [ortho numDiagonalPassTest:^BOOL(Tile *diagonalT) {
                // diagonalT will be nonconnected if it has 0 orthogonals that are equal to t
                if (diagonalT.tileType == TileTypeClosed) return false;
                
                NSInteger orthogonalsEqualToT = [diagonalT numOrthogonalPassTest:^BOOL(Tile *orthogonalT) {
                    return [orthogonalT isEqual:t];
                }];
                return orthogonalsEqualToT == 0;
            }];
            
            // make sure it won't make any merges
            NSInteger numClearOrthogonals = [ortho numOrthogonalOfType:TileTypeOpen];
            
            ortho.tileType = TileTypeOpen;
            BOOL isValidForMaze = ![ortho isRoom] && ![t isRoom];
            ortho.tileType = orthoTileType;
            
            if (nonConnectedDiagonals == 0
                && numClearOrthogonals == 1
                && isValidForMaze) {
                [nextCandidates addObject:ortho];
            }
            
        }
        
        // out of the candidates, pick a random one
        if (nextCandidates.count == 0) {
            if (LOG_MAZE) NSLog(@"  no orthogonal candidates, removing t");
            // no candidates for continuing, so this tile is solved
            [unsolved removeObject:t];
            t.mazeUnsolved = NO;
        } else {
            if (LOG_MAZE) NSLog(@"  %i orthogonal candidates", (int)nextCandidates.count);
            seed = rand_r(&seed);
            Tile *next = nextCandidates[seed%nextCandidates.count];
            [next setTileType:TileTypeOpen];
            next.mazeUnsolved = YES;
            [unsolved insertObject:next atIndex:0];
        }
        
        // redraw just the relevant rectangle
        if (redrawPerTile) {
            [self displayRect:NSMakeRect(self.tileSize.width * (t.x-1),
                                         self.tileSize.height * (t.y-1),
                                         self.tileSize.width * 3.0,
                                         self.tileSize.height * 3.0)];
//            [NSThread sleepForTimeInterval:1.0];
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
