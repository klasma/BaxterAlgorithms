#include "ArraySave.h"
#include <cstddef>  // To get NULL.
#include <fstream>

using namespace std;

////Save a 2D double matrix to a binary file
//void ArraySave::DoubleMatrixSave(int am, int an, double **aMat, const char *aName) {
//	int i, j;
//	int nDim = 2;
//
//	ofstream file(aName, ios::out|ios::binary);
//
//	file.write((char *) &nDim, sizeof(int));
//	file.write((char *) &am, sizeof(int));
//	file.write((char *) &an, sizeof(int));
//	for(j=0;j<an;j++){
//		for(i=0;i<am;i++){
//			file.write((char *) (aMat[i]+j), sizeof(double));
//		}
//	}
//	file.close();
//	return;
//}

//Save a 2D int matrix to a binary file
void ArraySave::IntMatrixSave(int am, int an, int **aMat, const char *aName){
	int i, j;
	int nDim = 2;

	ofstream file(aName, ios::out|ios::binary);

	file.write((char *) &nDim, sizeof(int));
	file.write((char *) &am, sizeof(int));
	file.write((char *) &an, sizeof(int));
	for(j=0;j<an;j++){
		for(i=0;i<am;i++){
			file.write((char *) (aMat[i]+j), sizeof(int));
		}
	}
	file.close();
	return;
}

//Save a 3D int matrix to a binary file
void ArraySave::IntMatrixSave3(int am, int an, int ao, int ***aMat, const char *aName){
	int i, j, k;
	int nDim = 3;

	ofstream file(aName, ios::out|ios::binary);

	file.write((char *) &nDim, sizeof(int));
	file.write((char *) &am, sizeof(int));
	file.write((char *) &an, sizeof(int));
	file.write((char *) &ao, sizeof(int));
	for(k=0;k<ao;k++){
		for(j=0;j<an;j++){
			for(i=0;i<am;i++){
				file.write((char *) (aMat[i][j]+k), sizeof(int));
			}
		}
	}
	file.close();
	return;
}

double *ArraySave::ReadDouble(string aName, int *aLength) {
	double *retPtr = NULL;  // Pointer to the double array that will be returned.

	ifstream file(aName.c_str(), ios::in|ios::binary|ios::ate);

	if (!file.is_open()) {
		// This will lead to a null-pointer exception if the file does not exist, unless
		// the caller checks that something was actaully read.
		*aLength = 0;
		return retPtr;
	}

	int byteLength = (int) file.tellg();
	file.seekg(0, ios::beg);
	
	// Read how many dimensions the array has.
	int nDims;
	file.read((char *) &nDims, sizeof(int));
	
	// Determine the number of doubles that will be returned.
	int retLength = (byteLength - (1 + nDims)*sizeof(int))/sizeof(double);
	*aLength = retLength;
	if (retLength == 0) {  // [] was saved in Matlab.
		return retPtr;
	}

	// Create the double array.
	retPtr = new double[retLength];
	file.seekg((1 + nDims)*sizeof(int), ios::beg);
	file.read((char *) retPtr, retLength*sizeof(double));
	
	file.close();
	return retPtr;
}