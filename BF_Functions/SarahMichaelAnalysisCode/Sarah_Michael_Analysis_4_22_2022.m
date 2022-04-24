%% Gal8 Recruitment MATLAB Program
%% Image Folder Location
clc, clear, close all

%ImgFile=char("Z:\Dropbox (VU Basic Sciences)\Duvall Confocal\Duvall Lab\Brock Fletcher\2021-09-08\DoseResponse\Gal8\BF_Gal8Overnight_Test003.nd2");
ImgFile=char("/Users/sarahreilly/Desktop/20211002BigProteinScreen.nd2");
r = loci.formats.Memoizer(bfGetReader(),0);
r.setId(ImgFile);
exportdir = char('/Users/sarahreilly/Desktop/Export');
ExportFile=char('/Users/sarahreilly/Desktop/TestData.xlsx'); % blank spreadsheet for output data
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

%%Log Data
Version=run;
LogFile=strcat(LogDirectory,'\');
FileNameAndLocation=[mfilename('fullpath')]; %#ok<NBRAK>
newbackup=sprintf('%sbackup_%s.m',LogFile,Version);
Gitdir=fullfile(pwd,'RunLog\');
GitLog=sprintf('%sbackup_%s.m',Gitdir,Version);
currentfile=strcat(FileNameAndLocation, '.m');
copyfile(currentfile,newbackup);
copyfile(currentfile,GitLog)


%% Sizing/Resolution Parameters EDIT HERE ADVANCED

MiPerPix=0.34;        
CellSize=1; %Scale as needed for different Cells                    
 
            
%% Analysis Functions
%Bit Depth    
bitdepthin= 12; %Bit depth of original image, usually 8, 12, or 16
bitConvert=(2^16/2^bitdepthin); %This assures that whatever the bit depth of the input image, the analyzed images are all 16 bit.

%Input Planes
numPlanes=3; %Which image Planes to analyze ##Integrate with GUI 
Nuc_bw4_perim=0;

ImageAnalyses=    {
                    {{'Nuc'},{1},{1 0.1},{3},{'Nuc_bw4_perim' [0.8500 0.3250 0.0980]},{true},{}};
                    {{'Cyt'},{2},{1 0.1},{2},{},{true},{}};
                    {{'CytWS'},{2},{0.1},{},{'Cyt_WS_perim' [0.4940, 0.1840, 0.5560]},{true},{}};
                    {{'Gal8'},{2},{0.01},{},{'Gal_bw4_Perim' [0.4940, 0.1840, 0.5560]},{true},{}};
                    };%Which Image analysis/functions to call. ##Need to solve problem of secondary analyses like watershed of Nuc and Cytosol or gal8 and cytosol
                                      
BaxExport=false; %#Integrate with GUI

BaxMask='Cyt_WS';
MakeExampleImage=0; %#Integrate with GUI
MakeOverlayImage=0;%Logical Yes or no to make overlay image #Integrate with GUI


%% Analysis Variables

NumSeries=r.getSeriesCount(); %The number of different wells you imaged
NumColors=r.getEffectiveSizeC(); %The number of colors of each well you imaged

NumTimepoint=(r.getImageCount())/NumColors; %The number of timepoints you imaged
NumImg=NumSeries*NumTimepoint*NumColors; %The total number of images, combining everything
nWorkers = 4;
ParSplit=[1:nWorkers:NumSeries]; %#ok<NBRAK>

%% SARAH: Making Variables for GUI
NumWells=NumSeries+1; %Put this Variable in the GUI (in the parameters tab) so the user knows how many images they have. Also might be useful to do the same as I did here for NumColors NumTimepoint NumImg 
WellStart=1; % Have this update by user in GUI
WellStart=WellStart-1;
WellEnd= 1; % Have this update by user in GUI
WellEnd=WellEnd-1;
%


%% Analysis Program 

% Initialize logging at INFO level
bfInitLogging('INFO');
% Initialize a new reader per worker as Bio-Formats is not thread safe
r2 = javaObject('loci.formats.Memoizer', bfGetReader(), 0);
% Initialization should use the memo file cached before entering the
% parallel loop
r2.setId(ImgFile);

wells = [1 2 48 47 3 4 46 45 59 60 86 85 61 62 84 83 63 64 82 81 65 66 80 79 145 146 192 191,...
         147 148 190 189 203 204 230 229 205 206 228 227 207 208 226 225 209 210 224 223];
well_names =   {'A01.1','A01.2','A01.3','A01.4'...
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
%timepoints = [1,4,7,10,13,16,19,22,25,28,31,34,37];
timepoints = [1];
ExportParamNames = {'CytArea','CytDrug','ECDrug','NucArea','NucDrug','Gal8Area','Gal8Drug','Gal8Sum'};
DataForExport = cell(length(wells),length(timepoints)+1,length(ExportParamNames));

for i=1:length(ExportParamNames)
    DataForExport(:,1,i) = well_names;
end

for j=1:size(wells,2)% Number of wells in ND2 File 
    
        CurrSeries=wells(j)-1; %The current well that we're looking at
        r2.setSeries(CurrSeries); %##uses BioFormats function, can be swapped with something else (i forget what) if it's buggy with the GUI
        fname = r2.getSeries; %gets the name of the series using BioFormats
        Well=num2str(fname,'%05.f'); %Formats the well name for up to 5 decimal places of different wells, could increase but 5 already feels like overkill 
        T_Value = r2.getSizeT()-1; %Very important, the timepoints of the images. Returns the total number of timepoints, the -1 is important.
        SizeX=r2.getSizeX();
        SizeY=r2.getSizeY();

        BaxWellFolder=fullfile(BaxtDirectory,Well); %Creates a filename that's compatible with both PC and Mac (##Check and see if any of the strcat functions need to be replaced with fullfile functions) 
        mkdir(BaxWellFolder); %makes a new folder on your hard drive for the baxter stuff   

        Img=zeros(SizeX,SizeY,numPlanes,T_Value+1);

        for i=1:length(timepoints)
            % Timepoint = num2str(i,'%03.f'); %Creates a string so that the BioFormats can read it
            iplane=r2.getIndex(0,0,timepoints(i)-1);
            for n=1:numPlanes             
                Img(:,:,n,i)= bfGetPlane(r2,iplane+n)';
            end
        end
        
        Img=uint16(Img);

        %for i=0:T_Value %For all of the time points in the series, should start at zero if T_Value has -1 built in, which it should
        for i=1:length(timepoints) %For all of the time points in the series, should start at zero if T_Value has -1 built in, which it should
                    %Set up the particular timepoint image
            Timepoint = num2str(timepoints(i)-1,'%03.f'); %Creates a string so taht the BioFormats can read it
        %        iplane=reader.getIndex(0,0,i); %Gets the particular timepoint image, so now we're in a particular well at a particular timepoint

        %        data= bfopen(
               %        WellTime = round(str2double(readeromeMeta.getPlaneDeltaT(CurrSeries,iplane).value())); %The time that the well image was taken. Very useful for sanity checks
        %        Img=[];%Creates an empty array for the image ##Check and see if this is necessary or if there's a more efficient way of doing this.

            BaxterName=strcat('w',Well,'t',Timepoint) ; %Very important, creates a name in the format that Baxter Algorithms prefers
            Img2=Img(:,:,:,i);                       
            ImageName=fullfile(BaxWellFolder,BaxterName); %Creates a name for each particular image

            for n=1:numPlanes             
%                 Img(:,:,n)= bitConvert*bfGetPlane(reader,iplane+n);
                if logical(BaxExport)
                    my_field = strcat('c',num2str(n,'%02.f'));
                    imwrite(Img2(:,:,n), strcat(ImageName,my_field,'.tif'),'tif');
                end
            end
            
            for k=1:length(ImageAnalyses)
                Analysis=ImageAnalyses{k,:}{1}{1};
                AnaChan=ImageAnalyses{k,:}{2}{1};
                AnaImage=Img2(:,:,AnaChan);
                AnaSettings= ImageAnalyses{k,:}{3};
%                     Storage
                switch Analysis
                    case 'Nuc'
                     [Nuc_bw4,Nuc_bw4_perim,Label]= NuclearStain(AnaImage,AnaSettings,MiPerPix);
                    
                    case 'Cyt'
                     [Cyt_bw4,Cyt_bw4_perim] = CytosolQuant(AnaImage,AnaSettings,MiPerPix);   
                            Cyt=AnaImage; 
                            
                    case 'CytWS'
                     [CytWS_bw4,CytWS_bw4_perim] = CytNucWaterShed(Nuc_bw4,Cyt,Cyt_bw4);
                     
                    case 'Gal8'    
                     [Gal8_bw4_perim,Gal8_bw4,Label] = Gal8(AnaImage,AnaSettings,Cyt_bw4,MiPerPix);
                     Gal8_Label=Label;
                     
                end
            end
            
            % Save data from each image
            CytImg = Img2(:,:,2);
            DrugImg = Img2(:,:,3);
            [ExportParams] = DrugParams(Cyt_bw4,Nuc_bw4,Gal8_bw4,CytImg,DrugImg);
            
            DataForExport(j,i+1,:) = ExportParams;
            
           figure
           imshow(imoverlay(imadjust(Img2(:,:,2)),CytWS_bw4_perim))
        end   
     
end
%% Write Analysis Data to File
ExportParamNames = {'CytArea','CytDrug','ECDrug','NucArea','NucDrug','Gal8Area','Gal8Drug','Gal8Sum'};

for i=1:length(ExportParamNames)
    writecell(DataForExport(:,:,i),ExportFile,'Sheet',char(ExportParamNames(i)));
end
%% add code that writes the text of this code with the timestamp to a record every time it is run