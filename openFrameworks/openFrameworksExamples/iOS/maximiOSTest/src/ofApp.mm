#include "ofApp.h"
#include "ofxMaxim.h"

//***************** STUFF FOR AUDIO ****************************

//****** SoundStream.mm (from ofxiOS)

#import <AVFoundation/AVFoundation.h>

@interface mySoundStream()<AVAudioSessionDelegate> {
    //
}
@end

@implementation mySoundStream

@synthesize delegate;
@synthesize streamType;
@synthesize numOfChannels;
@synthesize sampleRate;
@synthesize bufferSize;
@synthesize numOfBuffers;
@synthesize audioUnit;
@synthesize bInterruptedWhileRunning;

- (id)initWithNumOfChannels:(NSInteger)value0
             withSampleRate:(NSInteger)value1
             withBufferSize:(NSInteger)value2 {
    self = [super init];
    if(self) {
        numOfChannels = value0;
        sampleRate = value1;
        bufferSize = value2;
        numOfBuffers = 1; // always 1.
        audioUnit = nil;
        bInterruptedWhileRunning = NO;
        
#ifdef __IPHONE_6_0
        if([mySoundStream shouldUseAudioSessionNotifications]) {
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(handleInterruption:)
                                                         name:AVAudioSessionInterruptionNotification
                                                       object:nil];
        } else {
#endif
            
            [[AVAudioSession sharedInstance] setDelegate:self];
            
#ifdef __IPHONE_6_0
        }
#endif
        
    }
    return self;
}

- (void)dealloc {
    [super dealloc];
    
#ifdef __IPHONE_6_0
    if([mySoundStream shouldUseAudioSessionNotifications]) {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:AVAudioSessionInterruptionNotification
                                                      object:nil];
    } else {
#endif
        
        [[AVAudioSession sharedInstance] setDelegate:nil];
        
        
#ifdef __IPHONE_6_0
    }
#endif
    
}

- (void)start {
    
}

- (void)stop {
    [[AVAudioSession sharedInstance] setActive:NO error:nil];
}

- (BOOL)isStreaming {
    return (audioUnit != nil);
}

#pragma mark - Audio Session Config

- (void)configureAudioSession {
    NSError * audioSessionError = nil;
    AVAudioSession * audioSession = [AVAudioSession sharedInstance];
    
    if(![audioSession setActive:YES error:&audioSessionError]) {
        [self reportError:audioSessionError];
        
        // if we can't even activate the session, we better abort early
        return;
    }
    
    // setting sample rate (this has different selectors for iOS 5- and iOS 6+)
    double trueSampleRate = sampleRate;
    if([audioSession respondsToSelector:@selector(setPreferredSampleRate:error:)]) {
        if(![audioSession setPreferredSampleRate:sampleRate error:&audioSessionError]) {
            [self reportError:audioSessionError];
            audioSessionError = nil;
        }
        trueSampleRate = [audioSession sampleRate];
    } else if([audioSession respondsToSelector:@selector(setPreferredHardwareSampleRate:error:)]) {
        if(![audioSession setPreferredHardwareSampleRate:sampleRate error:&audioSessionError]) {
            [self reportError:audioSessionError];
            audioSessionError = nil;
        }
        trueSampleRate = [audioSession currentHardwareSampleRate];
    }
    sampleRate = trueSampleRate;
    
    // setting buffer size
    NSTimeInterval bufferDuration = bufferSize / trueSampleRate;
    if(![audioSession setPreferredIOBufferDuration:bufferDuration error:&audioSessionError]) {
        [self reportError:audioSessionError];
        audioSessionError = nil;
    }
}

#pragma mark - Interruptions

- (void) handleInterruption:(NSNotification *)notification {
#ifdef __IPHONE_6_0
    NSUInteger interruptionType = [notification.userInfo[AVAudioSessionInterruptionTypeKey] unsignedIntegerValue];
    
    if(interruptionType == AVAudioSessionInterruptionTypeBegan) {
        [self beginInterruption];
    } else if(interruptionType == AVAudioSessionInterruptionTypeEnded) {
        [self endInterruption];
    }
#endif
}

- (void)beginInterruption {
    if([self isStreaming]) {
        self.bInterruptedWhileRunning = YES;
    }
    [self stop];
    
    if([self.delegate respondsToSelector:@selector(soundStreamBeginInterruption:)]) {
        [self.delegate soundStreamBeginInterruption:self];
    }
}

- (void)endInterruption {
    if(self.bInterruptedWhileRunning) {
        self.bInterruptedWhileRunning = NO;
        [self start];
    }
    
    if([self.delegate respondsToSelector:@selector(soundStreamEndInterruption:)]) {
        [self.delegate soundStreamEndInterruption:self];
    }
}

// iOS 5- needs a delegate for Audio Session interruptions, iOS 6+ can use notifications
+ (BOOL) shouldUseAudioSessionNotifications {
    return [[[UIDevice currentDevice] systemVersion] floatValue] >= 6;
}

#pragma mark - Error Handling

- (BOOL)checkStatus:(OSStatus)status {
    if(status == noErr) {
        return YES;
    } else if([self.delegate respondsToSelector:@selector(soundStreamError:error:)]) {
        NSString * errorCode = [self stringForAudioUnitError:status];
        NSString * fullErrorString = [errorCode stringByAppendingFormat:@" (%i)", (int)status];
        [self.delegate soundStreamError:self error:fullErrorString];
    }
    return NO;
}

