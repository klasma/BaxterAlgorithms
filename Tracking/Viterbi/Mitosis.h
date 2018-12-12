#ifndef MITOSIS
#define MITOSIS

#include <vector>
#include "Event.h"

class CellNode;
class Detection;
class IdleState;
class Tree;

// A Mitosis object is an Event where one cell divides (undergoes mitosis) so that
// two new cells are created. The Mitosis is the mPrevEvent of the child nodes, but not the
// mNextEvent of the parent node. The CellNodes themselves are linked using the mParent
// and mChildren fields and not by the mNextCell and the mPrevCell fields. The parent has
// mNextCell == NULL and the children are linked to CellNodes with IdleStates using the mPrevCell
// fields. For every mitosis event there are two Mitosis objects, one for each daughter cell
// detection. They link an idle-state in the trellis to their respective daughter detection. The link
// goes to the detection which is not yet occupied by a cell. The two Mitosis objects are called
// mirrors and have to be updated separately when changes are made to the cell tree or the trellis.
// A mirror pair is created even in cases where the daughter cells are in the same detection.
class Mitosis : public Event {
public:
	Mitosis(IdleState *aStartState, Detection *aEndState, Detection *aStartDetection, Detection *aOtherChild,
		int aValue, int aNumScores, const double *aScore);

	// Returns true if a proposed linknig of 3 detections can be done using the
	// mitosis.
	bool Check(
		const State* aStateFrom,
		const State* aStateTo1,
		const State* aStateTo2) const;

	void AddToTrellis();

	// Adds the mitosis event to aTree by replacing a migration event by mitosis
	// and creating a new CellNode.
	virtual void Execute(Tree *aTree, vector<CellNode*> *aEndCellNodes, bool aPrint = true);

	// Adds the mitois event to aTree by replacing a migration event by mitosis
	// and linking to the preexisting CellNode aCell.
	virtual void Execute(Tree *aTree, vector<CellNode*> *aEndCellNodes, CellNode *aCell);

	// Defines the score of removing the Mitosis so that the replacing migration
	// is taken into account.
	virtual double GetMinusScore() const;

	Mitosis *GetMirror() { return mMirror; }

	Detection *GetOtherChild() { return mOtherChild; }

	// Returns the score associated with adding the mitosis event to a Tree.
	virtual double GetScore() const;

	// Returns true if the mitosis is currently an arc in the CellTrellis.
	bool IsInTrellis() { return mIsInTrellis; }

	// Sets the mirror object and also sets the mirror object of the mirror object.
	void LinkMirror(Mitosis *aMirror);

	// Avoids swaps where the mitosis replaces a migration which is required for the mitosis.
	virtual bool OkSwap12(Event *aEvent);

	virtual bool OkSwap32(Event *aEvent);

	// Removes the mitosis so that it is no longer an arc in the CellTrellis.
	void RemoveFromTrellis();

private:
	// Stores the parent cells Detection. mStartState is an IdleState.
	Detection *mStartDetection;
	
	// The daughter-cell detection which is already occupied by a cell. The Migration into this
	// Detection will be removed and replaced by this Mitosis when it is put into the cell tree.
	Detection *mOtherChild;

	// Returns a CellNode which is linked with a migration that can be replaced by the current Mitosis
	// if such a CellNode exist, and NULL otherwise.
	CellNode *GetAcceptingCell() const;

	// True if the Mitosis is an arc in the CellTrellis.
	bool mIsInTrellis;

	// A Mitosis object which represents the same event but links differnet trellis nodes.
	// It must be updated separately to match this object.
	Mitosis *mMirror;
};
#endif