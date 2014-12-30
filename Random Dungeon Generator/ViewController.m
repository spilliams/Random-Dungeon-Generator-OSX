//
//  ViewController.m
//  Random Dungeon Generator
//
//  Created by Spencer Williams on 12/28/14.
//  Copyright (c) 2014 Spencer Williams. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
@property (weak) IBOutlet NSTextField *infoLabel;
@property (nonatomic, strong) IBOutlet Dungeon *dungeonView;
- (IBAction)resetButtonPushed:(id)sender;
- (IBAction)testButtonPressed:(id)sender;
- (IBAction)roomsButtonPressed:(id)sender;
- (IBAction)mazeButtonPressed:(id)sender;
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
    NSSize tileSize = NSMakeSize(100, 100);
    NSInteger numRows = floor(height / (1.0* tileSize.height));
    NSInteger numColumns = floor(width / (1.0* tileSize.width));
    [self.dungeonView createWithDungeonTileSize:tileSize
                                           rows:numRows
                                        columns:numColumns
                                 reframePerTile:NO];
}

#pragma mark - IBActions

- (IBAction)resetButtonPushed:(id)sender {
    NSLog(@"[VC] reset");
    [self reinitializeDungeon];
}

- (IBAction)testButtonPressed:(id)sender {
    NSLog(@"[VC] test");
    CGFloat width = 1360;
    CGFloat height = 650;
    NSSize tileSize = NSMakeSize(10, 10);
    NSInteger numRows = floor(height / (1.0* tileSize.height));
    NSInteger numColumns = floor(width / (1.0* tileSize.width));
    [self.dungeonView createWithDungeonTileSize:tileSize
                                           rows:numRows
                                        columns:numColumns
                                 reframePerTile:NO];
    [self.dungeonView setupForTests];
}

- (IBAction)roomsButtonPressed:(id)sender {
    NSLog(@"[VC] rooms");
    [self.dungeonView generateRooms];
}

- (IBAction)mazeButtonPressed:(id)sender {
    NSLog(@"[VC] maze");
    [self.dungeonView generateMaze];
}

#pragma mark - Dungeon Delegate

- (void)mazeFinishedInTime:(NSTimeInterval)time
{
    [self.infoLabel setStringValue:[NSString stringWithFormat:@"maze time: %f",time]];
}
@end