- (NSString *)stringForAudioUnitError:(OSStatus)status {
    if(status == kAudioUnitErr_InvalidProperty) {
        return @"kAudioUnitErr_InvalidProperty";
    } else if(status == kAudioUnitErr_InvalidParameter) {
        return @"kAudioUnitErr_InvalidParameter";
    } else if(status == kAudioUnitErr_InvalidElement) {
        return @"kAudioUnitErr_InvalidElement";
    } else if(status == kAudioUnitErr_NoConnection) {
        return @"kAudioUnitErr_NoConnection";
    } else if(status == kAudioUnitErr_FailedInitialization) {
        return @"kAudioUnitErr_FailedInitialization";
    } else if(status == kAudioUnitErr_TooManyFramesToProcess) {
        return @"kAudioUnitErr_TooManyFramesToProcess";
    } else if(status == kAudioUnitErr_InvalidFile) {
        return @"kAudioUnitErr_InvalidFile";
    } else if(status == kAudioUnitErr_FormatNotSupported) {
        return @"kAudioUnitErr_FormatNotSupported";
    } else if(status == kAudioUnitErr_Uninitialized) {
        return @"kAudioUnitErr_Uninitialized";
    } else if(status == kAudioUnitErr_InvalidScope) {
        return @"kAudioUnitErr_InvalidScope";
    } else if(status == kAudioUnitErr_PropertyNotWritable) {
        return @"kAudioUnitErr_PropertyNotWritable";
    } else if(status == kAudioUnitErr_CannotDoInCurrentContext) {
        return @"kAudioUnitErr_CannotDoInCurrentContext";
    } else if(status == kAudioUnitErr_InvalidPropertyValue) {
        return @"kAudioUnitErr_InvalidPropertyValue";
    } else if(status == kAudioUnitErr_PropertyNotInUse) {
        return @"kAudioUnitErr_PropertyNotInUse";
    } else if(status == kAudioUnitErr_Initialized) {
        return @"kAudioUnitErr_Initialized";
    } else if(status == kAudioUnitErr_InvalidOfflineRender) {
        return @"kAudioUnitErr_InvalidOfflineRender";
    } else if(status == kAudioUnitErr_Unauthorized) {
        return @"kAudioUnitErr_Unauthorized";
    } else {
        return @"Unknown";
    }
}

- (void) reportError:(NSError *)error {
    if(error && [self.delegate respondsToSelector:@selector(soundStreamError:error:)]) {
        [self.delegate soundStreamError:self error:[error localizedDescription]];
    }
}

@end



//****** SoundInputStream.mm  (from ofxiOS)
//  Original code by,
//  Memo Akten, http://www.memo.tv
//  Marek Bareza http://mrkbrz.com/
//  Updated 2012 by Dan Wilcox <danomatika@gmail.com>
//
//  references,
//  http://www.cocoawithlove.com/2010/10/ios-tone-generator-introduction-to.html
//  http://atastypixel.com/blog/using-remoteio-audio-unit/
//  http://www.stefanpopp.de/2011/capture-iphone-microphone/
//

//#import "SoundInputStream.h"
//#import <AVFoundation/AVFoundation.h>

typedef struct {
    AudioBufferList * bufferList;
    AudioUnit remoteIO;
    mySoundInputStream * stream;
}
SoundInputStreamContext;

@interface mySoundInputStream() {
    SoundInputStreamContext context;
}
@end

static OSStatus soundInputStreamRenderCallback(void *inRefCon,
                                               AudioUnitRenderActionFlags *ioActionFlags,
                                               const AudioTimeStamp *inTimeStamp,
                                               UInt32 inBusNumber,
                                               UInt32 inNumberFrames,
                                               AudioBufferList *ioData) {
    
    SoundInputStreamContext * context = (SoundInputStreamContext *)inRefCon;
    AudioBufferList * bufferList = context->bufferList;
    AudioBuffer * buffer = &bufferList->mBuffers[0];
    
    // make sure our buffer is big enough
    UInt32 necessaryBufferSize = inNumberFrames * sizeof(Float32);
    if(buffer->mDataByteSize < necessaryBufferSize) {
        free(buffer->mData);
        buffer->mDataByteSize = necessaryBufferSize;
        buffer->mData = malloc(necessaryBufferSize);
    }
    
    // we need to store the original buffer size, since AudioUnitRender seems to change the value
    // of the AudioBufferList's mDataByteSize (at least in the simulator). We need to write it back
    // later, or else we'll end up reallocating continuously in the render callback (BAD!)
    UInt32 bufferSize = buffer->mDataByteSize;
    
    OSStatus status = AudioUnitRender(context->remoteIO,
                                      ioActionFlags,
                                      inTimeStamp,
                                      inBusNumber,
                                      inNumberFrames,
                                      context->bufferList);
    
    if(status != noErr) {
        @autoreleasepool {
            if([context->stream.delegate respondsToSelector:@selector(soundStreamError:error:)]) {
                [context->stream.delegate soundStreamError:context->stream error:@"Could not render input audio samples"];
            }
        }
        return status;
    }
    
    if([context->stream.delegate respondsToSelector:@selector(soundStreamReceived:input:bufferSize:numOfChannels:)]) {
        [context->stream.delegate soundStreamReceived:context->stream
                                                input:(float *)bufferList->mBuffers[0].mData
                                           bufferSize:bufferList->mBuffers[0].mDataByteSize / sizeof(Float32)
                                        numOfChannels:bufferList->mBuffers[0].mNumberChannels];
    }
    
    bufferList->mBuffers[0].mDataByteSize = bufferSize;
    
    return noErr;
}

//----------------------------------------------------------------
@implementation mySoundInputStream

- (id)initWithNumOfChannels:(NSInteger)value0
             withSampleRate:(NSInteger)value1
             withBufferSize:(NSInteger)value2 {
    self = [super initWithNumOfChannels:value0
                         withSampleRate:value1
                         withBufferSize:value2];
    if(self) {
        streamType = SoundStreamTypeInput;
    }
    
    return self;
}

- (void)dealloc {
    [self stop];
    [super dealloc];
}

