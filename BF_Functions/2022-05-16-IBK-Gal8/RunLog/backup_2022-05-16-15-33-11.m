%% Gal8 Recruitment MATLAB Program
%% Image Folder Location 
    %User Defines location of Image file and location of directory to
    %export to.
clc, clear, close all
ImgFile=char("D:\Dropbox (VU Basic Sciences)\Duvall Confocal\Duvall Lab\Isom Kelly\Gal8 Overnight + Uptake VDB.nd2");
r = loci.formats.Memoizer(bfGetReader(),0);
r.setId(ImgFile);
exportdir=char('D:\Dropbox (VU Basic Sciences)\Duvall Confocal\Duvall Lab\Isom Kelly\2022-05-16-BF-Gal8Analysis');
if ~exist(exportdir,'file')
mkdir(exportdir);
end

%% Directory Code
    %This section makes directories to export everything to
run=char(datetime(clock),"yyyy-MM-dd-HH-mm-ss");    % The Run number is used to track multiple runs of the software, and is used in
          
readeromeMeta=r.getMetadataStore();
RunDirectory= fullfile(exportdir,run);
mkdir(RunDirectory); 

OverlaidDirectory = fullfile(RunDirectory,'Overlaid');
mkdir(OverlaidDirectory); 

BaxtDirectory = fullfile(RunDirectory,'Baxter');
mkdir(BaxtDirectory);

LogDirectory = fullfile(RunDirectory,'Log');
mkdir(LogDirectory);

 SegDirectory = fullfile(BaxtDirectory,'Analysis','Segmentation_'); %We wait to make the muiltiple segmentation directories until they are needed later on.

   
