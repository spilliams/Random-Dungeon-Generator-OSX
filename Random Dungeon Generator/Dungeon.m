//
//  Dungeon.m
//  Random Dungeon Generator
//
//  Created by Spencer Williams on 12/28/14.
//  Copyright (c) 2014 Spencer Williams. All rights reserved.
//

#import "Dungeon.h"

#define LOG_MAZE NO
#define LOG_ROOMS YES
#define kColorOpen
#define kColorClosed

@interface Dungeon () {
    unsigned int seed;
}
@property (nonatomic, strong) NSMutableArray *rows;
@property (nonatomic, strong) NSMutableArray *rooms;
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
    self.pickType = MazePickTypeRiver;
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
                if (colored) { NSLog(@"[D] wall is room"); [[NSColor magentaColor] setFill];}
                else [[NSColor lightGrayColor] setFill];
                colored = YES;
            }
            if ([t isCorridor]) {
                if (colored) { NSLog(@"[D] corridor is room or wall"); [[NSColor magentaColor] setFill];}
                else [[NSColor lightGrayColor] setFill];
                colored = YES;
            }
            
            if (!colored) {
                [[NSColor redColor] setFill];
            }
            NSRect tileRect = [self rectForTileAtRow:r column:c];
            [NSBezierPath fillRect:tileRect];
            
//            if ([t isCorridorJunction]) {
//                [[NSColor whiteColor] setFill];
//            }
            if ([t isDeadEnd]) {
                [[[NSColor purpleColor] colorWithAlphaComponent:0.5] setFill];
                [NSBezierPath fillRect:tileRect];
            }
//            if ([t isDoorway]) {
//                [[NSColor brownColor] setFill];
//            }
            
            if (t.mazeUnsolved) {
                [[NSColor cyanColor] setFill];
                [NSBezierPath fillRect:tileRect];
            }
        }
    }
}

- (void)createWithTileSize:(NSSize)newTileSize rows:(NSInteger)newRows columns:(NSInteger)newColumns reframePerTile:(BOOL)reframePerTile
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
    NSAssert(self.rows!=nil, @"[D] Rows can't be nil");
    NSAssert(self.rows.count>row,@"[D] Row must exist");
    NSMutableArray *thisRow = ((NSMutableArray *)self.rows[row]);
    NSAssert(thisRow.count>column, @"[D] Row must be long enough");
    
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
    [self.rooms addObject:[NSValue valueWithRect:rect]];
    [self setNeedsDisplay:YES];
}

- (void)generateRoomsRedrawPerRoom:(BOOL)redrawPerRoom;
{
    // I probably made this more complicated than it needed to be...
    
    // givens
    float roomDensity = 0.2; // the percentage of total floor space that should be room in the end
    int ballparkNRooms = 10; // determines the average size of the rooms (this number is just a ballpark of the final number of rooms!)
    float targetAspectRatio = 16/9.0; // ie the most oblong room's ratio of width:height. 1 means all square rooms, 0 and infinity are bad. Negative numbers are untested...
    int roomPlacementTriesMax = 15;
    
    // derived
    int totalRoomSquares = self.width * self.height * roomDensity;
    float squaresPerRoom = totalRoomSquares / ((float)ballparkNRooms);
    float minAspectRatio = MIN(targetAspectRatio, 1.0/targetAspectRatio);
    float maxAspectRatio = MAX(targetAspectRatio, 1.0/targetAspectRatio);
    
    int countRoomSquares = 0;
    if (LOG_ROOMS) NSLog(@"[D] generating ~%i rooms totalling %i, aspect ratios %.2f - %.2f", ballparkNRooms, totalRoomSquares, minAspectRatio, maxAspectRatio);
    self.rooms = [NSMutableArray new];
    
    while (countRoomSquares < totalRoomSquares) {
        
        if (LOG_ROOMS) NSLog(@"[D] make room. current area %i/%i",countRoomSquares, totalRoomSquares);
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
        
        if (LOG_ROOMS) {
            NSLog(@"  aspect ratio %.2f", roomAspectRatio);
            NSLog(@"  %i wide, %i high", roomW, roomH);
        }
        
        NSRect room = NSZeroRect;
        room.size = NSMakeSize(roomW, roomH);
        
        // attempt to place room
        BOOL roomPlaced = NO;
        int roomPlacementTries = 0;
        while (!roomPlaced && roomPlacementTries < roomPlacementTriesMax) {
            if (LOG_ROOMS) NSLog(@"  placement try %i/%i",roomPlacementTries, roomPlacementTriesMax);
            // pick an origin that allows the room to fit within the dungeon bounds
            int xMin = 1;
            int yMin = 1;
            int xMax = self.width - room.size.width - 1;
            int yMax = self.height - room.size.height - 1;
            seed = rand_r(&seed);
            room.origin.x = (seed%(xMax-xMin)) + xMin;
            room.origin.y = (seed%(yMax-yMin)) + yMin;
            if (LOG_ROOMS) NSLog(@"    origin %.2f,%.2f", room.origin.x, room.origin.y);
            
            // does room collide with any of the other rooms? Keep in mind we need to leave wall space between them
            BOOL collision = NO;
            for (NSValue *v in self.rooms) {
                NSRect collider = [v rectValue];
                int buffer = 3;
                collider = NSMakeRect(collider.origin.x-buffer,
                                      collider.origin.y-buffer,
                                      collider.size.width+buffer*2,
                                      collider.size.height+buffer*2);
                if (CGRectIntersectsRect(room, collider)) {
                    collision = YES;
                    if (LOG_ROOMS) NSLog(@"    collision!");
                    continue;
                }
            }
            
            if (!collision) {
                if (LOG_ROOMS) NSLog(@"    no collisions, carve room");
                // it's a go! carve out the room
                for (int r=room.origin.y; r<room.origin.y+room.size.height; r++) {
                    for (int c=room.origin.x; c<room.origin.x+room.size.width; c++) {
                        ((Tile *)self.rows[r][c]).tileType = TileTypeOpen;
                    }
                }
                [self.rooms addObject:[NSValue valueWithRect:room]];
                roomPlaced = YES;
            } // if !collision
            
            roomPlacementTries++;
        } // room placement tries
        if (roomPlaced) {
            countRoomSquares += roomH * roomW;
        }
        if (redrawPerRoom) [self display];
    } // while square footage
    [self setNeedsDisplay:YES];
}

