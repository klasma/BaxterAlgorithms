%% Gal8 Recruitment MATLAB Program
%% Image Folder Location
clc, clear, close all


ImgFile=char("D:\Dropbox (VU Basic Sciences)\Duvall Confocal\Duvall Lab\Isa\2021-10-02-BigPRoteinScreen\20211002BigProteinScreen.nd2");
r = loci.formats.Memoizer(bfGetReader(),0);
r.setId(ImgFile);
exportdir=char('D:\Dropbox (VU Basic Sciences)\Duvall Confocal\Duvall Lab\Isa\2021-10-02-BigPRoteinScreen\2022-04-05-BF_Vasco');
if ~exist(exportdir,'file')
mkdir(exportdir);
end
%% Directory Code

run=char(datetime(clock),"yyyy-MM-dd-hh-mm-ss");    % The Run number is used to track multiple runs of the software, and is used in
          
readeromeMeta=r.getMetadataStore();
RunDirectory= fullfile(exportdir,run);
mkdir(RunDirectory); 

OverlaidDirectory = fullfile(RunDirectory,'Overlaid');
mkdir(OverlaidDirectory); 

BaxtDirectory = fullfile(RunDirectory,'Baxter');
mkdir(BaxtDirectory);

LogDirectory = fullfile(RunDirectory,'Log');
mkdir(LogDirectory);

SegDirectory = fullfile(BaxtDirectory,'Analysis','Segmentation_');
% mkdir(SegDirectory);



         

