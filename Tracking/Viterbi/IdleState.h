#ifndef IDLESTATE
#define IDLESTATE

#include "State.h"

// IdleStates represent all cell states that are not associated with a Detection,
// such as death and not being born yet.
class IdleState: public State {
public:
	// Creates an IdleState with state index aIndex in image aT.
	// The indexing is shared among all states in an image, not just
	// The IdleStates.
	IdleState(int aT, int aIndex);
};
#endif