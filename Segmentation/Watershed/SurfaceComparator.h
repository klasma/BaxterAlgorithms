#ifndef SURFACECOMPARATOR
#define SURFACECOMPARATOR

class Surface;

// Comparison class that specifies a comparison operator for pairs of Surfaces. The class is used
// for the comparison object that defines the order of Surfaces in a set container.
class SurfaceComparator {
public:
	// This operator returns true if aSurf1 should go before aSurf2 in the set container. The
	// operator returns true if aSurf1 has a lower score than aSurf2. If the Surfaces have the same
	// score, the operator compares the indices of the Segments bordering the surfaces. First the
	// Segment of aSurf1 with the lowest index and the Segment of aSurf2 with the lowest index are
	// compared. The surface with the lower index should come first in the set. If those indices are
	// equal, the two highest Segment indices are compared. This ensures that there is no ambiguity
	// in the ordering, as two Surfaces can never border the same pair of Segments.
	bool operator() (Surface *aSurf1, Surface *aSurf2) const;
};
#endif