configurationsAndSuffixes = {
    'GT' '_trained_on_GT'
    'ST' '_trained_on_ST'
    'GT+ST' '_trained_on_GT_plus_ST'
    'allGT' '_trained_on_GT_all'
    'allST' '_trained_on_ST_all'
    'allGT+allST' '_trained_on_GT_plus_ST_all'
    };

basePath = 'C:\CTC2021\Challenge';

exDirs = {
    'BF-C2DL-HSC'
    'Fluo-C2DL-MSC'
    'Fluo-N2DH-GOWT1'
    'Fluo-C3DH-A549'
    'Fluo-C3DL-MDA231'
    'Fluo-N2DL-HeLa'
    'Fluo-N3DH-CHO'
    'PhC-C2DL-PSC'
    'PhC-C2DH-U373'
    'DIC-C2DH-HeLa'
    'BF-C2DL-MuSC'
    'Fluo-N3DH-CE'
    'Fluo-C3DH-H157'
    };

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

sett = {'setting'};

for i = 1:size(configurationsAndSuffixes, 1)
    for j = 1:length(exDirs)
        configuration = configurationsAndSuffixes{i,1};
        suffix = configurationsAndSuffixes{i,2};
        exDir = exDirs{j};
        exPath = fullfile(basePath, exDir);
        settingsLinkPath = fullfile(exPath, sprintf('SettingsLinks%s.csv', suffix));
        seqDir = [exDir '_01'];
        try
            exSett = ReadSettings(settingsLinkPath, seqDir);
        catch
            fprintf('No settings file found for %s in configuration %s\n', exDir, configuration)
            continue
        end
        for k = 1:length(settingsToOptimize)
            settingToOptimize = settingsToOptimize{k};
            value = GetSeqSettings(exSett, seqDir, settingToOptimize);
            sett = SetSeqSettings(sett, exDir, settingToOptimize, num2str(value));
        end
    end
    outputFile = sprintf('Settings-%s.csv', configuration);
    WriteDelimMat(outputFile, sett, ';')
end