- (void)start {
    [super start];
    
    if([self isStreaming] == YES) {
        return; // already running.
    }
    
    [self configureAudioSession];
    
    //---------------------------------------------------------- audio session category config.
    
    AVAudioSession * audioSession = [AVAudioSession sharedInstance];
    NSError * err = nil;
    
#ifdef __IPHONE_6_0
    // need to configure set the audio category, and override to it route the audio to the speaker
    if([audioSession respondsToSelector:@selector(setCategory:withOptions:error:)]) {
        // we're on iOS 6 or greater, so use the AVFoundation API
        if(![audioSession setCategory:AVAudioSessionCategoryPlayAndRecord
                          withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker
                                error:&err]) {
            [self reportError:err];
            err = nil;
        }
    } else {
#endif
        // we're on iOS 5 or lower, need to use the C Audio Session API
        UInt32 sessionType = kAudioSessionCategory_PlayAndRecord;
        OSStatus success = AudioSessionSetProperty(kAudioSessionProperty_AudioCategory,
                                                   sizeof(sessionType),
                                                   &sessionType);
        
        if(success != noErr) {
            if([self.delegate respondsToSelector:@selector(soundStreamError:error:)]) {
                [self.delegate soundStreamError:self
                                          error:@"Couldn't set audio session category to Play and Record"];
            }
        }
        
        UInt32 overrideAudioRoute = kAudioSessionOverrideAudioRoute_Speaker;
        success = AudioSessionSetProperty(kAudioSessionProperty_OverrideCategoryDefaultToSpeaker,
                                          sizeof(UInt32),
                                          &overrideAudioRoute);
        if(success != noErr) {
            if([self.delegate respondsToSelector:@selector(soundStreamError:error:)]) {
                [self.delegate soundStreamError:self error:@"Couldn't override audio route"];
            }
        }
#ifdef __IPHONE_6_0
    }
#endif
    
    //---------------------------------------------------------- audio unit.
    
    // Configure the search parameters to find the default playback output unit
    // (called the kAudioUnitSubType_RemoteIO on iOS but
    // kAudioUnitSubType_DefaultOutput on Mac OS X)
    AudioComponentDescription desc = {
        .componentType = kAudioUnitType_Output,
        .componentSubType = kAudioUnitSubType_RemoteIO,
        .componentManufacturer = kAudioUnitManufacturer_Apple
    };
    
    // get component and get audio units.
    AudioComponent inputComponent = AudioComponentFindNext(NULL, &desc);
    [self checkStatus:AudioComponentInstanceNew(inputComponent, &audioUnit)];
    
    //---------------------------------------------------------- enable io.
    
    UInt32 on = 1;
    UInt32 off = 0;
    
    // enable input to AudioUnit.
    [self checkStatus:AudioUnitSetProperty(audioUnit,
                                           kAudioOutputUnitProperty_EnableIO,
                                           kAudioUnitScope_Input,
                                           kInputBus,
                                           &on,
                                           sizeof(on))];
    
    // enable output out of AudioUnit.
    [self checkStatus:AudioUnitSetProperty(audioUnit,
                                           kAudioOutputUnitProperty_EnableIO,
                                           kAudioUnitScope_Output,
                                           kOutputBus,
                                           &on,
                                           sizeof(on))];
    
    //---------------------------------------------------------- format.
    
    // Describe format
    AudioStreamBasicDescription audioFormat = {
        .mSampleRate       = static_cast<Float64>(sampleRate),
        .mFormatID         = kAudioFormatLinearPCM,
        .mFormatFlags      = kAudioFormatFlagsNativeFloatPacked,
        .mFramesPerPacket  = 1,
        .mChannelsPerFrame = static_cast<UInt32>(numOfChannels),
        .mBytesPerFrame    = sizeof(Float32),
        .mBytesPerPacket   = sizeof(Float32),
        .mBitsPerChannel   = sizeof(Float32) * 8
    };
    
    // Apply format
    [self checkStatus:AudioUnitSetProperty(audioUnit,
                                           kAudioUnitProperty_StreamFormat,
                                           kAudioUnitScope_Output,
                                           kInputBus,
                                           &audioFormat,
                                           sizeof(audioFormat))];
    
    //---------------------------------------------------------- callback.
    
    // input callback
    AURenderCallbackStruct callback = {soundInputStreamRenderCallback, &context};
    context.remoteIO = self.audioUnit;
    context.stream = self;
    [self checkStatus:AudioUnitSetProperty(audioUnit,
                                           kAudioOutputUnitProperty_SetInputCallback,
                                           kAudioUnitScope_Global,
                                           kInputBus,
                                           &callback,
                                           sizeof(callback))];
    
    //---------------------------------------------------------- make buffers.
    
    UInt32 bufferListSize = offsetof(AudioBufferList, mBuffers[0]) + (sizeof(AudioBuffer) * numOfChannels);
    context.bufferList = (AudioBufferList *)malloc(bufferListSize);
    context.bufferList->mNumberBuffers = numOfChannels;
    
    for(int i=0; i<context.bufferList->mNumberBuffers; i++) {
        context.bufferList->mBuffers[i].mNumberChannels = 1;
        context.bufferList->mBuffers[i].mDataByteSize = bufferSize * sizeof(Float32);
        context.bufferList->mBuffers[i].mData = calloc(bufferSize, sizeof(Float32));
    }
    
    //---------------------------------------------------------- go!
    
    [self checkStatus:AudioUnitInitialize(audioUnit)];
    [self checkStatus:AudioOutputUnitStart(audioUnit)];
}

- (void)stop {
    [super stop];
    
    if([self isStreaming] == NO) {
        return;
    }
    
    AudioOutputUnitStop(audioUnit);
    AudioUnitUninitialize(audioUnit);
    AudioComponentInstanceDispose(audioUnit);
    audioUnit = nil;
    
    for(int i=0; i<context.bufferList->mNumberBuffers; i++) {
        free(context.bufferList->mBuffers[i].mData);
    }
    free(context.bufferList);
}

@end



//****** SoundOutputStream.mm  (from ofxiOS)

