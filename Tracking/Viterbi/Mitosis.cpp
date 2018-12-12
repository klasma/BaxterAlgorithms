#include "Mitosis.h"
#include <cstddef>  // To get NULL.
#include "CellNode.h"
#include "Detection.h"
#include "LogStream.h"
#include "Migration.h"
#include "State.h"
#include "Tree.h"

#include <assert.h>
#include <limits>
#include <vector>

// Forwards to the Event constructor.
Mitosis::Mitosis(IdleState *aStartState, Detection *aEndState, Detection *aStartDetection, Detection *aOtherChild,
	int aValue, int aNumScores, const double *aScore)
	: Event((State*) aStartState, (State*) aEndState, aValue, aNumScores, aScore), mIsInTrellis(false) {
		mStartDetection = aStartDetection;
		mOtherChild = aOtherChild;
		mStartDetection->AddMitosis(this);
		mMirror = NULL;
		// Mitosis events are not added to the CellTrellis until the required migration is present.
		RemoveFromTrellis();
}

void Mitosis::AddToTrellis() {
	mStartState->AddForwardArc(this);
	mEndState->AddBackwardArc(this);
	mIsInTrellis = true;
}

bool Mitosis::Check(
	const State *aStateFrom,
	const State *aStateTo1,
	const State *aStateTo2) const {

		if (aStateFrom != (State*) mStartDetection) {
			return false;
		}
		if (aStateTo1 == mEndState) {
			if (aStateTo2 == (State*) mOtherChild) {
				return true;
			}
			else {
				return false;
			}
		}
		if (aStateTo1 == (State*) mOtherChild) {
			if (aStateTo2 == mEndState) {
				return true;
			}
			else {
				return false;
			}
		}
		return false;
}

void Mitosis::Execute(Tree *aTree, vector<CellNode*> *aEndCellNodes, bool aPrint) {
    if (aPrint) {
        lout << "t = " << right << setw(4) << setfill(' ') << mStartState->GetT()
                << setw(0) << "," << right  << setw(14) << setfill(' ') << "Mitosis"
                << right << setw(6) << setfill(' ') << mStartDetection->GetIndex() + 1
                << setw(0) << " -->"
                << right << setw(6) << setfill(' ') << mEndState->GetIndex() + 1
                << setw(0) << " = "
                << setprecision(16) << fixed << setw(22) << setfill(' ') << GetScore() << endl;
    }

    assert(mStartDetection->GetNumCells() > 0);

	CellNode *cell = GetAcceptingCell();
	assert(cell != NULL);
    Detection *detection = (Detection*) mEndState;

	Migration *oldMig = (Migration*) cell->GetNextEvent();
	Migration *newMig = mStartDetection->GetMigration(detection);
    
	// Create the second child CellNode.
	if (!aTree->HasActiveCell()) {
		aTree->CreateCellFirst((IdleState*) mStartState);  // Normally a new CellNode has to be created.
	}
	CellNode *child2 = aTree->GetActiveCell();
	assert(mStartState = child2->GetState());

	// Create the first child CellNode.
	CellNode *nextCell = cell->GetNextCell();
	cell->RemoveLink(aTree);
	CellNode *child1 = aTree->CreateCellFirst((IdleState*) mStartState);
	child1->AddLink(GetMirror(), nextCell);
	
	aTree->SetActiveCell(child2);
	aTree->CreateCellLink(child2, this);

	// Add the children (the CellNodes after the IdleStates).
	cell->AddChildren(this, child1->GetNextCell(), child2->GetNextCell());

	// We need to increment the values of the migrations as they are included in the mitosis.
	oldMig->Increment();
	newMig->Increment();

	// Specify the CellNodes that need new Swaps.
	aEndCellNodes->push_back(child1->GetNextCell());
	aEndCellNodes->push_back(child2->GetNextCell());
}

