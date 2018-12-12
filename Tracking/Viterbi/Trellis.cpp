#include <cstddef>  // To get NULL.
#include <limits>
#include <list>
#include <vector>
#include "Trellis.h"
#include "Arc.h"
#include "Node.h"

using namespace std;

// Default constructor used to make it possible to inherit from the class.
Trellis::Trellis(int aNumT) : mNumT(aNumT) {
	for (int t=0; t<mNumT; t++) {
		mNodes.push_back(new vector<Node*>());
	}
}

Trellis::~Trellis() {
	for (int t=0; t<(int)mNodes.size(); t++) {
		for (int i=0; i<(int)mNodes[t]->size() ;i++) {
			delete mNodes[t]->at(i);
		}
		delete mNodes[t];
	}
}

void Trellis::AddNode(int aT, Node *aNode) {
	mNodes[aT]->push_back(aNode);
}

Node *Trellis::GetNode(int aT, int aN) {
	return mNodes[aT]->at(aN);
}

// Finds the highest scoring path from the beginning of the trellis to the end using the Viterbi algorithm. For the
// function to work it is required that arcs that leave nodes in layer t only go to nodes in layer t+1 or layers with
// higher indices. In the future this fuction could be replanced by a more general shortest-path algorithm.
void Trellis::HighestScoringPath(list<Arc*> &aArcs, double &aScore) {

	vector<vector<Arc*>*> bestArcs;		// The best arcs leading to the nodes.
	vector<vector<double>*> bestScores;	// The highest possible score of going from the beginning of the trellis to a node.
	vector<vector<int>*> prevIndex;		// Index of the previous node on the best path.

	for (int t=0; t<mNumT; t++) {
		bestArcs.push_back(new vector<Arc*>(mNodes[t]->size(), NULL));
		// Set all the best scores to minus infinity to handle states with in-degree 0.
		bestScores.push_back(new vector<double>(mNodes[t]->size(), -numeric_limits<double>::max()));
		prevIndex.push_back(new vector<int>(mNodes[t]->size(), -1));  // -1 indicates that the node can not be reached.
	}

	// Set the initial scores to 0.
    for (int n=0; n< (int) mNodes[0]->size(); n++) {
        bestScores[0]->at(n) = 0;
    }
    
	// Go through the layers one by one to find the highest scoring path from the beginning of the Trellis to the end.
    for (int t=1; t<mNumT; t++) {
        for (int n=0; n<(int)mNodes[t]->size(); n++) {
            Node *node = mNodes[t]->at(n);
			for (int i=0; i<node->GetNumBackwardArcs(); i++) {
				Arc *bArc = node->GetBackwardArc(i);
                int pIndex = bArc->GetStartNode()->GetIndex();
                double score = bestScores[t-1]->at(pIndex) + bArc->GetScore();
                if (i==0 || score > bestScores[t]->at(n)){
                    bestArcs[t]->at(n) = bArc;
                    bestScores[t]->at(n) = score;
                    prevIndex[t]->at(n) = pIndex;
                }
            }
        }
    }
    
    // Backtrack to find the optimal path.

	// Find the highest scoring end state.
	int endIndex = 0;
	for (int n=0; n<(int)mNodes[mNumT-1]->size(); n++){
		if (bestScores[mNumT-1]->at(n) > bestScores[mNumT-1]->at(endIndex)) {
			endIndex = n;
		}
	}

	int maxIndex = endIndex;
    for (int t=mNumT-1; t>0; t--) {
		aArcs.push_front(bestArcs[t]->at(maxIndex));
        maxIndex = prevIndex[t]->at(maxIndex);
    }

	// Set output score.
    aScore = bestScores[mNumT-1]->at(endIndex);

	// Delete temporary vectors.
	for (int t=0; t<mNumT; t++) {
		delete bestArcs[t];
		delete bestScores[t];
		delete prevIndex[t];
	}
}
