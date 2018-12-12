#include "Arc.h"
#include "Node.h"

Arc::Arc(Node *aStart, Node *aEnd) {
		mStart = aStart;
		mEnd = aEnd;
		mStart->AddForwardArc(this);
		mEnd->AddBackwardArc(this);
}

Arc::~Arc() {
	mStart->RemoveForwardArc(this);
	mEnd->RemoveBackwardArc(this);
}