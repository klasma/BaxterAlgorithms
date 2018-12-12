#include "Node.h"
#include <vector>
#include <assert.h>
#include "Arc.h"

Node::Node(int aIndex) : mIndex(aIndex) {}

Node::~Node() {
	// TODO: TRY TO MAKE THIS NICER.

	// When the arcs are deleted, they first remove themselves from the associated nodes.
	while (mForwardArcs.size()>0) {
		delete *mForwardArcs.begin();
	}

	// When the arcs are deleted, they first remove themselves from the associated nodes.
	while (mBackwardArcs.size()>0) {
		delete *mBackwardArcs.begin();
	}
}

void Node::AddForwardArc(Arc *aArc) {
	assert(this == aArc->GetStartNode());
	mForwardArcs.push_back(aArc);
}

void Node::AddBackwardArc(Arc *aArc) {
	assert(this == aArc->GetEndNode());
	mBackwardArcs.push_back(aArc);
}

void Node::RemoveForwardArc(Arc *aArc) {
	// Slow way of erasing an element.
	for (int i=0; i<mForwardArcs.size(); i++) {
		if (mForwardArcs[i] == aArc) {
			mForwardArcs.erase(mForwardArcs.begin()+i);
			break;
		}
	}
}

void Node::RemoveBackwardArc(Arc *aArc) {
	// Slow way of erasing an element.
	for (int i=0; i<mBackwardArcs.size(); i++) {
		if (mBackwardArcs[i] == aArc) {
			mBackwardArcs.erase(mBackwardArcs.begin()+i);
			break;
		}
	}
}