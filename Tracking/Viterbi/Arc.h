#ifndef ARC
#define ARC

class Node;

// A directed arc, with a score, between two nodes in a trellis. The class is virtual, and requires
// that the function GetScore is implemented by a sub-class.
class Arc {
public:
	// Adds an arc between the nodes aStart and aEnd
	// The constructor also adds the new arc as a forward arc from aStart and
	// as a backward arc from aEnd.
	Arc(Node* aStart, Node* aEnd);

	// Removes the arc from the arc lists of aStart and aEnd. Nodes delete all of their arcs when they are
	// deleted, but arcs never delete nodes.
	virtual ~Arc();

	// Should return the score associated with traversing the arc.
	virtual double GetScore() const = 0;

	Node *GetStartNode() { return mStart; }

	Node *GetEndNode() { return mEnd; }

private:
	Node* mStart;	// Node at the beginning of the arc.
	Node* mEnd;		// Node at the end of the arc.
};
#endif