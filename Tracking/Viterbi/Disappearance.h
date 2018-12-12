#ifndef DISAPPEARANCE
#define DISAPPEARANCE

#include <vector>
#include "Event.h"

class CellNode;
class Detection;
class IdleState;
class Tree;

// Event associated with cells that disappear by leavnig the field of view. The
// Event is meant to deal with cells that are washed out in media changes, cells that crawl
// out of the field of view, or cells that disappear randomly by other mechanisms.
class Disappearance : public Event {
public:
	// Creates a disappearance object where a cell disappears from detection aStartDetection.
	//
	// Inputs:
	// aStartDetection - The detection that the cell may disappear from.
	// aEndState - IdleState that the cell goes to after disappearing.
	// aValue - The number of disappearance events that take place in the particular detection.
	// aNumScores - The number of scores defined. Adding more disappearances to the detection does not change the score.
	// aScore - The scores of differnet appearance counts. The first score is the score of 0 appearances.
	Disappearance(Detection *aStartDetection, IdleState *aEndState, int aValue, int aNumScores, const double *aScore);

	// Adds another instance of the disappearance to the Tree aTree.
	virtual void Execute(Tree *aTree, vector<CellNode*> *aEndCellNodes, bool aPrint = true);

	// Adds another instance of the disappearance event to a cell lineage tree, by linking it to
	// an existing CellNode associated with aEndState.
	//
	// Inputs:
	// aTree - Lineage tree that will get an additional disappearance event.
	// aCell - CellNode associated with aEndState.
	virtual void Execute(Tree *aTree, vector<CellNode*> *aEndCellNodes, CellNode* aCell);

	// Returns the score associated with adding the disappearance event to a tree.
	virtual double GetScore() const;
};
#endif