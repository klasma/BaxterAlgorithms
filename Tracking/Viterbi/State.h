#ifndef STATE
#define STATE

#include <vector>
#include "Node.h"

class CellNode;
class Event;

using namespace std;

// State in a CellTrellis, linked to other States by Events.
class State: public Node {

	// CellNode is made a friend class so that no other class can execute the Plus and Minus fuctions.
	friend class CellNode;

public:
	// Iterator types returned by get-methods.
	typedef vector<CellNode*>::iterator CellIterator;

	// Creates a state object in image aT, with index aIndex. The states
	// in image t are supposed to be numbered from 0 to Mt-1, where Mt is the
	// total number of states in image t. This has to be ensured by the caller,
	// but could also be ensured by using a static member or a factory design
	// pattern.
    State(int aT, int aIndex);
    
	// CellNodes must be deteted before their states!
    virtual ~State();

	// Adds a cell to the detection. A detection can have many cells passing through it.
	void AddCell(CellNode *aCell);

	// Returns an iterator to the first CellNode associated with the detection.
	State::CellIterator GetBeginCell() { return mCells.begin(); }

	// Returns an iterator to the position after the last CellNode associated with the detection.
	State::CellIterator GetEndCell() { return mCells.end(); }

	// Returns the number of cells currently assoicated with the detection.
	int GetNumCells() const { return (int) mCells.size(); }

	// The score of going through the State one time less. (NOT USED)
	virtual double GetMinusScore() { return 0.0; }

	// The score of going through the state one more time.
	virtual double GetPlusScore() { return 0.0; }

	// Returns the index of the image that the detection occurs in.
	int GetT() const { return mT; }

	// Removes aCell from the list of CellNodes assoicated with the detection. NOT CURRENTLY USED.
	void RemoveCell(CellNode *aCell);
    
protected:
	// The cells associated with the detection.
	vector<CellNode*> mCells;

	// Index of the image in which the detection occurs.
	int mT;

	// Updates counters to reflect that the algorithm goes throught the state one time less. (NOT USED)
	virtual void Minus() { ; }

	// Updates counters to reflect that the algorithm goes throught the state one mote time.
	virtual void Plus() { ; }
};
#endif