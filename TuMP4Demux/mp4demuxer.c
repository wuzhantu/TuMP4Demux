//
//  mp4demuxer.c
//  TuMP4Demux
//
//  Created by zhantu wu on 2026/8/12.
//

#include "mp4demuxer.h"
#include <string.h>

void mp4_open(const char *path) {
    FILE *fp = fopen(path, "rb");
    if (fseeko(fp, 0, SEEK_END) != 0) {
        return;
    }
    off_t fileSize = ftello(fp);
    fseeko(fp, 0, SEEK_SET);
    parse_boxes(fp, 0, fileSize);
}

void parse_boxes(FILE *fp, uint64_t begin, uint64_t end) {
    uint64_t start = begin;
    while (start + 8 <= end) {
        uint8_t size[5];
        memset(size, 0, 5);
        fread(size, 1, 4, fp);
        int val = 1;
        int boxSize = size[0] * (val << 24) + size[1] * (val << 16) + size[2] * (val << 8) + size[3] * (val);

        char type[5];
        memset(type, 0, 5);
        fread(type, 1, 4, fp);

        printf("size == %d %s\n", boxSize, type);
        if (isEqual(type, "moov") || isEqual(type, "trak") || isEqual(type, "mdia") || isEqual(type, "minf") || isEqual(type, "stbl") || isEqual(type, "dinf")) {
            parse_boxes(fp, start + 8, start + boxSize);
        } else if (isEqual(type, "stsd")) {
            fseeko(fp, start + 8 + 8, SEEK_SET);
            parse_boxes(fp, start + 8 + 8, start + boxSize);
        } else if (isEqual(type, "ftyp")) {
            parse_ftype(fp, start + 8, start + boxSize);
        }

        start += boxSize;
        fseeko(fp, start, SEEK_SET);
    }
}

int isEqual(const char *s1, const char *s2) {
    size_t len = strlen(s1);
    return memcmp(s1, s2, len) == 0;
}

void parse_ftype(FILE *fp, uint64_t begin, uint64_t end) {
    fseeko(fp, begin, SEEK_SET);
    
    char major_brand[5];
    memset(major_brand, 0, 5);
    fread(major_brand, 1, 4, fp);
    printf("major_brand %s\n", major_brand);
    
    char minor_version[5];
    memset(minor_version, 0, 5);
    fread(minor_version, 1, 4, fp);
    int version = minor_version[0] << 24 | minor_version[1] << 16 | minor_version[2] << 8 | minor_version[3];
    printf("minor_version %d\n", version);
}
