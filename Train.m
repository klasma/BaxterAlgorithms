function Train(aExDir, aGtType)
% Optimize segmentation on the primary track datasets for CTC 2021.

swPath = fileparts(mfilename('fullpath'));
subdirs = textscan(genpath(swPath), '%s','delimiter', pathsep);
addpath(subdirs{1}{:});

switch aGtType
    case 'GT'
        suffix = '_GT';
        suffix2 = [];
        longName = 'GT';
    case 'ST'
        suffix = '_ST';
        suffix2 = [];
        longName = 'ST';
    case 'GT+ST'
        suffix = '_GT';
        suffix2 = '_ST_minus_GT';
        longName = 'GT_plus_ST';
    otherwise
        error('aGtType must be either ''GT'', ''ST'' or ''GT+ST''')
end

maxIter = 25;
settingsToOptimize = {
    'BPSegHighStd'
    'BPSegLowStd'
    'BPSegBgFactor'
    'BPSegThreshold'
    'SegClipping'
    'SegWHMax'
    'SegWHMax2'
    'SegMinArea'
    'SegMinSumIntensity'
    };

exPath = fullfile(fileparts(swPath), aExDir);

DeleteOldOptimizationCellData({exPath})

seqDirs = GetSeqDirs(exPath);
seqDirs = regexp(seqDirs, '.*(?<!(_GT|_ST))$', 'match', 'once');
seqDirs = seqDirs(~cellfun(@isempty, seqDirs));
seqPaths = fullfile(exPath, seqDirs);

% Read initial settings which only have information about the images.
initialImData = [];
for j = 1:length(seqDirs)
    seqPath = fullfile(exPath, seqDirs{j});
    settingsPath =...
        fullfile(swPath,...
        'Files',...
        'Settings',...
        sprintf('CTC2021_clean'),...
        sprintf('Settings_ISBI_2021_Training_%s-%s_clean.csv', aExDir, seqDirs{j}));
    imData = ImageData(seqPath, 'SettingsFile', settingsPath);
    initialImData = [initialImData; imData]; %#ok<AGROW>
end

% Specify where the optimized settings should be saved.
optimizedSettingsPaths = cell(size(seqDirs));
for j = 1:length(seqDirs)
    optimizedSettingsPaths{j} =...
        fullfile(swPath,...
        'Files',...
        'Settings',...
        sprintf('CTC2021_trained_on_%s', longName),...
        sprintf('Settings_ISBI_2021_Challenge_%s-%s_trained_on_%s_new.csv', aExDir, seqDirs{j}, longName));
end

optimizer = SEGOptimizerEx(seqPaths, settingsToOptimize,...
    'SavePaths', optimizedSettingsPaths,...
    'InitialImData', initialImData,...
    'ScoringFunction', '0.9*SEG+0.1*DET',...
    'Suffix', suffix,...
    'Suffix2', suffix2,...
    'Plot', true);

optimizer.Optimize_coordinatedescent('MaxIter', maxIter)
end