#include "CellNode.h"
#include <assert.h>
#include "FreeArc.h"
#include "FreeArcNoSwap.h"
#include "IdleState.h"
#include "LogStream.h"
#include "State.h"
#include "Tree.h"

using namespace std;

// Forwards to the Event constructor.
FreeArcNoSwap::FreeArcNoSwap(IdleState *aStartState, IdleState *aEndState)
	: FreeArc(aStartState, aEndState) {
}

void FreeArcNoSwap::Execute(Tree *aTree, vector<CellNode*> *aEndCellNodes, bool aPrint) {
	assert(!aTree->HasActiveCell());
}

void FreeArcNoSwap::Execute(Tree *aTree, vector<CellNode*> *aEndCellNodes, CellNode *aCell) {
	assert(false);
}