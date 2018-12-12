#ifndef MIGRATION
#define MIGRATION

#include <vector>
#include "Event.h"

class CellNode;
class Detection;
class Tree;

// Migration links 2 Detection states together and represents a cell
// migration between the states.
class Migration : public Event {
public:
	// Generates a migration event, containing all information about a possible migration in the image
	// sequence.
	//
	// Inputs:
	// aStartDetection - The detection where the migration starts.
	// aEndDetection - The detection where the migration ends.
	// aValue - The number of times that the migration events occurs at creation.
	// aNumScores - The number of scores defined. Adding more migrations does not change the score.
	// aScore - The scores of differnet migration counts. The first score is the score of 0 migrations.
	Migration(Detection *aStartDetection, Detection *aEndDetection,
		int aValue, int aNumScores, const double *aScore, double aMaxMigScore);

	// Redefines the score so that probabilities > 0.5 don't count.
	// Should probably be changed, at least for the tracking challenge.
	virtual double GetPlusScore() const;

	// Redefines the score so that probabilities > 0.5 don't count.
	// Should probably be changed, at least for the tracking challenge.
	virtual double GetMinusScore() const;

	// Adds another instance of the migration to aTree.
	virtual void Execute(Tree *aTree, vector<CellNode*> *aEndCellNodes, bool aPrint = true);

	// Adds another instance of the migration event to a cell lineage tree, by linking it to
	// an existing CellNode associated with aEndState.
	//
	// Inputs:
	// aTree - Lineage tree that will get an additional migration event.
	// aCell - CellNode associated with aEndState.
	virtual void Execute(Tree *aTree, vector<CellNode*> *aEndCellNodes, CellNode* aCell);

	// Returns the score associated with adding the migration event to a Tree.
	virtual double GetScore() const;

	// Increases the count but does not add any mitotic events to the CellTrellis.
	void Increment();

	// This function adds mitotic events that become possible through this migration event, to the
	// trellis. Mitotic events don't need to be removed in Minus, because they will get the score
	// minus infinity if they require a migration which has been removed.
	virtual void Plus();

private:
	double mMaxScore;
};
#endif