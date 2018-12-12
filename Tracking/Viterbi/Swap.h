#ifndef SWAP
#define SWAP

#include <vector>
#include "Event.h"

class CellNode;
class Tree;

// Event (operation) that connects the active cell track of a Tree to the second half of a preexisting cell track.
// A new detection is then added to the end of the cut preexisting cell track. This extended track
// will then become the new active cell track of the Tree. The cell tracks can be broken between two Detections,
// representing to change a migration or between a Detection and an IdleState, to change other events.
class Swap : public Event {
 public:
	 // Creates a swap event that can be preformed using the Execute method.
	 //
	 // Inputs:
	 // aCell - The second CellNode in the cell track link that will be broken.
	 // aEvent1 - The event that will be used to link the active cell of a Tree to aCell.
	 // aEvent2 - The event that will be used to extend the first part of the broken cell track.
	 Swap(CellNode *aCell, Event *aEvent1, Event *aEvent2);

	 ~Swap();

	 // Performs the swap operation, and prints out information assoicated with the Operation.
	 virtual void Execute(Tree *aTree, vector<CellNode*> *aEndCellNodes, bool aPrint = true);

	 // This function is not allowed, because it is only called by Swap events for other Events.
	 // Swap events are not allowed to swap other swaps. Makes an assertion fail.
	 virtual void Execute(Tree *aTree, vector<CellNode*> *aEndCellNodes, CellNode *aCell);

	 // The score associated with the swap event.
	 virtual double GetScore() const;

	 // Swaps may not operate on other swaps.
	 virtual bool OkSwap12(Event *aEvent) { return false; }

	 // Swaps may not operate on other swaps.
	 virtual bool OkSwap32(Event *aEvent) { return false; }

	 void SetDeleted(int aDel) { mDeleted = aDel; }

	 int GetDeleted() { return mDeleted; }

private:
	Event *mEvent1;  //The event that will be used to link the active cell of a Tree to mCell.
	Event *mEvent2;  //The event that will be used to extend the first part of the broken cell track.
	CellNode *mCell;  // Second CellNode in preexisting cell track link.
	int mDeleted;
};

#endif
