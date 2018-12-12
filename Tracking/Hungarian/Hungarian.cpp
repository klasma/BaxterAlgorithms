/* An implementation of the Hungarian algorithm, that can be compiled as a
 * .mex file for Matlab or as a freestanding windows program (only for
 * degugging purposes).*/

#define MATLAB // Comment out to compile as free standing program that can be debugged without Matlab.

#include <iostream> // printf
#include <limits> // maximum double value

#ifdef MATLAB
#define printf mexPrintf // Makes ouputs print to Matlab command window.
#include "mex.h" // matlab types and functions
#include "matrix.h" // matlab matrices
#endif

using namespace std;

int Augment(int *aMateV, int *aMateU, int *aExposed, int* aLabel, int aV, int aN){
	/* Augment a matching along an augmneting path. The first node can
	* either be an unmatched v-node connected to an unmatched u-node or
	* a matched v-node, connected to an unmatched u-node, in the end of
	* the chain. The funciton is recursive and will call itself with the
	* preceding node in the chain until it finds an unmatched v-node.
	* Returns the cardinality of the matching.
	*
	* Inputs:
	* aMateV - Nodes matched to v-nodes.
	* aMateU - Nodes matched to u-nodes.
	* aExposed - Unmatched u-nodes connected to v-nodes by admissible arcs.
	* v-nodes with no such u-node has the value -1.
	* aLabel - The preceding v-nodes leading to the current v-nodes in the
	* augmenting path.
	* aV - Node to start the augmenting path at.
	* aN - Number of nodes to be matched.
	*
	* Outputs:
	* retMatches - Cardinality of the matching.
	*/

	int v; // Index for v-nodes.
	int retMatches; // Cardinality of matching.

	if(aLabel[aV] == -1){ // Pair aV with a u and nothing more.
		aMateV[aV] = aExposed[aV];
		aMateU[aExposed[aV]] = aV;
	}
	else{ // Recursively move back through a chain to find a v with label -1.
		aExposed[aLabel[aV]] = aMateV[aV];
		aMateV[aV] = aExposed[aV];
		aMateU[aExposed[aV]] = aV;
		Augment(aMateV, aMateU, aExposed, aLabel, aLabel[aV], aN);
	}

	// Compute the cardinality of the matching.
	retMatches = 0;
	for(v=0;v<aN;v++){
		if(aMateV[v] != -1)
			retMatches++;
	}
	return retMatches;
}

