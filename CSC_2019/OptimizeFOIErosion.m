function OptimizeFOIErosion(aExPath, aVersion, aMinErosion, aMaxErosion, aOriginalErosion)

seqDirs = GetSeqDirs(aExPath);
erosions = aMinErosion : aMaxErosion;
SEG = nan(length(seqDirs), length(erosions));
TRA = nan(length(seqDirs), length(erosions));

for i = 1:length(seqDirs)
    seqPath = fullfile(aExPath, seqDirs{i});
    imData = ImageData(seqPath);
    for j = 1:length(erosions)
        fprintf('Testing FOI erosion %d\n', erosions(j))
        cells = LoadCells(seqPath, aVersion);
        erodedVersion = sprintf('%s_eroded_%03d', aVersion, erosions(j));
        if ~HasVersion(seqPath, erodedVersion)
            erodedCells = ErodeFOI(cells, erosions(j), imData);
            SaveCells(erodedCells, seqPath, erodedVersion)
        end
        SEG(i,j) = PerformanceSEG(seqPath, erodedVersion, false);
        TRA(i,j) = PerformanceTRA(seqPath, erodedVersion);
    end
end

meanTRA = mean(TRA,1);
meanSEG = mean(SEG,1);

meanOP = (meanTRA+meanSEG)/2;

bestErosion = erosions(find(meanOP == max(meanOP), 1, 'last'));

for i = 1:length(seqDirs)
    seqPath = fullfile(aExPath, seqDirs{i});
    WriteSeqSettings(seqPath, 'foiErosion', num2str(bestErosion))
end

fprintf('%s', aExPath)
fprintf('Best erosion = %d\n', bestErosion)
performanceGain = meanOP(erosions == bestErosion) - meanOP(erosions == aOriginalErosion);
fprintf('Performance gain = %d\n\n', performanceGain)

[~, exDir] = fileparts(aExPath);
figure('Name', exDir)
plot(erosions, meanSEG)
hold all
plot(erosions, meanTRA)
plot(erosions, meanOP)

xlabel('Erosion')
ylabel('Performance')
legend('SEG', 'TRA', 'OP')
grid on
end