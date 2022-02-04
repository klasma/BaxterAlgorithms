% Update seqpath with image location
% Leave trailing slash
seqPath = 'C:\Users\Owner\Dropbox (VU Basic Sciences)\LabConfocalOld\Duvall Lab\Isa\2021-10-11-BigProteinFollowUp\Analysis\Baxter\'; 
% Update track number here from BaxterAlgorithms.m GUI
TrackVersion='_220105_121225'; 
FilePath=fullfile(seqPath,'Analysis',strcat('CellData',TrackVersion),'Compact');
a=dir(fullfile(FilePath,'*.mat'));
b={a.name};
% Rough way of gating / filtering cells by file size (bytes)
HasCells=[a.bytes]; 
c=~(HasCells>185);
d=b;
d(c) =[];


figure, ax2 = axes('Position',[0.1 0.1 0.7 0.7]);
for m=1:length(d)
        Run=d{1,m};
        Run=Run(1:end-4)
        cellPath=strcat(seqPath,Run); % Appends Cell Path
        cells = LoadCells (cellPath , TrackVersion,'AreCells', true, 'Compact', true);
        fluorProps = {cells.regionProps};
    fluorProps = cellfun(@fieldnames, fluorProps,'UniformOutput', false);
    fluorProps = unique(cat(1,fluorProps{:}))';
    
     Plot_Fluorescence3D(cells,ax2,'Cyt','Debris',rand(1,3));
   %   BronkBox=cell(length(cells),max([cells.stopT]),length(fluorProps),NumWells);
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

% Replaces all BronkBox 'empty' data with NaN
empties=cellfun('isempty',BronkBox);
BronkBox(empties) = {NaN};

% Data holds BronkBox in a matrix
% cell2mat converts cell array to one standard array
Data=cell2mat(BronkBox); 

means=mean(Data(:,:,:,:),'omitnan');
medians=median(Data(:,:,:,:),'omitnan');
stds=std(Data(:,:,:,:),'omitnan');
vars=var(Data(:,:,:,:),'omitnan');
sums=sum(Data(:,:,:,:),'omitnan');
CVs=stds./means;

figure, ax1 = axes('Position',[0.1 0.1 0.7 0.7]);
xbar=categorical(d);
ybar=[];
for n=1:length(d)
<<<<<<< HEAD
% PlotWithNan3D(ax1,n*ones(size(Data(:,:,6,n))),Data(:,:,1,n),Data(:,:,6,n));
swarmchart(n*ones(size(sums(:,:,6,n))),sums(:,:,1,n));
ybar=cat(2,ybar,[sums(:,:,1,n)]);
=======
PlotWithNan3D(ax1,n*ones(size(Data(:,:,5,n))),Data(:,:,1,n),Data(:,:,5,n));
% swarmchart(n*ones(size(sums(:,:,6,n))),sums(:,:,1,n));
 % ybar=cat(2,ybar,[sums(:,:,1,n)]);
%  Plot_Fluorescence3D(cells2,ax1,'Drug','Gal',rand(1,3));
>>>>>>> c1e554047a8962cae6cafd1ca8a96a7c2015188b

 % scatter(means(:,:,1,n),means(:,:,6,n));
hold on
end