- (void)generateMazeRedrawPerTile:(BOOL)redrawPerTile
{
    NSDate *start = [NSDate date];
    
    switch (self.algorithm) {
        case MazeGenerationAlgorithmGrowingTree:
            [self generateGrowingTreeMazeRedrawPerTile:redrawPerTile];
            break;
    }
    
    NSTimeInterval elapsed = [[NSDate date] timeIntervalSinceDate:start];
    if (self.delegate
        && [self.delegate conformsToProtocol:@protocol(DungeonDelegate)]
        && [self.delegate respondsToSelector:@selector(mazeFinishedInTime:)]) {
        [self.delegate mazeFinishedInTime:elapsed];
    }
}

- (void)generateDoors
{
    // assumes that self.rooms is populated with some `[NSValue valueWithRect:]`s
    // and that maze has already been run (won't do anything otherwise)
    
    for (NSValue *valueWithRect in self.rooms) {
        NSRect roomRect = [valueWithRect rectValue];
        NSMutableArray *candidates = [NSMutableArray new];
        
        // walk the perimeter of the room, asking each tile if it has space on the other side
        Tile *t = self.rows[(int)roomRect.origin.y][(int)roomRect.origin.x-1];
        for (int i=0; i<roomRect.size.height; i++) {
            if ([self tileIsBetweenDoorAndCorridor:t]) [candidates addObject:t];
            t = t.south;
        }
        t = t.east;
        for (int i=0; i<roomRect.size.width; i++) {
            if ([self tileIsBetweenDoorAndCorridor:t]) [candidates addObject:t];
            t = t.east;
        }
        t = t.north;
        for (int i=0; i<roomRect.size.height; i++) {
            if ([self tileIsBetweenDoorAndCorridor:t]) [candidates addObject:t];
            t = t.south;
        }
        t = t.west;
        for (int i=0; i<roomRect.size.width; i++) {
            if ([self tileIsBetweenDoorAndCorridor:t]) [candidates addObject:t];
            t = t.west;
        }
        
        // pick a random number between 1 and 4 doors
        seed = rand_r(&seed);
        int numDoors = seed%3 + 1;
        numDoors = MIN((int)candidates.count, numDoors);
        
        while (numDoors > 0) {
            seed = rand_r(&seed);
            int i = seed%candidates.count;
            Tile *door = candidates[i];
            if (door.tileType == TileTypeClosed) {
                door.tileType = TileTypeOpen;
                [candidates removeObject:door];
                numDoors--;
            }
        }
    }
    [self setNeedsDisplay:YES];
}
- (BOOL)tileIsBetweenDoorAndCorridor:(Tile *)tile
{
    return (([tile.north isRoom] && [tile.south isCorridor])
            || ([tile.east isRoom] && [tile.west isCorridor])
            || ([tile.south isRoom] && [tile.north isCorridor])
            || ([tile.west isRoom] && [tile.east isCorridor]));
}

