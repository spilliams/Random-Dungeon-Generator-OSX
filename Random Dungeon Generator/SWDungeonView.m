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
@end

#define kColorOpen
#define kColorClosed

@implementation SWDungeonView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    [[NSColor blackColor] setFill];
    NSRectFill(dirtyRect);
    
    // Drawing code here.
    for (int r=0; r<self.height; r++) {
        for (int c=0; c<self.width; c++) {
            if (((Tile *)self.rows[r][c]).tileType == SWTileTypeOpen) {
                [[NSColor greenColor] setFill];
            } else {
                [[NSColor darkGrayColor] setFill];
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

@end
