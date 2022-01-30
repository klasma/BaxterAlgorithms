seqPath = 'D:\Dropbox (VU Basic Sciences)\Duvall Confocal\Duvall Lab\Isa\2021-10-02-BigPRoteinScreen\2021-12-31-TestMultiTimepoint\Baxter\';
TrackVersion='_211231_152842';
FilePath=fullfile(seqPath,'Analysis',strcat('CellData',TrackVersion),'Compact');
a=dir(fullfile(FilePath,'*.mat'));
b={a.name};
HasCells=[a.bytes];
c=~(HasCells>185);
d=b;
d(c) =[];


figure, ax2 = axes('Position',[0.1 0.1 0.7 0.7]);
for m=1:length(d)
        Run=d{1,m};
        Run=Run(1:end-4)
        cellPath=strcat(seqPath,Run);
        cells = LoadCells (cellPath , TrackVersion,'AreCells', true, 'Compact', true);
        fluorProps = {cells.regionProps};
    fluorProps = cellfun(@fieldnames, fluorProps,'UniformOutput', false);
    fluorProps = unique(cat(1,fluorProps{:}))';
    
    Plot_Fluorescence3D(cells,ax2,'Cyt','Debris',rand(1,3));
%      BronkBox=cell(length(cells),max([cells.stopT]),length(fluorProps),NumWells);
for k=1:length(fluorProps);
    currProp=fluorProps{k};
    Test='MinorAxisLength';
for j=1:length(cells)
    c = cells(j);
    t = c.firstFrame : c.lastFrame;  
    tp=1;
    for i=t
        BronkBox{j,i,k,m}=cells(1,j).regionProps.(currProp)(tp);
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
% figure,
for n=1:length(d)
PlotWithNan3D(ax1,1:length(d),means(:,:,1,n),means(:,:,6,n));
%   scatter(means(:,:,1,n),means(:,:,6,n));
hold on
end