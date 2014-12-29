//
//  SWDungeonView.m
//  Random Dungeon Generator
//
//  Created by Spencer Williams on 12/28/14.
//  Copyright (c) 2014 Spencer Williams. All rights reserved.
//

#import "SWDungeonView.h"

@interface SWDungeonView ()
@property (nonatomic, strong) NSMutableArray *rows;
@property (nonatomic, assign) NSInteger width;
@property (nonatomic, assign) NSInteger height;

@property (nonatomic, assign) NSSize tileSize;

@property (nonatomic, strong) NSClickGestureRecognizer *clickGR;
- (void)handleClickGesture:(NSGestureRecognizer *)clickGR;
@end

#define kColorOpen
#define kColorClosed

@implementation SWDungeonView

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
            
            if (t.tileType == SWTileTypeClosed) {
                [[NSColor blackColor] setFill];
                colored = YES;
            }
            
            if ([t isWall]) {
                [[NSColor darkGrayColor] setFill];
                colored = YES;
            }
            
            if (!colored) {
                [[NSColor redColor] setFill];
            }
            NSRectFill([self rectForTileAtRow:r column:c]);
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
            if (r==0 && c==0) t.tileType = SWTileTypeOpen;
            [self updateTileAtRow:r column:c withTile:t redraw:reframePerTile];
        }
    }
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
}

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
    
    Tile *t = self.rows[row][column];
    switch (t.tileType) {
        case SWTileTypeClosed:
            [t setTileType:SWTileTypeOpen];
            break;
        case SWTileTypeOpen:
            [t setTileType:SWTileTypeClosed];
            break;
    }
    [self setNeedsDisplay:YES];
}

@end
