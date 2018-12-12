#include "CellTrellis.h"
#include <assert.h>
#include <cstddef>  // To get NULL.
#include <limits>
#include <list>
#include <vector>
#include "Apoptosis.h"
#include "Appearance.h"
#include "Arc.h"
#include "CellNode.h"
#include "Count.h"
#include "Detection.h"
#include "Disappearance.h"
#include "Event.h"
#include "FreeArc.h"
#include "FreeArcNoSwap.h"
#include "IdleState.h"
#include "LogStream.h"
#include "Migration.h"
#include "Mitosis.h"
#include "Node.h"
#include "Persist.h"
#include "Preexist.h"
#include "Tree.h"
#include "Trellis.h"
#include "Swap.h"

using namespace std;

// First the detections are generated and then all Event objects are added to them. The event
// objects hold the probabilities for different events, and also serve as arcs in the trellis.
CellTrellis::CellTrellis(bool singleIdleState, int aNumT, int aMaxCount, int aNumMigs, int aNumMits, int aNumApos, int aNumAppear, int aNumDisappear, double *aNumTDets,
	double *aCountA, double *aMigA, double *aMitA, double *aApoA, double *aAppearA, double *aDisappearA, double aMaxMigScore) 
	: Trellis(aNumT + 2), mSingleIdleState(singleIdleState) {

		mTree = new Tree(aNumT);

		int numDets = 0;  // Total number of detections.
		for (int t=0; t<aNumT; t++) {
			numDets += (int) aNumTDets[t];
		}

		mStartState = new IdleState(0,0);
		mEndState = new IdleState(aNumT+1,0);

		// Detections.
		for (int t=0; t<aNumT; t++) {
			mDetections.push_back(new vector<Detection*>());
			for (int d=0;d<aNumTDets[t];d++) {
				mDetections[t]->push_back(new Detection(t+1,d));
			}
		}
		// Add count objects to detections.
		double *tmpCountProbs = new double[aMaxCount+1];
		for (int d=0; d<numDets; d++) {
			int t = (int) aCountA[d] - 1;
			int det = (int) aCountA[numDets+d] - 1;
			for (int cnt=0; cnt<aMaxCount+1; cnt++) {
				tmpCountProbs[cnt] = aCountA[(2+cnt)*numDets+d];
			}
			Count *tmpCount = new Count(0,  aMaxCount+1, tmpCountProbs); // Deleted by Detection.
			mDetections[t]->at(det)->SetCount(tmpCount);
		}
		delete[] tmpCountProbs;

		if (mSingleIdleState) {
			for (int t=0; t<aNumT; t++) {
				mIdleStates.push_back(new IdleState(t+1,(int)aNumTDets[t]));
			}
		} else {
			// Idle states for mitosis.
			for (int t=0; t<aNumT; t++) {
				mBornLaterStates.push_back(new IdleState(t+1,(int)aNumTDets[t]));
			}

			// Idle states for apoptosis.
			for (int t=0; t<aNumT; t++) {
				mDeadStates.push_back(new IdleState(t+1,(int)aNumTDets[t]+1));
			}
		}

		// Create nodes in the super class Trellis.
		AddNode(0, mStartState);
		for (int t=0; t<aNumT; t++) {
			for (int d=0;d<aNumTDets[t];d++) {
				AddNode(t+1, mDetections[t]->at(d));
			}
			if (mSingleIdleState) {
				AddNode(t+1, mIdleStates[t]);
			} else {
				AddNode(t+1, mBornLaterStates[t]);
				AddNode(t+1, mDeadStates[t]);
			}
		}
		AddNode(aNumT+1, mEndState);

		// Add preexist arcs to all detections in the first frame, to the starting state.
		for ( int d=0; d<aNumTDets[0]; d++) {
			new Preexist(mStartState, mDetections[0]->at(d));  // Deleted by State.
		}

		// Add persist arcs from all detections in the last frame.
		for ( int d=0; d<aNumTDets[aNumT-1]; d++) {
			new Persist(mDetections[aNumT-1]->at(d), mEndState);  // Deleted by State.
		}

		// Add apoptosis arcs.
		for (int d=0; d<aNumApos; d++) {
			int t = (int) aApoA[d] - 1;
			int det = (int) aApoA[aNumApos+d] - 1;
			double apoProbs[2];
			apoProbs[0] = aApoA[2*aNumApos+d];
			apoProbs[1] = aApoA[3*aNumApos+d];

			IdleState *toState = NULL;
			if (mSingleIdleState) {
				toState = mIdleStates[t+1];
			} else {
				toState = mDeadStates[t+1];
			}

			new Apoptosis(mDetections[t]->at(det), toState, 0 , 2 , apoProbs);  // Deleted by State.
		}

		// Add mitosis arcs.
		for (int d=0; d<aNumMits; d++) {
			int t = (int) aMitA[d] - 1;
			int detParent = (int) aMitA[aNumMits+d] - 1;
			int detChild1 = (int) aMitA[2*aNumMits+d] - 1;
			int detChild2 = (int) aMitA[3*aNumMits+d] - 1;
			double mitProbs[2];
			mitProbs[0] = aMitA[4*aNumMits+d];
			mitProbs[1] = aMitA[5*aNumMits+d];

			IdleState *fromState = NULL;
			if (mSingleIdleState) {
				fromState = mIdleStates[t];
			} else {
				fromState = mBornLaterStates[t];
			}
			
			// There are two copies of all mitosis events. They link to different daughther cell detections.
			Mitosis *mit = new Mitosis(fromState, mDetections[t+1]->at(detChild1), mDetections[t]->at(detParent), mDetections[t+1]->at(detChild2), 0, 2, mitProbs);  // Deleted by State.
			Mitosis *mitMirror = new Mitosis(fromState, mDetections[t+1]->at(detChild2), mDetections[t]->at(detParent), mDetections[t+1]->at(detChild1), 0, 2, mitProbs);  // Deleted by State.
			mit->LinkMirror(mitMirror);
		}

		// Add migration arcs.
		for ( int d=0; d<aNumMigs; d++) {
			int t = (int) aMigA[d] - 1;
			int det1 = (int) aMigA[aNumMigs+d] - 1;
			int det2 = (int) aMigA[2*aNumMigs+d] - 1;
			double migProbs[2];
			migProbs[0] = aMigA[3*aNumMigs+d];
			migProbs[1] = aMigA[4*aNumMigs+d];
			new Migration(mDetections[t]->at(det1), mDetections[t+1]->at(det2), 0, 2, migProbs, aMaxMigScore);  // Deleted by State.
		}
        
		// Add appearance arcs.
		// TODO: MAKE SURE THAT NO CELLS ARE SET TO APPEAR IN THE FIRST IMAGE.
		for ( int d=0; d<aNumAppear; d++) {
			int t = (int) aAppearA[d] - 1;
			int det = (int) aAppearA[aNumAppear+d] - 1;
			double appearProbs[2];
			appearProbs[0] = aAppearA[2*aNumAppear+d];
			appearProbs[1] = aAppearA[3*aNumAppear+d];
			
			IdleState *fromState = NULL;
			if (mSingleIdleState) {
				fromState = mIdleStates[t-1];
			} else {
				fromState = mBornLaterStates[t-1];
			}
			
			new Appearance(fromState, mDetections[t]->at(det), 0, 2, appearProbs);  // Deleted by State.
		}
        
		// Add disappearance arcs.
		for ( int d=0; d<aNumDisappear; d++) {
			int t = (int) aDisappearA[d] - 1;
			int det = (int) aDisappearA[aNumDisappear+d] - 1;
			double disappearProbs[2];
			disappearProbs[0] = aDisappearA[2*aNumDisappear+d];
			disappearProbs[1] = aDisappearA[3*aNumDisappear+d];

			IdleState *toState = NULL;
			if (mSingleIdleState) {
				toState = mIdleStates[t+1];
			} else {
				toState = mDeadStates[t+1];
			}

			new Disappearance(mDetections[t]->at(det), toState, 0, 2, disappearProbs);  // Deleted by State.
		}

		// Free arcs that don't represent cell events. All FreeArcs are deleted by State.
		if (mSingleIdleState) {
			new FreeArcNoSwap(mStartState, mIdleStates[0]);
			for (int t=0; t<aNumT-1; t++) {
				new FreeArc(mIdleStates[t], mIdleStates[t+1]);
			}
			new FreeArcNoSwap(mIdleStates[aNumT-1], mEndState);
		}
		else {
			new FreeArcNoSwap(mStartState, mBornLaterStates[0]);
			new FreeArcNoSwap(mStartState, mDeadStates[0]);
			for (int t=0; t<aNumT-1; t++) {
				new FreeArcNoSwap(mBornLaterStates[t], mBornLaterStates[t+1]);
				new FreeArcNoSwap(mDeadStates[t], mDeadStates[t+1]);
				new FreeArc(mBornLaterStates[t], mDeadStates[t+1]);  // Allows swaps with IdleStates.
			}
			new FreeArcNoSwap(mBornLaterStates[aNumT-1], mEndState);
			new FreeArcNoSwap(mDeadStates[aNumT-1], mEndState);
		}
		// Adds swap arcs.
		// AddSwaps();
}

