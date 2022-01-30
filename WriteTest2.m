Bigbox=cell(1,3);
NumWells=3;
for m=0:NumWells-1
     seqPath = 'D:\Dropbox (VU Basic Sciences)\Duvall Confocal\Duvall Lab\Isa\2021-10-02-BigPRoteinScreen\2021-12-31-TestMultiTimepoint\Baxter\';
        Run=num2str(m,'%05.f');
        seqPath=strcat(seqPath,Run);
        cells = LoadCells (seqPath , '_211231_152842','AreCells', true, 'Compact', true);
        fluorProps = {cells.regionProps};
    fluorProps = cellfun(@fieldnames, fluorProps,'UniformOutput', false);
    fluorProps = unique(cat(1,fluorProps{:}))';
    BronkBox=cell(length(cells),max([cells.stopT]));
for k=1:length(fluorProps)
%     k=1:length(fluorProps);
    currProp=fluorProps{k};
    Test='MinorAxisLength';
for j=1:length(cells)
    c = cells(j);
    t = c.firstFrame : c.lastFrame;  
    tp=1;
    for i=t
%         BronkBox{j,i}=cells(1,j).regionProps;
        BronkBox{j,i}=cells(1,j).regionProps.(currProp)(tp);
        tp=tp+1;
        LilBox{k,1}=[BronkBox];
        
        Bigbox{1,m+1}=[LilBox];
    end
end
end 
LilStruct=cell2struct(LilBox,fluorProps,1);
Bigbox{1,m+1}=[LilStruct];
 Count{1,m+1}=char(Run);
end
% BigStruct=cell2struct(Bigbox,{'zero','One','Tree'},2);