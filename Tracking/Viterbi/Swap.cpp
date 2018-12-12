#include "Swap.h"
#include <assert.h>
#include <vector>
#include "CellNode.h"
#include "Count.h"
#include "LogStream.h"
#include "State.h"
#include "Tree.h"

Swap::Swap(CellNode *aCell, Event *aEvent1, Event *aEvent2)
	: Event(aEvent1->GetStartState(), aEvent2->GetEndState()), mDeleted(0) {

		// Set pointers.
		mEvent1 = aEvent1;
		mEvent2 = aEvent2;
		mCell = aCell;

		//if (!mCell->HasParent()) {
			mCell->AddDependentSwap(this);
		//} else {
		//	CellNode *child1 = mCell->GetParent()->GetChild(0);
		//	child1->AddDependentSwap(this);
		//	CellNode *child2 = mCell->GetParent()->GetChild(1);
		//	child2->AddDependentSwap(this);
		//}
}

Swap::~Swap() {
}

void Swap::Execute(Tree *aTree, vector<CellNode*> *aEndCellNodes, bool aPrint) {
	if (aPrint) {
        lout << "t = " << right << setw(4) << setfill(' ') << mEvent1->GetStartState()->GetT()
                << setw(0) << "," << right  << setw(14) << setfill(' ') << "Swap"
                << right << setw(6) << setfill(' ') << mEvent1->GetStartState()->GetIndex() + 1
                << setw(0) << " -->"
                << right << setw(6) << setfill(' ') << mEvent1->GetEndState()->GetIndex() + 1
                << setw(0) << " -->"
                << right << setw(6) << setfill(' ') << mEvent2->GetStartState()->GetIndex() + 1
                << setw(0) << " -->"
                << right << setw(6) << setfill(' ') << mEvent2->GetEndState()->GetIndex() + 1
                << setw(0) << " = "
                << setprecision(16) << fixed << setw(22) << setfill(' ') << GetScore() << endl;
	}
    
	double score = GetScore();

	CellNode *prevCell = mCell->GetPrevCell();
	
	// If a mitosis is modified, the the swaps associated with the other child will have to be recomputed later.
	if (mCell->HasParent()) {
		if (mCell->GetParent()->GetChild(0) == mCell) {
			aEndCellNodes->push_back(mCell->GetParent()->GetChild(1));
		} else {
			aEndCellNodes->push_back(mCell->GetParent()->GetChild(0));
		}
	}

	// Remove old event.
	prevCell->RemoveLink(aTree);

	// Add two new events.
	mEvent1->Execute(aTree, aEndCellNodes, mCell);
	aTree->SetActiveCell(prevCell);
	mEvent2->Execute(aTree, aEndCellNodes, false);
}

void Swap::Execute(Tree *aTree, vector<CellNode*> *aEndCellNodes, CellNode *aCell) {
	assert(false);
}

double Swap::GetScore() const {
	// New event for active cell. Does not include a cell count increase.
	double score = mEvent1->GetPlusScore();
	// Old event to remove. Does not include a cell count increase.

	// If mCell->GetPrevEvent() is a mitosis, we can end up subtracting and adding to the same to a migration variable,
	// and therefore we need to tell the mitosis that we are planning to add 1 to the migration. Not necessary as OkSwap23
	// takes care of that.
	// mEvent1->Plus();
	score += mCell->GetPrevEvent()->GetMinusScore();
	// mEvent1->Minus();
	
	// New event for old cell. Includes a cell count increase.
	score += mEvent2->GetScore();
	return score;
}