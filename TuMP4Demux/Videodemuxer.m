//
//  Videodemuxer.m
//  TuMP4Demux
//
//  Created by zhantu wu on 2026/10/20.
//

#import "Videodemuxer.h"

typedef struct {
    uint64_t start;
    uint64_t size;
    int headerSize;
}VideoBox;

@implementation Videodemuxer

uint64_t getNumberValue(const uint8_t *ptr) {
    uint64_t size = ((uint32_t)ptr[0] << 24) | ((uint32_t)ptr[1] << 16) | ((uint32_t)ptr[2] << 8) | (uint32_t)ptr[3];
    return size;
}

void findType(const uint8_t *bytes, char *desType, uint64_t start, uint64_t end, VideoBox *box) {
    while (start + 8 <= end) {
        int headerSize = 8;
        const uint8_t *sizePtr = bytes + start;
        const uint8_t *typePtr = sizePtr + 4;
        uint64_t size = ((uint32_t)sizePtr[0] << 24) | ((uint32_t)sizePtr[1] << 16) | ((uint32_t)sizePtr[2] << 8) | (uint32_t)sizePtr[3];
        if (size == 1) {
            headerSize += 8;
            sizePtr = sizePtr + 8;
            size = ((uint64_t)sizePtr[0] << 56) | ((uint64_t)sizePtr[1] << 48) | ((uint64_t)sizePtr[2] << 40) | ((uint64_t)sizePtr[3] << 32) | ((uint64_t)sizePtr[4] << 24) | ((uint64_t)sizePtr[5] << 16) | ((uint64_t)sizePtr[6] << 8) | (uint64_t)sizePtr[7];
        }
        
        char type[5];
        memset(type, 0, 5);
        memcpy(type, typePtr, 4);
        
        if (memcmp(type, desType, 4) == 0) {
            box->headerSize = headerSize;
            box->start = start;
            box->size = size;
            return;
        }
        
        start += size;
    }
}

- (void)demuxVideo {
    
    NSString *videoPath = [[NSBundle mainBundle] pathForResource:@"3-1 H264 NALU结构讲解.mp4" ofType:nil];
    NSData *videoData = [NSData dataWithContentsOfFile:videoPath];
    
    const uint8_t *bytes = videoData.bytes;
    VideoBox box = {0, 0, 0};
    findType(bytes, "moov", 0, videoData.length, &box);
    findType(bytes, "trak", box.start + box.headerSize, box.start + box.size, &box);
    findType(bytes, "mdia", box.start + box.headerSize, box.start + box.size, &box);
    findType(bytes, "minf", box.start + box.headerSize, box.start + box.size, &box);
    
    VideoBox stblBox = {0, 0, 0};
    findType(bytes, "stbl", box.start + box.headerSize, box.start + box.size, &stblBox);
    
    VideoBox stsdBox = {0, 0, 0};
    findType(bytes, "stsd", stblBox.start + stblBox.headerSize, stblBox.start + stblBox.size, &stsdBox);
    
    VideoBox sttsBox = {0, 0, 0};
    findType(bytes, "stts", stblBox.start + stblBox.headerSize, stblBox.start + stblBox.size, &sttsBox);
    
    VideoBox cttsBox = {0, 0, 0};
    findType(bytes, "ctts", stblBox.start + stblBox.headerSize, stblBox.start + stblBox.size, &cttsBox);
    
    VideoBox stssBox = {0, 0, 0};
    findType(bytes, "stss", stblBox.start + stblBox.headerSize, stblBox.start + stblBox.size, &stssBox);
    
    VideoBox stcoBox = {0, 0, 0};
    findType(bytes, "stco", stblBox.start + stblBox.headerSize, stblBox.start + stblBox.size, &stcoBox);
    
    VideoBox stscBox = {0, 0, 0};
    findType(bytes, "stsc", stblBox.start + stblBox.headerSize, stblBox.start + stblBox.size, &stscBox);
    
    VideoBox stszBox = {0, 0, 0};
    findType(bytes, "stsz", stblBox.start + stblBox.headerSize, stblBox.start + stblBox.size, &stszBox);
    const uint8_t *stsz_ptr = bytes + stszBox.start + stszBox.headerSize + 4;
    uint64_t per_sample_size = getNumberValue(stsz_ptr);
    uint64_t sample_count = getNumberValue(stsz_ptr + 4);
    
    const uint8_t *stco_ptr = bytes + stcoBox.start + stcoBox.headerSize + 4;
    uint64_t chunk_count = getNumberValue(stco_ptr);
    
    const uint8_t *stsc_ptr = bytes + stscBox.start + stscBox.headerSize + 4;
    uint64_t stsc_count = getNumberValue(stsc_ptr);
    
    uint64_t totalSample = 0;
    uint64_t stsc_index = 0;
    for (int i = 1 ; i <= chunk_count; i++) {
        uint64_t chunk_offset = getNumberValue(stco_ptr + 4 + (i - 1) * 4);
        while (stsc_index + 1 < stsc_count) {
            uint64_t next = getNumberValue(stsc_ptr + 4 + 12 * (stsc_index + 1));
            if (i >= next) {
                stsc_index++;
            } else {
                break;
            }
        }
        uint64_t per_samples_chunk = getNumberValue(stsc_ptr + 4 + 12 * stsc_index + 4);
        for (int j = 0; j < per_samples_chunk; j++) {
            uint64_t sample_size = per_sample_size > 0 ? per_sample_size : getNumberValue(stsz_ptr + 8 + 4 * totalSample);
            NSLog(@"sample_size %llu", sample_size);
            totalSample++;
        }
    }
}

@end

/*
 ftyp                      文件类型与兼容品牌
 moov                      元数据容器（全部媒体信息）
 ├── mvhd                  影片头：timescale、duration、播放速率、音量等
 ├── trak                  一条轨道（视频/音频/字幕各一个 trak）
 │   ├── tkhd              轨道头：track_id、时长、宽高、图层等
 │   ├── edts
 │   │   └── elst          编辑列表（时间偏移、裁剪）
 │   └── mdia
 │       ├── mdhd          媒体头：该轨道的 timescale、duration、语言
 │       ├── hdlr          处理器类型：vide / soun / hint / subt 等
 │       └── minf
 │           ├── vmhd/smhd 视频/音频媒体头
 │           ├── dinf
 │           │   └── dref  数据引用（媒体数据在本文件还是外部）
 │           └── stbl      Sample Table，最核心的 box
 │               ├── stsd  采样描述：编码格式（avc1/hvc1/mp4a…），
 │               │         内含 avcC/hvcC/esds 等解码配置（SPS/PPS 等）
 │               ├── stts  解码时间 → sample（每个 sample 的时长）
 │               ├── ctts  合成时间偏移（PTS - DTS，有 B 帧时需要）
 │               ├── stss  同步 sample 表（关键帧列表）
 │               ├── stsc  sample → chunk 的映射
 │               ├── stsz  每个 sample 的大小
 │               ├── stco  每个 chunk 在文件中的偏移（32 位）
 │               └── co64  同上，64 位版本
 └── udta                  用户数据（如 meta 元信息、标题等）
 mdat                      真正的音视频数据（裸的帧数据）
 free / skip               填充用，可忽略
 */
