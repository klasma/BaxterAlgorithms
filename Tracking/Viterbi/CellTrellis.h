#ifndef CELLTRELLIS
#define CELLTRELLIS

#include <vector>
#include "IdleState.h"
#include "Trellis.h"

class CellNode;
class Detection;
class Swap;
class Tree;

using namespace std;

// Class that represents the search trellis used for finding the optimal way of adding
// a cell to a preexisting lineage tree.
//
// The cell trellis has nodes that represent states that the cell can be in in different
// images. There is one state for every detection in the image seqeunce. There is also
// born-later states, indicating that the cell will enter the sequence later as the result
// of a mitotic event, or some other event. And there are dead states, indicating that the cell has
// died. In addition to these states, there is also a starting state before the first
// image, and an end state after the last image. The arcs in the trellis are Events that can occur
// in the cell tracks, and that can be executed to add the Events to a Tree. The optimal way
// of adding a single cell is found by finding the highest scoring path throgh the trellis, and
// executing the Events associated with the arcs on the optimal path adds the cell to the
// tree. Calling AddCell in a loop until it returns 0 finds an (approximate) solution to the
// tracking problem. Observe that the super-class Trellis has two more levels than there are
// images in the image sequence, because there is a start state and an end state. This means that
// mNumT is aNumT+2. In the future, we might combine the born-later states and the dead states
// into idle-states.

class CellTrellis : public Trellis {
    
public:
	// Creates an empty tree and the corresponding CellTrellis. The Tree will be changed when AddCell is called.
	//
	// Inputs:
	// aNumT - The number of images in the image sequence.
	// aMaxCount - The maximum number of cells that can be added to a detection before the cost of adding more
	// Cells becomes 0.
	// aNumMigs - The total number of possible migration events.
	// aNumMits - The total number of possible mitosis events.
	// aNumApos - The total number of possible apoptosis events.
	// aNumAppear - The total number of possible appearance events.
	// aNumDisappear - The total number of disappearance events.
	// aNumTDets - Array of length aNumT, with the number of detections in each image.
	//
	// The following inputs are double arrys taken directly from matlab variables. The variables have 2 dimensions and
	// represent scores associated with different cell events, such as migration and apoptosis. The
	// elements are ordered in the same way as the elements in a vector created by executing
	// matrix(:) in Matlab. The first dimension represents the different events and the second dimension contains the information
	// [t d1 d2 s0 s1... sN], where t is the image number, d1 is the index of a detection in
	// image t and d2, which is only included for some variables is a detecion in image t+1
	// s0 s1... sN are the scores associated with different realizations of the event.
	//
	// aCountA - Scores associated with different cell counts in detections. The second dimension is
	// [t d1 s0... sN], where s0 to sN are the scores associated with different cell counts.
	// aMigA - Migration scores. The second dimension is [t d1 d2 s0 s1], where s0 is the score of no migration
	// and s1 is the score of migration.
	// aMitA - Mitosis scores. The second dimension is [t d1 d2 s0 s1], where s0 is the score of no mitosis
	// and s1 is the score of mitosis.
	// aApoA - Apoptosis scores. The second dimension is [t d1 s0 s1], where s0 is the score of no apoptosis
	// and s1 is the score of apoptosis.
	// aAppearA - Appearance scores. The second dimension is [t d1 s0 s1], where s0 is the score of no appearance
	// and s1 is the score of appearance.
	// aDisappearA - Disappearance scores. The second dimension is [t d1 s0 s1], where s0 is the score of no disappearance
	// and s1 is the score of disappearance.
	CellTrellis(bool aSingleIdleState, int aNumT, int aMaxCount, int aNumMigs, int aNumMits, int aNumApos, int aNumAppear, int aNumDisappear,
	double *aNumTDets, double *aCountA, double *aMigA, double *aMitA, double *aApoA, double *aAppearA, double *aDisappearA, double aMaxMigScore);

	virtual ~CellTrellis();

	// Adds a cell to the lineage tree in an optimal way, if that increases the score of the lineage
	// Tree. The method returns 1 if a cell was added and 0 otherwise. The tracking problem is solved
	// by calling this function until it returns 0.
	int AddCell();
    
	// Returns a pointer to the Tree that AddCell has added cell to.
	Tree *GetTree() { return mTree; }

private:
	bool mSingleIdleState;

	// The lineage tree that keeps track of previously added cells. Can not be a
	// member object, because the Tree has to be destoyed before the States.
	Tree *mTree;
	
	// Starting state at depth 0 in the trellis. Can not be member objects because
	// Trellis will try to destroy it after they have gone out of scope.
	IdleState *mStartState;
	
	// End state at depth aNumT+1 in the trellis. Can not be member objects because
	// Trellis will try to destroy it after they have gone out of scope.
	IdleState *mEndState;							
	
	// States associated with detections.
	vector<vector<Detection*>*> mDetections;

    // States indicating that the cell is not born yet. These states are put after the detection states in
	// the super class Trellis. Introduced temporarily to make the code agree with old code.
	vector<IdleState*> mBornLaterStates; 

	// States indicating that the cell is dead. These states are put after the mBornLaterSates in the super
	// class Trellis.Introduced temporarily to make the code agree with old code.
    vector<IdleState*> mDeadStates;

	// A vector of all the swap events in the CellTrellis. At the moment, these
	// have to be replaced in every new call to AddCell.
	vector<Swap*> mSwaps;							

	vector<IdleState*> mIdleStates;						// States indicating that the cell is not present in a particular image.

	void AddSwaps(CellNode *aCell);

	//// Adds new swap events to the CellTrellis.
	//void AddSwaps();

	//// Removes all swap events from the CellTrellis.
	//void RemoveSwaps();
};

#endif