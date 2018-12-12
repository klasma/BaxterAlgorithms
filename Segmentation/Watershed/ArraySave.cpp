#include "ArraySave.h"
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