- (void)pruneDeadEndsRedrawPerTile:(BOOL)redrawPerTile
{
    // 1: round up all of the current dead ends
    NSMutableArray *deadEnds = [NSMutableArray new];
    for (int r=0; r<self.height; r++) {
        for (int c=0; c<self.width; c++) {
            Tile *t = self.rows[r][c];
            if ([t isDeadEnd]) [deadEnds addObject:t];
        }
    }
    
    // 2: while deadEnds has stuff in it, take one out, close it, and check its neighbors
    __block void(^checkForDeadEnd)(Tile *t) = ^(Tile *t) {
        if (t.tileType == TileTypeOpen
            && [t isDeadEnd]
            && ![deadEnds containsObject:t]) [deadEnds insertObject:t atIndex:0];
    };
    while (deadEnds.count > 0) {
        Tile *t = [deadEnds objectAtIndex:0];
        [deadEnds removeObject:t];
        t.tileType = TileTypeClosed;
        checkForDeadEnd(t.north);
        checkForDeadEnd(t.east);
        checkForDeadEnd(t.south);
        checkForDeadEnd(t.west);
        if (redrawPerTile) {
            [self display];
        }
    }
    [self setNeedsDisplay:YES];
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

- (void)generateGrowingTreeMazeRedrawPerTile:(BOOL)redrawPerTile
{
    // givens:
    BOOL avoidEdges = YES;
    float newOldThreshold = 0.25; // percentage of the unsolved cells that are "new" or "old"
    float riverThreshold = 0.05; // only used in MazePickTypeRiver
    
    // pick origin
    Tile *mazeOrigin;
    
    // first, check to see if the origin has been picked by the user
    // pick the first non-room tile you find
    for (int r=0; r<self.height; r++) {
        for (int c=0; c<self.width; c++) {
            Tile *t = ((Tile *)self.rows[r][c]);
            if (t.tileType == TileTypeOpen
                && [t numAdjacentOfType:TileTypeOpen] == 0) {
                NSLog(@"[D] using pre-selected maze origin %i,%i", (int)t.x, (int)t.y);
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
                NSLog(@"[D] picked random maze origin %i,%i", (int)candidate.x, (int)candidate.y);
                mazeOrigin = candidate;
            }
            
            guesses++;
        }
        if (mazeOrigin == nil) {
            NSLog(@"[D] couldn't find a valid origin. aborting");
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
            && (self.pickType == MazePickTypeRandomNew
                || self.pickType == MazePickTypeRandomOld)) {
            self.pickType = MazePickTypeRandom;
        }
        MazePickType tempPickType = self.pickType;
        if (self.pickType == MazePickTypeRiver) {
            if ((seed%100)/100.0 < riverThreshold) {
                tempPickType = MazePickTypeRandom;
            } else {
                tempPickType = MazePickTypeNewest;
            }
        }
        switch (tempPickType) {
            case MazePickTypeRiver:
                // sure it isn't a thrown exception, but waddayagunnado?
                NSAssert(0==1,@"this case shouldn't come up");
                break;
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
        if (LOG_MAZE) NSLog(@"[D] picked unsolved %i,%i", (int)t.x, (int)t.y);
        
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
            // Rule 1: ortho must be closed
            if (orthoTileType != TileTypeClosed) continue;
            
            if (LOG_MAZE) NSLog(@"    checking orthogonal %i,%i", (int)ortho.x, (int)ortho.y);
            
            // Rule 2: avoid edges if necessary
            if (avoidEdges) {
                // assume that if this tile has fewer than 8 adjacents, it is on an edge
                NSInteger numAdjacents = [ortho numAdjacentPassTest:^BOOL(Tile *t) {
                    return YES;
                }];
                if (numAdjacents < 8) continue;
            }
            
            // Rule 3: Make sure clearing this ortho won't make any merges
            NSInteger numClearOrthogonals = [ortho numOrthogonalOfType:TileTypeOpen];
            if (numClearOrthogonals != 1) continue;
            
            // Rule 4: Only accept orthos who have exactly 0 diagonals that don't directly connect to t
            NSInteger nonConnectedDiagonals = [ortho numDiagonalPassTest:^BOOL(Tile *diagonalT) {
                // diagonalT will be nonconnected if it has 0 orthogonals that are equal to t
                if (diagonalT.tileType == TileTypeClosed) return false;
                
                NSInteger orthogonalsEqualToT = [diagonalT numOrthogonalPassTest:^BOOL(Tile *orthogonalT) {
                    return [orthogonalT isEqual:t];
                }];
                return orthogonalsEqualToT == 0;
            }];
            if (nonConnectedDiagonals != 0) continue;
            
            // Rule 5: Make sure clearing this ortho won't turn it (or t) into a room
            ortho.tileType = TileTypeOpen;
            BOOL isValidForMaze = ![ortho isRoom] && ![t isRoom];
            ortho.tileType = orthoTileType;
            if (!isValidForMaze) continue;
            
            [nextCandidates addObject:ortho];
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