static OSStatus soundOutputStreamRenderCallback(void *inRefCon,
                                                AudioUnitRenderActionFlags *ioActionFlags,
                                                const AudioTimeStamp *inTimeStamp,
                                                UInt32 inBusNumber,
                                                UInt32 inNumberFrames,
                                                AudioBufferList *ioData) {
    
    mySoundOutputStream * stream = (mySoundOutputStream *)inRefCon;
    AudioBuffer * audioBuffer = &ioData->mBuffers[0];
    
    // clearing the buffer before handing it off to the user
    // this saves us from horrible noises if the user chooses not to write anything
    memset(audioBuffer->mData, 0, audioBuffer->mDataByteSize);
    
    int bufferSize = (audioBuffer->mDataByteSize / sizeof(Float32)) / audioBuffer->mNumberChannels;
    bufferSize = MIN(bufferSize, MAX_BUFFER_SIZE / audioBuffer->mNumberChannels);
    
    if([stream.delegate respondsToSelector:@selector(soundStreamRequested:output:bufferSize:numOfChannels:)]) {
        [stream.delegate soundStreamRequested:stream
                                       output:(float*)audioBuffer->mData
                                   bufferSize:bufferSize
                                numOfChannels:audioBuffer->mNumberChannels];
    }
    
    return noErr;
}

//----------------------------------------------------------------
@interface mySoundOutputStream() {
    //
}
@end

@implementation mySoundOutputStream

- (id)initWithNumOfChannels:(NSInteger)value0
             withSampleRate:(NSInteger)value1
             withBufferSize:(NSInteger)value2 {
    self = [super initWithNumOfChannels:value0
                         withSampleRate:value1
                         withBufferSize:value2];
    if(self) {
        streamType = SoundStreamTypeOutput;
    }
    
    return self;
}

- (void)dealloc {
    [self stop];
    [super dealloc];
}

- (void)start {
    [super start];
    
    if([self isStreaming] == YES) {
        return; // already running.
    }
    
    [self configureAudioSession];
    
    //---------------------------------------------------------- audio unit.
    
    // Configure the search parameters to find the default playback output unit
    // (called the kAudioUnitSubType_RemoteIO on iOS but
    // kAudioUnitSubType_DefaultOutput on Mac OS X)
    AudioComponentDescription desc = {
        .componentType         = kAudioUnitType_Output,
        .componentSubType      = kAudioUnitSubType_RemoteIO,
        .componentManufacturer = kAudioUnitManufacturer_Apple
    };
    
    // get component and get audio units.
    AudioComponent inputComponent = AudioComponentFindNext(NULL, &desc);
    [self checkStatus:AudioComponentInstanceNew(inputComponent, &audioUnit)];
    
    //---------------------------------------------------------- enable io.
    
    // enable output out of AudioUnit.
    UInt32 on = 1;
    [self checkStatus:AudioUnitSetProperty(audioUnit,
                                           kAudioOutputUnitProperty_EnableIO,
                                           kAudioUnitScope_Output,
                                           kOutputBus,
                                           &on,
                                           sizeof(on))];
    
    //---------------------------------------------------------- format.
    
    // Describe format
    AudioStreamBasicDescription audioFormat = {
        .mSampleRate       = static_cast<Float64>(sampleRate),
        .mFormatID         = kAudioFormatLinearPCM,
        .mFormatFlags      = kAudioFormatFlagsNativeFloatPacked,
        .mFramesPerPacket  = 1,
        .mChannelsPerFrame = static_cast<UInt32>(numOfChannels),
        .mBytesPerFrame    = sizeof(Float32),
        .mBytesPerPacket   = sizeof(Float32),
        .mBitsPerChannel   = sizeof(Float32) * 8
    };

    // Apply format
    [self checkStatus:AudioUnitSetProperty(audioUnit,
                                           kAudioUnitProperty_StreamFormat,
                                           kAudioUnitScope_Input,
                                           kOutputBus,
                                           &audioFormat,
                                           sizeof(AudioStreamBasicDescription))];
    
    //---------------------------------------------------------- render callback.
    
    AURenderCallbackStruct callback = {soundOutputStreamRenderCallback, self};
    [self checkStatus:AudioUnitSetProperty(audioUnit,
                                           kAudioUnitProperty_SetRenderCallback,
                                           kAudioUnitScope_Global,
                                           kOutputBus,
                                           &callback,
                                           sizeof(callback))];
    
    //---------------------------------------------------------- go!
    
    [self checkStatus:AudioUnitInitialize(audioUnit)];
    [self checkStatus:AudioOutputUnitStart(audioUnit)];
}

- (void)stop {
    [super stop];
    
    if([self isStreaming] == NO) {
        return;
    }
    
    [self checkStatus:AudioOutputUnitStop(audioUnit)];
    [self checkStatus:AudioUnitUninitialize(audioUnit)];
    [self checkStatus:AudioComponentInstanceDispose(audioUnit)];
    audioUnit = nil;
}

@end



//***** ofBaseSoundStream.mm

#include "ofSoundBuffer.h"
#include "ofLog.h"

//void myBaseSoundStream::printDeviceList() const {
//    ofLogNotice("myBaseSoundStream::printDeviceList") << std::endl << getDeviceList();
//}



//***** ofxiOSSoundStreamDelegate.mm

#include "ofBaseTypes.h"
//#include "ofSoundBuffer.h"

@interface myiosSoundStreamDelegate() {
    ofBaseSoundInput * soundInputApp;
    ofBaseSoundOutput * soundOutputApp;
    std::shared_ptr<ofSoundBuffer> inputBuffer;
    std::shared_ptr<ofSoundBuffer> outputBuffer;
    unsigned long long tickCount;
}

@end

@implementation myiosSoundStreamDelegate

