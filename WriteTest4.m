seqPath = 'D:\Dropbox (VU Basic Sciences)\Duvall Confocal\Duvall Lab\Brock Fletcher\2021-11-15-Ai9CMAX PRotein Screen\Analysis\Baxter';
TrackVersion='_220106_115446';
FilePath=fullfile(seqPath,'Analysis',strcat('CellData',TrackVersion),'Compact');
a=dir(fullfile(FilePath,'*.mat'));
b={a.name};
HasCells=[a.bytes];
blank=~(HasCells>185);
d=b;
d(blank) =[];


ax2 = axes;
for m=1:length(b)
    Run=b{1,m};
    Run=Run(1:end-4)
    if blank(m)
        BronkBox{1,1,1,m}={};    
    else
    
        cellPath=strcat(seqPath,'\',Run);
        cells = LoadCells(cellPath, TrackVersion, 'Compact', true);
        fluorProps = {cells.regionProps};
    fluorProps = cellfun(@fieldnames, fluorProps,'UniformOutput', false);
    fluorProps = unique(cat(1,fluorProps{:}))';
        x_in=m;
%      Plot_Fluorescence3D_2(cells,ax2,'c01','c01',rand(1,3),x_in);
     hold on
%      BronkBox=cell(length(cells),max([cells.stopT]),length(fluorProps),NumWells);
for k=1:length(fluorProps)
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
% figure, ax1 = axes('Position',[0.1 0.1 0.7 0.7]);
% % figure,
% xbar=categorical(d);
% ybar=[];
% for n=1:length(d)
% % PlotWithNan3D(ax1,n*ones(size(Data(:,:,6,n))),Data(:,:,1,n),Data(:,:,6,n));
% % swarmchart(n*ones(size(sums(:,:,6,n))),sums(:,:,1,n));
% % ybar=cat(2,ybar,[sums(:,:,1,n)]);
% 
% %   scatter(means(:,:,1,n),means(:,:,6,n));
% hold on
% end