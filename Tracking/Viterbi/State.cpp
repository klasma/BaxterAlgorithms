#include "State.h"
#include <assert.h>
#include "CellNode.h"

State::State(int aT, int aIndex)
	: Node(aIndex), mT(aT) {
}

State::~State() {
	assert(GetNumCells() == 0);
}

void State::AddCell(CellNode *aCell) {
	// A cell can not be added if it does not contain the State.
    assert(aCell->GetState() == this);
    mCells.push_back(aCell);
}

void State::RemoveCell(CellNode *aCell) {
	// Slow way of erasing an element.
	for (int i=0; i<(int)mCells.size(); i++){
		if (mCells[i] == aCell) {
			mCells.erase(mCells.begin()+i);
			return;
		}
	}
}