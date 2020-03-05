% Computes C. elegans settings for a shorter second challenge sequence.
%
% In CTC V, the second challenge sequence in the C. elegans data has been
% shortened from 190 to 140 frames. Some of the settings in the C. elegans
% dataset vary linearly with the frame index. To get the same settings in
% the frames of the shorter sequence, the settings of the last frame have
% to be changed. The new settings are computed by using linear
% interpolation to get the settings in frame 140 of the old data.

n = 190;  % Old length
aFrame = 140;  % New length

% Old settings in first and last frame.
aHighStd = [20 12];
aLowStd = [15 8];
aTrackXSpeedStd = [30 6];
aTrackZSpeedStd = [15 3];

% Compute new settings in last frame.
highStd_newMax =        aHighStd(1)         * (n-aFrame) / (n-1) + aHighStd(2)          * (aFrame-1) / (n-1)
lowStd_newMax =         aLowStd(1)          * (n-aFrame) / (n-1) + aLowStd(2)           * (aFrame-1) / (n-1)
trackXSpeedStd_newMax = aTrackXSpeedStd(1)  * (n-aFrame) / (n-1) + aTrackXSpeedStd(2)   * (aFrame-1) / (n-1)
trackZSpeedStd_newMax = aTrackZSpeedStd(1)  * (n-aFrame) / (n-1) + aTrackZSpeedStd(2)   * (aFrame-1) / (n-1)

% Verify that the settings in frame 100 are the same for the long and the
% short sequences.
test1 = aHighStd(1)  * (n-100) / (n-1) + aHighStd(2)   * (100-1) / (n-1)
test2 = aHighStd(1)  * (aFrame-100) / (aFrame-1) + highStd_newMax   * (100-1) / (aFrame-1)