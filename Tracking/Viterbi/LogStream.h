#ifndef LOGSTREAM
#define LOGSTREAM

#include "LogStreamBuffer.h"

#include <iostream>
#include <iomanip>
#include <string>

using namespace std;

// Stream class which sends text output to either the Matlab command line or to the windows
// command line. If the OpenFile function has been called, the text output will also be sent
// to a text file. The desired behaviour is achieved by inheriting from the ostream class
// and redefining sync function of the stringbuf member object. The printout can be turned
// on or off but it is turned on when objects are created. There is a globally available
// LogStream object named lout declared at the end of this header. This object should be
// used for all printouts.
class LogStream: public ostream
{
    public:
        LogStream()
            :ostream(&mBuffer) {}
            
        ~LogStream();

        // Make the LogStreamBuffer open a text file where all subsequent outputs will be stored. 
        void OpenFile(string aName);
        
	   // Makes the LogStreamBuffer close the text file so that subsequent outputs will not be written to it.
       void CloseFile();
       
       // Returns true if outputs are currently printed to the output locations.
       bool GetPrintout() { return mBuffer.GetPrintout(); }
       
       // Turns printouts to all output locations on or off.
       void SetPrintout(bool aDoPrint) { mBuffer.SetPrintout(aDoPrint); }

private:
	// Modified string buffer wich will send text outputs to the correct places.
	LogStreamBuffer mBuffer;
            
};

// Globally available LogStream object.
extern LogStream lout;

#endif