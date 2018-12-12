#include "Persist.h"
#include <assert.h>
#include <cstddef>  // To get NULL.
#include <vector>
#include "Detection.h"
#include "IdleState.h"
#include "State.h"
#include "Tree.h"

// Creates an event with a dummy Variable object with a constant score of 0.
Persist::Persist(Detection *aBeginState, IdleState *aEndDetection)
	: Event((State*) aBeginState, (State*) aEndDetection) {
}

void Persist::Execute(Tree* aTree, vector<CellNode*> *aEndCellNodes, bool aPrint) {
	CellNode *activeCell = aTree->GetActiveCell();
	aTree->CreateCellLink(activeCell, this);
	aTree->SetActiveCell(NULL);
}

void Persist::Execute(Tree *aTree, vector<CellNode*> *aEndCellNodes, CellNode* aCell) {
	assert(false);
}