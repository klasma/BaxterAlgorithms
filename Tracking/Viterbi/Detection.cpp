#include "Detection.h"
#include <cstddef>  // To get NULL.
#include <vector>
#include "CellNode.h"
#include "Count.h"
#include "Migration.h"
#include "Mitosis.h"

using namespace std;

Detection::Detection(int aT, int aIndex)
	: State(aT, aIndex) {
		mCount = NULL;  // Set in SetCount.
}

Detection::~Detection() {
	delete mCount;

	// Destroy the mitosis events that are not in the Trellis. The ones in the Trellis are destoyed
	// when the Trellis Nodes are destroyed.
	for (MitosisIterator mitIt=mMitosisMap.begin(); mitIt!=mMitosisMap.end(); ++mitIt) {
		Mitosis *mit = mitIt->second;
		if (!mit->IsInTrellis()) {
			delete mit;
		}
	}
}

void Detection::AddMigration(Migration *aMigration) {
	mMigrationMap[(Detection*) aMigration->GetEndState()] = aMigration;
}

void Detection::AddMitosis(Mitosis *aMitosis) {
	mMitosisMap.insert(pair<Detection*,Mitosis*>(aMitosis->GetOtherChild(), aMitosis));
}

Migration *Detection::GetMigration(Detection *aDetection) {
	map<Detection*, Migration*>::iterator it = mMigrationMap.find(aDetection);
	if (it!=mMigrationMap.end()) {
		return it->second;
	} else {
		return NULL;
	}
}

void Detection::GetMitosis(Detection *aDetection, MitosisIterator &aFirst, MitosisIterator &aLast) {
	pair<MitosisIterator, MitosisIterator> mitInterval = mMitosisMap.equal_range(aDetection);
	aFirst = mitInterval.first;
	aLast = mitInterval.second;
}

double Detection::GetMinusScore() {
	return mCount->GetMinusScore();
}

double Detection::GetPlusScore() {
	return mCount->GetPlusScore();
}

void Detection::Minus() {
	mCount->Minus();
}

void Detection::Plus() {
	mCount->Plus();
}
