#pragma once

#include "ofMain.h"
#include "ofxiOS.h"
#include "ofxiOSExtras.h"
#include "ofxMaxim.h" 
#include "ofxGui.h"
#include "ofxOsc.h"

#include <sys/time.h>

#include "maxiMFCC.h"
#define HOST "localhost"
#define PORT 6448




//***************** STUFF FOR AUDIO ****************************

//***** SoundStream.h (from ofxiOS)

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>

#define MAX_BUFFER_SIZE 4096

#define kOutputBus 0
#define kInputBus 1

typedef enum {
    SoundStreamTypeOutput = 0,
    SoundStreamTypeInput = 1
} SoundStreamType;

@protocol SoundStreamDelegate <NSObject>
@optional
- (void)soundStreamRequested:(id)sender output:(float *)output bufferSize:(NSInteger)bufferSize numOfChannels:(NSInteger)numOfChannels;
- (void)soundStreamReceived:(id)sender input:(float *)input bufferSize:(NSInteger)bufferSize numOfChannels:(NSInteger)numOfChannels;
- (void)soundStreamBeginInterruption:(id)sender;
- (void)soundStreamEndInterruption:(id)sender;
- (void)soundStreamError:(id)sender error:(NSString *)error;
@end

@interface SoundStream : NSObject {
    id<SoundStreamDelegate> delegate;
    SoundStreamType streamType;
    NSInteger numOfChannels;
    NSInteger sampleRate;
    NSInteger bufferSize;
    NSInteger numOfBuffers;
    AudioUnit audioUnit;
    BOOL bInterruptedWhileRunning;
}

@property (nonatomic, assign) id delegate;
@property (readonly) SoundStreamType streamType;
@property (readonly) NSInteger numOfChannels;
@property (readonly) NSInteger sampleRate;
@property (readonly) NSInteger bufferSize;
@property (readonly) NSInteger numOfBuffers;
@property (readonly) AudioUnit audioUnit;
@property (assign) BOOL bInterruptedWhileRunning;

- (id)initWithNumOfChannels:(NSInteger)numOfChannels
             withSampleRate:(NSInteger)sampleRate
             withBufferSize:(NSInteger)bufferSize;

- (void)start;
- (void)stop;
- (BOOL)isStreaming;

- (BOOL)checkStatus:(OSStatus)status;
- (void)reportError:(NSError *)error;

- (void)configureAudioSession;
+ (BOOL)shouldUseAudioSessionNotifications;

@end



//***** SoundInputStream.h (from ofxiOS)

//#import "SoundStream.h"

@interface SoundInputStream : SoundStream {
    
}

@end



//****** SoundOutputStream.h (from ofxiOS)

//#import "SoundStream.h"

@interface SoundOutputStream : SoundStream

@end



//***** ofBaseSoundStream.h

//class ofBaseSoundInput;
//class ofBaseSoundOutput;
//class ofSoundBuffer;
//
//class ofSoundDevice {
//public:
//
//    ofSoundDevice();
//
//    friend std::ostream& operator << (std::ostream& os, const ofSoundDevice& dev);
//    friend std::ostream& operator << (std::ostream& os, const std::vector<ofSoundDevice>& devs);
//
//    std::string name;
//
//    unsigned int deviceID;
//    unsigned int inputChannels;
//    unsigned int outputChannels;
//    bool isDefaultInput;
//    bool isDefaultOutput;
//
//    std::vector<unsigned int> sampleRates;
//};

//class myBaseSoundStream{
//public:
//    virtual ~myBaseSoundStream(){}
//    
//    virtual void setDeviceID(int deviceID) = 0;
//    virtual bool setup(int outChannels, int inChannels, int sampleRate, int bufferSize, int nBuffers)=0;
//    virtual bool setup(ofBaseApp * app, int outChannels, int inChannels, int sampleRate, int bufferSize, int nBuffers)=0;
//    virtual void setInput(ofBaseSoundInput * soundInput) = 0;
//    virtual void setOutput(ofBaseSoundOutput * soundOutput) = 0;
//    
//    virtual std::vector<ofSoundDevice> getDeviceList() const = 0;
//    virtual void printDeviceList() const;
//    
//    virtual void start() = 0;
//    virtual void stop() = 0;
//    virtual void close() = 0;
//    
//    virtual long unsigned long getTickCount() const = 0;
//    virtual int getNumInputChannels() const = 0;
//    virtual int getNumOutputChannels() const = 0;
//    virtual int getSampleRate() const = 0;
//    virtual int getBufferSize() const = 0;
//    virtual int getDeviceID() const = 0;
//};



//***** ofxiOSSoundStreamDelegate.h

//#import "SoundStream.h"

//class ofBaseSoundInput;
//class ofBaseSoundOutput;

@interface myiosSoundStreamDelegate : NSObject <SoundStreamDelegate>

- (id)initWithSoundInputApp:(ofBaseSoundInput *)app;
- (id)initWithSoundOutputApp:(ofBaseSoundOutput *)app;
- (void)setInput:(ofBaseSoundInput *)input;
- (void)setOutput:(ofBaseSoundOutput *)output;

@end



//***** ofxiOSSoundStream.h

class myiosSoundStream {
    
public:
    myiosSoundStream();
    ~myiosSoundStream();
    
