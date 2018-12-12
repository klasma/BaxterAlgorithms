#include "Event.h"
#include <vector>
#include <assert.h>
#include "State.h"

using namespace std;

// This version of the constructor creates a dummy Variable object where the
// score does not change when the number of occurrances changes.
Event::Event(State *aStartState, State *aEndState) 
	: Arc((Node*) aStartState, (Node*) aEndState),
	Variable() {
	 
		mStartState = aStartState;
		mEndState = aEndState;
}

Event::Event(State *aStartState, State *aEndState, int aValue, int aNumScores, const double *aScores) 
	: Arc((Node*) aStartState, (Node*) aEndState),
	Variable(aValue, aNumScores, aScores) {
	 
		mStartState = aStartState;
		mEndState = aEndState;
}

bool Event::Check(
	const State *aStateFrom,
	const State *aStateTo) const {

	if (aStateFrom == mStartState && aStateTo == mEndState) {
		return true;
	} else {
		return false;
	}
}

// Avoids swaps that swap equivalent cell links so that the score is equal
// to a normal operation.
bool Event::OkSwap12(Event *aEvent) {
	if (aEvent->mStartState == mStartState) {
		return false;
	} else {
		return true;
	}
}

// Avoids swaps that swap equivalent cell links so that the score is equal
// to a normal operation.
bool Event::OkSwap21(Event *aEvent) {
	if (aEvent->mStartState == mStartState) {
		return false;
	} else {
		return true;
	}
}

// Avoids swaps that swap equivalent cell links so that the score is equal
// to a normal operation.
bool Event::OkSwap23(Event *aEvent) {
	if (aEvent->mEndState == mEndState) {
		return false;
	} else {
		return true;
	}
}

// Avoids swaps that swap equivalent cell links so that the score is equal
// to a normal operation.
bool Event::OkSwap32(Event *aEvent) {
	if (aEvent->mEndState == mEndState) {
		return false;
	} else {
		return true;
	}
}