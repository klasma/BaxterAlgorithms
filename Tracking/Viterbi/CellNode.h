#ifndef CELLNODE
#define CELLNODE

#include <vector>

class Event;
class Mitosis;
class State;
class Swap;
class Tree;

using namespace std;

// Nodes in the tree representation of the cell tracks. Every CellNode has a Detection or an IdleState assoicated with it and
// has a backward link (mPrevCell) and a forward link (mNextCell) to other CellNodes. mPrevCell is NULL if the CellNode is the
// beginning of a cell track and mNext is NULL if the cell is the end of a cell track. The first and the last CellNodes in a
// track are almost always associated with IdleStates before and after the first and the last detection respectively. The only
// exception is when a cell ends with a mitosis, in which case the last CellNode is the last detection before the mitosis.
// The cell also has a preceding event mPrevEvent and a following event mNextEvent that specifies how the cell got to the current
// state and how it leaves it, respectively. When a mitosis event occurs, this is indicated in the mChildren and mParent fields. A
// CellNode can be associated with only one Detection, but a detection can be assoicated with multiple CellNodes. The contstructor
// is private and can only be called form the friend class Tree. Use Tree::CreateCellFirst or Tree::CreateCellLink to create cells.
// This design choice was made to avoid bugs where CellNodes are created without being linked to a tree.
class CellNode {

	// Tree is the only class that is allowed to create CellNodes.
	friend class Tree;

public:
	// Removes the CellNode from mStates list of CellNodes. The CellNode must be
	// deleted before mState!
    ~CellNode();
    
	// Adds two CellNodes as children to the current CellNode. This assumes that the
	// child CellNodes are the second CellNodes in their chains, after idle-CellNodes.
	// The function sets all of the mParent and mChildren members correctly. The mitosis
	// counter is decreased by one, becaues it was incremented once for each cell, when
	// the child tracks were created.
	//
	// Inputs:
	// aMitosis - The mitosis event associated with the detections in the CellNodes.
	// aChild1 - The CellNode wich will be the first child.
	// aChild1 - The CellNode wich will be the second child.
    void AddChildren(Mitosis *aMitosis, CellNode *aChild1, CellNode *aChild2);

	void AddDependentSwap(Swap *aSwap);

	// Links the current CellNode to another CellNode using a particular event. This will
	// join two cell tracks together. The second track will often have only one CellNode.
	// The function also updates the counters in aEvent and aCell.
	//
	// Inputs:
	// aEvent - Event used to link the current CellNode to aCell.
	// aCell - The beginning of a cell track that will be linked to the current CellNode.
	void AddLink(Event *aEvent, CellNode *aCell);
    
	// Returns the state that the cell is associated with.
    State *GetState() { return mState; }

	// Returns the next CellNode in the cell track or NULL if there is no next CellNode.
	CellNode *GetNextCell() { return mNextCell; }

	// Returns the previous CellNode in the cell track or NULL if there is no previous CellNode.
	CellNode *GetPrevCell() { return mPrevCell; }

	// Returns the event object that specifies how the cell left its state or NULL if the CellNode is the
	// last node in a cell track, or if the cell track is under construction.
	Event *GetNextEvent() { return mNextEvent; }

	// Returns child CellNode aIndex, or NULL if there are no children.
    CellNode *GetChild(int aIndex) { return mChildren[aIndex]; }

	int GetIteration() { return mIteration; }
    
	// Returns the parent CellNode or NULL if there is no parent.
    CellNode *GetParent() { return mParent; }
    
	// Returns the event object representing how the cell ended up in mDetection or NULL if the CellNode is
	// the first node in a cell track that starts in the first image.
	Event *GetPrevEvent() { return mPrevEvent; }

    // Returns true if the CellNode is the last node of a cell that undergoes mitosis.
    bool HasChildren() const;

	// Returns false if the cell is the last CellNode in a cell track.
	bool HasNextCell() const;

	// Returns true if the CellNode is the first detection (not state) of a cell that was created through mitosis.
	bool HasParent() const;

	// Returns false if the cell is the fist CellNode in a cell track.
	bool HasPrevCell() const;

	void RemoveDependentSwaps();

	// Removes the link between the current CellNode and the next CellNode in a cell.
	// The function also updates the counters in Events and CellNodes. The function can
	// also be used to remove one of the children of a cell that undergoes mitosis, and
	// and link the other child with a migration instead.
	//
	// Inputs:
	// aTree - Tree in which the link will be removed.
	// aCell - CellNode to which the link will be broken. This input only matters when a
	// child is removed.  TODO: UPDATE COMMENT.
	void RemoveLink(Tree *aTree);

private:
	int mIteration;				// The iteration in which the cell was created.
	State *mState;				// Detection or IdleState which is associated with the CellNode.
	CellNode *mNextCell;		// Next CellNodes in a cell track.
	CellNode *mPrevCell;		// Previous CellNode in a cell track.
	CellNode *mParent;			// Parent CellNode of a CellNode created through mitosis.
	CellNode *mChildren[2];		// The two child CellNodes of a CellNode that undergoes mitosis.
	Event *mNextEvent;			// Event representing how the cell left mDetection.
	Event *mPrevEvent;			// Event representing how the cell ended up in mDetection.
	vector<Swap*> mDependentSwaps;

	// Creates a CellNode associated with the State aDetection. The constructor
	// also adds the CellNode to the list of CellNodes in aDetection. Can only be called by Tree.
	//
	// Inputs:
	// aState - Detection or IdleState that the CellNode will be associated with.
	// aIteration - Iteration in which the cell was created.
	CellNode(State *aState, int aIteration);

	// Removes the children of a CellNode, sets all members of the parent CellNode and the Children
	// correctly and updates the counters in the States and the Events.
	//
	// Inputs:
	// aTree - Tree that the current CellNode is a part of.
	void RemoveChildren(Tree *aTree);
};
#endif