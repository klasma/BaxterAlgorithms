#ifndef SEGMENT
#define SEGMENT

#include "Region.h"

#include <vector>

class Corner;
class Surface;

using namespace std;

// Segment objects prepresent segmented watershed regions. Every Segment has a unique index which
// is equal to the lowest original label in the watersheds that have been merged together to create
// the Segment.
class Segment : public Region {

public:
	explicit Segment(int aIndex);

	// Merges a the Segment aSegment into the current Segment. The current region takes over the
	// pixels of the aSegment and the pixels in the Surface between the Segments. Surfaces and
	// corners associated with aSegment are either taken over by the current region or merged into
	// prexeisting Surfaces assocaited with the current Segment. Corner objects can be transformed
	// into Surface objects as a result of the merging. This should be very rare, but when such
	// Surfaces are created, they are added to the vector aCreatedSurfaces, so that the memory
	// associated with them can be freed by the calling function.
	//
	// Inputs:
	// aSegment - Segment that will be merged into the current Segment.
	//
	// aCreatedSurfaces - Vector where new surfaces, created during the merge will be put.
	void Merge(Segment *aSegment, vector<Surface*>* aCreatedSurfaces);

	// Adds a neighboring Corner to the Segment. This function should only be called by the
	// Corner class.
	void AddCorner(Corner *aCorner) { mCorners.push_back(aCorner); }

	// Adds a neighboring Surface to the Segment. This function should only be called by the
	// Surface class.
	void AddSurface(Surface *aSurface) { mSurfaces.push_back(aSurface); }

	// Returns the index of the Segment.
	int GetIndex() { return mIndex; }

	// Returns neighboring Corner number aIndex.
	Corner *GetCorner(int aIndex) { return mCorners[aIndex]; }

	// Returns the number of corners that border the Segment.
	int GetNumCorners() {return (int) mCorners.size(); }

	// Returns the number of Surfaces adjacent that border the Segment.
	int GetNumSurfaces() { return (int) mSurfaces.size(); }

	// Returns neighboring Surface number aIndex.
	Surface *GetSurface(int aIndex) { return mSurfaces[aIndex]; }

	// Removes a Corner from the list of adjacent Corners. Used when a corner is meged into a
	// preexisting Surface or transformed into a new Surface.
	void RemoveCorner(Corner *aCorner);

	// Removes a Surface from the list of adjacent Surfaces.
	void RemoveSurface(Surface *aSurface);

private:
	// Merges a Surface into the Segment.
	void Merge(Surface *aSurface);

private:
	int mIndex;						// Index of the Segment.				
	vector<Surface*> mSurfaces;		// Adjacent Surfaces.
	vector<Corner*> mCorners;		// Adjacent Corners.
};
#endif