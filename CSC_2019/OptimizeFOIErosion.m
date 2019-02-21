function OptimizeFOIErosion(aSeqPaths, aVersion)

maxErosion = 100;
SEG = nan(maxErosion + 1, length(aSeqPaths));
TRA = nan(maxErosion + 1, length(aSeqPaths));

for i = 1:length(aSeqPaths)
    seqPath = aSeqPaths{i};
    imData = ImageData(seqPath);
    for erosion = 0:maxErosion
        fprintf('Testing FOI erosion %d / %d\n', erosion, maxErosion)
        cells = LoadCells(seqPath, aVersion);
        erodedVersion = sprintf('%s_eroded_%03d', aVersion, erosion);
        if ~HasVersion(seqPath, erodedVersion)
            erodedCells = ErodeFOI(cells, erosion, imData);
            SaveCells(erodedCells, seqPath, erodedVersion)
        end
        SEG(erosion+1) = PerformanceSEG(seqPath, erodedVersion, false);
        TRA(erosion+1) = PerformanceTRA(seqPath, erodedVersion);
    end
end

meanTRA = mean(TRA,2);
meanSEG = mean(SEG,2);

meanOP = (meanTRA+meanSEG)/2;

bestErosion = find(meanOP == max(meanOP), 1, 'last') - 1;
fprintf('The best erosion is %d\n', bestErosion)

for i = 1:length(aSeqPaths)
    WriteSeqSettings(aSeqPaths{i}, 'foiErosion', bestErosion)
end

figure
plot(0:maxErosion, meanSEG)
hold all
plot(0:maxErosion, meanTRA)
plot(0:maxErosion, meanOP)

xlabel('Erosion')
ylabel('Performance')
legend('SEG', 'TRA', 'OP')
grid on
end