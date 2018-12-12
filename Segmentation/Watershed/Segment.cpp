#include "Corner.h"
#include "Segment.h"
#include "Surface.h"

#include <assert.h>
#include <vector>

using namespace std;

Segment::Segment(int aIndex) : mIndex(aIndex) {}

void Segment::Merge(Surface *aSurface) {
	Region::Merge(aSurface);
	for (int i=0; i<aSurface->GetNumSegments(); i++) {
		aSurface->GetSegment(i)->RemoveSurface(aSurface);
	}
}

void Segment::Merge(Segment *aSegment, vector<Surface*>* aCreatedSurfaces) {
	Region::Merge((Region*) aSegment);  // Only copies the pixels.

	// We can not iterate over the Surface vector that we are modifying.
	vector<Surface*> allSurfs2;
	for (int i=0; i<aSegment->GetNumSurfaces(); i++) {
		allSurfs2.push_back(aSegment->GetSurface(i));
	}

	// All surfaces associated with aSegment need to be either transfered to the current Segment or
	// merged into surfaces associated with the current Segment, or the current Segment itself.
	for (int i=0; i<(int)allSurfs2.size(); i++) {
		Surface *surf2 = allSurfs2[i];
		Segment *neighbor2 = surf2->GetNeighbor(aSegment);

		// The surface between this and aSegment is meged into this.
		if (neighbor2 == this) {
			Merge(surf2);
			continue;
		}
		
		bool mergedSurfs = false;  // True if the Surface was merged into a preexisting Surface.
		// Try to find a preexisting surface, associated with the current object, that the surf2
		// can be merged into.
		for (int j=0; j<GetNumSurfaces(); j++) {
			Surface *surf1 = GetSurface(j);
			Segment *neighbor1 = surf1->GetNeighbor(this);
			if (neighbor1 == neighbor2) {
				surf1->Merge(surf2);
				mergedSurfs = true;
				break;
			}
		}

		// Transfer the surf2 to the current Segment if no preexisting Surface was found.
		if (!mergedSurfs) {
			surf2->SwitchSegment(aSegment, this);
		}
	}

	// We can not iterate over the Corner vector that we are modifying.
	vector<Corner*> allCorners;
	for (int i=0; i<aSegment->GetNumCorners(); i++) {
		allCorners.push_back(aSegment->GetCorner(i));
	}

	// All Corners associated with aSegment need to be either transfered to the current Segment,
	// merged into Surfaces associated with the current Segment or converted into Surfaces
	// associated with the current Segment.
	for (int i=0; i<(int)allCorners.size(); i++) {
		Corner *cor = allCorners[i];
		cor->SwitchSegment(aSegment, this);  // This transfers the corner to the current Segment.
		if (cor->GetNumSegments() == 2) {
			Segment *neighbor2 = cor->GetNeighbor(this);

			// Try to merge the corner into a preexisting Surface.
			bool mergedCor = false;
			for (int j=0; j<GetNumSurfaces(); j++) {
				Surface *surf1 = GetSurface(j);
				Segment *neighbor1 = surf1->GetNeighbor(this);
				if (neighbor1 == neighbor2) {
					surf1->Merge(cor);
					mergedCor = true;
					break;
				}
			}

			if (!mergedCor) {
				// Convert the corner into a Surface.
				Surface *newSurface = cor->ConvertToSurface();
				aCreatedSurfaces->push_back(newSurface);
			}
		}
	}
}

// Removes a Corner from the vector of Corners, by searching through the vector lineary. The
// The removal could be made faster if a different container was used for the Corners.
void Segment::RemoveCorner(Corner *aCorner) {
	for (int i=0; i<(int)mCorners.size(); i++) {
		if (mCorners[i] == aCorner) {
			mCorners.erase(mCorners.begin()+i);
			return;
		}
	}
	// It is not allowed to remove a Corner wich is not associated with the Segment.
	assert(false);
}

// Removes a Surface from the vector of Surfaces, by searching through the vector lineary. The
// The removal could be made faster if a different container was used for the Surfaces.
void Segment::RemoveSurface(Surface *aSurface) {
	for (int i=0; i<(int)mSurfaces.size(); i++) {
		if (mSurfaces[i] == aSurface) {
			mSurfaces.erase(mSurfaces.begin()+i);
			return;
		}
	}
	// It is not allowed to remove a Surface wich is not associated with the Segment.
	assert(false);
}