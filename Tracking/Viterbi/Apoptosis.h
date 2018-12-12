#ifndef APOPTOSIS
#define APOPTOSIS

#include <vector>
#include "Event.h"

class CellNode;
class Detection;
class IdleState;
class Tree;

// Event that represents cell apoptosis in a detection.
class Apoptosis : public Event {

	public:
		// Generates an apoptosis event, containing all information about a possible apoptosis in the image
		// sequence.
		//
		// Inputs:
		// aStartDetection - The detection that may contain an apoptosis.
		// aEndState - The dead state that the cell goes to after aStartDetection.
		// aValue - The number of apoptois events that take place at the creation.
		// aNumScores - The number of scores defined. Adding more apoptosis does not change the score.
		// aScore - The scores of differnet apoptosis counts. The first score is the score of 0 deaths.
		Apoptosis(Detection *aStartDetection, IdleState *aEndState, int aValue, int aNumScores, const double *aScores);

		// Adds another instance of the apoptosis event to a cell lineage tree aTree.
		virtual void Execute(Tree *aTree, vector<CellNode*> *aEndCellNodes, bool aPrint = true);

		// Adds another instance of the apoptosis event to a cell lineage tree, by linking it to
		// an existing CellNode associated with aEndState.
		//
		// Inputs:
		// aTree - Lineage tree that will get an additional apoptosis event.
		// aCell - CellNode associated with aEndState.
		virtual void Execute(Tree *aTree, vector<CellNode*> *aEndCellNodes, CellNode* aCell);

		// Returns the score associated with adding the apoptosis event to a tree.
		virtual double GetScore() const;
};
#endif