// The nodes are deleted by Trellis, and the arcs are deleted by the nodes.
CellTrellis::~CellTrellis() {
	delete mTree;  // Must be destoryed before the states.

	// All of the states are destroyed by ~Trellis().

	//for (int t=0; t<(int)mDetections.size(); t++) {
	//	for (int d=0; d<(int)mDetections[t]->size(); d++) {
	//		delete mDetections[t]->at(d);
	//	}
	//	delete mDetections[t];
	//	delete mBornLaterStates[t];
	//	delete mDeadStates[t];
	//}
}

// Known issues:
// It would be nice if only the swap events that are effected by the creation
// of a new cell could be replaced.
int CellTrellis::AddCell() {
	// Adds a singe cell to the mTree if that increases the score.

	list<Arc*> sPath;
	double score;
	HighestScoringPath(sPath, score);

	vector<CellNode*> newCells;

	if (score > 0) {
		for (list<Arc*>::iterator lIt = sPath.begin(); lIt!=sPath.end() ; ++lIt) { // THE ARCS HAVE TO BE CONVERTED BACK TO OPERATIONARCS
			((Event*) *lIt)->Execute(mTree, &newCells); // MAYBE EXECUTE SHOULD TAKE THE TREE AS AN INPUT.
		}
		lout << "The tree has " << setw(0) <<  mTree->GetNumCells() << " cells." << endl;
		lout << endl;  // Separate output from different iterations.

		// Replace the swap events.
		// RemoveSwaps();
		// AddSwaps();

		//for (int i=0; i<(int)newCells.size(); i++) {
		//	if (newCells[i] == NULL) {
		//		// FreeArc.
		//		continue;
		//	}

		//	AddSwaps(newCells[i]);
		//	if (i < newCells.size()-1 && newCells[i+1] != newCells[i]->GetNextCell()) {
		//		AddSwaps(newCells[i]->GetNextCell());
		//	}

		//	//if (i==0 || newCells[i-1] != newCells[i]->GetPrevCell()) {
		//	//	AddSwaps(newCells[i]->GetPrevCell());
		//	//}
		//	//if (i < newCells.size()-1) {
		//	//	AddSwaps(newCells[i]);
		//	//}
		//}

		//list<Arc*> sPath2;
		//double score2;
		//HighestScoringPath(sPath2, score2);

		for (int i=0; i<(int)newCells.size(); i++) {
			newCells[i]->RemoveDependentSwaps();
			if (!newCells[i]->HasNextCell() && !newCells[i]->HasPrevCell()) {
				// This CellNode was left after a swap that started with a FreeArc.
				delete newCells[i];
			} else {
				AddSwaps(newCells[i]);
			}
		}

		//list<Arc*> sPath3;
		//double score3;
		//HighestScoringPath(sPath3, score3);

		//for (int i=0; i<(int)newCells.size(); i++) {
		//	AddSwaps(newCells[i]);
		//}

		//list<Arc*> sPath4;
		//double score4;
		//HighestScoringPath(sPath4, score4);

		return 1;
	} else {
		return 0;
	}
}

