//
//  IGOBufferReader.h
//  IGOBufferReader
//
//  Created by ingo on 21/03/2018.
//  Copyright © 2018 ingo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

@class AVAsset;
@protocol IGOBufferReaderDelegate;

@interface IGOBufferReader : NSObject
@property (nonatomic, weak) id <IGOBufferReaderDelegate> delegate;

- (void)startReadingAsset:(AVAsset *)asset;
- (void)cancelReading;
@end

@protocol IGOBufferReaderDelegate <NSObject>
- (void)bufferReader:(IGOBufferReader *)reader didFinishReadingAsset:(AVAsset *)asset;
- (void)bufferReader:(IGOBufferReader *)reader didReadNextVideoSample:(CMSampleBufferRef)bufferRef;
- (void)bufferReader:(IGOBufferReader *)reader didFailToReadAsset:(NSError *)error;
@end