void Hungarian(int aN, double *aC, int *aMateV){
	/* Solves the assignment problem (also called weighted bipartite
	* matching) using the Hungarian algorithm, as described in "Combinatorial
	* optimization Algorithms and complexity" by Papadimitriou and Steiglitz.
	* 
	* Inputs:
	* aN - Number of pairs to be matched.
	* aC - Costs of the arcs in the bipartite graph. aC[v+u*n] contains the
	* cost of the arc from v to u.
	* aMateV - Array where the output will be saved. aMateV[v] will contain
	* the index of the u-node matched to v in the optimal matching, when
	* the funciton is done executing.*/

	// Definitions.
	const double tol = 1e-9; // Absolute error tolerance. 1E-12 has given some errors in FPTrack.m.

	bool br; // Used to skip the remainder of a loop after an augmentation.
	int nMatches; // # of matched node pairs. Used as stopping criterion.
	int v, v1, v2; // Indecies of v-nodes.
	int v2i; // Index into A;
	int u; // Index of u-nodes.
	int nQ; // # of nodes in the search set for v-nodes.
	double sl; // Temporary variable to hold slacks.
	int *nhbor; // Alphas for which the slacks are equal to slack
	int *label; // Previous v-nodes in the search for an augmentation path.
	int *Q; // Search set of v-nodes.
	int *nA;  // # of arcs from nodes in auxilary graph.
	int *A; // Auxilary graph.
	int *mateU; // v-nodes matched to u-nodes.
	int *exposed; // u-nodes that are connected to v-nodes by admissible edges.
	double *alpha;// Dual variable assocated with v.
	double *beta; // Dual variable assocated with u.
	double *slack; // Minimum slacks for betas (minimized over alphas).

	// Memory allocation.
	label = new int[aN];
	mateU = new int[aN];
	exposed = new int[aN];
	nhbor = new int[aN];
	Q = new int[aN];
	A = new int[aN*aN];
	nA = new int[aN];
	alpha = new double[aN];
	beta = new double[aN];
	slack = new double[aN];

	// initialize
	for(v=0;v<aN;v++){
		aMateV[v] = -1;
		alpha[v] = 0;
	}
	for(u=0;u<aN;u++){
		mateU[u] = -1;
		beta[u] = aC[0+u*aN];
		for(v=0;v<aN;v++){
			if(aC[v+u*aN] < beta[u]){
				beta[u] = aC[v+u*aN];
			}
		}
	}
    
//     // ADDED TO ENABLE PRINTOUTS
//     for(v=0;v<aN;v++){ // empty A.
//         nA[v] = 0;
//     }
//     nQ = 0; // Empty Q.
    
	nMatches = 0;
	while(nMatches < aN){ // Run until all pairs are matched.
        
        // Print out variables for each iteration for debugging.
        //printf("nMatches = %d\n", nMatches);
		//printf("\nalpha:");
		//for(v=0;v<aN;v++){
		//	printf(" %.2f", alpha[v]);
		//}
		//printf("\nbeta:");
		//for(u=0;u<aN;u++){
		//	printf(" %.2f", beta[u]);
		//}
		//printf("\nexposed:");
		//for(v=0;v<aN;v++){
		//	printf(" %d", exposed[v]+1);
		//}
		//printf("\nMatched edges:");
		//for(v=0;v<aN;v++){
		//	printf("\nv%d - u%d\n", v+1, aMateV[v]+1);
		//}
// 		printf("\nAuxilary graph edges:");
// 		for(v1=0;v1<aN;v1++){
// 			for(v2i=0;v2i<nA[v1];v2i++){
// 				v2 = A[v1+v2i*aN];
// 				printf("\nv%d - v%d\n", v1+1, v2+1);
// 			}
// 		}
// 		printf("\n:Unmatched edges");
// 		for(v1=0;v1<aN;v1++){
// 			for(v2i=0;v2i<nA[v1];v2i++){
// 				v2 = A[v1+v2i*aN];
// 				printf("\nv%d - v%d\n", v1+1, aMateV[v2]+1);
// 			}
// 		}
		//printf("\n");

		br = false;

		for(v=0;v<aN;v++){
			exposed[v] = -1;
			label[v] = -1;
		}
		for(u=0;u<aN;u++){
			slack[u] = numeric_limits<double>::max();
		}

		for(v=0;v<aN;v++){ // empty A.
			nA[v] = 0;
		}
		// Look for admissible edges.
		for(v=0;v<aN;v++){
			for(u=0;u<aN;u++){
				sl = aC[v+u*aN] - alpha[v] - beta[u];
				if(sl < tol) // REMOVED && sl > -tol
					if(mateU[u] == -1){
						exposed[v] = u;
 						// break; // It seems like a break can be added here but it does not decrease the execution time significantly.
					}
					else if(mateU[u] != v){
						A[v+nA[v]*aN] = mateU[u];
						nA[v]++;
					}
			}
		}

		// Find unmatched v-nodes. Match them if they are connected to unmatched u-nodes by admissible edges.
		nQ = 0; // Empty Q.
		for(v=0;v<aN;v++){
			if(aMateV[v] == -1){
				// If it has an admissible arc to an umnatched u-node we can augment.
				if(exposed[v] != -1 && mateU[exposed[v]] == -1){ // ADDED mateU[exposed[v]] == -1 AND REMOVED BREAK FOR SPEED.
					nMatches = Augment(aMateV, mateU, exposed, label, v, aN);
					br = true;
// 					break; // REMOVED FROM ORIGINAL ALRORITHM.
				}
				// If we can not augment we mark the node to try and match it later.
				else{
					// Add v-node to search set.
					Q[nQ] = v;
					nQ++;
					label[v] = -1;
				}
			}
		}
		if(br)
			continue;

		// Search for augmenting paths to increase the cardinality of
        // the matching. If no path is found, the dual variables are
        // modified so that more edges become admissible, until an
        // augmenting path can be found. The algorithm works by labeling all
        // v-nodes that can be reached from unmatched v-nodes and looking
        // for ways to connect them to more u-nodes.
		while(true){
            
            	// Check the number of input and output arguments.
            if(nQ == 0){
				#ifdef MATLAB
				mexErrMsgTxt("Hungarian algorithm unable to find matching.");
				#else
				printf("Hungarian algorithm unable to find matching.\n");
				#endif
			}
            
			while(nQ > 0){
				v1 = Q[nQ-1]; // The algorithm might become faster if the search is done breadth first instead.
				nQ--; // Remove v1 from Q.
                
                // We have found the end of a chain that we can augment. MOVED FROM ORIGINAL LOCATION.
                if(exposed[v1] != -1){
                    nMatches = Augment(aMateV, mateU, exposed, label, v1, aN);
                    br = true;
                    break;
                }
                
                // Compute slacks and alpha-beta pairs that achieve them.
                for(u=0;u<aN;u++){
                    if(aC[v1+u*aN] - alpha[v1] - beta[u] < slack[u] && tol < slack[u]){
                        slack[u] = aC[v1+u*aN] - alpha[v1] - beta[u];
                        nhbor[u] = v1;
                    }
                }
                
				// Search for all unlabeled v2 with [v1,v2] in A, label them and put them in Q.
				for(v2i=0;v2i<nA[v1];v2i++){
					v2 = A[v1+v2i*aN];
					if(label[v2] == -1){
						label[v2] = v1;
						Q[nQ] = v2;
						nQ++;
					}
				}
            }
            if(br)
                break;

			//////////////////////////////// modify ///////////////////////////////////
			///////////////////////////////////////////////////////////////////////////
			/* Calculates theta1, updates the alphas and betas and activetes
			* new nodes to continue the search.*/

			// Find theta1.
			double theta1 = numeric_limits<double>::max();
			for(u=0;u<aN;u++){
				if(tol < slack[u] && slack[u]/2 < theta1){
					theta1 = slack[u]/2;
				}
			}

			// Update alpha.
			for(v=0;v<aN;v++){
				if(label[v]!=-1 || aMateV[v] == -1){ // mateV[v] == -1 is different from the described algorithm, but this has to be encorporated either here or in the labels.
					alpha[v] += theta1;
				}
				else{
					alpha[v] -= theta1;
				}
			}

			// Update beta.
			for(u=0;u<aN;u++){
				if(slack[u] < tol){
					beta[u] -= theta1;
				}
				else{
					beta[u] += theta1;
				}
			}
            
            // Update slacks and find new admissible edges.
			for(u=0;u<aN;u++){
				if(tol < slack[u]){
					slack[u] -= 2*theta1;
					if(slack[u] < tol){ // New admissible edge. % REMOVED slack[u] > -tol
						if(mateU[u] == -1){
							exposed[nhbor[u]] = u;
							nMatches = Augment(aMateV, mateU, exposed, label, nhbor[u], aN);
							br = true;
                            break;
						}
						else{
							v = nhbor[u];
							label[mateU[u]] = v;
							Q[nQ] = mateU[u];
							nQ++;
							A[v+nA[v]*aN] = mateU[u];
							nA[v]++;
						}
					}
				}
			}
            if(br)
                break;
		}
	}

	// Turn memory back.
	delete[] label;
	delete[] mateU;
	delete[] exposed;
	delete[] nhbor;
	delete[] Q;
	delete[] A;
	delete[] nA;
	delete[] alpha;
	delete[] beta;
	delete[] slack;
}