- (id)init {
    self = [super init];
    if(self) {
        soundInputApp = NULL;
        soundOutputApp = NULL;
        inputBuffer = std::shared_ptr<ofSoundBuffer>(new ofSoundBuffer);
        outputBuffer = std::shared_ptr<ofSoundBuffer>(new ofSoundBuffer);
        tickCount = 0;
    }
    return self;
}

- (void)dealloc {
    soundInputApp = NULL;
    soundOutputApp = NULL;
    [super dealloc];
}

- (id)initWithSoundInputApp:(ofBaseSoundInput *)app {
    self = [self init];
    if(self) {
        soundInputApp = app;
    }
    return self;
}

- (id)initWithSoundOutputApp:(ofBaseSoundOutput *)app {
    self = [self init];
    if(self) {
        soundOutputApp = app;
    }
    return self;
}

- (void)setInput:(ofBaseSoundInput *)input{
    soundInputApp = input;
}
- (void)setOutput:(ofBaseSoundOutput *)output{
    soundOutputApp = output;
}

- (void)soundStreamRequested:(id)sender
                      output:(float *)output
                  bufferSize:(NSInteger)bufferSize
               numOfChannels:(NSInteger)numOfChannels {
    if(soundOutputApp) {
        outputBuffer->setNumChannels(numOfChannels);
        outputBuffer->resize(bufferSize*numOfChannels);
        outputBuffer->setTickCount(tickCount);
        soundOutputApp->audioOut(*outputBuffer);
        outputBuffer->copyTo(output, bufferSize, numOfChannels, 0);
        tickCount++;
    }
}

- (void)soundStreamReceived:(id)sender
                      input:(float *)input
                 bufferSize:(NSInteger)bufferSize
              numOfChannels:(NSInteger)numOfChannels {
    if(soundInputApp) {
        inputBuffer->copyFrom(input, bufferSize, numOfChannels, inputBuffer->getSampleRate());
        inputBuffer->setTickCount(tickCount);
        soundInputApp->audioIn(*inputBuffer);
    }
}

- (void)soundStreamBeginInterruption:(id)sender {
    NSString * streamType = [[sender class] description];
    NSString * errorMessage = [NSString stringWithFormat:@"%@ :: Begin Interruption", streamType];
    ofLogVerbose("myiosSoundStreamDelegate") << [errorMessage UTF8String];
}

- (void)soundStreamEndInterruption:(id)sender {
    NSString * streamType = [[sender class] description];
    NSString * errorMessage = [NSString stringWithFormat:@"%@ :: End Interruption", streamType];
    ofLogVerbose("myiosSoundStreamDelegate") << [errorMessage UTF8String];
}

- (void)soundStreamError:(id)sender
                   error:(NSString *)error {
    NSString * streamType = [[sender class] description];
    NSString * errorMessage = [NSString stringWithFormat:@"%@ :: %@", streamType, error];
    ofLogVerbose("myiosSoundStreamDelegate") << [errorMessage UTF8String];
}

@end



//***** ofxiOSSoundStream.mm

//#include "ofxiOSSoundStream.h"
//#include "ofxiOSSoundStreamDelegate.h"
//#include "ofSoundStream.h"
#include "ofBaseApp.h"

//#import "SoundInputStream.h"
//#import "SoundOutputStream.h"
//#import <AVFoundation/AVFoundation.h>

//------------------------------------------------------------------------------
myiosSoundStream::myiosSoundStream() {
    soundInputStream = NULL;
    soundOutputStream = NULL;
    
    soundInputPtr = NULL;
    soundOutputPtr = NULL;
    
    numOfInChannels = 0;
    numOfOutChannels = 0;
    sampleRate = 0;
    bufferSize = 0;
    numOfBuffers = 0;
}

//------------------------------------------------------------------------------
myiosSoundStream::~myiosSoundStream() {
    close();
}

//------------------------------------------------------------------------------
vector<ofSoundDevice> myiosSoundStream::getDeviceList()  const{
    ofLogWarning("myiosSoundStream") << "getDeviceList() isn't implemented on iOS";
    return vector<ofSoundDevice>();
}

//------------------------------------------------------------------------------
vector<ofSoundDevice> myiosSoundStream::getMatchingDevices(const std::string& name, unsigned int inChannels, unsigned int outChannels) const {
    vector<ofSoundDevice> devs = getDeviceList();
    vector<ofSoundDevice> hits;
    
    for(size_t i = 0; i < devs.size(); i++) {
        bool nameMatch = devs[i].name.find(name) != string::npos;
        bool inMatch = (inChannels == UINT_MAX) || (devs[i].inputChannels == inChannels);
        bool outMatch = (outChannels == UINT_MAX) || (devs[i].outputChannels == outChannels);
        
        if(nameMatch && inMatch && outMatch) {
            hits.push_back(devs[i]);
        }
    }
    
    return hits;
}

//------------------------------------------------------------------------------
void myiosSoundStream::setDeviceID(int _deviceID) {
    //
}

//------------------------------------------------------------------------------
int myiosSoundStream::getDeviceID()  const{
    return 0;
}

//------------------------------------------------------------------------------
void myiosSoundStream::setInput(ofBaseSoundInput * soundInput) {
    soundInputPtr = soundInput;
    [(myiosSoundStreamDelegate *)[(id)soundInputStream delegate] setInput:soundInputPtr];
}

//------------------------------------------------------------------------------
void myiosSoundStream::setOutput(ofBaseSoundOutput * soundOutput) {
    soundOutputPtr = soundOutput;
    [(myiosSoundStreamDelegate *)[(id)soundOutputStream delegate] setOutput:soundOutputPtr];
}

//------------------------------------------------------------------------------
ofBaseSoundInput * myiosSoundStream::getInput(){
    return soundInputPtr;
}

//------------------------------------------------------------------------------
ofBaseSoundOutput * myiosSoundStream::getOutput(){
    return soundOutputPtr;
}

