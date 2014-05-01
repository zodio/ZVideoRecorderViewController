//
//  PBJMediaWriter.m
//  Vision
//
//  Created by Patrick Piemonte on 1/27/14.
//  Copyright (c) 2014 Patrick Piemonte. All rights reserved.
//

#import "PBJMediaWriter.h"
#import "PBJVisionUtilities.h"

#import <UIKit/UIDevice.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import <Accelerate/Accelerate.h>


#define LOG_WRITER 0
#if !defined(NDEBUG) && LOG_WRITER
#   define DLog(fmt, ...) NSLog((@"writer: " fmt), ##__VA_ARGS__);
#else
#   define DLog(...)
#endif

@interface PBJMediaWriter ()
{
    AVAssetWriter *_assetWriter;
	AVAssetWriterInput *_assetWriterAudioIn;
	AVAssetWriterInput *_assetWriterVideoIn;
    
    NSURL *_outputURL;
    BOOL _audioReady;
    BOOL _videoReady;
}

@end

@implementation PBJMediaWriter

@synthesize outputURL = _outputURL;
@synthesize delegate = _delegate;

#pragma mark - getters/setters

- (BOOL)isAudioReady
{
    return _audioReady;
}

- (BOOL)isVideoReady
{
    return _videoReady;
}

- (NSError *)error
{
    return _assetWriter.error;
}

#pragma mark - init

- (id)initWithOutputURL:(NSURL *)outputURL
{
    self = [super init];
    if (self) {
        NSError *error = nil;
        _assetWriter = [[AVAssetWriter alloc] initWithURL:outputURL fileType:(NSString *)kUTTypeQuickTimeMovie error:&error];
        if (error) {
            DLog(@"error setting up the asset writer (%@)", error);
            _assetWriter = nil;
            return nil;
        }

        _outputURL = outputURL;
        _assetWriter.shouldOptimizeForNetworkUse = YES;
        _assetWriter.metadata = [self _metadataArray];

        // It's possible to capture video without audio or audio without video.
        // If the user has denied access to a device, we don't need to set it up
        if ([[AVCaptureDevice class] respondsToSelector:@selector(authorizationStatusForMediaType:)]) {
            
            if ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio] == AVAuthorizationStatusDenied) {
                _audioReady = YES;
                if ([_delegate respondsToSelector:@selector(mediaWriterDidObserveAudioAuthorizationStatusDenied:)]) {
                    [_delegate mediaWriterDidObserveAudioAuthorizationStatusDenied:self];
                }
            }
            
            if ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo] == AVAuthorizationStatusDenied) {
                _videoReady = YES;
                if ([_delegate respondsToSelector:@selector(mediaWriterDidObserveVideoAuthorizationStatusDenied:)]) {
                    [_delegate mediaWriterDidObserveVideoAuthorizationStatusDenied:self];
                }
            }
            
        }
    }
    return self;
}

#pragma mark - private

- (NSArray *)_metadataArray
{
    UIDevice *currentDevice = [UIDevice currentDevice];
    
    // device model
    AVMutableMetadataItem *modelItem = [[AVMutableMetadataItem alloc] init];
    [modelItem setKeySpace:AVMetadataKeySpaceCommon];
    [modelItem setKey:AVMetadataCommonKeyModel];
    [modelItem setValue:[currentDevice localizedModel]];

    // software
    AVMutableMetadataItem *softwareItem = [[AVMutableMetadataItem alloc] init];
    [softwareItem setKeySpace:AVMetadataKeySpaceCommon];
    [softwareItem setKey:AVMetadataCommonKeySoftware];
    [softwareItem setValue:[NSString stringWithFormat:@"%@ %@ PBJVision", [currentDevice systemName], [currentDevice systemVersion]]];

    // creation date
    AVMutableMetadataItem *creationDateItem = [[AVMutableMetadataItem alloc] init];
    [creationDateItem setKeySpace:AVMetadataKeySpaceCommon];
    [creationDateItem setKey:AVMetadataCommonKeyCreationDate];
    [creationDateItem setValue:[NSString PBJformattedTimestampStringFromDate:[NSDate date]]];

    return @[modelItem, softwareItem, creationDateItem];
}

