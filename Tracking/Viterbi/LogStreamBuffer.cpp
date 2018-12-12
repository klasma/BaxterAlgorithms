#include "LogStreamBuffer.h"

#include <string>
#include <iostream>
#include <fstream>
#include <sstream>

#ifdef MATLAB
#include "mex.h"
#endif

using namespace std;

LogStreamBuffer::LogStreamBuffer() : mDoPrint(true) {
}

int LogStreamBuffer::sync()
{
	// Write output to log file. There won't an error if no file is open.
	logFile << str().c_str();
	logFile.flush();


#ifdef MATLAB
	// Write ouput to matlab command window.
	mexPrintf("%s",str().c_str());
#else
	// Write output to windows command window.
	cout << str().c_str();
	cout.flush();
#endif

	// The string buffer has been printed and needs to be cleared. cout has it's own un-modified sting buffer
	// which is emptied automatically.
	str("");

	return 0;
}
        
void LogStreamBuffer::OpenFile(string aName)
{
	logFile.open(aName.c_str());
}
        
void LogStreamBuffer::CloseFile()
{
	// There won't be an error if the file is already closed.
	logFile.close();
}