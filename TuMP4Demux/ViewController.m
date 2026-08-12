//
//  ViewController.m
//  TuMP4Demux
//
//  Created by zhantu wu on 2026/8/12.
//

#import "ViewController.h"
#include "mp4demuxer.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"youvideo" ofType:@"mp4"];
    const char *cpath = [path cStringUsingEncoding:NSUTF8StringEncoding];
    mp4_open(path.fileSystemRepresentation);
}


@end
