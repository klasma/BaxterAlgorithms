#ifndef TRELLIS
#define TRELLIS

#include <list>
#include <vector>

class Arc;
class Node;

using namespace std;

// A graph with trellis structure. The edges (arcs) are directed and the nodes are arranged in layers. It has
// a function HighestScoringPath that uses the Viterbi algorithm to find the highest scoring path
// from the beginning of the trellis to the end. It is assumed that the arcs go from one layer to a layer
// with higher index. If this is violated, the HighestScoringPath function will not work correctly. It is
// however up to the caller to ensure that this condition is met. In the future, we would like to allow
// backward arcs and use a more general shortest-path algorithm to find the best modificaiton to the tree,
// and not just the best insertion of a new cell. The Trellis keeps track of nodes, but not the arcs.
// The nodes keep track of the arcs.
//
// Known issues:
// There will be a runtime error if there is no path from the first layer to the last layer.
class Trellis {
public:
	// Creates an empty Trellis of length aNumT with no nodes or arcs.
	Trellis(int aNumT);

	// Deletes the nodes.
	virtual ~Trellis();

	// Adds a node to layer aT.
	void AddNode(int aT, Node *aNode);

	// Returns node aN in layer aT.
	Node *GetNode(int aT, int aN);

	// Returns the number of nodes in layer aT.
	int GetNumNodes(int aT) { return (int)mNodes[aT]->size(); }

	// Finds the highest scoring path through the Trellis and writes the arcs on the path into aArcs and
	// the score of the path into aScore.
	void HighestScoringPath(list<Arc*> &aArcs, double &aScore);

protected:
	int mNumT;  // The number of layers in the trellis.

private:
	vector<vector<Node*>*> mNodes;  // Element t contains the nodes in layer t.
};
#endif