//------------------------------------------------------------------------------
bool myiosSoundStream::setup(int numOfOutChannels, int numOfInChannels, int sampleRate, int bufferSize, int numOfBuffers) {
    close();
    
    this->numOfOutChannels = numOfOutChannels;
    this->numOfInChannels = numOfInChannels;
    this->sampleRate = sampleRate;
    this->bufferSize = bufferSize;
    this->numOfBuffers = numOfBuffers;
    
    if(numOfInChannels > 0) {
        soundInputStream = [[mySoundInputStream alloc] initWithNumOfChannels:numOfInChannels
                                                            withSampleRate:sampleRate
                                                            withBufferSize:bufferSize];
        myiosSoundStreamDelegate * delegate = [[myiosSoundStreamDelegate alloc] initWithSoundInputApp:soundInputPtr];
        ((mySoundInputStream *)soundInputStream).delegate = delegate;
        [(mySoundInputStream *)soundInputStream start];
    }
    
    if(numOfOutChannels > 0) {
        soundOutputStream = [[mySoundOutputStream alloc] initWithNumOfChannels:numOfOutChannels
                                                              withSampleRate:sampleRate
                                                              withBufferSize:bufferSize];
        myiosSoundStreamDelegate * delegate = [[myiosSoundStreamDelegate alloc] initWithSoundOutputApp:soundOutputPtr];
        ((mySoundInputStream *)soundOutputStream).delegate = delegate;
        [(mySoundInputStream *)soundOutputStream start];
    }
    
    bool bOk = (soundInputStream != NULL) || (soundOutputStream != NULL);
    return bOk;
}

//------------------------------------------------------------------------------
bool myiosSoundStream::setup(ofBaseApp * app, int numOfOutChannels, int numOfInChannels, int sampleRate, int bufferSize, int numOfBuffers){
    setInput(app);
    setOutput(app);
    bool bOk = setup(numOfOutChannels, numOfInChannels, sampleRate, bufferSize, numOfBuffers);
    return bOk;
}

//------------------------------------------------------------------------------
void myiosSoundStream::start(){
    if(soundInputStream != NULL) {
        [(mySoundInputStream *)soundInputStream start];
    }
    
    if(soundOutputStream != NULL) {
        [(mySoundOutputStream *)soundOutputStream start];
    }
}

//------------------------------------------------------------------------------
void myiosSoundStream::stop(){
    if(soundInputStream != NULL) {
        [(mySoundInputStream *)soundInputStream stop];
    }
    
    if(soundOutputStream != NULL) {
        [(mySoundOutputStream *)soundOutputStream stop];
    }
}

//------------------------------------------------------------------------------
void myiosSoundStream::close(){
    if(soundInputStream != NULL) {
        [((mySoundInputStream *)soundInputStream).delegate release];
        [(mySoundInputStream *)soundInputStream setDelegate:nil];
        [(mySoundInputStream *)soundInputStream stop];
        [(mySoundInputStream *)soundInputStream release];
        soundInputStream = NULL;
    }
    
    if(soundOutputStream != NULL) {
        [((mySoundOutputStream *)soundInputStream).delegate release];
        [(mySoundOutputStream *)soundInputStream setDelegate:nil];
        [(mySoundOutputStream *)soundOutputStream stop];
        [(mySoundOutputStream *)soundOutputStream release];
        soundOutputStream = NULL;
    }
    
    numOfInChannels = 0;
    numOfOutChannels = 0;
    sampleRate = 0;
    bufferSize = 0;
    numOfBuffers = 0;
}

//------------------------------------------------------------------------------
long unsigned long myiosSoundStream::getTickCount() const{
    return 0;
}

//------------------------------------------------------------------------------
int myiosSoundStream::getNumOutputChannels() const{
    return numOfOutChannels;
}

//------------------------------------------------------------------------------
int myiosSoundStream::getNumInputChannels() const{
    return numOfInChannels;
}

//------------------------------------------------------------------------------
int myiosSoundStream::getSampleRate() const{
    return sampleRate;
}

//------------------------------------------------------------------------------
int myiosSoundStream::getBufferSize() const{
    return bufferSize;
}

//------------------------------------------------------------------------------
bool myiosSoundStream::setMixWithOtherApps(bool bMix){
    AVAudioSession * audioSession = [AVAudioSession sharedInstance];
    bool success = false;
    
#ifdef __IPHONE_6_0
    if(bMix) {
        if([audioSession respondsToSelector:@selector(setCategory:withOptions:error:)]) {
            if([audioSession setCategory:AVAudioSessionCategoryPlayAndRecord
                             withOptions:AVAudioSessionCategoryOptionMixWithOthers
                                   error:nil]) {
                success = true;
            }
        }
    } else {
#endif
        
        // this is the default category + options setup
        // Note: using a sound input stream will set the category to PlayAndRecord
        if([audioSession setCategory:AVAudioSessionCategorySoloAmbient error:nil]) {
            success = true;
        }
        
#ifdef __IPHONE_6_0
    }
#endif
    
    if(!success) {
        ofLogError("myiosSoundStream") << "setMixWithOtherApps(): couldn't set app audio session category";
    }
    
    return success;
}

void myiosSoundStream::printDeviceList() const {
    ofLogNotice("myBaseSoundStream::printDeviceList") << std::endl << getDeviceList();
}



//***** ofSoundStream.cpp

//#include "ofSoundStream.h"
#include "ofAppRunner.h"