//// The function adds all swap arcs to the Trellis. To construct the Swaps, we need to find
//// sequences of 3 Events, where the first Event (ev1) and the second Event end in
//// the same State (state1) and the second Event and the third Event (ev3) start in the same State.
//// In addition to this, the second event must be the mPrevEvent member of a CellNode object.
//// To find all such triplets of Events, we take a node and look at all forward Arcs (Events).
//// Then we look for CellNodes associated with the end node of the arcs, find the previous state
//// that the Cell was associated with and look at all forward arcs associated with that state.
//// The swap arcs are created between the start State of the first Event and the end State of
//// the last event.
////
//// Known issues:
//// Some swaps where state3 == state1 or state4 == state2 could be allowed.
//void CellTrellis::AddSwaps() {
//	// Vectors to pointers that will be used to create the swaps.
//	vector<CellNode*> cells;
//	vector<Event*> events1;
//	vector<Event*> events3;
//
//	for (int t=1; t<mNumT-2; t++) {
//		for (int n=0; n<GetNumNodes(t); n++) {
//			State *state1 = (State*) GetNode(t, n);
//			for (Node::ArcIterator a1=state1->GetBeginForwardArc(); a1<state1->GetEndForwardArc(); ++a1) {
//				Event *ev1 = (Event*) *a1;
//				State *state2 = ev1->GetEndState();
//				for (State::CellIterator c=state2->GetBeginCell(); c<state2->GetEndCell(); ++c) {
//					CellNode *cell = *c;
//					if (!cell->HasPrevCell()) {
//						// There must be a cell event to replace.
//						continue;
//					}
//					Event *ev2 = cell->GetPrevEvent();
//					State *state3 = cell->GetPrevCell()->GetState();
//					if (!ev1->OkSwap12(ev2)) {
//						// Avoids score errors when the same event is both added and removed.
//						// Also avoids adding a mitosis and then trying to remove the migration
//						// that was replaced by mitosis.
//						continue;
//					}
//					for (Node::ArcIterator a2=state3->GetBeginForwardArc(); a2<state3->GetEndForwardArc(); ++a2) {
//						Event *ev3 = (Event*) *a2;
//						State *state4 = ev3->GetEndState();
//						if (!ev2->OkSwap23(ev3)) {
//							// Avoids score errors when the same event is both removed and added.
//							// Also avoids removing a migration and then trying to add a mitosis
//							// that requires the mitosis to be present.
//							continue;
//						}
//						// The swaps can not be added here, because that would make the iterator a1 invalid.
//						cells.push_back(cell);
//						events1.push_back(ev1);
//						events3.push_back(ev3);
//					}
//				}
//			}
//		}
//	}
//
//	// Add the swaps.
//	for (int i=0; i<(int)cells.size(); i++) {
//		Swap *swap = new Swap(cells[i], events1[i], events3[i]);
//		mSwaps.push_back(swap);
//	}
//}

