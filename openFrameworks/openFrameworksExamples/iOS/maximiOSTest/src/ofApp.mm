#include "ofApp.h"
#include "ofxMaxim.h"

//***************** STUFF FOR AUDIO ****************************

//***** ofSoundStream.h

#include "ofBaseSoundStream.h"

//For iOS...
#include "ofxiOSSoundStream.h"
#define OF_SOUND_STREAM_TYPE ofxiOSSoundStream

class XXofSoundStream{
public:
    XXofSoundStream();
    
    void setSoundStream(shared_ptr<ofBaseSoundStream> soundStreamPtr);
    shared_ptr<ofBaseSoundStream> getSoundStream();
    
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
    shared_ptr<ofBaseSoundStream> soundStream;
    
};


//***** ofSoundStream.cpp

//#include "ofSoundStream.h"
#include "ofAppRunner.h"

namespace{
    XXofSoundStream systemSoundStream;
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
XXofSoundStream::XXofSoundStream(){
#ifdef OF_SOUND_STREAM_TYPE
    setSoundStream( shared_ptr<OF_SOUND_STREAM_TYPE>(new OF_SOUND_STREAM_TYPE) );
#endif
}

//------------------------------------------------------------
void XXofSoundStream::setSoundStream(shared_ptr<ofBaseSoundStream> soundStreamPtr){
    soundStream = soundStreamPtr;
}

//------------------------------------------------------------
shared_ptr<ofBaseSoundStream> XXofSoundStream::getSoundStream(){
    return soundStream;
}

//------------------------------------------------------------
vector<ofSoundDevice> XXofSoundStream::getDeviceList() const{
    if( soundStream ){
        return soundStream->getDeviceList();
    } else {
        return vector<ofSoundDevice>();
    }
}

//------------------------------------------------------------
vector<ofSoundDevice> XXofSoundStream::listDevices() const{
    vector<ofSoundDevice> deviceList = getDeviceList();
    ofLogNotice("XXofSoundStream::listDevices") << std::endl << deviceList;
    return deviceList;
}

//------------------------------------------------------------
void XXofSoundStream::printDeviceList()  const{
    if( soundStream ) {
        soundStream->printDeviceList();
    }
}

//------------------------------------------------------------
void XXofSoundStream::setDeviceID(int deviceID){
    if( soundStream ){
        soundStream->setDeviceID(deviceID);
    }
}

//------------------------------------------------------------
void XXofSoundStream::setDevice(const ofSoundDevice &device) {
    setDeviceID(device.deviceID);
}

//------------------------------------------------------------
bool XXofSoundStream::setup(ofBaseApp * app, int outChannels, int inChannels, int sampleRate, int bufferSize, int nBuffers){
    if( soundStream ){
        return soundStream->setup(app, outChannels, inChannels, sampleRate, bufferSize, nBuffers);
    }
    return false;
}

//------------------------------------------------------------
void XXofSoundStream::setInput(ofBaseSoundInput * soundInput){
    if( soundStream ){
        soundStream->setInput(soundInput);
    }
}

//------------------------------------------------------------
void XXofSoundStream::setInput(ofBaseSoundInput &soundInput){
    setInput(&soundInput);
}

//------------------------------------------------------------
void XXofSoundStream::setOutput(ofBaseSoundOutput * soundOutput){
    if( soundStream ){
        soundStream->setOutput(soundOutput);
    }
}

//------------------------------------------------------------
void XXofSoundStream::setOutput(ofBaseSoundOutput &soundOutput){
    setOutput(&soundOutput);
}

//------------------------------------------------------------
bool XXofSoundStream::setup(int outChannels, int inChannels, int sampleRate, int bufferSize, int nBuffers){
    if( soundStream ){
        return soundStream->setup(outChannels, inChannels, sampleRate, bufferSize, nBuffers);
    }
    return false;
}

//------------------------------------------------------------
void XXofSoundStream::start(){
    if( soundStream ){
        soundStream->start();
    }
}

//------------------------------------------------------------
void XXofSoundStream::stop(){
    if( soundStream ){
        soundStream->stop();
    }
}

//------------------------------------------------------------
void XXofSoundStream::close(){
    if( soundStream ){
        soundStream->close();
    }
}

//------------------------------------------------------------
long unsigned long XXofSoundStream::getTickCount() const{
    if( soundStream ){
        return soundStream->getTickCount();
    }
    return 0;
}

//------------------------------------------------------------
int XXofSoundStream::getNumInputChannels() const{
    if( soundStream ){
        return soundStream->getNumInputChannels();
    }
    return 0;
}

//------------------------------------------------------------
int XXofSoundStream::getNumOutputChannels() const{
    if( soundStream ){
        return soundStream->getNumOutputChannels();
    }
    return 0;
}

//------------------------------------------------------------
int XXofSoundStream::getSampleRate() const{
    if( soundStream ){
        return soundStream->getSampleRate();
    }
    return 0;
}

//------------------------------------------------------------
int XXofSoundStream::getBufferSize() const{
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
vector<ofSoundDevice> XXofSoundStream::getMatchingDevices(const std::string& name, unsigned int inChannels, unsigned int outChannels) const {
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

