#include "Segment.h"
#include "Surface.h"
#include "SurfaceComparator.h"
#include "Corner.h"
#include <vector>
#include <set>
#include <assert.h>
#include <cstddef>  // To get NULL.
#include <stdio.h>

using namespace std;

/* MergeSegments merges waterheds in a watershed transform based on a score associate with the
* borders between the watersheds. See the header file for explanations of the input arguments.
*
* The algorithm needs to keep track of all waterhsed borers and iteratively remove the one with
* the lowest score, and at the same time update the watershed borders and their scores as other
* borders are removed. To solve this problem, I represent the watershed label image as a graph,
* where there are nodes for labeled segments, surfaces between pairs of segments and corners with
* single pixels that border more than one segment. The segments, surfaces and corners keep
* pointers to all objects that they are neighbors of in the image. The segments are kept in a
* vector where the vector index represents the original index of the segment in the image. When
* two segments are merged the segment with the lowest index takes over the pixels of the other
* segment, the other segment is deleted and its position in the vector is set to NULL. The
* surfaces are kept in a set, ordered by the surface scores. The surface to be removed is then
* taken as the first element in the set, until the first element of the set has a score above the
* merging threshold. To speed the computations up, the mean pixel values of segments and surfaces
* are cashed and recomputed whenever new pixels are added to them.
*/

