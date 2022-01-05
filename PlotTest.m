figure, ax1 = axes('Position',[0.1 0.1 0.7 0.7]);
for i=0:2
    seqPath = 'D:\Dropbox (VU Basic Sciences)\Duvall Confocal\Duvall Lab\Isa\2021-10-02-BigPRoteinScreen\2021-12-31-TestMultiTimepoint\Baxter\';
        Run=num2str(i)
        seqPath=strcat(seqPath,'0000',num2str(i));
        cells2 = LoadCells (seqPath , '_211231_152842','AreCells', true, 'Compact', true);
%         cells2=AreCells(cells);
        Plot_Fluorescence3D(cells2,ax1,'Drug','Gal',rand(1,3));
end
% for i = 1:length(cells2)
%     c = cells2(i)
%     
% end    