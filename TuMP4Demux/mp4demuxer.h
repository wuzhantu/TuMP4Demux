//
//  mp4demuxer.h
//  TuMP4Demux
//
//  Created by zhantu wu on 2026/8/12.
//

#ifndef mp4demuxer_h
#define mp4demuxer_h

#include <stdio.h>
void mp4_open(const char *path);
void parse_boxes(FILE *fp, uint64_t begin, uint64_t end);
int isEqual(const char *s1, const char *s2);
void parse_ftype(FILE *fp, uint64_t begin, uint64_t end);
#endif /* mp4demuxer_h */
