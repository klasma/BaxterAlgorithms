#ifndef APPEARANCE
#define APPEARANCE

#include <vector>
#include "Event.h"

class CellNode;
class Detection;
class IdleState;
class Tree;

// Event associated with a cell randomly appearing in a detection. This events is meant to deal with cells
// that are washed into the field of view or appear in random places by some other mechanism.
class Appearance : public Event {
public:
	// Generates a appearance event, containing all information about a possible appearance event in the image
	// sequence.
	//
	// Inputs:
	// aStartState - Idle-state that the cell is in before entering aEndDetection.
	// aEndDetection - The detection that the cell may appear in.
	// aValue - The number of appearance events that take place in the particular detection.
	// aNumScores - The number of scores defined. Adding more appearances to the detection does not change the score.
	// aScore - The scores of differnet appearance counts. The first score is the score of 0 appearances.
	Appearance(IdleState *aStartState, Detection *aEndDetection, int aValue, int aNumScores, const double *aScore);

	// Adds the appearance event to a cell lineage tree.
	//
	// Inputs:
	// aTree - Lineage tree that will get an additional cell appearance.
	virtual void Execute(Tree *aTree, vector<CellNode*> *aEndCellNodes, bool aPrint = true);

	// Adds the appearance event to a cell lineage tree, by linking the active cell to an existing CellNode
	// associated with aEndDetection.
	//
	// Inputs:
	// aTree - Lineage tree that will get an additional cell appearance.
	// aCell - CellNode associated with aEndDetection.
	virtual void Execute(Tree *aTree, vector<CellNode*> *aEndCellNodes, CellNode* aCell);

	// Score associated with adding the appearance event to a tree.
	virtual double GetScore() const;
};
#endif