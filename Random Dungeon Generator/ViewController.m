//
//  ViewController.m
//  Random Dungeon Generator
//
//  Created by Spencer Williams on 12/28/14.
//  Copyright (c) 2014 Spencer Williams. All rights reserved.
//

#import "ViewController.h"
#import "Dungeon.h"

@interface ViewController () {
    BOOL toStep;
}
@property (nonatomic, strong) IBOutlet Dungeon *dungeonView;
@property (weak) IBOutlet NSButton *redrawPerTileCheckBox;

@property (weak) IBOutlet NSTextField *tileWidthNumberField;
@property (weak) IBOutlet NSTextField *tileHeightNumberField;

@property (weak) IBOutlet NSTextField *roomDensityLabel;
@property (weak) IBOutlet NSSlider *roomDensitySlider;

@property (weak) IBOutlet NSTextField *roomMaxAspectRatioLabel;
@property (weak) IBOutlet NSSlider *roomMaxAspectRatioSlider;

@property (weak) IBOutlet NSTextField *roomBallparkCountLabel;
@property (weak) IBOutlet NSSlider *roomBallparkCountSlider;

- (IBAction)resetButtonPushed:(id)sender;
- (IBAction)roomsButtonPressed:(id)sender;
- (IBAction)mazeButtonPressed:(id)sender;
- (IBAction)doorsButtonPressed:(id)sender;
- (IBAction)pruneButtonPressed:(id)sender;

- (IBAction)mazeAlgorithmChanged:(id)sender;
- (IBAction)mazePickStyleChanged:(id)sender;
- (IBAction)mazeTesellationChanged:(id)sender;

- (IBAction)detailModeToggled:(id)sender;
- (IBAction)roomDensitySliderChanged:(id)sender;
- (IBAction)roomMaxAspectRatioSliderChanged:(id)sender;
- (IBAction)roomBallparkCountSliderChanged:(id)sender;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self reinitializeDungeon];
    
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

- (void)updateSliderValueLabels {
    [self.roomDensityLabel setStringValue:[NSString stringWithFormat:@"%.0f%%", self.roomDensitySlider.floatValue]];
    [self.roomMaxAspectRatioLabel setStringValue:[NSString stringWithFormat:@"%.2f", self.roomMaxAspectRatioSlider.floatValue]];
    [self.roomBallparkCountLabel setStringValue:[NSString stringWithFormat:@"%i", self.roomBallparkCountSlider.intValue]];
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

- (IBAction)detailModeToggled:(id)sender {
    [self.dungeonView setDetailedDraw:(((NSButton *)sender).state == NSOnState)];
}

- (IBAction)roomDensitySliderChanged:(id)sender {
    [self updateSliderValueLabels];
    [self.dungeonView setRoomDensity:((NSSlider *)sender).floatValue / 100.0];
}

- (IBAction)roomMaxAspectRatioSliderChanged:(id)sender {
    [self updateSliderValueLabels];
    [self.dungeonView setRoomMaxAspectRatio:((NSSlider *)sender).floatValue];
}

- (IBAction)roomBallparkCountSliderChanged:(id)sender {
    [self updateSliderValueLabels];
    [self.dungeonView setRoomBallparkCount:((NSSlider *)sender).intValue];
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
