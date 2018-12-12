#include "Surface.h"
#include "Segment.h"
#include "Border.h"
#include "Corner.h"

#include <assert.h>

Surface::Surface(Segment *aSegment1, Segment *aSegment2) {
	AddSegment(aSegment1);
	AddSegment(aSegment2);
	aSegment1->AddSurface(this);
	aSegment2->AddSurface(this);
}

void Surface::Merge(Surface *aSurface) {
	Region::Merge((Region*) aSurface);
	for (int i=0; i<aSurface->GetNumSegments(); i++) {
		aSurface->GetSegment(i)->RemoveSurface(aSurface);
	}
}

void Surface::Merge(Corner *aCorner) {
	Region::Merge((Region*) aCorner);
	for (int i=0; i<aCorner->GetNumSegments(); i++) {
		aCorner->GetSegment(i)->RemoveCorner(aCorner);
	}
}

double Surface::Score() {
	// Avoid division by 0. (Only works if the mean is nonnegative.)  TODO: Make this nicer.
	double score1 = Mean() / (GetSegment(0)->Mean() + 1E-3);
	double score2 = Mean() / (GetSegment(1)->Mean() + 1E-3);

	if (score1 > score2) {
		return score1;
	} else {
		return score2;
	}
}

void Surface::SwitchSegment(Segment *aOldSegment, Segment *aNewSegment) {
	bool alreadyNeighbor = ReplaceSegment(aOldSegment, aNewSegment);
	assert(!alreadyNeighbor);  // aNewSegment can not be on both sides of the Surface.
	aNewSegment->AddSurface(this);
}