#include "CellNode.h"
#include <assert.h>
#include <vector>
#include "Preexist.h"
#include "Detection.h"
#include "IdleState.h"
#include "LogStream.h"
#include "State.h"
#include "Tree.h"

// The Preexist event does not have its own Variable object, so a dummy
// Variable object is created. Executing the Preexist event does however
// change the cell count in a Detection.
Preexist::Preexist(IdleState *aBeginState, Detection *aEndDetection)
	: Event((State*) aBeginState, (State*) aEndDetection) {
}

void Preexist::Execute(Tree *aTree, vector<CellNode*> *aEndCellNodes, bool aPrint) {
	if (aPrint) {
        lout << "t = " << right << setw(4) << setfill(' ') << 0
                << setw(0) << "," << right  << setw(14) << setfill(' ') << "Add"
                << setw(0) << "       -->"
                << right << setw(6) << setfill(' ') << mEndState->GetIndex() + 1
                << setw(0) << " = "
                << setprecision(16) << fixed << setw(22) << setfill(' ') << GetScore() << endl;
	}

	aTree->CreateCellFirst((IdleState*) mStartState);
	CellNode *activeCell = aTree->GetActiveCell();
	aEndCellNodes->push_back(aTree->CreateCellLink(activeCell, this));
}

void Preexist::Execute(Tree *aTree, vector<CellNode*> *aEndCellNodes, CellNode *aCell) {
	assert(false);
}

double Preexist::GetScore() const {
	return mEndState->GetPlusScore();
}