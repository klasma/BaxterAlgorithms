#include "Migration.h"
#include <algorithm>
#include <vector>
#include "CellNode.h"
#include "Detection.h"
#include "Event.h"
#include "LogStream.h"
#include "Mitosis.h"
#include "State.h"
#include "Tree.h"

using namespace std;

// Forwards to the Event constructor.
Migration::Migration(Detection *aStartDetection, Detection *aEndDetection,
	int aValue, int aNumScores, const double *aScore, double aMaxMigScore)
	: Event((State*) aStartDetection, (State*) aEndDetection, aValue, aNumScores, aScore),
	mMaxScore(aMaxMigScore) {
		aStartDetection->AddMigration(this);
}

// Migrations are effectively set to true whenever they have a positive score.
double Migration::GetPlusScore() const {
	return min(Variable::GetPlusScore(), mMaxScore);
}

// Migrations are effectively set to true whenever they have a posistive score.
double Migration::GetMinusScore() const {
	return max(Variable::GetMinusScore(), -mMaxScore);
}

void Migration::Execute(Tree *aTree, vector<CellNode*> *aEndCellNodes, bool aPrint) {
	if (aPrint) {
        lout << "t = " << right << setw(4) << setfill(' ') << mStartState->GetT()
                << setw(0) << "," << right << setw(14) << setfill(' ') << "Migration"
                << right << setw(6) << setfill(' ') << mStartState->GetIndex() + 1
                << setw(0) << " -->"
                << right << setw(6) << setfill(' ') << mEndState->GetIndex() + 1
                << setw(0) << " = "
                << setprecision(16) << fixed << setw(22) << setfill(' ') << GetScore() << endl;
	}

	CellNode *activeCell = aTree->GetActiveCell();
	aEndCellNodes->push_back(aTree->CreateCellLink(activeCell, this));
}

void Migration::Execute(Tree *aTree, vector<CellNode*> *aEndCellNodes, CellNode *aCell) {

	CellNode *activeCell = aTree->GetActiveCell();
	activeCell->AddLink(this, aCell);

	aEndCellNodes->push_back(aCell);
}

double Migration::GetScore() const {
	return mEndState->GetPlusScore() + GetPlusScore();
}

void Migration::Increment() {
	Event::Plus();
}

void Migration::Plus() {
	Event::Plus();
	// Add a mitosis it requires the current migration and is not in the trellis already.
	Detection::MitosisIterator firstMit;
	Detection::MitosisIterator lastMit;
	((Detection*) mStartState)->GetMitosis((Detection*) mEndState, firstMit, lastMit);
	for (Detection::MitosisIterator it = firstMit; it != lastMit; ++it) {
		Mitosis *mit = it->second;
		if (!mit->IsInTrellis()) {
			mit->AddToTrellis();
		}
	}
}