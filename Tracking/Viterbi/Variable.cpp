#include "Variable.h"
#include <assert.h>
#include <algorithm>
#include <vector>

using namespace std;

// Dummy constructor for events that don't have a real variable associated with them.
Variable::Variable()
	: mScore(2,0), mValue(0), mNumScores(2) {
}

Variable::Variable(int aValue, int aNumScores, const double *aScores)
	: mScore(aNumScores, 0.0), mValue(aValue), mNumScores(aNumScores) {
		
		// Copy the scores to the vector.
		for (int i=0; i<aNumScores; i++) {
			mScore[i] = aScores[i];
		}
}


double Variable::GetMinusScore() const {
	//// Old version where events were free when enough of them had been added.
	//int value = min(mValue, mNumScores-1);  // Must not read outside vector.
	//   double currScore = mScore[value];
	//   double nextScore = mScore[max(value-1, 0)];
	//   return nextScore - currScore;

	assert(mValue > 0);  // We can not subtract an event that does not occur.
	if (mValue < mNumScores) {
		return mScore[mValue-1] - mScore[mValue];
	} else {
		// 120406 - Changed from 0.0 to -10.0, to get rid of duplicated tracks.
		return max(mScore[mNumScores-2] - mScore[mNumScores-1], 0.0);
	}
}

double Variable::GetPlusScore() const {
	//// Old version where events were free when enough of them had been added.
	//int value = min(mValue, mNumScores-1);  // Must not read outside vector.
	//double currScore = mScore[value];
	//double nextScore = mScore[min(value+1, mNumScores-1)];
	//return nextScore - currScore;

	if (mValue < mNumScores-1) {
		return mScore[mValue+1] - mScore[mValue];
	} else {
		// 120406 - Changed from 0.0 to -10.0, to get rid of duplicated tracks.
		return min(mScore[mNumScores-1] - mScore[mNumScores-2], 0.0);
	}
}

// The Variable keeps track of the exact number or times that the event has occured, even
// though the score might not change, as mValue might have to go down again.
void Variable::Plus() {
    mValue++;
}

void Variable::Minus() {
	if (mValue == 0) {
		int stop = 1;
	}

	assert(mValue > 0);  // We can not subtract from a Variabel when the event does not occur.
    mValue = max(mValue-1, 0);
}