#pragma mark - sample buffer setup

- (BOOL)setupAudioOutputDeviceWithSettings:(NSDictionary *)audioSettings
{
	if ([_assetWriter canApplyOutputSettings:audioSettings forMediaType:AVMediaTypeAudio]) {
    
		_assetWriterAudioIn = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeAudio outputSettings:audioSettings];
		_assetWriterAudioIn.expectsMediaDataInRealTime = YES;
        
        DLog(@"prepared audio-in with compression settings sampleRate (%f) channels (%d) bitRate (%ld)",
                    [[audioSettings objectForKey:AVSampleRateKey] floatValue],
                    [[audioSettings objectForKey:AVNumberOfChannelsKey] unsignedIntegerValue],
                    (long)[[audioSettings objectForKey:AVEncoderBitRateKey] integerValue]);
        
		if ([_assetWriter canAddInput:_assetWriterAudioIn]) {
			[_assetWriter addInput:_assetWriterAudioIn];
            _audioReady = YES;
		} else {
			DLog(@"couldn't add asset writer audio input");
		}
        
	} else {
    
		DLog(@"couldn't apply audio output settings");
        
	}
    
    return _audioReady;
}

- (BOOL)setupVideoOutputDeviceWithSettings:(NSDictionary *)videoSettings
{
	if ([_assetWriter canApplyOutputSettings:videoSettings forMediaType:AVMediaTypeVideo]) {
    
		_assetWriterVideoIn = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
		_assetWriterVideoIn.expectsMediaDataInRealTime = YES;
//		_assetWriterVideoIn.transform = CGAffineTransformIdentity;
//        [self updateOrientation];
        
#if !defined(NDEBUG) && LOG_WRITER
        NSDictionary *videoCompressionProperties = [videoSettings objectForKey:AVVideoCompressionPropertiesKey];
        if (videoCompressionProperties)
            DLog(@"prepared video-in with compression settings bps (%f) frameInterval (%ld)",
                    [[videoCompressionProperties objectForKey:AVVideoAverageBitRateKey] floatValue],
                    (long)[[videoCompressionProperties objectForKey:AVVideoMaxKeyFrameIntervalKey] integerValue]);
#endif

		if ([_assetWriter canAddInput:_assetWriterVideoIn]) {
			[_assetWriter addInput:_assetWriterVideoIn];
            _videoReady = YES;
		} else {
			DLog(@"couldn't add asset writer video input");
		}
        
	} else {
    
		DLog(@"couldn't apply video output settings");
        
	}
    
    return _videoReady;
}

#pragma mark - sample buffer writing

- (void)writeSampleBuffer:(CMSampleBufferRef)sampleBuffer ofType:(NSString *)mediaType
{
	if ( _assetWriter.status == AVAssetWriterStatusUnknown ) {
        
        if ([_assetWriter startWriting]) {
            CMTime startTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
			[_assetWriter startSessionAtSourceTime:startTime];
            DLog(@"started writing with status (%ld)", (long)_assetWriter.status);
		} else {
			DLog(@"error when starting to write (%@)", [_assetWriter error]);
		}
        
	}
    
    if ( _assetWriter.status == AVAssetWriterStatusFailed ) {
        DLog(@"writer failure, (%@)", _assetWriter.error.localizedDescription);
        return;
    }
	
	if ( _assetWriter.status == AVAssetWriterStatusWriting ) {
		
		if (mediaType == AVMediaTypeVideo) {

			if (_assetWriterVideoIn.readyForMoreMediaData) {
				if (![_assetWriterVideoIn appendSampleBuffer:sampleBuffer]) {
					DLog(@"writer error appending video (%@)", [_assetWriter error]);
				} else {

                }
			}
		} else if (mediaType == AVMediaTypeAudio) {
			if (_assetWriterAudioIn.readyForMoreMediaData) {
				if (![_assetWriterAudioIn appendSampleBuffer:sampleBuffer]) {
					DLog(@"writer error appending audio (%@)", [_assetWriter error]);
				}
			}
		}
	}
    
}

