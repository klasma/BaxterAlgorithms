#include "Corner.h"
#include "Border.h"
#include "Surface.h"
#include "Segment.h"

#include <assert.h>

void Corner::AddSegment(Segment *aSegment) {
	Border::AddSegment(aSegment);
	aSegment->AddCorner(this);
}

Surface *Corner::ConvertToSurface() {
	assert(GetNumSegments() == 2);

	// Create the Surface.
	Surface *newSurface = new Surface(GetSegment(0), GetSegment(1));
	newSurface->AddPixel(GetPixel(0), GetValue(0));

	// Replace the Corner by the Surface in all adjacent segments.
	for (int i=0; i < GetNumSegments(); i++) {
		Segment *seg = GetSegment(i);
		seg->RemoveCorner(this);
	}

	return newSurface;
}

void Corner::SwitchSegment(Segment *aOldSegment, Segment *aNewSegment) {
	bool alreadyNeighbor = ReplaceSegment(aOldSegment, aNewSegment);
	if (!alreadyNeighbor) {
		aNewSegment->AddCorner(this);
	}
}