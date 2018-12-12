#ifndef SURFACE
#define SURFACE

#include "Border.h"

#include <vector>

class Corner;
class Segment;

using namespace std;

// Class for regions of ridge pixels that border exactly 2 watersheds. The watershed merging
// algorithm works by removing Surfaces between Segments. For any given pair of adjacent
// Segments, there will be a single Surface object containing all ridge pixels that border
// those 2 Segments and no other Segments. The Suface objects have a score associated with
// them that determine what surfaces should be removed and in what order they should be removed,
// during the watershed merging.
class Surface : public Border {

public:
	// Creates a Surface that borders the Segments aSegment1 and aSegment2. The Region starts
	// with no pixels. Pixels can be added but additional Segments can not be added.
	Surface(Segment *aSegment1, Segment *aSegment2);

	// Merges the pixels in aSurface into the current Surface.
	void Merge(Surface *aSurface);

	// Merges the pixels in aCorner into the current Surface.
	void Merge(Corner *aCorner);

	// Returns the score determining how desirable it is to remove the Surface during watershed
	// merging. The score is computed as the average pixel intensity in the Surface, divided by the
	// minimum of the two mean pixel intensities of the adjacent Segments.
	double Score();

	// Switches one of the adjacent Segments with a different Segment, and updates the Surface list
	// in the new Segment.
	void SwitchSegment(Segment *aOldSegment, Segment *aNewSegment);
};
#endif