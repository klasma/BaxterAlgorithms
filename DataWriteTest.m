for i=0:2
    seqPath = 'D:\Dropbox (VU Basic Sciences)\Duvall Confocal\Duvall Lab\Isa\2021-10-02-BigPRoteinScreen\2021-12-31-TestMultiTimepoint\Baxter\';
        Run=num2str(i)
        seqPath=strcat(seqPath,'0000',num2str(i));
        cells = LoadCells (seqPath , '_211231_152842','AreCells', true, 'Compact', true);
%         cells2=AreCells(cells);
properties=cells(1).regionProps.Area(2)
% % [cellVec2, labels2] = PartitionCells(cells, 'firstFrame');
% Test=a;
fluorProps = {cells.regionProps};
fluorProps = cellfun(@fieldnames, fluorProps,'UniformOutput', false);
fluorProps = unique(cat(1,fluorProps{:}))';
% fluorProps = regexp(fluorProps, '^Fluor.*', 'match', 'once');
% fluorProps(cellfun(@isempty, fluorProps)) = [];

        Plot_Fluorescence3D(cells,ax1,'Drug','Gal',rand(1,3));
end
