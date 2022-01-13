The Baxter Algorithms is a software package for tracking and analysis of cells in microscope images. The software can handle images produced using both 2D transmission microscopy and 2D or 3D fluorescence microscopy. In addition to cell tracking, the Baxter Algorithms can perform automated analysis of myoblast fusion and automated analysis of fluorescent histological sections of muscle tissue.

The software has shown excellent performance compared to other software in the ISBI Cell Tracking Challenges of 2013, 2014, 2015, 2019, 2020 and 2021 (http://celltrackingchallenge.net). The source code submitted to the cell tracking challenges of 2020 and 2021 can be found in the branches ctc2020 and ctc2021 respectively. The branches have some improvements for processing of large datasets, handling of multiple settings files and training of segmentation parameters. Use these branches if you want to reproduce the results from the cell tracking challenges or if you are having problems processing huge datasets or if you really want the latest segmentation optimization code. In the future, ctc2020 and ctc2021 will be merged into the master branch (but not deleted).

The software has been designed to work on Windows, Mac and Linux. Most of the testing has however been done on Windows.

The software is written in MATLAB, but it also contains some algorithms written in C++, which are compiled into mex-files.

The software is started by running the file BaxterAlgorithms.m in MATLAB. For users without a MATLAB license, it is also possible to download deployed versions for 64-bit Windows and 64-bit Mac by pressing the release tab and expanding the assets dropdown under the latest release.

To run the software in MATLAB, you need the toolboxes for Image Processing, Optimization, Parallel Computing, and Statistics and Machine Learning.

The software has been tested with MATLAB 2019b. Later versions should work too, but it cannot be guaranteed.

Further instructions on how to use the software can be found in UserGuide.pdf, which is located in the folder UserGuide. There are also video tutorials in the YouTube playlist https://tinyurl.com/ba-tutorials.



The file RunBaxterAlgorithms_ISBI_2021.m can be used to reproduce the results in the ISBI Cell Tracking Challenge 2021. The bat-files with names in the format [dataset]-[sequence_index]-[configuration].bat, where [sequence_index] is either 01 or 02 and [configuration] is GT, ST, GT+ST, allGT, allST or allGT+allST, generate the results for the primary track. The bat-files with names in the format [dataset]-[sequence_index].bat generate results for the secondary track.

The file Train.m can be used to reproduce the training of segmentation parameters for the primary track of the ISBI Cell Tracking Challenge 2021. The bat-files with names in the format Train-[dataset]-[configuration].bat reproduce the training for a specific dataset and training data configuration. The bat-files with names in the format Train-[configuration].bat reproduce the joint training over all datasets in the training data configurations allGT, allST and allGT+allST. The settings are saved to csv-files in one of the folders CTC2021_trained_on_GT, CTC2021_trained_on_ST, CTC2021_trained_on_GT_plus_ST, CTC2021_trained_on_GT_all, CTC2021_trained_on_ST_all and CTC2021_trained_on_GT_plus_ST_all in Files\Settings. The csv-files are given the same names as the existing csv-files for the training data, but '_new' is added as a suffix.

To run tracking or training using bat-files, the dataset folder must be placed next to the SW-folder (the top folder of the git-repository).

To apply the training procedure used in the ISBI Cell Tracking Challenge 2021 on a new dataset (referred to as training data) and use the trained parameters to segment and track cells in a different dataset (referred to as challenge data), do the following:
   1. Place the folder with training data next to the top folder of the git-repository (the BaxterAlgorithms folder). The training data should have the same folder structure as the training data of the cell tracking challenge. The training data should be placed in a folder and the name of that folder should be inserted instead of [dataset] in the following instructions. The brackets should be removed. The folder [dataset] should contain image sequence folders named 01, 02,..., gold truth folders 01_GT, 02_GT,... and/or silver truth folders named 01_ST, 02_ST,.... In the following instructions, [sequence_index] should be replaced by the number of an image sequence, e.g. 01. More details about the structure of the training data can be found on http://celltrackingchallenge.net/datasets.
   2. Go to the folder Files\Settings\CTC2021_clean and use the template file Settings_ISBI_2021_Training_[dataset]-[sequence_index]_clean.csv to create clean settings files for all image sequences. This is done by inserting the corresponding values for [dataset] and [sequence_index] in the file name and replacing text in brackets in the file with whatever the text tells you to put there. The brackets should be removed. The values that need to be filled in specify properties of the data, such as numZ which is the number of z-planes in z-stacks of 3D data. Normally, there is no need to make any changes to the initial values of the segmentation parameters, which are also in the clean settings files.
   3. Run Train.m with the name of the dataset as the first input and the desired training data configuration as the second input. The following command will train on the gold truth: Train({'[dataset]'}, 'GT'). To train on ST or GT+ST, the second input argument should be changed to 'ST' or 'GT+ST' respectively.
   4. Go to CTC2021_trained_on_GT, CTC2021_trained_on_ST, CTC2021_trained_on_GT_plus_ST, CTC2021_trained_on_GT_all, CTC2021_trained_on_ST_all or CTC2021_trained_on_GT_plus_ST_all in Files\Settings and locate the generated settings files. The generated files will have the suffix '_new'. Remove the suffix '_new' and replace 'Training' by 'Challenge' in the file name. Edit the numZ parameter if the number of z-planes per z-stack is not the same in the challenge data as in the training data.
   5. Replace the training data folder with the challenge data folder. The challenge data folder should have the same name and structure as the training data folder, but there should be no gold truth or silver truth folders.
   6. Call RunBaxterAlgorithms_ISBI_2021.m in the same way as in the existing bat-files for the primary track. If the segmentation parameters have been trained on gold truth, the command is RunBaxterAlgorithms_ISBI_2021('[dataset]', '[sequence_index]', 'Settings_ISBI_2021_Challenge_[dataset]-[sequence_index]_trained_on_GT.csv', '-GT'). If the training has been done on 'ST' or 'GT+ST', the last argument should be replaced by '-ST' or '-GT+ST' respectively.