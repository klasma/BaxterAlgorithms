#ifndef BORDER
#define BORDER

#include "Region.h"

#include <vector>

class Segment;

using namespace std;

// The Border class is a type of region, for ridge pixels between segmented watersheds.
// The class is the base class off all such border regions.
class Border : public Region {

public:
	// Creates an empty Border object with no pixels and no adjacent Segments.
	Border() { ; }

	// Returns the Segment which is on the other side of the border, relative to aSegment.
	// The border must have exactly 2 neighboring Segments, and one of them must be aSegment,
	// otherwise an assertion will fail.
	Segment *GetNeighbor(Segment *aSegment);

	// Returns the number of segmented watersheds that the border is adjacent to.
	int GetNumSegments() { return (int) mSegments.size(); }

	// Returns the neighboring segment with index aIndex.
	Segment *GetSegment(int aIndex) { return mSegments[aIndex]; }

	// Returns true if the border is adjacent to the Segment aSegment.
	bool IsAdjacent(Segment *aSegment);

protected:
	// Adds a Segment to the list of adjacent Segments. It is protected so that Segments can not
	// be added to any subclass of Border. The function does make any changes to the aSegment.
	void AddSegment(Segment *aSegment) { mSegments.push_back(aSegment); }

	// Replaces the neighboring Segment aOldSegment by aNewSegment, in the list of adjacent
	// Segments. If the new segment is already a neighbor, the old segment will be removed,
	// but the new segment will not be duplicated. The function does not change the object
	// lists of the aSegment. It is not allowed to replace a Segment with itself.
	//
	// Inputs:
	// aOldSegment - Segment pointer that will be replaced.
	//
	// aNewSegment - Segment pointer that will replace aOldSegment.
	//
	// Return value:
	// True if aNewSegment was already adjacent to the Border.
	bool ReplaceSegment(Segment *aOldSegment, Segment *aNewSegment);

private:
	vector<Segment*> mSegments;  // List of adjacent Segments.
};
#endif