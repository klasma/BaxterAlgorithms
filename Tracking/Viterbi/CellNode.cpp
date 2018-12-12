#include "CellNode.h"
#include <assert.h>
#include <cstddef>  // To get NULL.
#include <vector>
#include "Detection.h"
#include "Event.h"
#include "Migration.h"
#include "Mitosis.h"
#include "State.h"
#include "Swap.h"
#include "Tree.h"

using namespace std;


CellNode::CellNode(State *aState, int aIteration): mIteration(aIteration) {
	mState = aState;
	mNextCell = NULL;
	mPrevCell = NULL;
	mParent = NULL;
	mChildren[0] = NULL;
	mChildren[1] = NULL;
	mNextEvent = NULL;
	mPrevEvent = NULL;

	mState->AddCell(this);
}

CellNode::~CellNode() {
	mState->RemoveCell(this);
}

void CellNode::AddChildren(Mitosis *aMitosis, CellNode *aChild1, CellNode *aChild2) {
    
    // Check that a child can be added.
    assert(mNextCell == NULL && mNextEvent == NULL);
    assert(mChildren[0] == NULL && mChildren[1] == NULL);
	assert(!aChild1->HasParent()
		&& aChild1->mPrevCell != NULL 
		&& aChild1->mPrevCell->mPrevCell == NULL
		&& aChild1->mPrevCell->mPrevEvent == NULL);
	assert(!aChild2->HasParent() 
		&& aChild2->mPrevCell != NULL 
		&& aChild1->mPrevCell->mPrevCell == NULL 
		&& aChild1->mPrevCell->mPrevEvent == NULL);
	assert(aMitosis->Check(mState, aChild1->GetState(), aChild2->GetState()));

    // Changes to parent cell.
	mChildren[0] = aChild1;
	mChildren[1] = aChild2;
	// mNextEvent is still NULL.

	// Changes to first child.
	// aChild1->mPrevEvent = aMitosis;
	aChild1->mParent = this;

	// Changes to second child.
	// aChild2->mPrevEvent = aMitosis;
	aChild2->mParent = this;
}

void CellNode::AddDependentSwap(Swap *aSwap) {
	mDependentSwaps.push_back(aSwap);
}

void CellNode::AddLink(Event *aEvent, CellNode *aCell) {

	// Check that the link is allowed.
	assert(mNextCell == NULL && mNextEvent == NULL);
	assert(!HasChildren());
	assert(aCell->mPrevCell == NULL && aCell->mPrevEvent == NULL);
	assert(!aCell->HasParent());
	assert(aEvent->Check(mState, aCell->GetState()));

	// Update members.
	mNextEvent = aEvent;
	mNextCell = aCell;
	aCell->mPrevEvent = aEvent;
	aCell->mPrevCell = this;

	// Update counters.
	mNextEvent->Plus();
	mNextCell->GetState()->Plus();
}

bool CellNode::HasChildren() const {
	if (mChildren[0] != NULL) {
		return true;
	} else {
		return false;
	}
}

// Returns false if the cell is the last CellNode in a cell track.
bool CellNode::HasNextCell() const {
	if (mNextCell != NULL) {
		return true;
	} else {
		return false;
	}
}

// Returns true if the CellNode is the first detection (not state) of a cell that was created through mitosis.
bool CellNode::HasParent() const {
	if (mParent != NULL) {
		return true;
	} else {
		return false;
	}
}

// Returns false if the cell is the fist CellNode in a cell track.
bool CellNode::HasPrevCell() const {
	if (mPrevCell != NULL) {
		return true;
	} else {
		return false;
	}
}

void CellNode::RemoveChildren(Tree *aTree) {
	assert(HasChildren());

	// Remove the first child from aTree.
	CellNode *prevCell1 = mChildren[0]->GetPrevCell();
	Mitosis *mit1 = (Mitosis*) mChildren[0]->GetPrevEvent();
	prevCell1->mNextEvent = NULL;
	prevCell1->mNextCell = NULL;
	//aTree->RemoveFirstCell(prevCell1);
	// Update members of the first child.
	mChildren[0]->mPrevEvent = NULL;
	mChildren[0]->mPrevCell = NULL;
	mChildren[0]->mParent = NULL;

	// Remove the second child from aTree.
	CellNode *prevCell2 = mChildren[1]->GetPrevCell();
	Mitosis *mit2 = (Mitosis*) mChildren[1]->GetPrevEvent();
	prevCell2->mNextEvent = NULL;
	prevCell2->mNextCell = NULL;
	//aTree->RemoveFirstCell(prevCell2);
	// Update members of the second child.
	mChildren[1]->mPrevEvent = NULL;
	mChildren[1]->mPrevCell = NULL;
	mChildren[1]->mParent = NULL;

	// Update counters.
	mChildren[0]->GetState()->Minus();
	mChildren[1]->GetState()->Minus();
	mit1->Minus();
	mit2->Minus();  // Mirror of mit1;

	// Update members of parent.
	mNextEvent = NULL;
	mChildren[0] = NULL;
	mChildren[1] = NULL;
}

void CellNode::RemoveDependentSwaps() {
	for (int i=0; i<(int)mDependentSwaps.size(); i++) {
		delete mDependentSwaps[i];
	}
	mDependentSwaps.clear();
}

void CellNode::RemoveLink(Tree *aTree) {
	if (mNextCell->HasParent()) {
		// Removes one of the children from the last CellNode
		// in a cell track that ends with mitosis.

		CellNode *parent = mNextCell->GetParent();

		CellNode *newNextCell = NULL;
		if (parent->GetChild(1) == mNextCell) {
			newNextCell = parent->GetChild(0);
		}
		else if (parent->GetChild(0) == mNextCell) {
			newNextCell = parent->GetChild(1);
		}
		else {
			assert(false);
		}

		// Find the migration that will replace the mitosis.
		Migration *migToKeep = ((Detection*) parent->GetState())->
			GetMigration((Detection*) newNextCell->GetState());

		// Find the migration which will disappear with the mitosis.
		Migration* migToRemove = ((Detection*) parent->GetState())->
			GetMigration((Detection*) mNextCell->GetState());

		CellNode *removeCell = newNextCell->GetPrevCell();
		parent->RemoveChildren(aTree);
		// The other child is no longer a cell of its own.
		aTree->RemoveFirstCell(removeCell);
        
        // Both migrations are first removed and laster one of them is added again.
        migToKeep->Minus();
        migToRemove->Minus();
            
        // Add back the migration that should be kept.
		parent->AddLink((Event*) migToKeep, newNextCell);
	} else {
		// Removes a link between two CellNodes in a cell track.

		mNextCell->mPrevEvent = NULL;
		mNextCell->mPrevCell = NULL;

		// Update counters.
		mNextCell->GetState()->Minus();
		mNextEvent->Minus();

		mNextCell = NULL;
		mNextEvent = NULL;
	}
}