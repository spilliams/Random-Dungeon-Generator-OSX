//
//  ViewController.m
//  Random Dungeon Generator
//
//  Created by Spencer Williams on 12/28/14.
//  Copyright (c) 2014 Spencer Williams. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () {
    BOOL toStep;
}
@property (weak) IBOutlet NSTextField *infoLabel;
@property (nonatomic, strong) IBOutlet Dungeon *dungeonView;
@property (weak) IBOutlet NSButton *redrawPerTileCheckBox;
@property (weak) IBOutlet NSTextField *tileWidthNumberField;
@property (weak) IBOutlet NSTextField *tileHeightNumberField;

- (IBAction)resetButtonPushed:(id)sender;
- (IBAction)roomsButtonPressed:(id)sender;
- (IBAction)mazeButtonPressed:(id)sender;
- (IBAction)doorsButtonPressed:(id)sender;
- (IBAction)pruneButtonPressed:(id)sender;

- (IBAction)mazeAlgorithmChanged:(id)sender;
- (IBAction)mazePickStyleChanged:(id)sender;
- (IBAction)mazeTesellationChanged:(id)sender;
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
    CGFloat width = self.dungeonView.frame.size.width;
    CGFloat height = self.dungeonView.frame.size.height;
    NSSize tileSize = NSMakeSize([self.tileWidthNumberField intValue], [self.tileHeightNumberField intValue]);
    NSInteger numRows = floor(height / (1.0* tileSize.height));
    NSInteger numColumns = floor(width / (1.0* tileSize.width));
    [self.dungeonView createWithTileSize:tileSize
                                    rows:numRows
                                 columns:numColumns
                          reframePerTile:NO];
}

#pragma mark - Dungeon Delegate

- (void)mazeFinishedInTime:(NSTimeInterval)time
{
    [self.infoLabel setStringValue:[NSString stringWithFormat:@"maze time: %f",time]];
}

#pragma mark - IBActions

- (IBAction)resetButtonPushed:(id)sender {
    NSLog(@"[VC] reset");
    [self reinitializeDungeon];
}

- (IBAction)roomsButtonPressed:(id)sender {
    NSLog(@"[VC] rooms");
    [self.dungeonView generateRoomsRedrawPerRoom:(self.redrawPerTileCheckBox.state == NSOnState)];
}

- (IBAction)mazeButtonPressed:(id)sender {
    NSLog(@"[VC] maze");
    [self.dungeonView generateMazeRedrawPerTile:(self.redrawPerTileCheckBox.state == NSOnState)];
}

- (IBAction)doorsButtonPressed:(id)sender {
    [self.dungeonView generateDoors];
}

- (IBAction)pruneButtonPressed:(id)sender {
    [self.dungeonView pruneDeadEndsRedrawPerTile:(self.redrawPerTileCheckBox.state == NSOnState)];
}

- (IBAction)mazeAlgorithmChanged:(id)sender {
    // does not invalidate UI
    [self.dungeonView setAlgorithm:((NSPopUpButton *)sender).selectedTag];
}

- (IBAction)mazePickStyleChanged:(id)sender {
    // does not invalidate UI
    [self.dungeonView setPickType:((NSPopUpButton *)sender).selectedTag];
}

- (IBAction)mazeTesellationChanged:(id)sender {
    // TODO: DOES invalidate UI
    [self.dungeonView setTesellation:((NSPopUpButton *)sender).selectedTag];
}
@end
