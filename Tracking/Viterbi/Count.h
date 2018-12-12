#ifndef COUNT
#define COUNT

#include "Variable.h"

// Event that keeps track of the number of cells in a detection
// and the scores associated with different cell counts.
// Count is the only Variable which is not also an Event.
class Count : public Variable {

public:
	// Stores the cell count, the scores associated with different cell counts and the number of scores.
	// The number of scores is equal to the maximum cell count minus 1.
	Count(int aValue, int aNumScores, const double *aScores);
};
#endif