#ifndef ARRAYSAVE
#define ARRAYSAVE

#include <fstream>

using namespace std;

class ArraySave {
public:
	template <class type>
	static void Save(int aNumDims, const int *aDims, const type *aArray, const char *aName) {

	// Compute the number of elements in the array.
	int N = 1;
	for (int d=0; d<aNumDims; d++) {
		N = N*aDims[d];
	}

	// Open file.
	ofstream file(aName, ios::out|ios::binary);

	// Write to file.
	file.write((char *) &aNumDims, sizeof(int));
	file.write((char *) aDims, sizeof(int)*aNumDims);
	for(int n=0; n<N; n++) {
		file.write((char *) (aArray+n), sizeof(type));
	}
	
	file.close();
	return;
}

	//static void DoubleArraySave(int aNumDim, const int *aDims, const double *aArray, const char *aName); 

	//Save a 2D double matrix to a binary file.
	static void DoubleMatrixSave(int am, int an, double **aMat, const char *aName); 

	//Save a 2D int matrix to a binary file
	static void IntMatrixSave(int am, int an, int **aMat, const char *aName);

	//Save a 3D int matrix to a binary file
	static void IntMatrixSave3(int am, int an, int ao, int ***aMat, const char *aName);
    
    // Reads an array of doubles from a binary file. The files start with an
    // int that specifies how many dimenstions the array has. Then have one
    // int for each dimension, that specify the dimensions of the array.
    // Finally they have the doubles of the array. The output is a vectorized
    // version of the stored matrix (or tensor) and does not depend on dimensions.
    //
    // Inputs:
    // aName - The full path of the binary file.
    // aLength - The number of doubles read.
    //
    // Outputs:
    // A poniter to a double array with the double values. The array has to
    // be deleted by the caller.
    static double *ReadDouble(string aName, int *aLength);
};

#endif