%% Log Data
Version=run;
LogFile=strcat(LogDirectory,'\');
FileNameAndLocation=[mfilename('fullpath')]; %#ok<NBRAK>
newbackup=sprintf('%sbackup_%s.m',LogFile,Version);
Gitdir=fullfile(pwd,'RunLog\');
if ~isfolder(Gitdir)
mkdir(Gitdir);
end 
GitLog=sprintf('%sbackup_%s.m',Gitdir,Version);
currentfile=strcat(FileNameAndLocation, '.m');
copyfile(currentfile,newbackup);
copyfile(currentfile,GitLog)

%% Sizing/Resolution Parameters EDIT HERE ADVANCED
MiPerPix=0.34;        
CellSize=1; %Scale as needed for different Cells        
            %Disks  
            
 
            
%% Analysis Functions
%Input Planes
    numPlanes=3; %Which image Planes to analyze ##Integrate with GUI 
    Nuc_bw4_perim=0;
    
    ImageAnalyses=    {
                        {{'Nuc'},{1},{4 0.4 0.2},{3},{'Nuc_bw4_perim' [0.8500 0.3250 0.0980]},{true},{}};
                        {{'Cyt'},{2},{1 0.3},{2},{},{false},{}};
                        {{'CytWS'},{2},{1,2},{},{'Cyt_WS_perim' [0.4940, 0.1840, 0.5560]},{true},{}};
                        {{'Gal8'},{2},{0.1},{},{'Gal_bw4_Perim' [0.4940, 0.1840, 0.5560]},{true},{}};
                            };%Which Image analysis/functions to call. ##NEed to solve problem of secondary analyses like watershed of Nuc and Cytosol or gal8 and cytosol
    
    
       DataName = {};                  
       LiveData = {};
       AllData = {};
    BaxExport=true; %#Integrate with GUI
    
    
    MakeExampleImage=0; %#Integrate with GUI
    MakeOverlayImage=0;%Logical Yes or no to make overlay image #Integrate with GUI

    
%% Analysis Variables

% Categories=[{'run'},{'well'},{'areacell'},{'CellSum'},{'areaGal8'},{'galsum'},{'areaDrug'},{'Drugsum'},{'DrugAvgInCell'},{'DrugAvgOutCell'}]; 
%##Categories are manually typed out here, but it should integrate so that
%these are auto-populated or selectable within the GUI, might have to get
%clever for this to work
FastRun=1;
if FastRun>0
NumSeries=FastRun;    
else
NumSeries=r.getSeriesCount(); %The number of different wells you imaged
end
NumColors=r.getEffectiveSizeC(); %The number of colors of each well you imaged

NumTimepoint=(r.getImageCount())/NumColors; %The number of timepoints you imaged
NumImg=NumSeries*NumTimepoint*NumColors; %The total number of images, combining everything
    %Generate Pool
     poolobj = gcp;
            if isempty(poolobj)
                nWorkers = 0;
            else
                nWorkers = poolobj.NumWorkers;
            end
ParSplit=[1:nWorkers:NumSeries]; %#ok<NBRAK>
%% Analysis Program 
for nn = 1 : nWorkers % Initialize logging at INFO level
    bfInitLogging('INFO'); % Initialize a new reader per worker as Bio-Formats is not thread safe
    r2 = javaObject('loci.formats.Memoizer', bfGetReader(), 0); % Initialization should use the memo file cached before entering the parallel loop
    r2.setId(ImgFile);

for j=ParSplit+nn-2% Number of wells in ND2 File  
        CurrSeries=j; %The current well that we're looking at
        r2.setSeries(CurrSeries); %##uses BioFormats function, can be swapped with something else (i forget what) if it's buggy with the GUI
        fname = r2.getSeries; %gets the name of the series using BioFormats
        Well=num2str(fname,'%05.f'); %Formats the well name for up to 5 decimal places of different wells, could increase but 5 already feels like overkill 
        T_Value = r2.getSizeT()-1; %Very important, the timepoints of the images. Returns the total number of timepoints, the -1 is important.
        SizeX=r2.getSizeX();
        SizeY=r2.getSizeY();

        BaxWellFolder=fullfile(BaxtDirectory,Well); %Creates a filename that's compatible with both PC and Mac (##Check and see if any of the strcat functions need to be replaced with fullfile functions) 
        mkdir(BaxWellFolder); %makes a new folder on your hard drive for the baxter stuff   

        Img=zeros(SizeX,SizeY,numPlanes,T_Value+1);

        for i=0:T_Value
          iplane=r2.getIndex(0,0,i);
            for n=1:numPlanes             
                            Img(:,:,n,i+1)= bfGetPlane(r2,iplane+n);
            end
        end
        Img=uint16(Img);

for i=0:T_Value %For all of the time points in the series, should start at zero if T_Value has -1 built in, which it should
           
            Timepoint = num2str(i,'%03.f'); %Creates a string so taht the BioFormats can read it
            BaxterName=strcat('w',Well,'t',Timepoint) ; %Very important, creates a name in the format that Baxter Algorithms prefers
            Img2=Img(:,:,:,i+1);                       
            ImageName=fullfile(BaxWellFolder,BaxterName); %Creates a name for each particular image
            
            %Export Images for Baxter
            for n=1:numPlanes                        
                
                if logical(BaxExport)
                    my_field = strcat('c',num2str(n,'%02.f'));
                    imwrite(Img2(:,:,n), strcat(ImageName,my_field,'.tif'),'tif');
                end
            end
                    
            for k =1:length(ImageAnalyses)
                    Analysis=ImageAnalyses{k,:}{1}{1};
                    AnaChan=ImageAnalyses{k,:}{2}{1};
                    AnaImage=Img2(:,:,AnaChan);
                    AnaSettings= ImageAnalyses{k,:}{3};
%                     Storage
                        DataName{k} = matlab.lang.makeValidName(Analysis);
                        DataLoop=strcat(DataName{k},'_',num2str(k));

                    switch Analysis
                        case 'Nuc'
                         [bw4,bw4_perim,Label,Data]= NuclearStain(AnaImage,AnaSettings,MiPerPix);
                        case 'Cyt'
                         [bw4,bw4_perim,Label,Data] = Cytosol(AnaImage,AnaSettings,MiPerPix);  
                        case 'Nuc_Cyt'
                         [bw4,bw4_perim,Label,Data] = Nuc_Cyt(AnaImage,AnaSettings,Cyt,Cyt_bw4,MiPerPix);
                        case 'CytWS'
                            NucChan=ImageAnalyses{k,:}{3}{1};
                             CytChan=ImageAnalyses{k,:}{3}{2};
                            Cyt=LiveData{CytChan}.AnaImage;
                            Nuc_bw4=LiveData{NucChan}.bw4;
                            Cyt_bw4=LiveData{CytChan}.bw4;
                         [Label,bw4_perim,Data] = CytNucWaterShed(Nuc_bw4,Cyt,Cyt_bw4);                           
                        case 'Gal8'    
                         [bw4_perim,bw4,Label,Data] = Gal8(AnaImage,AnaSettings,Cyt_bw4,MiPerPix);
                     end
                    LiveData{k}.AnaImage = AnaImage;
                    LiveData{k}.bw4 = bw4;
                    LiveData{k}.bw4_perim = bw4_perim;
                    LiveData{k}.Label=Label;
                    LiveData{k}.Data=Data;

                    if ImageAnalyses{k,:}{6}{1}
                                    SegDir=fullfile(strcat(SegDirectory,Analysis,'_',num2str(k)),Well);
                                        if ~exist(SegDir,'file')
                                        mkdir(SegDir);
                                        end
                                    ImName=strcat(BaxterName,'c' ,num2str(AnaChan,'%02.f'),'.tif');
                                    SegFile=fullfile(SegDir,ImName);
                                    imwrite(Label,SegFile);   
                    end
            end
    %% Get Area and Intensities
       [AllData,SpotData] = LabelAnalysis(LiveData,Img2,Well,Timepoint,AllData);
       
    %% ExportSegment        
    
end   
end   
end
%% Write Analysis Data to File