//namespace{
//    mySoundStream systemSoundStream;
//}
//
////------------------------------------------------------------
//void ofSoundStreamSetup(int nOutputChannels, int nInputChannels, ofBaseApp * appPtr){
//    if( appPtr == nullptr ){
//        appPtr = ofGetAppPtr();
//    }
//    ofSoundStreamSetup(nOutputChannels, nInputChannels, appPtr, 44100, 256, 4);
//}
//
////------------------------------------------------------------
//void ofSoundStreamSetup(int nOutputChannels, int nInputChannels, int sampleRate, int bufferSize, int nBuffers){
//    ofSoundStreamSetup(nOutputChannels, nInputChannels, ofGetAppPtr(), sampleRate, bufferSize, nBuffers);
//}
//
////------------------------------------------------------------
//void ofSoundStreamSetup(int nOutputChannels, int nInputChannels, ofBaseApp * appPtr, int sampleRate, int bufferSize, int nBuffers){
//    systemSoundStream.setup(appPtr, nOutputChannels, nInputChannels, sampleRate, bufferSize, nBuffers);
//}
//
////------------------------------------------------------------
//void ofSoundStreamStop(){
//    systemSoundStream.stop();
//}
//
////------------------------------------------------------------
//void ofSoundStreamStart(){
//    systemSoundStream.start();
//}
//
////------------------------------------------------------------
//void ofSoundStreamClose(){
//    systemSoundStream.close();
//}
//
////------------------------------------------------------------
//vector<ofSoundDevice> ofSoundStreamListDevices(){
//    vector<ofSoundDevice> deviceList = systemSoundStream.getDeviceList();
//    ofLogNotice("ofSoundStreamListDevices") << std::endl << deviceList;
//    return deviceList;
//}

////------------------------------------------------------------
//mySoundStream::mySoundStream(){
//#ifdef MY_SOUND_STREAM_TYPE
//    setSoundStream( new myiosSoundStream() );
//#endif
//}
//
////------------------------------------------------------------
//void mySoundStream::setSoundStream(myiosSoundStream* soundStreamPtr){
//    soundStream = soundStreamPtr;
//}
//
////------------------------------------------------------------
//myiosSoundStream* mySoundStream::getSoundStream(){
//    return soundStream;
//}
//
////------------------------------------------------------------
//vector<ofSoundDevice> mySoundStream::getDeviceList() const{
//    if( soundStream ){
//        return soundStream->getDeviceList();
//    } else {
//        return vector<ofSoundDevice>();
//    }
//}
//
////------------------------------------------------------------
//vector<ofSoundDevice> mySoundStream::listDevices() const{
//    vector<ofSoundDevice> deviceList = getDeviceList();
//    ofLogNotice("mySoundStream::listDevices") << std::endl << deviceList;
//    return deviceList;
//}
//
////------------------------------------------------------------
//void mySoundStream::printDeviceList()  const{
//    if( soundStream ) {
//        soundStream->printDeviceList();
//    }
//}
//
////------------------------------------------------------------
//void mySoundStream::setDeviceID(int deviceID){
//    if( soundStream ){
//        soundStream->setDeviceID(deviceID);
//    }
//}
//
////------------------------------------------------------------
//void mySoundStream::setDevice(const ofSoundDevice &device) {
//    setDeviceID(device.deviceID);
//}
//
////------------------------------------------------------------
//bool mySoundStream::setup(ofBaseApp * app, int outChannels, int inChannels, int sampleRate, int bufferSize, int nBuffers){
//    if( soundStream ){
//        return soundStream->setup(app, outChannels, inChannels, sampleRate, bufferSize, nBuffers);
//    }
//    return false;
//}
//
////------------------------------------------------------------
//void mySoundStream::setInput(ofBaseSoundInput * soundInput){
//    if( soundStream ){
//        soundStream->setInput(soundInput);
//    }
//}
//
////------------------------------------------------------------
//void mySoundStream::setInput(ofBaseSoundInput &soundInput){
//    setInput(&soundInput);
//}
//
////------------------------------------------------------------
//void mySoundStream::setOutput(ofBaseSoundOutput * soundOutput){
//    if( soundStream ){
//        soundStream->setOutput(soundOutput);
//    }
//}
//
////------------------------------------------------------------
//void mySoundStream::setOutput(ofBaseSoundOutput &soundOutput){
//    setOutput(&soundOutput);
//}
//
////------------------------------------------------------------
//bool mySoundStream::setup(int outChannels, int inChannels, int sampleRate, int bufferSize, int nBuffers){
//    if( soundStream ){
//        return soundStream->setup(outChannels, inChannels, sampleRate, bufferSize, nBuffers);
//    }
//    return false;
//}
//
////------------------------------------------------------------
//void mySoundStream::start(){
//    if( soundStream ){
//        soundStream->start();
//    }
//}
//
////------------------------------------------------------------
//void mySoundStream::stop(){
//    if( soundStream ){
//        soundStream->stop();
//    }
//}
//
////------------------------------------------------------------
//void mySoundStream::close(){
//    if( soundStream ){
//        soundStream->close();
//    }
//}
//
////------------------------------------------------------------
//long unsigned long mySoundStream::getTickCount() const{
//    if( soundStream ){
//        return soundStream->getTickCount();
//    }
//    return 0;
//}
//
////------------------------------------------------------------
//int mySoundStream::getNumInputChannels() const{
//    if( soundStream ){
//        return soundStream->getNumInputChannels();
//    }
//    return 0;
//}
//
////------------------------------------------------------------
//int mySoundStream::getNumOutputChannels() const{
//    if( soundStream ){
//        return soundStream->getNumOutputChannels();
//    }
//    return 0;
//}
//
////------------------------------------------------------------
//int mySoundStream::getSampleRate() const{
//    if( soundStream ){
//        return soundStream->getSampleRate();
//    }
//    return 0;
//}
//
////------------------------------------------------------------
//int mySoundStream::getBufferSize() const{
//    if( soundStream ){
//        return soundStream->getBufferSize();
//    }
//    return 0;
//}

//------------------------------------------------------------
ofSoundDevice::ofSoundDevice()
: name("Unknown")
, deviceID(0)
, inputChannels(0)
, outputChannels(0)
, isDefaultInput(false)
, isDefaultOutput(false) {
    
}

