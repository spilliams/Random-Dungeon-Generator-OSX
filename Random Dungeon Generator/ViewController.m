//
//  ViewController.m
//  Random Dungeon Generator
//
//  Created by Spencer Williams on 12/28/14.
//  Copyright (c) 2014 Spencer Williams. All rights reserved.
//

#import "ViewController.h"
#import "SWDungeonView.h"

@interface ViewController ()
@property (nonatomic, strong) IBOutlet SWDungeonView *dungeonView;
- (IBAction)resetButtonPushed:(id)sender;
- (IBAction)testButtonPressed:(id)sender;
@end

@implementation ViewController

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [self reinitializeDungeon];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
}

- (void)reinitializeDungeon
{
    // my current screen/storyboard allows for roughly 65 rows and 136 columns of 10x10 tiles
    CGFloat width = 1360;
    CGFloat height = 650;
    NSSize tileSize = NSMakeSize(10, 10);
    NSInteger numRows = floor(height / (1.0* tileSize.height));
    NSInteger numColumns = floor(width / (1.0* tileSize.width));
    [self.dungeonView createWithDungeonTileSize:tileSize
                                           rows:numRows
                                        columns:numColumns
                                 reframePerTile:NO];
}

- (IBAction)resetButtonPushed:(id)sender {
    [self reinitializeDungeon];
}

- (IBAction)testButtonPressed:(id)sender {
    [self reinitializeDungeon];
    [self.dungeonView setupForTests];
}
@end
