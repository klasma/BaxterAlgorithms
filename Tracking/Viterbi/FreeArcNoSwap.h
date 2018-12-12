#ifndef FREEARCNOSWAP
#define FREEARCNOSWAP

#include <vector>
#include "FreeArc.h"

class CellNode;
class IdleState;
class Tree;

// FreeArc is a link between two IdleStates that always has a score of 0.0.
// The class can not be used to link Detections, and they must never be used
// in CellNodes.
class FreeArcNoSwap : public FreeArc {
public:
	// Creates a link from aStartState to aEndState.
	FreeArcNoSwap(IdleState *aStartState, IdleState *aEndState);

	// Adds the effects associated with traversing a FreeArc to aTree.
	// This only has an effect when a Swap event has terminated a cell
	// track after the first CellNode. In this case it removes that
	// first CellNode from aTree.
	virtual void Execute(Tree *aTree, vector<CellNode*> *aEndCellNodes, bool aPrint = true);

	// This is not allowed, because it would link one CellNode to another
	// using the FreeArc. This function makes an assertion fail!
	virtual void Execute(Tree *aTree, vector<CellNode*> *aEndCellNodes, CellNode* aCell);

	// FreeArcNoSwap can not be the first event in a swap.
	virtual bool OkSwap12(Event *aEvent) { return false; }

	// FreeArcNoSwap can not be the last event in a swap.
	virtual bool OkSwap32(Event *aEvent) { return false; }
};
#endif