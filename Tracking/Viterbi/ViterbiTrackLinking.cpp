// Create the precompiler definition MATLAB in to compile mex file. Otherwise a standalone executable for for debugging will be generated.

#include "ArraySave.h"
#include "CellTrellis.h"
#include "LogStream.h"
#include "Tree.h"

#include <string>
#include <sstream>

// Matlab types and functions.
#include "mex.h"
#include "matrix.h"

using namespace std;

/* Function that interfaces with Matlab. "/" is used instead of "\" in path
* names as "\" does not work on mac and linux. Windows does not care.
*
* Inputs:
* int nrhs			- Number of inputs.
* mxArray *prhs[0]	- Array with detection counts per frame.
* mxArray *prhs[1]	- Count events.
* mxArray *prhs[2]	- Migration events.
* mxArray *prhs[3]	- Mitosis events.
* mxArray *prhs[4]	- Apoptosis events.
* mxArray *prhs[5]	- Appearance events.
* mxArray *prhs[6]	- Disappearnace events.
* mxArray *prhs[7]	- If this is != 0, there will be a single idle state in the
*                     trellis instead of one for appearing and one for disappearing
*                     cells. 
* mxArray *prhs[8]	- Maximum score increase for a migration.
* mxArray *prhs[9]	- Path where intermediate results can be saved as binary
*                     files. It it left empty, no intermediate files are saved.   
* mxArray *prhs[10]	- Folder to save intermediate results to.
*
* Outputs:
* int nlhs			- Number of outputs
* mxArray *plhs[0]	- Detection numbers for all cells
* mxArray *plhs[1]	- Mitosis relationships between cells.
*/
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {

	// Check the number of input and output arguments
	if (nrhs != 11) {
		mexErrMsgTxt("Must have 11 input arguments");
	}
	if (nlhs != 3) {
		mexErrMsgTxt("Must have 2 output arguments");
	}
    
    lout << "Running ViterbiTrackLinking from Matlab." << endl << endl; 

	// Get inputs
	double *numDetsA = mxGetPr(prhs[0]);
	double *countA = mxGetPr(prhs[1]);
	double *migA = mxGetPr(prhs[2]);
	double *mitA = mxGetPr(prhs[3]);
	double *apoA = mxGetPr(prhs[4]);
	double *appearA = mxGetPr(prhs[5]);
	double *disappearA = mxGetPr(prhs[6]);
	bool singleIdleState = (*mxGetPr(prhs[7]) != 0);
	double maxMigScore = *mxGetPr(prhs[8]);
	char iterationPath[1000];
	mxGetString(prhs[9], iterationPath, 1000);
    bool saveIterationFiles = mxGetNumberOfElements(prhs[9]) > 0;
	char logFilePath[1000];
	mxGetString(prhs[10], logFilePath, 1000);
    bool saveLogFile = mxGetNumberOfElements(prhs[10]) > 0;


	// Get the dimensions of the inputs.
	const mwSize *countSize = mxGetDimensions(prhs[1]);
	const mwSize *migSize = mxGetDimensions(prhs[2]);
	const mwSize *mitSize = mxGetDimensions(prhs[3]);
	const mwSize *apoSize = mxGetDimensions(prhs[4]);
	const mwSize *appearSize = mxGetDimensions(prhs[5]);
	const mwSize *disappearSize = mxGetDimensions(prhs[6]);
	int tMax = (int) mxGetNumberOfElements(prhs[0]);  // Allow numDetsA to be either row or column vector.
	int maxCount = countSize[1]-3; // first element is t, second is detection index and the third is the debris probability
	int numMigs = migSize[0];
	int numMits = mitSize[0];
	int numApos = apoSize[0];
	int numAppear = appearSize[0];
	int numDisappear = disappearSize[0];

    if (saveLogFile) {
        lout.OpenFile(logFilePath);
    }

	// Create a trellis graph that will be used to solve the tracknig problem.
	CellTrellis cellTrellis(singleIdleState, tMax, maxCount, numMigs, numMits, numApos, numAppear, numDisappear,
		numDetsA, countA, migA, mitA, apoA, appearA, disappearA, maxMigScore);
    
	// Add cells iteratively until as long as the score increases.
	int iter = 1;
	int addedCells = 0;
	Tree *tree = cellTrellis.GetTree();

	while (true) {
		tree->SetIteration(iter);
		lout << "Iteration " << iter << endl;
		addedCells = cellTrellis.AddCell();
        
        // No modifications were made in the last iteration.
        if (addedCells == 0) {
            break;
        }

        if (saveIterationFiles) {
            // Save tracking matrices after each iterations, so that the algorithm steps
            // can be looked at later.
            double *cellArray = new double[tMax*tree->GetNumCells()];
            double *divArray = new double[tree->GetNumCells()*2];
            double *deathArray = new double[tree->GetNumCells()];
            tree->GetCells(cellArray, divArray, deathArray);
            
            // Detection indices.
            int cellArrayDims[2];
            cellArrayDims[0] = tMax;
            cellArrayDims[1] = tree->GetNumCells();
            stringstream cellArrayPath;
            cellArrayPath << iterationPath << "/cellArray" << setw(5) << setfill('0') << iter << ".bin";
            
            // Cell divisions.
            int divArrayDims[2];
            divArrayDims[0] = tree->GetNumCells();
            divArrayDims[1] = 2;
            stringstream divArrayPath;
            divArrayPath << iterationPath << "/divArray" << setw(5) << setfill('0') << iter << ".bin";
            
            // Cell deaths.
            int deathArrayDims[2];
            deathArrayDims[0] = tree->GetNumCells();
            deathArrayDims[1] = 1;
            stringstream deathArrayPath;
            deathArrayPath << iterationPath << "/deathArray" << setw(5) << setfill('0') << iter << ".bin";
            
            // Iterations when the cells were created.
            double *iterArray = new double[tMax*tree->GetNumCells()];
            tree->GetIterations(iterArray);
            int iterArrayDims[2];
            iterArrayDims[0] = tMax;
            iterArrayDims[1] = tree->GetNumCells();
            stringstream iterArrayPath;
            iterArrayPath << iterationPath << "/iterationArray" << setw(5) << setfill('0') << iter << ".bin";
            
            ArraySave::Save<double>(2, cellArrayDims, cellArray, cellArrayPath.str().c_str());
            ArraySave::Save<double>(2, divArrayDims, divArray, divArrayPath.str().c_str());
            ArraySave::Save<double>(2, deathArrayDims, deathArray, deathArrayPath.str().c_str());
            ArraySave::Save<double>(2, iterArrayDims, iterArray, iterArrayPath.str().c_str());
            
            delete[] cellArray;
            delete[] divArray;
            delete[] deathArray;
            delete[] iterArray;
        }

		iter++;
	}

	tree->Print();
    lout << endl;  // Empty line after all outputs.

	// Output.
	plhs[0] = mxCreateDoubleMatrix(tMax, tree->GetNumCells(), mxREAL);
	plhs[1] = mxCreateDoubleMatrix(tree->GetNumCells(), 2, mxREAL);
    plhs[2] = mxCreateDoubleMatrix(tree->GetNumCells(), 1, mxREAL);
	double *cellA = mxGetPr(plhs[0]);
	double *divA = mxGetPr(plhs[1]);
    double *deathA = mxGetPr(plhs[2]);
	tree->GetCells(cellA, divA, deathA);

    if (saveLogFile) {
        lout.CloseFile();
    }

	return;
}