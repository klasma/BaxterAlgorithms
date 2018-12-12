#ifndef PREEXIST
#define PREEXIST

#include <vector>
#include "Event.h"

class CellNode;
class Detection;
class IdleState;
class Tree;

// Event associated with cells that are present in the first image.
class Preexist: Event {
public:
	// Creates a preexist event (arc) between a start-IdleState and a Detection.
	Preexist(IdleState *aStartState, Detection *aEndDetection);

	// Adds a cell in the first image in aTree.
	virtual void Execute(Tree *aTree, vector<CellNode*> *aEndCellNodes, bool aPrint = true);

	// Not allowed, because there is no reason to swap events before the first image.
	// Makes an assertion fail!
	virtual void Execute(Tree *aTree, vector<CellNode*> *aEndCellNodes, CellNode* aCell);

	// Returns the score associated with having the cell in the first image.
	virtual double GetScore() const;
};
#endif