#ifndef MATLAB
int main(){
	/* MAIN is used to test the implementation of the Hungarian algorithm
	* on the problem given in Example 11.1 in "Combinatorial optimization
	* Algorithms and complexity" by Papadimitriou and Steiglitz. The
	* will be the main function in a normal C++ compilation and will
	* run without a call from Matlab.*/

	const int n = 5; // Number of pairs to match.
	double cost = 0; // Total cost of matching.
	int v; // Nodes in bipartite graph.
	int mateV[n]; // Nodes matched to v-nodes in optimal matching.

	double c[n*n] = {
		7, 9, 3, 7, 8,
		2, 6, 8, 9, 4,
		1, 9, 3, 4, 7,
		9, 5, 1, 2, 4,
		4, 5, 8, 2, 8}; // Edge costs.

		Hungarian(n, c, mateV); // Find chapest matching.

		// Print cheapest matching.
		printf("Matched edges:\n");
		for(v=0;v<n;v++){
			printf("%v%d - u%d : %.2f\n", v+1, mateV[v]+1, c[v+mateV[v]*n]);
			cost += c[v+mateV[v]*n];
		}
		printf("Total cost = %.2f\n", cost);
		cin.get();
}
#endif

#ifdef MATLAB
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]){
	/* MEXFUNCITON interfaces with matlab.
	*
	* Inputs:
	* int nlhs - Number of outputs.
	* mxarray *plhs[0] - u-nodes matched to the list of v-nodes.
	* int nrhs - Number of inputs.
	* mxarray *prhs[0] - Matrix with edge costs.
	*/

	int n; // Number of node pairs to be matched.
	int v; // v-node index.
	int *mateV; // u-nodes matched to the v-nodes.
	double *dMateV; // u-nodes matched to the v-nodes. (Double array for output to Matlab.)¨
	double *c; // Arc costs.

	// Check the number of input and output arguments.
	if(nrhs != 1){
		mexErrMsgTxt("Hungarian must be called with 1 input argument.");}
	if(nlhs != 1){
		mexErrMsgTxt("Hungarian must be called with 1 output argument.");}

	// Input
	c = mxGetPr(prhs[0]);
	n = (int) mxGetM(prhs[0]);

	// Output
	plhs[0] = mxCreateDoubleMatrix(n, 1, mxREAL);
	dMateV = mxGetPr(plhs[0]);

	// Memory allocation.
	mateV = new int[n];

	Hungarian(n, c, mateV);

	// Transfer results to matlab output.
	for(v=0;v<n;v++)
		dMateV[v] = (double) mateV[v] + 1;

	// Turn memory back.
	delete[] mateV;
}
#endif