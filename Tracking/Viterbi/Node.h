#ifndef NODE
#define NODE

#include <vector>

class Arc;

using namespace std;

// Node class for nodes in a Trellis.
class Node{
public:
	// Creates a node with index mIndex. The index should be the index of the node in
	// a container.
    explicit Node(int aIndex);
    
	// Deletes all arcs that go in and out of the node. This in turn will delete the
	// arcs from the arc lists of all nodes that they occur in.
    virtual ~Node();

	Arc *GetForwardArc(int aIndex) { return mForwardArcs[aIndex]; }

	// Returns the index of the node.
	int GetIndex() const { return mIndex; }
    
	Arc *GetBackwardArc(int aIndex) { return mBackwardArcs[aIndex]; }

	// Returns the number of arcs that start in the node.
	int GetNumForwardArcs() const { return (int) mForwardArcs.size(); }
    
	// Returns the number of arcs that end in the node.
	int GetNumBackwardArcs() const { return (int) mBackwardArcs.size(); }

	// Adds a forward arc to the node. An assertion fails if the starting point of the arc
	// is not this node.
    void AddForwardArc(Arc *aArc);
    
	// Adds a backward arc to the node. An assertion fails if the end point of the arc
	// is not this node.
    void AddBackwardArc(Arc *aArc);

	// Removes aArc from the set of forward arc from the node.
	void RemoveForwardArc(Arc *aArc);

	// Removes aArc from the set of backward arcs from the node.
	void RemoveBackwardArc(Arc *aArc);

private:
	int mIndex;						// Index of the node in some container.
	vector<Arc*> mForwardArcs;		// Arcs that start in the node.
	vector<Arc*> mBackwardArcs;		// Arcs that end in the node.
};
#endif