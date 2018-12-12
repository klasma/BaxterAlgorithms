#ifndef LOGSTREAMBUFFER
#define LOGSTREAMBUFFER

#include <fstream>
#include <string>
#include <sstream>

using namespace std;

// String buffer class with a modified sync function wich will send text outputs to either the
// matlab command line or to the windows command line. The buffer can also open and close a log
// file where all outputs can be stored.
class LogStreamBuffer: public stringbuf
{
public:
	LogStreamBuffer();

	// Function which will send text output to the appropriate places whenever the LogStream is
	// flushed.
	virtual int sync();

	// Opens a log file to which subsequent outputs will be written.
	void OpenFile(string fname);

	// Closes the log file so that subsequent ouputs won't be written to it.
	void CloseFile();
    
    // Returns true if outputs are currently printed to the output locations.
    bool GetPrintout() { return mDoPrint; }
    
    // Turns printouts to all output locations on or off.
    void SetPrintout(bool aDoPrint) { mDoPrint = aDoPrint; }

private:
	// File stream to a log file that records everything sent to the command window.
	ofstream logFile;
    
    // If mDoPrint is true, output is printed to all output locations. Otherwise,
    // no outputs are printed.
    bool mDoPrint;
};
#endif