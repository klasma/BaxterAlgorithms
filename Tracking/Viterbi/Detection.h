#ifndef DETECTION
#define DETECTION

#include <map>
#include "State.h"

class Count;
class Migration;
class Mitosis;

using namespace std;

// Detections are states associated with detected pixel regions that could contain cells.
// The detection keeps track of what cells pass through and has a Count object that keeps
// track of how the count score of the detection changes when cells are added or removed.
class Detection: public State {
public:
	typedef multimap<Detection*, Mitosis*>::iterator MitosisIterator;

	// Creates a detection object in image aT, with index aIndex. The states
	// in image t are supposed to be numbered from 0 to Mt-1, where Mt is the
	// total number of states in image t. This has to be ensured by the caller,
	// but could also be ensured by using a static member or a factory design
	// pattern. Keep in mind that there can be IdleStates in addition to the
	// Detection states.
    Detection(int aT, int aIndex);
    
	// Deletes mCount.
    virtual ~Detection();

	// Add a migration event to the detection. This does not imply that the migration takes
	// place, but that cells are allowed to perform the migration in the tracking problem.
	// The migrations are stored in a map where they can be accessed with the end Detection
	// as a key. This is done to make Mitosis events easier to create.
	void AddMigration(Migration *aMigration);

	void AddMitosis(Mitosis *aMitosis);

	// Returns a migration that starts in the current Detection and ends in aDetection,
	// if such a migration exists. If no such migration exists, the function returns NULL.
	Migration *GetMigration(Detection *aDetection);

	// Score associated with removing a CellNode from the Detection.
	virtual double GetMinusScore();

	void GetMitosis(Detection *aDetection, MitosisIterator &aFirst, MitosisIterator &aLast);

	// Score associated with adding a CellNode to the Detection.
	virtual double GetPlusScore();

	// Decreases the cell count by 1 and changes the scores apropriately.
	virtual void Minus();

	// Increases the cell count by 1 and changes the scroes apropriately.
	virtual void Plus();
    
	// Sets the cell cont event that the detection should be associated with. The detection can only be associated with
	// one cell count event.
    void SetCount(Count *aCount) { mCount = aCount; }

private:

	// Specifies the cell count and the score assoicated with it.
	// This object is created outside the detection, but destoyed in
	// its destructor.
	Count *mCount;

	// All of the migrations that start in the current detection, stored in a map
	// where the migration end detections are used as keys.
	map<Detection*, Migration*> mMigrationMap;

	multimap<Detection*, Mitosis*> mMitosisMap;
};
#endif