- (void)finishWritingWithCompletionHandler:(void (^)(void))handler
{
    if (_assetWriter.status == AVAssetWriterStatusUnknown) {
        DLog(@"asset writer is in an unknown state, wasn't recording");
        return;
    }

    [_assetWriter finishWritingWithCompletionHandler:handler];
    
    _audioReady = NO;
    _videoReady = NO;
}

- (CVPixelBufferRef) rotateBuffer: (CMSampleBufferRef) sampleBuffer
{
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(imageBuffer,0);
    
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    void *src_buff = CVPixelBufferGetBaseAddress(imageBuffer);
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             nil];
    
    CVPixelBufferRef pxbuffer = NULL;
    //CVReturn status = CVPixelBufferPoolCreatePixelBuffer (NULL, _pixelWriter.pixelBufferPool, &pxbuffer);
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, width,
                                          height, kCVPixelFormatType_32BGRA, (__bridge CFDictionaryRef) options,
                                          &pxbuffer);
    
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *dest_buff = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(dest_buff != NULL);
    
    int *src = (int*) src_buff ;
    int *dest= (int*) dest_buff ;
    size_t count = (bytesPerRow * height) / 4 ;
    while (count--) {
        *dest++ = *src++;
    }
    
    //Test straight copy.
    //memcpy(pxdata, baseAddress, width * height * 4) ;
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    return pxbuffer;
}

//for (int i = 1; i <= new_height; i++) {
//    for (int j = new_width - 1; j > -1; j--) {
//        *dest++ = *(src + (j * width) + i) ;
//    }
//}

//- (void)updateOrientation {
//    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
//    
//    switch (orientation) {
//        case UIInterfaceOrientationPortrait:
//        {
//            _assetWriterVideoIn.transform = CGAffineTransformIdentity;
//        }
//            break;
//            
//        case UIInterfaceOrientationPortraitUpsideDown:
//        {
//            _assetWriterVideoIn.transform = CGAffineTransformMakeRotation(M_PI);
//        }
//            break;
//            
//        case UIInterfaceOrientationLandscapeLeft:
//        {
//            _assetWriterVideoIn.transform = CGAffineTransformMakeRotation(M_PI_2);
//            
//        }
//            break;
//            
//        case UIInterfaceOrientationLandscapeRight:
//        {
//            _assetWriterVideoIn.transform = CGAffineTransformMakeRotation(-M_PI_2);
//            
//        }
//            break;
//            
//        default:
//            break;
//    }
//}

//- (unsigned char*) rotateBuffer: (CMSampleBufferRef) sampleBuffer
//{
//    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
//    CVPixelBufferLockBaseAddress(imageBuffer,0);
//    
//    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
//    size_t width = MIN(CVPixelBufferGetWidth(imageBuffer),CVPixelBufferGetHeight(imageBuffer));
//    size_t height = width;
//    size_t currSize = bytesPerRow*height*sizeof(unsigned char);
//    size_t bytesPerRowOut = 4*height*sizeof(unsigned char);
//    
//    void *srcBuff = CVPixelBufferGetBaseAddress(imageBuffer);
//    
//    /*
//     * rotationConstant:   0 -- rotate 0 degrees (simply copy the data from src to dest)
//     *             1 -- rotate 90 degrees counterclockwise
//     *             2 -- rotate 180 degress
//     *             3 -- rotate 270 degrees counterclockwise
//     */
//    uint8_t rotationConstant = 0;
//    
//    unsigned char *outBuff = (unsigned char*)malloc(currSize);
//    
//    vImage_Buffer ibuff = { srcBuff, height, width, bytesPerRow};
//    vImage_Buffer ubuff = { outBuff, width, height, bytesPerRow};
//    
//    Pixel_8888 backColor = {255, 255, 255, 255};
//    vImage_Error err= vImageRotate90_ARGB8888 (&ibuff, &ubuff, rotationConstant, backColor, 0);
//    if (err != kvImageNoError) NSLog(@"%ld", err);
//    
//    return outBuff;
//}

@end
