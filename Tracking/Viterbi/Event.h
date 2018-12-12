#ifndef EVENT
#define EVENT

#include <vector>
#include "Arc.h"
#include "Variable.h"

class CellNode;
class State;
class Tree;

// Event is a class that represents events that can occur in a cell tracking scenario.
// There are a number of States in each image that a cell can be associated with, and
// the Events represent possible transitions between the states. The class is abstarct,
// and cell events such as Migration, Mitosis and Apoptosis are sub-classes of Event.
// By inheriting from Variable, the Events can also keep track of how many times they
// have occurred and the scores associated with maknig them occur one time more or one
// time less.
class Event: public Arc, public Variable {    
public:
	// Creates an Event that has no score associated with it.
	// 
	// Inputs:
	// aStartState - The state that the event links from.
	// aEndState - The state that the event links to.
	Event(State *aStartState, State *aEndState);

	// Creates an Event that has different scores associated different occurrance counts.
	// 
	// Inputs:
	// aStartState - The state that the event links from.
	// aEndState - The state that the event links to.
	// aValue - The number of times that the event occurs when it is created.
	// aScores - The scores of the event occuring a given number of times. The first element
	// specifies the score associated with the Event occurring once.
	// aNumScores - The length of aScore.
	Event(State *aStartState, State *aEndState, int aValue, int aNumScores, const double *aScores);

	// Should add an additional occurrance of the event to the Tree aTree. aPrint specifies if
	// the parameters of the Event should be printed. This is to allow Swaps to supress the
	// printouts of other Events that they execute.
	 virtual void Execute(Tree *aTree, vector<CellNode*> *aEndCellNodes, bool aPrint = true) = 0;

	 // Adds another occurrance of the event to a cell lineage tree, by linking it to
	 // an existing CellNode associated with aEndState.
	 //
	 // Inputs:
	 // aTree - Lineage tree that will get an additional event.
	 // aCell - CellNode associated with aEndState.
	 virtual void Execute(Tree *aTree, vector<CellNode*> *aEndCellNodes, CellNode *aCell) = 0;

	State *GetEndState() { return mEndState; }

	State *GetStartState() { return mStartState; }
    
	// Checks that it is allowed to link from aStateFrom to aStateTo using the Event.
	// This is used when chains of CellNodes are created, to make sure that only valid
	// links are created.
	virtual bool Check(
		const State *aStateFrom, 
		const State *aStateTo) const;

	// Returns true if it is ok to perform a swap where the current Event is the first
	// event and aEvent is the second Event.
	// TODO: MAKE THIS FUNCTION TAKE A CELLNODE AS INPUT.
	virtual bool OkSwap12(Event *aEvent);

	virtual bool OkSwap21(Event *aEvent);

	// Returns true if it is ok to perform a swap where the current Event is the second
	// event and aEvent is the third Event.
	// TODO: MAKE THIS FUNCTION TAKE A CELLNODE AS INPUT.
	virtual bool OkSwap23(Event *aEvent);

	virtual bool OkSwap32(Event *aEvent);

protected:
	State *mEndState;		// The state linked to by the Event.
	State *mStartState;		// The state linked from by the Event.
};
#endif