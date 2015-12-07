#include "ofApp.h"
#include "ofxMaxim.h"

//***************** STUFF FOR AUDIO ****************************

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

class myBaseSoundStream{
public:
    virtual ~myBaseSoundStream(){}
    
    virtual void setDeviceID(int deviceID) = 0;
    virtual bool setup(int outChannels, int inChannels, int sampleRate, int bufferSize, int nBuffers)=0;
    virtual bool setup(ofBaseApp * app, int outChannels, int inChannels, int sampleRate, int bufferSize, int nBuffers)=0;
    virtual void setInput(ofBaseSoundInput * soundInput) = 0;
    virtual void setOutput(ofBaseSoundOutput * soundOutput) = 0;
    
    virtual std::vector<ofSoundDevice> getDeviceList() const = 0;
    virtual void printDeviceList() const;
    
    virtual void start() = 0;
    virtual void stop() = 0;
    virtual void close() = 0;
    
    virtual long unsigned long getTickCount() const = 0;
    virtual int getNumInputChannels() const = 0;
    virtual int getNumOutputChannels() const = 0;
    virtual int getSampleRate() const = 0;
    virtual int getBufferSize() const = 0;
    virtual int getDeviceID() const = 0;
};


//***** ofBaseSoundStream.mm

#include "ofSoundBuffer.h"
#include "ofLog.h"

void myBaseSoundStream::printDeviceList() const {
    ofLogNotice("myBaseSoundStream::printDeviceList") << std::endl << getDeviceList();
}


//***** ofxiOSSoundStreamDelegate.h

#import "SoundStream.h"

//class ofBaseSoundInput;
//class ofBaseSoundOutput;

@interface myiosSoundStreamDelegate : NSObject <SoundStreamDelegate>

- (id)initWithSoundInputApp:(ofBaseSoundInput *)app;
- (id)initWithSoundOutputApp:(ofBaseSoundOutput *)app;
- (void)setInput:(ofBaseSoundInput *)input;
- (void)setOutput:(ofBaseSoundOutput *)output;

@end


//***** ofxiOSSoundStreamDelegate.mm

#include "ofBaseTypes.h"
#include "ofSoundBuffer.h"

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


//***** ofxiOSSoundStream.h

class myiosSoundStream : public myBaseSoundStream {
    
public:
    myiosSoundStream();
    ~myiosSoundStream();
    
    /// these are not implemented on iOS
    std::vector<ofSoundDevice> getDeviceList() const;
    void setDeviceID(int deviceID);
    
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

//***** ofxiOSSoundStream.mm

//#include "ofxiOSSoundStream.h"
//#include "ofxiOSSoundStreamDelegate.h"
//#include "ofSoundStream.h"
#include "ofBaseApp.h"

#import "SoundInputStream.h"
#import "SoundOutputStream.h"
#import <AVFoundation/AVFoundation.h>

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
        soundInputStream = [[SoundInputStream alloc] initWithNumOfChannels:numOfInChannels
                                                            withSampleRate:sampleRate
                                                            withBufferSize:bufferSize];
        myiosSoundStreamDelegate * delegate = [[myiosSoundStreamDelegate alloc] initWithSoundInputApp:soundInputPtr];
        ((SoundInputStream *)soundInputStream).delegate = delegate;
        [(SoundInputStream *)soundInputStream start];
    }
    
    if(numOfOutChannels > 0) {
        soundOutputStream = [[SoundOutputStream alloc] initWithNumOfChannels:numOfOutChannels
                                                              withSampleRate:sampleRate
                                                              withBufferSize:bufferSize];
        myiosSoundStreamDelegate * delegate = [[myiosSoundStreamDelegate alloc] initWithSoundOutputApp:soundOutputPtr];
        ((SoundInputStream *)soundOutputStream).delegate = delegate;
        [(SoundInputStream *)soundOutputStream start];
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
        [(SoundInputStream *)soundInputStream start];
    }
    
    if(soundOutputStream != NULL) {
        [(SoundOutputStream *)soundOutputStream start];
    }
}

//------------------------------------------------------------------------------
void myiosSoundStream::stop(){
    if(soundInputStream != NULL) {
        [(SoundInputStream *)soundInputStream stop];
    }
    
    if(soundOutputStream != NULL) {
        [(SoundOutputStream *)soundOutputStream stop];
    }
}

