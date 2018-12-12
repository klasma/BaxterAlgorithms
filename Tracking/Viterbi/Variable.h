#ifndef VARIABLE
#define VARIABLE

#include <vector>

using namespace std;

// Variable is some kind of parameter associated with one or more States in the
// tracking problem. The Variable is usually a counter for how many times an event
// occurs, and it can be equal to any nonnegative integer. There is a score
// associated with every value, but the score does not change after value
// aNumScores-1. The scores associated with increasing or decrasing the value of
// the Variable are most interesting. All Event classes and the Count class inherits
// from Variable.
class Variable {
	// CellNode and Detection are he only classes that are allowed to call the Plus and Minus functions.
	friend class CellNode;
	friend class Detection;
public:
	// Creates a dummy Variable which always has the score 0.0.
	// TODO: MAKE THIS NICER.
	Variable();

	virtual ~Variable() { ; }

	// Creates a Variable with aNumScores predefined values found in aScores.
	// The variable starts with the value aValue.
	Variable(int aValue, int aNumScores, const double *aScores);

	// Returns the score associated with increasing the value by 1. If the value is already 
	// mNumScores-1 or more, the score does not change if it is increased further.
	virtual double GetPlusScore() const;

	// Returns the score associated with decreasing the value by 1, or 0.0 if the value is 0.
	virtual double GetMinusScore() const;

	// Increases the value by 1.
	virtual void Plus();

	// Decreases the value by 1. The value must not be 0 before the function call.
	virtual void Minus();

protected:

	int GetValue() { return mValue; }

private:
	int mValue;				// Value of the Variable. Usually the number of times that an event occurs.
	int mNumScores;			// The number of predefined scores.
	vector<double> mScore;  // Vector with scores for the Variable being equal to 0, 1,... mNumScores-1.
};
#endif