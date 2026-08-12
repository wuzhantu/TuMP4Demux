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
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"3-1 H264 NALU结构讲解" ofType:@"mp4"];
    const char *cpath = [path cStringUsingEncoding:NSUTF8StringEncoding];
    mp4_open(path.fileSystemRepresentation);
}


@end