//------------------------------------------------------------------------------
void myiosSoundStream::close(){
    if(soundInputStream != NULL) {
        [((SoundInputStream *)soundInputStream).delegate release];
        [(SoundInputStream *)soundInputStream setDelegate:nil];
        [(SoundInputStream *)soundInputStream stop];
        [(SoundInputStream *)soundInputStream release];
        soundInputStream = NULL;
    }
    
    if(soundOutputStream != NULL) {
        [((SoundOutputStream *)soundInputStream).delegate release];
        [(SoundOutputStream *)soundInputStream setDelegate:nil];
        [(SoundOutputStream *)soundOutputStream stop];
        [(SoundOutputStream *)soundOutputStream release];
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



//***** ofSoundStream.h

//#include "ofBaseSoundStream.h"

//For iOS...
//#include "ofxiOSSoundStream.h"
#define MY_SOUND_STREAM_TYPE myiosSoundStream

class mySoundStream{
public:
    mySoundStream();
    
    void setSoundStream(shared_ptr<myBaseSoundStream> soundStreamPtr);
    shared_ptr<myBaseSoundStream> getSoundStream();
    
    void printDeviceList() const;
    std::vector<ofSoundDevice> getDeviceList() const;
    std::vector<ofSoundDevice> getMatchingDevices(const std::string& name, unsigned int inChannels = UINT_MAX, unsigned int outChannels = UINT_MAX) const;
    
    void setDeviceID(int deviceID);
    void setDevice(const ofSoundDevice& device);
    
    bool setup(ofBaseApp * app, int outChannels, int inChannels, int sampleRate, int bufferSize, int nBuffers);
    bool setup(int outChannels, int inChannels, int sampleRate, int bufferSize, int nBuffers);
    
    void setInput(ofBaseSoundInput * soundInput);
    void setInput(ofBaseSoundInput &soundInput);
    void setOutput(ofBaseSoundOutput * soundOutput);
    void setOutput(ofBaseSoundOutput &soundOutput);
    
    void start();
    void stop();
    void close();
    
    long unsigned long getTickCount() const;
    int getNumInputChannels() const;
    int getNumOutputChannels() const;
    int getSampleRate() const;
    int getBufferSize() const;
    
    OF_DEPRECATED_MSG("Use printDeviceList instead", std::vector<ofSoundDevice> listDevices() const);
    
protected:
    shared_ptr<myBaseSoundStream> soundStream;
    
};


//***** ofSoundStream.cpp

//#include "ofSoundStream.h"
#include "ofAppRunner.h"

namespace{
    mySoundStream systemSoundStream;
}

//------------------------------------------------------------
void ofSoundStreamSetup(int nOutputChannels, int nInputChannels, ofBaseApp * appPtr){
    if( appPtr == nullptr ){
        appPtr = ofGetAppPtr();
    }
    ofSoundStreamSetup(nOutputChannels, nInputChannels, appPtr, 44100, 256, 4);
}

//------------------------------------------------------------
void ofSoundStreamSetup(int nOutputChannels, int nInputChannels, int sampleRate, int bufferSize, int nBuffers){
    ofSoundStreamSetup(nOutputChannels, nInputChannels, ofGetAppPtr(), sampleRate, bufferSize, nBuffers);
}

//------------------------------------------------------------
void ofSoundStreamSetup(int nOutputChannels, int nInputChannels, ofBaseApp * appPtr, int sampleRate, int bufferSize, int nBuffers){
    systemSoundStream.setup(appPtr, nOutputChannels, nInputChannels, sampleRate, bufferSize, nBuffers);
}

//------------------------------------------------------------
void ofSoundStreamStop(){
    systemSoundStream.stop();
}

//------------------------------------------------------------
void ofSoundStreamStart(){
    systemSoundStream.start();
}

//------------------------------------------------------------
void ofSoundStreamClose(){
    systemSoundStream.close();
}

//------------------------------------------------------------
vector<ofSoundDevice> ofSoundStreamListDevices(){
    vector<ofSoundDevice> deviceList = systemSoundStream.getDeviceList();
    ofLogNotice("ofSoundStreamListDevices") << std::endl << deviceList;
    return deviceList;
}

//------------------------------------------------------------
mySoundStream::mySoundStream(){
#ifdef MY_SOUND_STREAM_TYPE
    setSoundStream( shared_ptr<MY_SOUND_STREAM_TYPE>(new MY_SOUND_STREAM_TYPE) );
#endif
}

//------------------------------------------------------------
void mySoundStream::setSoundStream(shared_ptr<myBaseSoundStream> soundStreamPtr){
    soundStream = soundStreamPtr;
}

//------------------------------------------------------------
shared_ptr<myBaseSoundStream> mySoundStream::getSoundStream(){
    return soundStream;
}

//------------------------------------------------------------
vector<ofSoundDevice> mySoundStream::getDeviceList() const{
    if( soundStream ){
        return soundStream->getDeviceList();
    } else {
        return vector<ofSoundDevice>();
    }
}

//------------------------------------------------------------
vector<ofSoundDevice> mySoundStream::listDevices() const{
    vector<ofSoundDevice> deviceList = getDeviceList();
    ofLogNotice("mySoundStream::listDevices") << std::endl << deviceList;
    return deviceList;
}

//------------------------------------------------------------
void mySoundStream::printDeviceList()  const{
    if( soundStream ) {
        soundStream->printDeviceList();
    }
}

//------------------------------------------------------------
void mySoundStream::setDeviceID(int deviceID){
    if( soundStream ){
        soundStream->setDeviceID(deviceID);
    }
}

//------------------------------------------------------------
void mySoundStream::setDevice(const ofSoundDevice &device) {
    setDeviceID(device.deviceID);
}

//------------------------------------------------------------
bool mySoundStream::setup(ofBaseApp * app, int outChannels, int inChannels, int sampleRate, int bufferSize, int nBuffers){
    if( soundStream ){
        return soundStream->setup(app, outChannels, inChannels, sampleRate, bufferSize, nBuffers);
    }
    return false;
}

//------------------------------------------------------------
void mySoundStream::setInput(ofBaseSoundInput * soundInput){
    if( soundStream ){
        soundStream->setInput(soundInput);
    }
}

//------------------------------------------------------------
void mySoundStream::setInput(ofBaseSoundInput &soundInput){
    setInput(&soundInput);
}

//------------------------------------------------------------
void mySoundStream::setOutput(ofBaseSoundOutput * soundOutput){
    if( soundStream ){
        soundStream->setOutput(soundOutput);
    }
}

//------------------------------------------------------------
void mySoundStream::setOutput(ofBaseSoundOutput &soundOutput){
    setOutput(&soundOutput);
}

//------------------------------------------------------------
bool mySoundStream::setup(int outChannels, int inChannels, int sampleRate, int bufferSize, int nBuffers){
    if( soundStream ){
        return soundStream->setup(outChannels, inChannels, sampleRate, bufferSize, nBuffers);
    }
    return false;
}

//------------------------------------------------------------
void mySoundStream::start(){
    if( soundStream ){
        soundStream->start();
    }
}

//------------------------------------------------------------
void mySoundStream::stop(){
    if( soundStream ){
        soundStream->stop();
    }
}

//------------------------------------------------------------
void mySoundStream::close(){
    if( soundStream ){
        soundStream->close();
    }
}

//------------------------------------------------------------
long unsigned long mySoundStream::getTickCount() const{
    if( soundStream ){
        return soundStream->getTickCount();
    }
    return 0;
}

//------------------------------------------------------------
int mySoundStream::getNumInputChannels() const{
    if( soundStream ){
        return soundStream->getNumInputChannels();
    }
    return 0;
}

//------------------------------------------------------------
int mySoundStream::getNumOutputChannels() const{
    if( soundStream ){
        return soundStream->getNumOutputChannels();
    }
    return 0;
}

//------------------------------------------------------------
int mySoundStream::getSampleRate() const{
    if( soundStream ){
        return soundStream->getSampleRate();
    }
    return 0;
}

//------------------------------------------------------------
int mySoundStream::getBufferSize() const{
    if( soundStream ){
        return soundStream->getBufferSize();
    }
    return 0;
}

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
vector<ofSoundDevice> mySoundStream::getMatchingDevices(const std::string& name, unsigned int inChannels, unsigned int outChannels) const {
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
    systemSoundStream.setup(this, 2, 2, sampleRate, initialBufferSize, 4);
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

