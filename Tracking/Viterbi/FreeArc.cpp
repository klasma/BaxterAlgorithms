#include "CellNode.h"
#include <cstddef>  // To get NULL.
#include <assert.h>
#include "FreeArc.h"
#include "IdleState.h"
#include "LogStream.h"
#include "State.h"
#include "Tree.h"

using namespace std;

// Forwards to the Event constructor.
FreeArc::FreeArc(IdleState *aStartState, IdleState *aEndState)
	: Event((State*) aStartState, (State*) aEndState) {
}

void FreeArc::Execute(Tree *aTree, vector<CellNode*> *aEndCellNodes, bool aPrint) {
	// Clean up after swaps that end in a FreeArc.
	if (aTree->HasActiveCell()) {
		aTree->RemoveFirstCell(aTree->GetActiveCell());
		aTree->SetActiveCell(NULL);
	}
}

void FreeArc::Execute(Tree *aTree, vector<CellNode*> *aEndCellNodes, CellNode *aCell) {
	//assert(false);
	assert(!aCell->HasNextCell() && !aCell->HasPrevCell() && !aCell->HasChildren() && !aCell->HasParent());
	
	aEndCellNodes->push_back(aCell);

	// The cell can not be deleted yet, because there are still Swaps arcs associated with it.
	//delete aCell;
}