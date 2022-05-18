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

            
%% Analysis Functions
%Input Planes
    numPlanes=3; %Which image Planes to analyze ##Integrate with GUI 
    Nuc_bw4_perim=0;
    
    ImageAnalyses=    {
                        {{'Nuc'},{1},{1 0.1},{3},{'Nuc_bw4_perim' [0.8500 0.3250 0.0980]},{true},{}};
                        {{'Cyt'},{2},{1 0.1},{2},{},{true},{}};
                        {{'CytWS'},{2},{1,2},{},{'Cyt_WS_perim' [0.4940, 0.1840, 0.5560]},{true},{}};
                        {{'Gal8'},{2},{0.01},{},{'Gal_bw4_Perim' [0.4940, 0.1840, 0.5560]},{true},{}};
                            };%Which Image analysis/functions to call. ##NEed to solve problem of secondary analyses like watershed of Nuc and Cytosol or gal8 and cytosol
    
    
       DataName = {};                  
       LiveData = {};
       AllData2 = {};
       ExportParamNames={};
    BaxExport=true; %#Integrate with GUI
    
    
    MakeExampleImage=0; %#Integrate with GUI
    MakeOverlayImage=0;%Logical Yes or no to make overlay image #Integrate with GUI

    
%% Analysis Variables
    %Define Wells if Necessary
    customrun=false;
 
if customrun
NumSeries=FastRun;

wellsSR = [1 2 48 47 3 4 46 45 59 60 86 85 61 62 84 83 63 64 82 81 65 66 80 79 145 146 192 191,...
         147 148 190 189 203 204 230 229 205 206 228 227 207 208 226 225 209 210 224 223];
well_namesSR =   {'A01.1','A01.2','A01.3','A01.4'...
                'A02.1','A02.2','A02.3','A02.4'...
                'B06.1','B06.2','B06.3','B06.4'...
                'B07.1','B07.2','B07.3','B07.4'...
                'B08.1','B08.2','B08.3','B08.4'...
                'B09.1','B09.2','B09.3','B09.4'...
                'D01.1','D01.2','D01.3','D01.4'...
                'D02.1','D02.2','D02.3','D02.4'...
                'E06.1','E06.2','E06.3','E06.4'...
                'E07.1','E07.2','E07.3','E07.4'...
                'E08.1','E08.2','E08.3','E08.4'...
                'E09.1','E09.2','E09.3','E09.4'};
timepointsSR = [1,4,7,10,13,16,19,22,25,28,31,34,37];


else
NumSeries=r.getSeriesCount(); %The number of different wells you imaged
end


NumColors=r.getEffectiveSizeC(); %The number of colors of each well you imaged

NumTimepoint=(r.getImageCount())/NumColors; %The number of timepoints you imaged
NumImg=NumSeries*NumTimepoint*NumColors; %The total number of images, combining everything
    %Generate Pool
     poolobj = gcp;
            if isempty(poolobj)
                nWorkers = 1;
            else
                nWorkers = poolobj.NumWorkers;
            end
ParSplit=[1:nWorkers:NumSeries]; 
%% Analysis Program 
AllData4={};
for nn = 1 : nWorkers % Initialize logging at INFO level
    bfInitLogging('INFO'); % Initialize a new reader per worker as Bio-Formats is not thread safe
    r2 = javaObject('loci.formats.Memoizer', bfGetReader(), 0); % Initialization should use the memo file cached before entering the parallel loop
    r2.setId(ImgFile);
    AllData3={};
