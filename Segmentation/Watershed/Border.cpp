#include "Border.h"
#include "Segment.h"

#include <assert.h>
#include <cstddef>  // To get NULL.

Segment *Border::GetNeighbor(Segment *aSegment) {
	assert(mSegments.size() == 2);

	if (mSegments[0] == aSegment) {
		return mSegments[1];
	}
	else if (mSegments[1] == aSegment) {
		return mSegments[0];
	}
	else {
		// aSegment was not a neighboring region.
		assert(false);
		return NULL;
	}
}

bool Border::IsAdjacent(Segment *aSegment) {
	for (int i=0; i<GetNumSegments(); i++) {
		if (aSegment == mSegments[i]) {
			return true;
		}
	}
	return false;
}

bool Border::ReplaceSegment(Segment *aOldSegment, Segment *aNewSegment) {
	assert(aNewSegment != aOldSegment);

	// Check if aNewSegment is already a neighbor of the Border.
	bool alreadyNeighbor = false;
	for (int i=0; i<(int)mSegments.size(); i++) {
		if (mSegments[i] == aNewSegment) {
			alreadyNeighbor = true;
			break;
		}
	}

	if (!alreadyNeighbor) {
		mSegments.push_back(aNewSegment);
	}

	// Replace the old Segment with the new segment.
	for (int i=0; i<(int)mSegments.size(); i++) {
		if (mSegments[i] == aOldSegment) {
			mSegments.erase(mSegments.begin()+i);
			return alreadyNeighbor;
		}
	}

	// The old segment has to be a neighbor.
	assert(false);
	return alreadyNeighbor;  // Only to ensure that there is always an output.
}