%% Log Data
Version=run;
LogFile=strcat(LogDirectory,'\');
FileNameAndLocation=[mfilename('fullpath')];
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
MiPerPix=0.34; %The resolution of your microscopy, in Microns per pixel. A very important parameter. #PROJECT: I believe OME and BioFormats could pull this automagically        
CellSize=1;  %Scale as needed for different Cells. Not currently used but maybe incorporate later      
        
BitDepth=12;


%% Analysis Functions
%Input Planes
    numPlanes=3; %Which image Planes to analyze ##Integrate with GUI 
    BaxExport=true; %Do you wish to export images to folder so they can be analyzed using BaxterAlgorithms? #Integrate with GUI.
    MakeCompImage=true;
    Parallelize=false;
%         MakeCompImage is useful for storing your segements for quick
%         checks, but will take up more storage space. It's reccomended to
%         leave on as you check paramters, but then to turn it off if
%         you're anlayzing a very large file. you can always use the
%         BaxExport and Segment images to check everything in Baxter
%         Algorithms.

   %IMPORTANT: ImageAnalyses is the heart of the user-input Data. Each Row is a pass
   %of the program, and contained within each row is all the data needed for analysis.
   
    ImageAnalyses=    {
                        {{'NucPlus'},{1},{2 0.04 0.2 2 [20 80]},  {3},    {[1 0 1]},{true},{}};
                        {{'Cyt'},   {2},{1 0.175},   {2},    {},{true},{}};
                        {{'CytWS'}, {2},{1 2},      {},     {[0 1 1]},{true},{}};
                        {{'Gal8'},  {2},{0.004 2},  {},     {[0.4940 0.1840 0.5560]},{true},{}};
                        {{'Drug'},  {3},{0.9},      {1},    {[0.8500 0.3250 0.0980]},{true},{}};
%                         {{'Nuc'},{1},{2 0.2},{3},{'Nuc_bw4_perim' [0.8500 0.3250 0.0980]},{true},{}};
%                         {{'Cyt'},{2},{1 0.1},{2},{},{true},{}};
%                         {{'Gal8'},{2},{0.01},{},{'Gal_bw4_Perim' [0.4940, 0.1840, 0.5560]},{true},{}};
%                         {{'Cyt'},{1},{5 0.2},{2},{},{true},{}};
%                         {{'Cyt'},{2},{4 0.2},{1},{},{true},{}};
%                         {{'Gal8'},{2},{0.004 2},{},{},{true},{}};
                            };%Which Image analysis/functions to call. 
    
    %Here's a key to what each cell represents:
    %{{'Analysis Program'},{Image Plane Number to analyze},{Paramter1 Parameter2},{Output Image Color (1=r 2=g 3=b},{},{Export a Segmented Image? True or False},{}}
    % At Present ImageAnalyses{k,:}{5} and {7} are available to add
    % additional capabilities. This whole package is taken by the
    % BronkSegment Function to define the analysis parameters
    
    %Set Blanks for speed optimization purposes
       DataName = {};                  
       LiveData = {};
       AllData2 = {};
       
%% Analysis Variables
    %Define What to Analyze
    %#PROJECT: This section needs to be finished and integrated with the GUI. 
    % The goal would be to have a simple way of either analyzing all the wells, 
    % a single well, or only a selected list of wells and timepoints.
    
    customrun=false; %False analyzes all the wells, true analyzes only select few wells
 FastRun=8;
    if customrun
    NumSeries=FastRun; % #PROJECT: This will need to be modified to allow selected wells to run

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
    NumSeries=r.getSeriesCount(); %The count of all the wells you imaged

    end
NumColors=r.getEffectiveSizeC(); %The number of colors of each well you imaged
NumTimepoint=(r.getImageCount())/NumColors; %The number of timepoints you imaged
NumImg=NumSeries*NumTimepoint*NumColors; %The total number of images, combining everything
    %Generate Parallel Pool for analysis
     poolobj = gcp;
            if isempty(poolobj)
                nWorkers = 1;
            else
                if Parallelize
                nWorkers = poolobj.NumWorkers;
                else
                 nWorkers = 1;
                end
            end
ParSplit=[1:nWorkers:NumSeries]; %This splits everything so that it can be parrallelized even though OME does not support Parfor. Basically, we make a list of which cores will handle which wells ahead of time.

%% Analysis Program 
AllData4={}; %Blank for Parfor CompSci reasons
   for nn = 1 : nWorkers % Initialize logging at INFO level
        bfInitLogging('INFO'); % Initialize a new reader per worker as Bio-Formats is not thread safe
        r2 = javaObject('loci.formats.Memoizer', bfGetReader(), 0); % Initialization should use the memo file cached before entering the parallel loop
        r2.setId(ImgFile);
        
            AllData3={};%Clear because parfor  
            RunNum=0
            for j=ParSplit+nn-2% Number of wells in ND2 File. Dependent on nn so that each worker has its own list of wells to analyze
                
                if j<=(NumSeries-1)
                RunNum=RunNum+1    
                %Prep Metadata
                CurrSeries=j; %The current well that we're looking at
                r2.setSeries(CurrSeries); %##uses BioFormats function, can be swapped with something else (i forget what) if it's buggy with the GUI
                fname = r2.getSeries; %gets the name of the series using BioFormats
                Well=num2str(fname,'%05.f'); %Formats the well name for up to 5 decimal places of different wells, could increase but 5 already feels like overkill 
                T_Value = r2.getSizeT()-1; %Very important, the timepoints of the images. Returns the total number of timepoints, the -1 is important.
%                 T_Value = 1
                SizeX=r2.getSizeX(); %Number of pixels in image in X dimension
                SizeY=r2.getSizeY(); %Number of pixels in image in Y Dimension
                    
                    BaxWellFolder=fullfile(BaxtDirectory,Well); %Creates a filename that's compatible with both PC and Mac (#PROJECT: Check and see if any of the strcat functions need to be replaced with fullfile functions) 
                    if logical(BaxExport)
                    if ~isfolder(BaxWellFolder)
                        mkdir(BaxWellFolder); %makes a new folder on your hard drive for the baxter stuff   
                        end
                    end
                    AllData2={};%Clear because parfor 
                    for i=0:T_Value %For all of the time points in the series, should start at zero if T_Value has -1 built in, which it should
                        Img2=zeros(SizeY,SizeX,numPlanes);  %Make a blank shell for the images  
                                iplane=r2.getIndex(0,0,i);
                                for n=1:numPlanes             
                                        Img2(:,:,n)= bfGetPlane(r2,iplane+n); %Creates a 3D matrix with every image color channel as a different layer. Matlab fast at matrixes
                                end
                                Img2=Img2*(65536)/(2^BitDepth);
                                Img2=uint16(Img2); %Converts Images to uint16 so they're always the same for downstream analysis.
        %##PROJECT: uint8 may be faster and better than uint16 because it would enable GPU integration.
        %However,our Nikon images are captured in uint12,and often the
        %dimmest pixels are very important for demarcating nuclei or cells.
        %Therefore, would need to experiment with.

                        
                            Timepoint = num2str(i,'%03.f'); %Creates a string so that the BioFormats can read it
                            BaxterName=strcat('w',Well,'t',Timepoint) ; %Very important, creates a name in the format that Baxter Algorithms prefers                     
                            ImageName=fullfile(BaxWellFolder,BaxterName); %Creates a name for each particular image
                                
                                if logical(BaxExport)    %Export Images for Baxter
                                    for n=1:numPlanes                        
                                        Img3=Img2(:,:,n);
                                        my_field = strcat('c',num2str(n,'%02.f'));
                                        imwrite((Img3), strcat(ImageName,my_field,'.tif'),'tif');
                                    end
                                end
                                
                            %% Analyze Images Custom Functions
                            [LiveData] = BronkSegment(ImageAnalyses,Img2,MiPerPix,SegDirectory,Well,BaxterName,MakeCompImage,OverlaidDirectory);
                                % #PROJECT: The way I formatted LiveData
                                % would probably be faster for matlab to
                                % use in the LabelAnalysis function if it
                                % was structured differently.
                                
                                % #PROJECT: I'd like to see someday if running
                                % BronkSemgent and LabelAnalysis on the GPU
                                % would potentially make them faster
                                
                                
                       %% Get Area and Intensity data for every combination of channels
                            [TidyFeat] = LabelAnalysis(LiveData,Img2,Well,Timepoint);
                                % #PROJECT: LabelAnalysis was written
                                % quickly and could likely be optimized to
                                % run faster. It's relatively slow.
               
                           AllData2{i+1}=TidyFeat
                           

                    end

                AllData3{RunNum}=AllData2


                else
                end    
            end
            RunNum=0

            AllData4{nn}=AllData3 %Store Data in parfor-compatible way
    end %end of all analysis

    
%% Write Analysis Data to File    
[TPs] = CumCell2(AllData4); %Custom Function to combine weird data format from parfor Loop
[ExportParamNames] = ParamNames(numPlanes); %Export the names of the parameters used for analysis
IntensityExport=array2table(TPs,'VariableNames',ExportParamNames); %Make a table with all of the data
ExcelName=fullfile(RunDirectory,strcat(run,'.xlsx')); %Prepare excel file name
writetable(IntensityExport,ExcelName) %Write Excel file of all analysis Data
