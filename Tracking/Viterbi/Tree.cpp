#include "Tree.h"
#include <cstddef>  // To get NULL.
#include <map>
#include <stdio.h>
#include <assert.h>
#include "Apoptosis.h"
#include "CellNode.h"
#include "Event.h"
#include "LogStream.h"
#include "State.h"

using namespace std;

Tree::Tree(int aNumT) : mNumT(aNumT), mIteration(1) {
	mActiveCell = NULL;
}

// The CellNodes have to be deleted first, because they remove themselves
// from the cell lists in the detections that they move through.
Tree::~Tree() {
	for (int i=0; i<(int)mFirstCells.size(); i++) {
		CellNode *delCell = mFirstCells[i];
		while (delCell->HasNextCell()) {
			delCell = delCell->GetNextCell();
			delete delCell->GetPrevCell();
		}
		delete delCell;
	}
}

CellNode *Tree::CreateCellFirst(IdleState *aState) {
	CellNode *cell = new CellNode((State*) aState, mIteration);  // Deleted in destructor.
	mFirstCells.push_back(cell);
	mActiveCell = cell;
	return cell;
}

CellNode *Tree::CreateCellLink(CellNode *aLinkCell, Event *aEvent) {
	CellNode *newCell = new CellNode(aEvent->GetEndState(), mIteration);  // Deleted in destructor.
	aLinkCell->AddLink(aEvent, newCell);
	mActiveCell = newCell;
	return newCell;
}

// Writes the Tree information directly into the memory of Matlab variables.
void Tree::GetCells(double *aCellA, double *aDivA, double *aDeathA) {

	// Create a map from CellNodes in mFirstCells pointers to the index they have in mFirstCells.
	map<CellNode*,int> cellIndices;
	int mapIndex = 0;  // Iteration of the iterator.
	for (Tree::CellIterator cIt = GetBeginFirstCell(); cIt!=GetEndFirstCell(); ++cIt) {
		cellIndices[*cIt] = mapIndex;
		mapIndex++;
	}

	// Fill the matrices with -1 or 0.
	for (int t=0; t<mNumT; t++) {
		for (int c=0; c<GetNumCells(); c++) {
			aCellA[c*mNumT+t] = 0.0;
		}
	}
	for (int c=0; c<GetNumCells(); c++) {
		for (int i=0; i<2; i++) {
			aDivA[i*GetNumCells()+c] = 0.0;
		}
	}
    for (int c=0; c<GetNumCells(); c++) {
        aDeathA[c] = 0.0;
    }

	int cIndex = 0;
	for (Tree::CellIterator cIt = GetBeginFirstCell(); cIt!=GetEndFirstCell(); ++cIt) {
		CellNode *cell = *cIt;

		cell = cell->GetNextCell();  // The first CellNode is an IdleState.

		// Write track to aCellA.
		while (true) {
			State*state = cell->GetState();
			aCellA[cIndex*mNumT + state->GetT()-1] = double(state->GetIndex()) + 1.0;
			
			// Move to the next CellNode in the Cell unless we have reached the end.
			// Don't include the IdleState that end all cells except the dividing ones.
			CellNode *nextCell = cell->GetNextCell();
			if (cell->HasChildren() || (!nextCell->HasNextCell() && !nextCell->HasChildren())) {
				break;
			}
			cell = nextCell;
		}

		// Write Mitosis information to aDivA.
		if (cell->HasChildren()) {
			CellNode *cell1 = cell->GetChild(0);
			CellNode *cell2 = cell->GetChild(1);
			aDivA[cIndex] = double(cellIndices[cell1->GetPrevCell()]) + 1.0;
			aDivA[GetNumCells()+cIndex] = double(cellIndices[cell2->GetPrevCell()]) + 1.0;
		}
        
        // Write a 1 to aDeathA if the cell dies.
        if ( dynamic_cast<Apoptosis*> (cell->GetNextEvent()) != NULL ) {
            aDeathA[cIndex] = 1.0;
        } 

		cIndex++;
	}
}

void Tree::GetIterations(double *aIterationA) {

	// Fill the matrix with -1.
	for (int t=0; t<mNumT; t++) {
		for (int c=0; c<GetNumCells(); c++) {
			aIterationA[c*mNumT+t] = -1.0;
		}
	}

	int cIndex = 0;
	for (Tree::CellIterator cIt = GetBeginFirstCell(); cIt!=GetEndFirstCell(); ++cIt) {
		CellNode *cell = *cIt;

		cell = cell->GetNextCell();  // The first CellNode is an IdleState.

		// Write track to aIterationA.
		while (true) {
			State*state = cell->GetState();
			aIterationA[cIndex*mNumT + state->GetT()-1] = (double) cell->GetIteration();
			
			// Move to the next CellNode in the Cell unless we have reached the end.
			// Don't include the IdleState that end all cells except the dividing ones.
			CellNode *nextCell = cell->GetNextCell();
			if (cell->HasChildren() || (!nextCell->HasNextCell() && !nextCell->HasChildren())) {
				break;
			}
			cell = nextCell;
		}

		cIndex++;
	}
}

void Tree::Print(){
	double *cellMat = new double[mNumT * GetNumCells()];  // Deleted at end of fuction.
	double *divMat = new double[GetNumCells()*3];  // Deleted at end of fuction.
    double *deathMat = new double[GetNumCells()];  // Deleted at end of fuction.
	GetCells(cellMat, divMat, deathMat);

	lout << "\nCell matrix:" << endl;
	for (int t=0; t<mNumT; t++) {
		for (int cIndex=0; cIndex<GetNumCells(); cIndex++) {
			lout << setw(3) << setfill(' ') << (int) cellMat[cIndex*mNumT+t] << " ";
		}
		lout << endl;
	}

	lout << endl << "Mitosis matrix:" << endl;
	for (int cIndex=0; cIndex<GetNumCells(); cIndex++) {
		for (int i=0; i<2; i++) {
			lout << setw(3) << setfill(' ') << (int) divMat[i*GetNumCells()+cIndex] << " ";
		}
		lout << endl;
	}
    
    lout << endl << "Apoptosis matrix:" << endl;
	for (int cIndex=0; cIndex<GetNumCells(); cIndex++) {
        lout << (int) deathMat[cIndex] << endl;
	}

	delete[] cellMat;
	delete[] divMat;
    delete[] deathMat;
}

void Tree::RemoveFirstCell(CellNode* aCell){
	// Slow way of erasing an element.
	for (int i=0; i<(int)mFirstCells.size(); i++){
		if (mFirstCells[i] == aCell) {
			mFirstCells.erase(mFirstCells.begin()+i);
			delete aCell;
			return;
		}
	}
	assert(false);
}