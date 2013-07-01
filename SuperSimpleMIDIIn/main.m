
#include <CoreFoundation/CoreFoundation.h>
#import <CoreMIDI/CoreMIDI.h>
#import <AudioUnit/AudioUnit.h>

/* Create an AudioUnit */
AudioUnit instrumentUnit;

/* Establisth MIDIRead and MIDI Notify callbacks which will get MIDI data from the devices */
#pragma mark CoreMIDi callbacks
static void	MIDIRead(const MIDIPacketList *pktlist, void *refCon, void *srcConnRefCon) {
    
    //Reads the source/device's name which is allocated in the MidiSetupWithSource function.
    const char *source = srcConnRefCon;
    
    //Extracting the data from the MIDI packets receieved.
    MIDIPacket *packet = (MIDIPacket *)pktlist->packet;
	Byte note = packet->data[1] & 0x7F;
    Byte velocity = packet->data[2] & 0x7F;
    
    for (int i=0; i < pktlist->numPackets; i++) {
        
		Byte midiStatus = packet->data[0];
		Byte midiCommand = midiStatus >> 4;
                
		if ((midiCommand == 0x09) || //note on
			(midiCommand == 0x08)) { //note off
			
            MusicDeviceMIDIEvent(instrumentUnit, midiStatus, note, velocity, 0);
            
            NSLog(@"%s - NOTE : %d | %d", source, note, velocity);
            
		} else {
        
            NSLog(@"%s - CNTRL  : %d | %d", source, note, velocity);
        }
		
        //After we are done reading the data, move to the next packet.
        packet = MIDIPacketNext(packet);
        
	}
    
}

void NotificationProc (const MIDINotification  *message, void *refCon) {
	NSLog(@"MIDI Notify, MessageID=%d,", message->messageID);
}

#pragma mark MIDI Source list
void listSources ()
{
    unsigned long sourceCount = MIDIGetNumberOfSources();
    for (int i=0; i<sourceCount; i++) {
        MIDIEndpointRef source = MIDIGetSource(i);
        CFStringRef endpointName = NULL;
        MIDIObjectGetStringProperty(source, kMIDIPropertyName, &endpointName);
        char endpointNameC[255];
        CFStringGetCString(endpointName, endpointNameC, 255, kCFStringEncodingUTF8);
        NSLog(@"Source %d - %s", i, endpointNameC);
    }
}

#pragma mark MIDI Setup
void MIDISetupWithSource(int sourceNo)
{
    MIDIClientRef client;
	MIDIClientCreate(CFSTR("SuperSimpleMIDIIn"), NotificationProc, instrumentUnit, &client);
    
	MIDIPortRef inPort;
	MIDIInputPortCreate(client, CFSTR("Input port"), MIDIRead, instrumentUnit, &inPort);
    
    MIDIEndpointRef source = MIDIGetSource(sourceNo);
    CFStringRef endpointName = NULL;
    MIDIObjectGetStringProperty(source, kMIDIPropertyName, &endpointName);
    char endpointNameC[255];
    CFStringGetCString(endpointName, endpointNameC, 255, kCFStringEncodingUTF8);
    
    //This is done manually due to the issue I currenly have with the <#void *connRefCon#> paramater of MIDIPortConnectSource not passing.
    //I hope to have a fix soon.
    
    if(strncmp(endpointNameC, "Launchpad",2)==0)
    {
        MIDIPortConnectSource(inPort, source, (void*)"Launchpad");
        NSLog(@"Recieving MIDI data from Launchpad");
    };
    if(strncmp(endpointNameC, "Controls",2)==0)
    {
        MIDIPortConnectSource(inPort, source, (void*)"Code");
        NSLog(@"Recieving MIDI data from Code");
    };
    
}

#pragma mark - Main
int main (int argc, const char * argv[])
{
	@autoreleasepool {
        
    listSources();           //See which sources you'd like to connect and then connect them as below.
        
    MIDISetupWithSource(6);  //Connecting source 6 - Novation Launchpad.
    MIDISetupWithSource(7);  //Connecting source 7 - Livid Code.

	CFRunLoopRun();          //Loop this for constant data updates.

    }
	return 0;
}

#pragma mark Unused function for next commit.
void setupMIDI() { //Currently unused function.
	
	MIDIClientRef client;
	MIDIClientCreate(CFSTR("SuperSimpleMIDIIn"), NotificationProc, instrumentUnit, &client);
    
	MIDIPortRef inPort;
	MIDIInputPortCreate(client, CFSTR("Input port"), MIDIRead, instrumentUnit, &inPort);
    
    unsigned long sourceCount = MIDIGetNumberOfSources();
    
    for (int i=0; i<sourceCount; i++) {
        MIDIEndpointRef src = MIDIGetSource(i);
        CFStringRef endpointName = NULL;
        MIDIObjectGetStringProperty(src, kMIDIPropertyName, &endpointName);
        char endpointNameC[255];
        CFStringGetCString(endpointName, endpointNameC, 255, kCFStringEncodingUTF8);
        
        MIDIPortConnectSource(inPort, src, (void*)"NameOfDevice"); //This works.
        MIDIPortConnectSource(inPort, src, (void*)endpointNameC); //This doesn't work..
        char *string1 = endpointNameC;
        MIDIPortConnectSource(inPort, src, (void*)string1); //and this doesn't work either. FIX needed for automation.
    }
}

