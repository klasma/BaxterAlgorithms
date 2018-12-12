#ifndef FREEARC
#define FREEARC

#include <vector>
#include "Event.h"

class CellNode;
class IdleState;
class Tree;

// FreeArc is a link between two IdleStates that always has a score of 0.0.
// The class can not be used to link Detections, and they must never be used
// in CellNodes.
class FreeArc : public Event {
public:
	// Creates a link from aStartState to aEndState.
	FreeArc(IdleState *aStartState, IdleState *aEndState);

	// Checks that it is allowed to link from aStateFrom to aStateTo using the Event,
	// when CellNodes are created. The function returns false, because CellNodes
	// must not be linked using FreeArcs.
	virtual bool Check(
		const State *aStateFrom, 
		const State *aStateTo) const { return false; }

	// Adds the effects associated with traversing a FreeArc to aTree.
	// This only has an effect when a Swap event has terminated a cell
	// track after the first CellNode. In this case it removes that
	// first CellNode from aTree.
	virtual void Execute(Tree *aTree, vector<CellNode*> *aEndCellNodes, bool aPrint = true);

	// This is not allowed, because it would link one CellNode to another
	// using the FreeArc. This function makes an assertion fail!
	virtual void Execute(Tree *aTree, vector<CellNode*> *aEndCellNodes, CellNode* aCell);

	// The score associated with traversing the FreeArc is 0.0.
	virtual double GetScore() const { return 0.0; }
};
#endif