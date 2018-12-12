#ifndef CORNER
#define CORNER

#include "Border.h"

#include <vector>

class Segment;
class Surface;

using namespace std;

// Corner objects represent single ridge pixels that are adjacent to more than 2 watershed Segments.
class Corner : public Border {

public:
	// Creates an empty Corner object without pixels or adjacent Segments.
	Corner() { ; }

	// Adds an adjacent Segment to the Corner and adds the Corner to the Segment.
	void AddSegment(Segment *aSegment);

	// Converts the Corner to a Surface and changes all pointers in the adjacent Segments
	// accordingly. The function must not be called for Corners with more than 2 neighboring
	// Segments. The function returns a pointer to the created Surface. The Corner object is
	// not altered.
	Surface *ConvertToSurface();

	// Switches one of the adjacent Segments with a different Segment, and updates the Surface list
	// in the new Segment. If the new Segment is already adjacent to the Corner, the fuction only
	// removes the old Segment.
	void SwitchSegment(Segment *aOldSegment, Segment *aNewSegment);
};
#endif