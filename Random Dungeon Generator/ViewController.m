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
@end

@implementation ViewController

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    // my current screen/storyboard allows for roughly 65 rows and 136 columns of 10x10 tiles
    [self.dungeonView createWithDungeonTileSize:NSMakeSize(10, 10)
                                           rows:65 columns:136
                                 reframePerTile:NO];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
}

@end
