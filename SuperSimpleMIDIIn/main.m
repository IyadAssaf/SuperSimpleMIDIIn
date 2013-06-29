
#include <CoreFoundation/CoreFoundation.h>
#import <CoreMIDI/CoreMIDI.h>
#import <AudioUnit/AudioUnit.h>


AudioUnit instrumentUnit;

/* Establisth MIDIRead and MIDI Notify functions */

static void	MIDIRead(const MIDIPacketList *pktlist, void *refCon, void *connRefCon) {
    
    
    
	MIDIPacket *packet = (MIDIPacket *)pktlist->packet;
	
    for (int i=0; i < pktlist->numPackets; i++) {
        
		Byte midiStatus = packet->data[0];
		Byte midiCommand = midiStatus >> 4;
                
		if ((midiCommand == 0x09) || //note on
			(midiCommand == 0x08)) { //note off
			Byte note = packet->data[1] & 0x7F;
			Byte velocity = packet->data[2] & 0x7F;
            
			
            MusicDeviceMIDIEvent (instrumentUnit,
                                  midiStatus,
                                  note,
                                  velocity,0);

            NSLog(@"NOTE : %d | %d", note, velocity);
            
            
            
            
		} else {
            
            Byte note = packet->data[1] & 0x7F;
			Byte velocity = packet->data[2] & 0x7F;
            

            NSLog(@"CNTRL: %d | %d", note, velocity);
        }
		packet = MIDIPacketNext(packet);
	}
    
}

void NotificationProc (const MIDINotification  *message, void *refCon) {
	printf("MIDI Notify, messageId=%d,", message->messageID);
}


void setupMIDI() {
	
	MIDIClientRef client;
	MIDIClientCreate(CFSTR("SuperSimpleMIDIIn"), NotificationProc, instrumentUnit, &client);
    
	MIDIPortRef inPort;
	MIDIInputPortCreate(client, CFSTR("Input port"), MIDIRead, instrumentUnit, &inPort);
    
    NSLog(@"********************************");
    NSLog(@"   Current MIDI Input devices   ");
    NSLog(@"********************************");
    
    unsigned long sourceCount = MIDIGetNumberOfSources();
	for (int i = 0; i < sourceCount; ++i) {
		MIDIEndpointRef src = MIDIGetSource(i);
		CFStringRef endpointName = NULL;
		MIDIObjectGetStringProperty(src, kMIDIPropertyName, &endpointName);
		char endpointNameC[255];
		CFStringGetCString(endpointName, endpointNameC, 255, kCFStringEncodingUTF8);
		NSLog(@"%d - %s", i, endpointNameC);
	}
    
    NSLog(@":> Type the number of the device you would like input from");

    int devNo = 0;
    
    printf(":>");
    scanf("%d", &devNo);

    MIDIEndpointRef src = MIDIGetSource(devNo);
	CFStringRef endpointName = NULL;
    MIDIObjectGetStringProperty(src, kMIDIPropertyName, &endpointName);
    char endpointNameC[255];
    CFStringGetCString(endpointName, endpointNameC, 255, kCFStringEncodingUTF8);
    NSLog(@":> Now receiving input from %s...", endpointNameC);
    MIDIPortConnectSource(inPort, src, NULL);
}



#pragma mark - main

int main (int argc, const char * argv[])
{
    int interrupt = -1;
    
	@autoreleasepool {

        
    if (interrupt<0) {
        setupMIDI();
    }
        
    
        
    scanf("%d", &interrupt);
    
        
        
	CFRunLoopRun();
	// run until aborted with control-C

    }
	return 0;
}

