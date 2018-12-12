#include "LogStream.h"
#include "LogStreamBuffer.h"

#include <iostream>

using namespace std;

LogStream lout;

// Closes the text file in case the user forgot to do that.
LogStream::~LogStream()
{
	// There won't be an error if the file is already closed.
	CloseFile();
}

void LogStream::OpenFile(string aName)
{
	mBuffer.OpenFile(aName);
}

void LogStream::CloseFile()
{
	mBuffer.CloseFile();
}