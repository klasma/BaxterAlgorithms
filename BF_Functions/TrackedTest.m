SeqPath='D:\Dropbox (VU Basic Sciences)\Duvall Confocal\Duvall Lab\Isa\2021-10-02-BigPRoteinScreen\2021-12-31-TestMultiTimepoint\Baxter\00000';

TrackVersion='_211231_152842';
imData = ImageData(SeqPath);
cells = LoadCells(SeqPath , TrackVersion);
for i=9:10
OutImage = ReconstructSegments(imData, cells,i);
figure, imshow(OutImage)
end