void MergeSegments(
	int aNumDims,
	const int *aDims,
	const int *aLabels,
	const double *aImage,
	double aMergeThreshold,
	int aMinSize,
	int *aNewLabels)
{

	// Array with all segments. When a segment is merged into another segment, the corresponding
	// position in the vector is set to NULL
	vector<Segment*> segments;
	// Set where the surfaces are sorted in ascending order according to their score.
	set<Surface*, SurfaceComparator> surfaces;

	// All surfaces that ever existed. Used to free the memory.
	vector<Surface*> allSurfaces;
	// All corners that ever existed. Used to free the memory.
	vector<Corner*> allCorners;

	// Create graphical representation of the label image.
	if (aNumDims == 2) {
		// Find the maximum segment index.
		int numSegments = 0;
		for (int p=0; p<aDims[0]*aDims[1]; p++) {
			if (aLabels[p] > numSegments) {
				numSegments = aLabels[p];
			}
		}

		// Generate empty segments.
		for(int s=0; s<numSegments; s++) {
			segments.push_back(new Segment(s));
		}

		for (int i=0; i<aDims[0]; i++) {
			for (int j=0; j<aDims[1]; j++) {
				int index = i + j*aDims[0];  // Pixel index.
				int label = aLabels[index];
				double value = aImage[index];
				if (label > 0) {  // Segment pixel.
					segments[label-1]->AddPixel(index,value);
				}
				else {  // Surface or corner pixel.

					// Get a vector of neighboring region indices.
					vector<int> neighbors;
					// Iterate over a 3x3 region around the pixel.
					for (int ii = i-1; ii < i+2; ii++) {
						for (int jj = j-1; jj < j+2; jj++) {
							// Check that pixel is inside the image.
							if (ii > -1 && ii < aDims[0] && jj > -1 && jj < aDims[1]) {
								int nb = aLabels[ii + jj*aDims[0]] - 1;  // Neighbor index.
								if (nb == -1) {
									// Ridge pixel.
									continue;
								}
								bool taken = false;
								for (int v=0; v<(int)neighbors.size(); v++) {
									if (neighbors[v] == nb) {
										taken = true;
										break;
									}
								}
								if (!taken) {
									// Add the neighbor index if it has not been added before.
									neighbors.push_back(nb);
								}
							}
						}
					}

					//// A ridge pixel must have more than one neighbor in the ordinary watershed
					//// trannsform. It is not allowed to have background regions of zero pixels.
					//assert(neighbors.size() > 1);

					if (neighbors.size() < 2) {
						// Background pixel which is not a proper ridge pixel.
						continue;
					}

					if (neighbors.size() == 2) {  // Surface between 2 segments.
						Segment *seg1 = segments[neighbors[0]];
						Segment *seg2 = segments[neighbors[1]];

						// Check if there is already a surface object linking the two segments, and
						// add the pixel to that sufrace if there is.
						bool surfExists = false;
						for (int su=0; su<seg1->GetNumSurfaces(); su++) {
							Surface *surf = seg1->GetSurface(su);
							if (surf->IsAdjacent(seg2)) {
								surf->AddPixel(index, value);
								surfExists = true;
								break;
							}
						}

						// Create a new surface linking the two segments. Don't add the surface to
						// the sorted set yet, as the score will change when more pixels are added.
						if (!surfExists) {
							Surface *newSurf = new Surface(seg1, seg2);
							newSurf->AddPixel(index, value);
							allSurfaces.push_back(newSurf);
						}
					}
					else {  // Corner, consisting of a single pixel, bordering 3 or more segments.
						Corner *newCorner = new Corner();
						newCorner->AddPixel(index, value);
						allCorners.push_back(newCorner);
						for (int v=0; v<(int)neighbors.size(); v++) {
							newCorner->AddSegment(segments[neighbors[v]]);
						}
					}
				}
			}
		}
	}
	// Add the surfaces to the sorted set, now that all pixels have been added.
	for (int su=0; su<(int)allSurfaces.size(); su++) {
		surfaces.insert(allSurfaces[su]);
	}

	// Iteratively remove the surface with the lowest score until all surfaces have scores
	// above the merging threshold, or until there are no surfaces left.
	int iteration = 0;
	while (!surfaces.empty()) {

		set<Surface*, SurfaceComparator>::iterator it = surfaces.begin();
		Surface *weakestSurf = *it;  // Surface with the lowest score.

		if (weakestSurf->Score() > aMergeThreshold) {
			// All surfaces have a score above the merging threshold.
			if (weakestSurf->GetSegment(0)->GetNumPixels() > aMinSize &&
				weakestSurf->GetSegment(1)->GetNumPixels() > aMinSize) {
					surfaces.erase(weakestSurf);
					continue;
			}
		}

		Segment *seg1 = weakestSurf->GetSegment(0);
		Segment *seg2 = weakestSurf->GetSegment(1);
		if (seg2->GetIndex() < seg1->GetIndex()) {
			// Make sure that the segment with the higher index is merged into the segment with the
			// lower index.
			Segment *tmp = seg1;
			seg1 = seg2;
			seg2 = tmp;
		}

		// Remove all surfaces that border the merging segments from the sorted set.
		for (int su1=0; su1<seg1->GetNumSurfaces(); su1++) {
			surfaces.erase(seg1->GetSurface(su1));
		}
		for (int su2=0; su2<seg2->GetNumSurfaces(); su2++) {
			surfaces.erase(seg2->GetSurface(su2));
		}

		// Merge the segment with the higher index into the segment with the lower index.
		vector<Surface*> createdSurfaces;
		seg1->Merge(seg2, &createdSurfaces);
		segments[seg2->GetIndex()] = NULL;
		delete seg2;

		// Keep track of corners that turn into surfaces in the segment merging.
		for (int i=0; i<(int)createdSurfaces.size(); i++) {
			allSurfaces.push_back(createdSurfaces[i]);
		}

		// Insert the surfaces that border the merged segment into the sorted set.
		for (int su1=0; su1<seg1->GetNumSurfaces(); su1++) {
			surfaces.insert(seg1->GetSurface(su1));
		}

		iteration ++;
	}

	// Construct the new label matrix for the merged segments.
	for (int i=0; i<aDims[0]*aDims[1]; i++) {
		aNewLabels[i] = 0;
	}
	int index = 1;
	for (int i=0; i<(int)segments.size(); i++) {
		Segment *seg = segments[i];
		if (seg == NULL) {
			// This segment was merged into another segment.
			continue;
		}
		for (int j=0; j < seg->GetNumPixels(); j++) {
			aNewLabels[seg->GetPixel(j)] = index;
		}
		index++;
	}

	// Free memory.

	for (int i=0; i<(int)segments.size(); i++) {
		Segment *seg = segments[i];
		if (seg != NULL) {
			delete segments[i];
		}
	}

	for (int i=0; i < (int) allSurfaces.size(); i++) {
		delete allSurfaces[i];
	}

	for (int i=0; i< (int) allCorners.size(); i++) {
		delete allCorners[i];
	}
}