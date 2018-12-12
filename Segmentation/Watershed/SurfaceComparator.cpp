#include "SurfaceComparator.h"
#include "Surface.h"
#include "Segment.h"

#include <assert.h>

bool SurfaceComparator::operator() (Surface *aSurf1, Surface *aSurf2) const {
	// Compare Surface scores.
	if (aSurf1->Score() < aSurf2->Score()) {
		return true;
	} else if (aSurf1->Score() > aSurf2->Score()) {
		return false;
	}

	// Find the lower and the higher Segment indices associated with aSurf1.
	int minIndex1 = aSurf1->GetSegment(0)->GetIndex();
	int maxIndex1 = aSurf1->GetSegment(1)->GetIndex();
	if (maxIndex1 < minIndex1) {
		int tmp = minIndex1;
		minIndex1 = maxIndex1;
		maxIndex1 = tmp;
	}

	// Find the lower and the higher Segment indices associated with aSurf2.
	int minIndex2 = aSurf2->GetSegment(0)->GetIndex();
	int maxIndex2 = aSurf2->GetSegment(1)->GetIndex();
	if (maxIndex2 < minIndex2) {
		int tmp = minIndex2;
		minIndex2 = maxIndex2;
		maxIndex2 = tmp;
	}

	// Compare first the lower Segment indices and then the higher Segment indices if necessary.
	if (minIndex1 < minIndex2) {
		return true;
	}
	else if (minIndex2 < minIndex1) {
		return false;
	}
	else if (maxIndex1 < maxIndex2) {
		return true;
	}
	else {
		// Check that there are not two different Surfaces between the same pair of Segments.
		assert(aSurf1 == aSurf2 || maxIndex2 < maxIndex1);
		return false;
	}
}