    /// these are not implemented on iOS
    std::vector<ofSoundDevice> getDeviceList() const;
    std::vector<ofSoundDevice> getMatchingDevices(const std::string& name, unsigned int inChannels = UINT_MAX, unsigned int outChannels = UINT_MAX) const;
    void setDeviceID(int deviceID);
    virtual void printDeviceList() const;
    
    void setInput(ofBaseSoundInput * soundInput);
    void setOutput(ofBaseSoundOutput * soundOutput);
    ofBaseSoundInput * getInput();
    ofBaseSoundOutput * getOutput();
    
    /// currently, the number of buffers is always 1 on iOS and setting nBuffers has no effect
    /// the max buffersize is 4096
    bool setup(int numOfOutChannels, int numOfInChannels, int sampleRate, int bufferSize, int numOfBuffers);
    bool setup(ofBaseApp * app, int numOfOutChannels, int numOfInChannels, int sampleRate, int bufferSize, int numOfBuffers);
    
    void start();
    void stop();
    void close();
    
    // not implemented on iOS, always returns 0
    long unsigned long getTickCount() const;
    
    int getNumInputChannels() const;
    int getNumOutputChannels() const;
    int getSampleRate() const;
    int getBufferSize() const;
    int getDeviceID() const;
    
    static bool setMixWithOtherApps(bool bMix);
    
private:
    ofBaseSoundInput * soundInputPtr;
    ofBaseSoundOutput * soundOutputPtr;
    
    void * soundInputStream;
    void * soundOutputStream;
    
    int numOfInChannels;
    int numOfOutChannels;
    int sampleRate;
    int bufferSize;
    int numOfBuffers;
};



//***** ofSoundStream.h

//#include "ofBaseSoundStream.h"

//For iOS...
//#include "ofxiOSSoundStream.h"
//#define MY_SOUND_STREAM_TYPE myiosSoundStream
//
//class mySoundStream{
//public:
//    mySoundStream();
//    
//    void setSoundStream(myiosSoundStream* soundStreamPtr);
//    myiosSoundStream* getSoundStream();
//    
//    void printDeviceList() const;
//    std::vector<ofSoundDevice> getDeviceList() const;
//    std::vector<ofSoundDevice> getMatchingDevices(const std::string& name, unsigned int inChannels = UINT_MAX, unsigned int outChannels = UINT_MAX) const;
//    
//    void setDeviceID(int deviceID);
//    void setDevice(const ofSoundDevice& device);
//    
//    bool setup(ofBaseApp * app, int outChannels, int inChannels, int sampleRate, int bufferSize, int nBuffers);
//    bool setup(int outChannels, int inChannels, int sampleRate, int bufferSize, int nBuffers);
//    
//    void setInput(ofBaseSoundInput * soundInput);
//    void setInput(ofBaseSoundInput &soundInput);
//    void setOutput(ofBaseSoundOutput * soundOutput);
//    void setOutput(ofBaseSoundOutput &soundOutput);
//    
//    void start();
//    void stop();
//    void close();
//    
//    long unsigned long getTickCount() const;
//    int getNumInputChannels() const;
//    int getNumOutputChannels() const;
//    int getSampleRate() const;
//    int getBufferSize() const;
//    
//    OF_DEPRECATED_MSG("Use printDeviceList instead", std::vector<ofSoundDevice> listDevices() const);
//    
//protected:
//    myiosSoundStream* soundStream;
//    
//};


//***************** END OF STUFF FOR AUDIO *********************




class ofApp : public ofxiOSApp{
    
public:
    void setup();
    void update();
    void draw();
    void exit();
    
    void touchDown(ofTouchEventArgs & touch);
    void touchMoved(ofTouchEventArgs & touch);
    void touchUp(ofTouchEventArgs & touch);
    void touchDoubleTap(ofTouchEventArgs & touch);
    void touchCancelled(ofTouchEventArgs & touch);
    
    void lostFocus();
    void gotFocus();
    void gotMemoryWarning();
    void deviceOrientationChanged(int newOrientation);
    void audioIn(float * input, int bufferSize, int nChannels);
    void audioOut(float * output, int bufferSize, int nChannels);    
    
    float   * lAudioOut; /* outputs */
    float   * rAudioOut;
    
    float * lAudioIn; /* inputs */
    float * rAudioIn;
    
    int     initialBufferSize; /* buffer size */
    
    
    //MAXIMILIAN STUFF:
    
    int sampleRate;
    int bufferSize;
    
    maxiMix channel1;
    
    double wave,sample,outputs[2], ifftVal;
    maxiMix mymix;
    maxiOsc osc;
    
    ofxMaxiFFTOctaveAnalyzer oct;
    int nAverages;
    float *ifftOutput;
    int ifftSize;
    
    float peakFreq = 0;
    float centroid = 0;
    float RMS = 0;
    
    ofxMaxiIFFT ifft;
    ofxMaxiFFT mfft;
    int fftSize;
    int bins, dataSize;
    
    float callTime;
    timeval callTS, callEndTS;
    
    maxiMFCC mfcc;
    double *mfccs;
    
    maxiSample samp;
    
    //GUI STUFF
    bool bHide;
    
    ofxToggle mfccToggle;
    ofxToggle fftToggle;
    ofxToggle chromagramToggle;
    ofxToggle peakFrequencyToggle;
    ofxToggle centroidToggle;
    ofxToggle rmsToggle;
    
    ofxPanel gui;
    
    ofTrueTypeFont myfont;
    
    ofxOscSender sender;

    myiosSoundStream *theSoundStream;
};