//------------------------------------------------------------
//vector<ofSoundDevice> mySoundStream::getMatchingDevices(const std::string& name, unsigned int inChannels, unsigned int outChannels) const {
//    vector<ofSoundDevice> devs = getDeviceList();
//    vector<ofSoundDevice> hits;
//    
//    for(size_t i = 0; i < devs.size(); i++) {
//        bool nameMatch = devs[i].name.find(name) != string::npos;
//        bool inMatch = (inChannels == UINT_MAX) || (devs[i].inputChannels == inChannels);
//        bool outMatch = (outChannels == UINT_MAX) || (devs[i].outputChannels == outChannels);
//        
//        if(nameMatch && inMatch && outMatch) {
//            hits.push_back(devs[i]);
//        }
//    }
//    
//    return hits;
//}

//------------------------------------------------------------
std::ostream& operator << (std::ostream& os, const ofSoundDevice& dev) {
    os << "[" << dev.deviceID << "] " << dev.name;
    os << " [in:" << dev.inputChannels << " out:" << dev.outputChannels << "]";
    if(dev.isDefaultInput) os << " (default in)";
    if(dev.isDefaultOutput) os << " (default out)";
    return os;
}

//------------------------------------------------------------
std::ostream& operator << (std::ostream& os, const std::vector<ofSoundDevice>& devs) {
    for(std::size_t i = 0; i < devs.size(); i++) {
        os << devs[i] << std::endl;
    }
    return os;
}


//***************** END OF STUFF FOR AUDIO *********************

//--------------------------------------------------------------
void ofApp::setup(){
    
    sender.setup(HOST, PORT);
    /* some standard setup stuff*/
    
    
    
    ofEnableAlphaBlending();
    ofSetupScreen();
    ofBackground(0, 0, 0);
    ofSetFrameRate(60);
    
    /* This is stuff you always need.*/
    
    sampleRate          = 44100; /* Sampling Rate */
    initialBufferSize   = 512;  /* Buffer Size. you have to fill this buffer with sound*/
    lAudioOut           = new float[initialBufferSize];/* outputs */
    rAudioOut           = new float[initialBufferSize];
    lAudioIn            = new float[initialBufferSize];/* inputs */
    rAudioIn            = new float[initialBufferSize];
    
    
    /* This is a nice safe piece of code */
    memset(lAudioOut, 0, initialBufferSize * sizeof(float));
    memset(rAudioOut, 0, initialBufferSize * sizeof(float));
    
    memset(lAudioIn, 0, initialBufferSize * sizeof(float));
    memset(rAudioIn, 0, initialBufferSize * sizeof(float));
    
    /* Now you can put anything you would normally put in maximilian's 'setup' method in here. */
    
    //  samp.load(ofToDataPath("sinetest_stepping2.wav"));
    //      samp.load(ofToDataPath("whitenoise2.wav"));
    //  samp.load(ofToDataPath("additive22.wav"));
    //samp.load(ofToDataPath("pinknoise2.wav"));
    //samp.load(ofToDataPath("filtersweep2.wav"));
    //samp.getLength();
    
    
//    fftSize = 1024;
//    mfft.setup(fftSize, 512, 256);
//    ifft.setup(fftSize, 512, 256);
//    
//    
//    nAverages = 12;
//    oct.setup(sampleRate, fftSize/2, nAverages);
//    
//    mfccs = (double*) malloc(sizeof(double) * 13);
//    mfcc.setup(512, 42, 13, 20, 20000, sampleRate);
    
    ofxMaxiSettings::setup(sampleRate, 2, initialBufferSize);
//    ofSoundStreamSetup(2,2, this, sampleRate, initialBufferSize, 4);
//    void ofSoundStreamSetup(int nOutputChannels, int nInputChannels, ofBaseApp * appPtr, int sampleRate, int bufferSize, int nBuffers)
//    systemSoundStream.setup(appPtr, nOutputChannels, nInputChannels, sampleRate, bufferSize, nBuffers);
//    systemSoundStream.setup(this, 2, 2, sampleRate, initialBufferSize, 4);
    
    theSoundStream = new myiosSoundStream();
    theSoundStream->setup(this, 2, 2, sampleRate, initialBufferSize, 4);
    
}

//--------------------------------------------------------------
void ofApp::update(){
}

//--------------------------------------------------------------
void ofApp::draw(){
}

//--------------------------------------------------------------
void ofApp::exit(){
    
}


//--------------------------------------------------------------
void ofApp::audioOut(float * output, int bufferSize, int nChannels) {
    
        for (int i = 0; i < bufferSize; i++){
            wave = osc.sinebuf(440);
            mymix.stereo(wave, outputs, 0.5);
            lAudioOut[i] = 0;
            rAudioOut[i] = 0;
            
            output[i*nChannels    ] = wave;
            output[i*nChannels + 1] = wave;
        }
    
}

//--------------------------------------------------------------
void ofApp::audioIn(float * input, int bufferSize, int nChannels){
    
    for (int i = 0; i < bufferSize; i++){
        lAudioIn[i]=input[i*nChannels];
        rAudioIn[i]=input[i*nChannels +1];
    }
    
    

    
}


//--------------------------------------------------------------
void ofApp::touchDown(ofTouchEventArgs &touch){
    
}

//--------------------------------------------------------------
void ofApp::touchMoved(ofTouchEventArgs &touch){
    
}

//--------------------------------------------------------------
void ofApp::touchUp(ofTouchEventArgs &touch){
    
}

//--------------------------------------------------------------
void ofApp::touchDoubleTap(ofTouchEventArgs &touch){
    
}

//--------------------------------------------------------------
void ofApp::touchCancelled(ofTouchEventArgs & touch){
    
}

//--------------------------------------------------------------
void ofApp::lostFocus(){
    
}

//--------------------------------------------------------------
void ofApp::gotFocus(){
    
}

//--------------------------------------------------------------
void ofApp::gotMemoryWarning(){
    
}

//--------------------------------------------------------------
void ofApp::deviceOrientationChanged(int newOrientation){
    
}

