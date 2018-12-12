#include "Appearance.h"
#include <assert.h>
#include <vector>
#include "CellNode.h"
#include "Detection.h"
#include "IdleState.h"
#include "LogStream.h"
#include "State.h"
#include "Tree.h"

Appearance::Appearance(IdleState *aStartState, Detection *aEndDetection, int aValue, int aNumScores, const double *aScore)
	: Event((State*) aStartState, (State*) aEndDetection, aValue, aNumScores, aScore) {
}

void Appearance::Execute(Tree *aTree, vector<CellNode*> *aEndCellNodes, bool aPrint) {
	if (aPrint) {
        lout << "t = " << right << setw(4) << setfill(' ') << mStartState->GetT()
                << setw(0) << "," << right << setw(14) << setfill(' ') << "Appearance"
                << setw(0) << "       -->"
                << right << setw(6) << setfill(' ') << mEndState->GetIndex() + 1
                << setw(0) << " = "
                << setprecision(16) << fixed << setw(22) << setfill(' ') << GetScore() << endl;
	}
	if (!aTree->HasActiveCell()) {
		aTree->CreateCellFirst((IdleState*) mStartState);
	}
	CellNode *activeCell = aTree->GetActiveCell();
	assert(mStartState = activeCell->GetState());
	aEndCellNodes->push_back(aTree->CreateCellLink(activeCell, this));
}

void Appearance::Execute(Tree *aTree, vector<CellNode*> *aEndCellNodes, CellNode *aCell) {

	if (!aTree->HasActiveCell()) {
		aTree->CreateCellFirst((IdleState*) mStartState);
	}
	CellNode *activeCell = aTree->GetActiveCell();
	assert(mStartState = activeCell->GetState());
	activeCell->AddLink(this, aCell);

	aEndCellNodes->push_back(aCell);
}

double Appearance::GetScore() const {
	return mEndState->GetPlusScore() + GetPlusScore();
}