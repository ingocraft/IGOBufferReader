//
//  IGOBufferReader.m
//  IGOBufferReader
//
//  Created by ingo on 21/03/2018.
//  Copyright © 2018 ingo. All rights reserved.
//

#import "IGOBufferReader.h"
#import <AVFoundation/AVFoundation.h>

@interface IGOBufferReader ()

@property (nonatomic) CADisplayLink *displayLink;
@property (nonatomic) AVAssetReaderTrackOutput *trackOutput;
@property (nonatomic) AVAssetReader *reader;
@property (nonatomic) AVAsset *asset;

@end

@implementation IGOBufferReader

- (void)startReadingAsset:(AVAsset *)asset {
    _asset = asset;
    
    NSError *error;
    AVAssetReader *reader = [[AVAssetReader alloc] initWithAsset:asset error:&error];
    if ([_delegate respondsToSelector:@selector(bufferReader:didFailToReadAsset:)]) {
        [_delegate bufferReader:self didFailToReadAsset:error];
        return;
    }
    
    NSArray *videoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    if (videoTracks.count == 0) {
        error = [NSError errorWithDomain:@"IGOBufferReader error" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Fail to read asset."}];
        if ([_delegate respondsToSelector:@selector(bufferReader:didFailToReadAsset:)]) {
            [_delegate bufferReader:self didFailToReadAsset:error];
        }
        return;
    }
    
    AVAssetTrack *videoTrack = [videoTracks objectAtIndex:0];
    NSDictionary *settings = @{(NSString *)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithInt:kCVPixelFormatType_32BGRA]};
    AVAssetReaderTrackOutput *trackOutput = [[AVAssetReaderTrackOutput alloc] initWithTrack:videoTrack outputSettings:settings];
    _trackOutput = trackOutput;
    [reader addOutput:trackOutput];
    [reader startReading];
    _reader = reader;
    
    [self AddTimerToFetchFrame];
}

- (void)cancelReading {
    [_reader cancelReading];
    [self removeTimerForFetchFrame];
}

- (void)AddTimerToFetchFrame {
    // display link
    CADisplayLink *displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkAction:)];
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    displayLink.frameInterval = 2;
    self.displayLink = displayLink;
}

- (void)removeTimerForFetchFrame {
    [_displayLink removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    [_displayLink invalidate];
    _displayLink = nil;
}

- (void)displayLinkAction:(CADisplayLink *)displayLink {
    CMSampleBufferRef buffer = NULL;
    AVAssetReaderStatus status = [self.reader status];
    switch (status) {
        case AVAssetReaderStatusReading: {
            buffer = [_trackOutput copyNextSampleBuffer];
            
            if (!buffer) {
                NSError *error = [NSError errorWithDomain:@"IGOBufferReader error" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"sample buffer is empty"}];
                [_delegate bufferReader:self didFailToReadAsset:error];
                [_reader cancelReading];
                [self removeTimerForFetchFrame];
                break;
            }
            
            if ([_delegate respondsToSelector:@selector(bufferReader:didReadNextVideoSample:)]) {
                [_delegate bufferReader:self didReadNextVideoSample:buffer];
            }
        }
            break;
        case AVAssetReaderStatusCompleted: {
            if ([_delegate respondsToSelector:@selector(bufferReader:didFinishReadingAsset:)]) {
                [_delegate bufferReader:self didFinishReadingAsset:_asset];
                [self removeTimerForFetchFrame];
            }
        }
            break;
        case AVAssetReaderStatusFailed: {
            if ([_delegate respondsToSelector:@selector(bufferReader:didFailToReadAsset:)]) {
                [_delegate bufferReader:self didFailToReadAsset:_reader.error];
            }
            [_reader cancelReading];
            [self removeTimerForFetchFrame];
        }
            break;
        case AVAssetReaderStatusUnknown: break;
        case AVAssetReaderStatusCancelled: break;
    }
    
    if (buffer) {
        CMSampleBufferInvalidate(buffer);
        CFRelease(buffer);
        buffer = NULL;
    }
}

@end
