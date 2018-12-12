#ifndef PERSIST
#define PERSIST

#include <vector>
#include "Event.h"

class CellNode;
class Detection;
class IdleState;
class Tree;

using namespace std;

// Event for cells that survives to the end of the imgage sequence.
// The event is used to link the Detection in the last image to an end-IdleState.
// The score of the event is 0.
class Persist: public Event {
public:
	// Creates a persist event (arc) between aStartState and aEndState.
	Persist(Detection *aStartState, IdleState *aEndDetection);

	// Adds the persist event to aTree. Does not print anything.
	virtual void Execute(Tree *aTree, vector<CellNode*> *aEndCellNodes, bool aPrint = true);

	// This is not allowed, because it would link to a CellNode with a Detection and
	// not an IdleState. This function makes an assertion fail!
	virtual void Execute(Tree *aTree, vector<CellNode*> *aEndCellNodes, CellNode* aCell);

	// The score associated with the Persist event is always 0.
	virtual double GetScore() const { return 0.0; }
};
#endif