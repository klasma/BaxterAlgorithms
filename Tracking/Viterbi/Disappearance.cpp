#include "Disappearance.h"
#include <cstddef>  // To get NULL.
#include <vector>
#include "CellNode.h"
#include "Detection.h"
#include "IdleState.h"
#include "LogStream.h"
#include "Tree.h"

Disappearance::Disappearance(Detection *aStartDetection, IdleState *aEndState, 
	int aValue, int aNumScores, const double *aScore)
	: Event((State*) aStartDetection, (State*) aEndState, aValue, aNumScores, aScore) {
}

void Disappearance::Execute(Tree *aTree, vector<CellNode*> *aEndCellNodes, bool aPrint) {
	if (aPrint) {
        lout << "t = " << right << setw(4) << setfill(' ') << mStartState->GetT()
                << setw(0) << "," << right << setw(14) << setfill(' ') << "Disappearance"
                << right << setw(6) << setfill(' ') << mStartState->GetIndex() + 1
                << setw(0) << " -->       = "
                << setprecision(16) << fixed << setw(22) << setfill(' ') << GetScore() << endl;
	}

	CellNode *activeCell = aTree->GetActiveCell();
	aEndCellNodes->push_back(aTree->CreateCellLink(activeCell, this));
	aTree->SetActiveCell(NULL);
}

void Disappearance::Execute(Tree *aTree, vector<CellNode*> *aEndCellNodes, CellNode *aCell) {
	CellNode *activeCell = aTree->GetActiveCell();
	activeCell->AddLink(this, aCell);
	aTree->SetActiveCell(NULL);

	aEndCellNodes->push_back(aCell);
}

double Disappearance::GetScore() const {
	return GetPlusScore();
}