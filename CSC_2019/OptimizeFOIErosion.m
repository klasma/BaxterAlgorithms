seqPath = 'C:\Users\klasma\Dropbox\DataSets\Fluo-C2DL-MSC\Fluo-C2DL-MSC_01';
imData = ImageData(seqPath);
version = '_190220_223623_no_foi_erosion';
maxErosion = 100;
SEG = nan(maxErosion + 1, 1);
TRA = nan(maxErosion + 1, 1);

for erosion = 0:maxErosion
    fprintf('Testing FOI erosion %d / %d\n', erosion, maxErosion)
    cells = LoadCells(seqPath, version);
    erodedVersion = sprintf('%s_eroded_%03d', version, erosion);
    if ~HasVersion(seqPath, erodedVersion)
        erodedCells = ErodeFOI(cells, erosion, imData);
        SaveCells(erodedCells, seqPath, erodedVersion)
    end
    SEG(erosion+1) = PerformanceSEG(seqPath, erodedVersion, false);
    TRA(erosion+1) = PerformanceTRA(seqPath, erodedVersion);
end

OP = (TRA+SEG)/2;

bestErosion = find(OP == max(OP), 1, 'last') - 1;
fprintf('The best erosion is %d\n', bestErosion)

figure
plot(0:maxErosion, SEG)
hold all
plot(0:maxErosion, TRA)
plot(0:maxErosion, OP)

xlabel('Erosion')
ylabel('Performance')
legend('SEG', 'TRA', 'OP')
grid on