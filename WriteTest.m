NumWells=3;
figure, ax2 = axes('Position',[0.1 0.1 0.7 0.7]);
for m=0:NumWells-1
     seqPath = 'D:\Dropbox (VU Basic Sciences)\Duvall Confocal\Duvall Lab\Isa\2021-10-02-BigPRoteinScreen\2021-12-31-TestMultiTimepoint\Baxter\';
        Run=num2str(m,'%05.f');
        seqPath=strcat(seqPath,Run);
        cells = LoadCells (seqPath , '_211231_152842','AreCells', true, 'Compact', true);
        fluorProps = {cells.regionProps};
    fluorProps = cellfun(@fieldnames, fluorProps,'UniformOutput', false);
    fluorProps = unique(cat(1,fluorProps{:}))';
    
    Plot_Fluorescence3D(cells,ax2,'Cyt','Drug',rand(1,3));
%      BronkBox=cell(length(cells),max([cells.stopT]),length(fluorProps),NumWells);
for k=1:length(fluorProps);
    currProp=fluorProps{k};
    Test='MinorAxisLength';
for j=1:length(cells)
    c = cells(j);
    t = c.firstFrame : c.lastFrame;  
    tp=1;
    for i=t
        BronkBox{j,i,k,(m+1)}=cells(1,j).regionProps.(currProp)(tp);
        tp=tp+1;
    end
end
end
end
empties=cellfun('isempty',BronkBox);
BronkBox(empties) = {NaN};
Data=cell2mat(BronkBox);
means=mean(Data(:,:,:,:),'omitnan');
medians=median(Data(:,:,:,:),'omitnan');
stds=std(Data(:,:,:,:),'omitnan');
vars=var(Data(:,:,:,:),'omitnan');
sums=sum(Data(:,:,:,:),'omitnan');
CVs=stds./means;
figure, ax1 = axes('Position',[0.1 0.1 0.7 0.7]);
for n=1:NumWells
PlotWithNan3D(ax1,[1:37],means(:,:,2,n),means(:,:,3,n));
hold on
end