void CellTrellis::AddSwaps(CellNode *aCell) {
	assert(aCell->HasPrevCell());

	State *startState = aCell->GetPrevCell()->GetState();
	State *endState = aCell->GetState();
	Event *ev2 = aCell->GetPrevEvent();

	vector<Event*> events1;
	vector<Event*> events3;

	for (int i=0; i<endState->GetNumBackwardArcs(); i++) {
		Event *ev1 = (Event*) endState->GetBackwardArc(i);
		if (!ev1->OkSwap12(ev2) || !ev2->OkSwap21(ev1)) {
			// Avoids score errors when the same event is both added and removed.
			// Also avoids adding a mitosis and then trying to remove the migration
			// that was replaced by mitosis. Both tests must be done,
				// as the class of the argument to OkSwap12 is never tested.
			continue;
		}
		for (int j=0; j<startState->GetNumForwardArcs(); j++) {
			Event *ev3 = (Event*) startState->GetForwardArc(j);
			if (!ev2->OkSwap23(ev3)  || !ev3->OkSwap32(ev2)) {
				// Avoids score errors when the same event is both removed and added.
				// Also avoids removing a migration and then trying to add a mitosis
				// that requires the mitosis to be present. Both tests must be done,
				// as the class of the argument to OkSwap23 is never tested.
				continue;
			}
			events1.push_back(ev1);
			events3.push_back(ev3);
		}
	}

	// Add the swaps.
	for (int i=0; i<(int)events1.size(); i++) {
		Swap *swap = new Swap(aCell, events1[i], events3[i]);
		if (aCell->GetState()->GetIndex() == 1 && events1[i]->GetEndState()->GetIndex() == 3) {
			bool test = 1;
		}
	}
}

//void CellTrellis::RemoveSwaps() {
//	for (int i=0; i<(int)mSwaps.size(); i++) {
//		delete mSwaps[i];
//	}
//	mSwaps.clear();
//}