void Mitosis::Execute(Tree *aTree, vector<CellNode*> *aEndCellNodes, CellNode *aCell) {
	assert(mStartDetection->GetNumCells() > 0);
    
	CellNode *cell = GetAcceptingCell();
	assert(cell != NULL);
    Detection *detection = (Detection*) mEndState;

	Migration *oldMig = (Migration*) cell->GetNextEvent();
	Migration *newMig = mStartDetection->GetMigration(detection);

	// Create the second child CellNode.
	if (!aTree->HasActiveCell()) {
		aTree->CreateCellFirst((IdleState*) mStartState);  // Normally a new CellNode has to be created.
	}
	CellNode *child2 = aTree->GetActiveCell();
	assert(mStartState = child2->GetState());

	// Create the first child CellNode
	CellNode *nextCell =  cell->GetNextCell();
	cell->RemoveLink(aTree);
	CellNode *child1 = aTree->CreateCellFirst((IdleState*) mStartState);
	child1->AddLink(GetMirror(), nextCell);
	
	aTree->SetActiveCell(child2);
	child2->AddLink(this, aCell);

	// Add the children.
	cell->AddChildren(this, child1->GetNextCell(), child2->GetNextCell());

	// We need to increment the values of the migrations as they are included in the mitosis.
	oldMig->Increment();
	newMig->Increment();

	// Specify the CellNodes that need new Swaps.
	aEndCellNodes->push_back(child1->GetNextCell());
	aEndCellNodes->push_back(child2->GetNextCell());
}

void Mitosis::LinkMirror(Mitosis *aMitosis) {
	assert(mMirror == NULL && aMitosis->mMirror == NULL);
	mMirror = aMitosis;
	aMitosis->mMirror = this;
}

double Mitosis::GetMinusScore() const {
    // This was probably wrong. The other migration should have been increased.
    // Migration *migration = mStartDetection->GetMigration((Detection*) mEndState);
    // 	return Variable::GetMinusScore() + migration->GetPlusScore();
    
    Migration *migration = mStartDetection->GetMigration((Detection*) mEndState);
    return Variable::GetMinusScore() - migration->GetPlusScore();
}

double Mitosis::GetScore() const {
	CellNode *cell = GetAcceptingCell();

	if (cell == NULL) {
		// This mitosis has become inpossible, because the migration it depends on has been removed
		// from the trellis. These mitotic events could be removed from the trellis, but they are
		// so few that it is unnecessary.
		return -numeric_limits<double>::infinity();
	}

	Detection *detection = (Detection*) mEndState;
	//Migration *migration = (Migration*) cell->GetNextEvent();  // The migration which is replaced by mitosis.
    Migration *migration = mStartDetection->GetMigration(detection);
    
	double score = GetPlusScore();
	//score += migration->GetMinusScore();
    score += migration->GetPlusScore();
	score += detection->GetPlusScore();
    
	return score;
}

// The function is const to allow GetScore to call it.
CellNode *Mitosis::GetAcceptingCell() const {
	for (Detection::CellIterator cIt = mStartDetection->GetBeginCell(); cIt < mStartDetection->GetEndCell(); ++cIt) {
		CellNode *cell = *cIt;
		if (cell->HasNextCell() && cell->GetNextCell()->GetState() == (State*) mOtherChild) {
			return cell;  
		}
	}
	return NULL;
}

// TODO: REFINE THIS SO THAT IT ALLOWS A SWAP WHEN THERE ARE MULIPLE CELLS IN THE DETECTION.
bool Mitosis::OkSwap12(Event *aEvent) {
	return false;  // It is too complicated to remove swaps when the mitosis becomes invalid.
	//if (aEvent->GetStartState() == mStartDetection) {
	//	return false;
	//} else {
	//	return true;
	//}
}

// TODO: REFINE THIS SO THAT IT ALLOWS A SWAP WHEN THERE ARE MULIPLE CELLS IN THE DETECTION.
bool Mitosis::OkSwap32(Event *aEvent) {
	return false;  // It is too complicated to remove swaps when the mitosis becomes invalid.
}

void Mitosis::RemoveFromTrellis() {
	mStartState->RemoveForwardArc(this);
	mEndState->RemoveBackwardArc(this);
	mIsInTrellis = false;
}