% for j=ParSplit+nn-2% Number of wells in ND2 File
for j=0:0
        CurrSeries=j; %The current well that we're looking at
        r2.setSeries(CurrSeries); %##uses BioFormats function, can be swapped with something else (i forget what) if it's buggy with the GUI
        fname = r2.getSeries; %gets the name of the series using BioFormats
        Well=num2str(fname,'%05.f'); %Formats the well name for up to 5 decimal places of different wells, could increase but 5 already feels like overkill 
        T_Value = r2.getSizeT()-1; %Very important, the timepoints of the images. Returns the total number of timepoints, the -1 is important.
        SizeX=r2.getSizeX();
        SizeY=r2.getSizeY();

        BaxWellFolder=fullfile(BaxtDirectory,Well); %Creates a filename that's compatible with both PC and Mac (##Check and see if any of the strcat functions need to be replaced with fullfile functions) 
        if ~isfolder(BaxWellFolder)
        mkdir(BaxWellFolder); %makes a new folder on your hard drive for the baxter stuff   
        end    
        Img=zeros(SizeX,SizeY,numPlanes,T_Value+1);

        for i=0:T_Value
          iplane=r2.getIndex(0,0,i);
            for n=1:numPlanes             
                            Img(:,:,n,i+1)= bfGetPlane(r2,iplane+n);
            end
        end
        Img=uint16(Img);
AllData2={};
% for i=0:1
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
                    
%             for k =1:length(ImageAnalyses)
%                 test=k   
%                 Analysis=ImageAnalyses{k,:}{1}{1};
%                     AnaChan=ImageAnalyses{k,:}{2}{1};
%                     AnaImage=Img2(:,:,AnaChan);
%                     AnaSettings= ImageAnalyses{k,:}{3};
% %                     Storage
% %                         DataName{k} = matlab.lang.makeValidName(Analysis);
% %                         DataLoop=strcat(DataName{k},'_',num2str(k));
% 
%                     switch Analysis
%                         case 'Nuc'
%                          [bw4,bw4_perim,Label,Data]= NuclearStain(AnaImage,AnaSettings,MiPerPix);
%                         case 'Cyt'
%                          [bw4,bw4_perim,Label,Data] = Cytosol(AnaImage,AnaSettings,MiPerPix);  
%                          case 'CytWS'
%                             NucChan=ImageAnalyses{k,:}{3}{1};
%                              CytChan=ImageAnalyses{k,:}{3}{2};
%                             Cyt=All_AnaImage(:,:,CytChan);
%                             Nuc_bw4=All_bw4(:,:,NucChan);
%                             Cyt_bw4=All_bw4(:,:,CytChan);
%                          [Label,bw4_perim,Data] = CytNucWaterShed(Nuc_bw4,Cyt,Cyt_bw4);                           
%                         case 'Gal8'    
%                          [bw4_perim,bw4,Label,Data] = Gal8(AnaImage,AnaSettings,Cyt_bw4,MiPerPix);
%                      end
%                     All_AnaImage(:,:,k) = AnaImage;
%                     All_bw4(:,:,k) = bw4;
%                     All_bw4_perim(:,:,k) = bw4_perim;
%                     All_Label(:,:,k)=Label;
%                     All_Data(:,:,k)=Data;
% 
%                     if ImageAnalyses{k,:}{6}{1}
%                                     SegDir=fullfile(strcat(SegDirectory,Analysis,'_',num2str(k)),Well);
%                                         if ~exist(SegDir,'file')
%                                         mkdir(SegDir);
%                                         end
%                                     ImName=strcat(BaxterName,'c' ,num2str(AnaChan,'%02.f'),'.tif');
%                                     SegFile=fullfile(SegDir,ImName);
%                                     imwrite(Label,SegFile);   
%                     end
%             end
            
    %% Get Area and Intensities
%         LiveData={All_AnaImage,All_bw4,All_Label,Img2,All_Data};
%        [AllData2,ExportParamNames] = LabelAnalysis(LiveData,Well,Timepoint,AllData2,ExportParamNames);
        
[LiveData] = BronkSegment(ImageAnalyses,Img2,MiPerPix,SegDirectory,Well,BaxterName);
[SpotData] = LabelAnalysis(LiveData,Img2,Well,Timepoint)
test=i+1
AllData2{test}=SpotData

    %% ExportSegment        
    
end
AllData3{1,j+1}=AllData2
end
AllData4{nn}=AllData3
end
%% Write Analysis Data to File
[TPs] = CumCell(AllData4);
[ExportParamNames] = ParamNames(numPlanes);
IntensityExport=array2table(TPs,'VariableNames',ExportParamNames);
