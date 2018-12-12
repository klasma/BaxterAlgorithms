function CompileMex(varargin)
% Compiles all mex-files used by the BaxterAlgortihms.
%
% All mex-files are compiled from C++ code. There should always be up to
% date compiled files for 64-bit versions of Windows, Mac and Linux, so
% that people can use the software without having to first run this
% function. To compile the mex-files, you need to have a C++ compiler
% installed and you need to tell MATLAB which compiler to use by running
% 'mex -setup'. This function will change the working directory to the
% directories containing the source code for the mex-files and then change
% it back to the original directory once it is done compiling.
%
% Syntax:
% CompileMex(varargin)
%
% Property/Value inputs:
% Debug - Set this to true to compile mex-files with debugging information.
%         These files can be debugged in Visual Studio and other IDEs, but
%         they run slower than the normal files.
% Files - The name of the mex-file that should be compiled. The mex-files
%         that can be compiled are 'Hungarian', 'ViterbiTrackLinking',
%         'SeededWatershed', and 'MergeWatersheds'. A cell array with the
%         names of multiple mex-files can also be given as input. The
%         default is to compile all mex-files.
% GPP44 - Tells the function to use version 4.4 or g++ for compilation of
%         the mex-files. This has been required to compile the mex-files on
%         the simulation computers in the School of Electrical Engineering
%         at KTH.

% Add necessary paths.
subdirs = textscan(genpath(fileparts(mfilename('fullpath'))), '%s','delimiter',pathsep);
addpath(subdirs{1}{:});

% Names of the mex-files that can be compiled.
filenames = {...
    'Hungarian'
    'ViterbiTrackLinking'
    'SeededWatershed'
    'MergeWatersheds'};

[aDebug, aFiles, aGPP44] = GetArgs({'Debug', 'Files', 'GPP44'},...
    {false, filenames, false}, true, varargin);

% Handle a character array with a single name.
if ~iscell(aFiles)
    aFiles = {aFiles};
end

% Check that all files are files that can be compiled.
for i = 1:length(aFiles)
    if ~any(strcmp(filenames, aFiles{i}))
        error(['%s is not a file that can be compiled. The valid '...
            'options are ''Hungarian'', ''ViterbiTrackLinking'', '...
            '''SeededWatershed'', and ''MergeWatersheds''.'], aFiles{i})
    end
end

currDir = pwd;  % So that we can go back.
basePath = fileparts(mfilename('fullpath'));  % Top directory.

% The newest version of gcc on the simulation computers at KTH can not be
% used to compile mex files, but the version 4.4 works and is installed.
if aGPP44
    gccStr = 'CXX=g++-4.4';
else
    gccStr = '';
end

% Option to compile debug files.
if aDebug
    debugStr = '-g';
else
    debugStr = '';
end

% Compile implementation of the Hungarian algorithm.
if any(strcmp(aFiles, 'Hungarian'))
    cd(fullfile(basePath, 'Tracking', 'Hungarian'))
    compileStr_Hungarian = sprintf('mex %s %s Hungarian.cpp', gccStr, debugStr);
    eval(compileStr_Hungarian)
    fprintf('Done compiling Hungarian.\n')
end

% Compile sparse implementation of the Viterbi-tracking.
if any(strcmp(aFiles, 'ViterbiTrackLinking'))
    cd(fullfile(basePath, 'Tracking', 'Viterbi'))
    compileStr_ViterbiTrackLinking = sprintf(['mex -DMATLAB %s %s '...
        'ViterbiTrackLinking.cpp '...
        'Apoptosis.cpp '...
        'Appearance.cpp '...
        'Arc.cpp '...
        'ArraySave.cpp '...
        'CellNode.cpp '...
        'CellTrellis.cpp '...
        'Count.cpp '...
        'Detection.cpp '...
        'Disappearance.cpp '...
        'Event.cpp '...
        'FreeArc.cpp '...
        'FreeArcNoSwap.cpp '...
        'IdleState.cpp '...
        'LogStream.cpp '...
        'LogStreamBuffer.cpp '...
        'Migration.cpp '...
        'Mitosis.cpp '...
        'Node.cpp '...
        'Persist.cpp '...
        'Preexist.cpp '...
        'State.cpp '...
        'Swap.cpp '...
        'Tree.cpp '...
        'Trellis.cpp '...
        'Variable.cpp'],...
        gccStr, debugStr);
    eval(compileStr_ViterbiTrackLinking)
    fprintf('Done compiling ViterbiTrackLinking.\n')
end

% Compile seeded watershed algorithm.
if any(strcmp(aFiles, 'SeededWatershed'))
    cd(fullfile(basePath, 'Segmentation', 'Watershed'))
    compileStr_SeededWatersheds = sprintf(['mex -DMATLAB %s %s '...
        'SeededWatershed.cpp'],...
        gccStr, debugStr);
    eval(compileStr_SeededWatersheds)
    fprintf('Done compiling SeededWatershed.\n')
end

% Compile watershed merging.
if any(strcmp(aFiles, 'MergeWatersheds'))
    cd(fullfile(basePath, 'Segmentation', 'Watershed'))
    compileStr_MergeWatersheds = sprintf(['mex -DMATLAB %s %s '...
        'MergeWatersheds.cpp '...
        'Border.cpp '...
        'Corner.cpp '...
        'MergeSegments.cpp '...
        'Region.cpp '...
        'Segment.cpp '...
        'Surface.cpp '...
        'SurfaceComparator.cpp'],...
        gccStr, debugStr);
    eval(compileStr_MergeWatersheds)
    fprintf('Done compiling MergeWatersheds.\n')
end

% Go back to the original directory.
cd(currDir)
fprintf('Done compiling.\n')
end