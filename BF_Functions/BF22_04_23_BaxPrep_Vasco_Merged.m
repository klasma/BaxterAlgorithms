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
            %Disks  
            
 
            
%% Analysis Functions
%Input Planes
    numPlanes=3; %Which image Planes to analyze ##Integrate with GUI 
  
   
    
    
    ImageAnalyses=     {
                    {{'Nuc'},{1},{1 0.1},{3},{'Nuc_bw4_perim' [0.8500 0.3250 0.0980]},{true},{}};
                    {{'Cyt'},{2},{1 0.1},{2},{},{true},{}};
                    {{'CytWS'},{2},{0.1},{},{'Cyt_WS_perim' [0.4940, 0.1840, 0.5560]},{true},{}};
                    {{'Gal8'},{2},{0.01},{},{'Gal_bw4_Perim' [0.4940, 0.1840, 0.5560]},{true},{}};
                    };
    
               
    BaxExport=true; %#Integrate with GUI
    
    
    MakeExampleImage=0; %#Integrate with GUI
    MakeOverlayImage=0;%Logical Yes or no to make overlay image #Integrate with GUI
   
        DataName = {};                  
        myStruct = {};         
%% Wells To Analyze
  CustomWells=true;
  
if CustomWells
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
timepoints = [1,4,7,10,13,16,19,22,25,28,31,34,37];
NumSeries = length(wells);
else
NumSeries=r.getSeriesCount(); %The number of different wells you imaged    
    
end
%timepoints = [1];
ExportParamNames = {'CytArea','CytDrug','ECDrug','NucArea','NucDrug','Gal8Area','Gal8Drug','Gal8Sum'};
DataForExport = cell(length(wells),length(timepoints)+1,length(ExportParamNames));

% NumSeries=r.getSeriesCount(); %The number of different wells you imaged
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
for nn = 1 : nWorkers
    % Initialize logging at INFO level
    bfInitLogging('INFO');
    % Initialize a new reader per worker as Bio-Formats is not thread safe
    r2 = javaObject('loci.formats.Memoizer', bfGetReader(), 0);
    % Initialization should use the memo file cached before entering the
    % parallel loop
    r2.setId(ImgFile);

for j=ParSplit+nn-2% Number of wells in ND2 File  
    % Set Current Well and other important values
    %##Would be very useful to figure out how to make this work as a parfor
    %loop, but might be quite difficult
    CurrSeries=j; %The current well that we're looking at
    r2.setSeries(CurrSeries); %##uses BioFormats function, can be swapped with something else (i forget what) if it's buggy with the GUI
    fname = r2.getSeries; %gets the name of the series using BioFormats
    Well=num2str(fname,'%05.f'); %Formats the well name for up to 5 decimal places of different wells, could increase but 5 already feels like overkill 
%     PositionX = readeromeMeta.getPlanePositionX(CurrSeries,1).value(); %May be useful someday, but not needed here
%     PositionY = readeromeMeta.getPlanePositionY(CurrSeries,1).value(); %May be useful someday, but not needed yet. Get's the position of the actual image. Useful for checking stuff
    T_Value = r2.getSizeT()-1; %Very important, the timepoints of the images. Returns the total number of timepoints, the -1 is important.
    SizeX=r2.getSizeX();
    SizeY=r2.getSizeY();

    %CreateFolders for Baxter to read data
        %##Important work: generalize this folder creation and put into GUI, so
        %that whatever segmentations the user creates can be saved for baxter
        %analysis. The "BaxSegFolderCell" is probably the most important and
        %default, but this should be customizable
    
    BaxWellFolder=fullfile(BaxtDirectory,Well); %Creates a filename that's compatible with both PC and Mac (##Check and see if any of the strcat functions need to be replaced with fullfile functions) 
    mkdir(BaxWellFolder); %makes a new folder on your hard drive for the baxter stuff   
    
%     BaxSegFolderNuc=fullfile(exportbaseBAXTSegNuc,Well); %Creates a filename that's compatible with both PC and Mac
%     mkdir(BaxSegFolderNuc); %makes a new folder on your hard drive for the nuclear segmentaiton for Baxter
%     
%     BaxSegFolderCell=fullfile(exportbaseBAXTSegCell,Well); %Creates a filename that's compatible with both PC and Mac
%     mkdir(BaxSegFolderCell);

%     data = bfopen('/path/to/data/file')

Img=zeros(SizeX,SizeY,numPlanes,T_Value+1);
for i=0:T_Value
% Timepoint = num2str(i,'%03.f'); %Creates a string so taht the BioFormats can read it
iplane=r2.getIndex(0,0,i);
    for n=1:numPlanes             
                    Img(:,:,n,i+1)= bfGetPlane(r2,iplane+n);
    end
end
Img=uint16(Img);

for i=0:T_Va lue %For all of the time points in the series, should start at zero if T_Value has -1 built in, which it should
            %Set up the particular timepoint image
        Timepoint = num2str(i,'%03.f'); %Creates a string so taht the BioFormats can read it
%        iplane=reader.getIndex(0,0,i); %Gets the particular timepoint image, so now we're in a particular well at a particular timepoint

%        data= bfopen(
       %        WellTime = round(str2double(readeromeMeta.getPlaneDeltaT(CurrSeries,iplane).value())); %The time that the well image was taken. Very useful for sanity checks
%        Img=[];%Creates an empty array for the image ##Check and see if this is necessary or if there's a more efficient way of doing this.
                         
                        BaxterName=strcat('w',Well,'t',Timepoint) ; %Very important, creates a name in the format that Baxter Algorithms prefers
                        Img2=Img(:,:,:,i+1);                       
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
                        DataName{k} = matlab.lang.makeValidName(Analysis);
                        DataLoop=strcat(DataName{k},'_',num2str(k));

                    switch Analysis
                        case 'Nuc'
                         [bw4,bw4_perim,Label,Data]= NuclearStain(AnaImage,AnaSettings,MiPerPix);
%                              Nuc=AnaImage; 
%                              Nuc_bw4=bw4;
%                              Nuc_bw4_perim=bw4_perim;
                        case 'Cyt'
                         [bw4,bw4_perim,Label,Data] = Cytosol(AnaImage,AnaSettings,MiPerPix);   
%                              Cyt=AnaImage; 
%                              Cyt_bw4=bw4;
%                              Cyt_bw4_perim=bw4_perim;
                        case 'Nuc_Cyt'
                         [bw4,bw4_perim,Label,Data] = Nuc_Cyt(AnaImage,AnaSettings,Cyt,Cyt_bw4,MiPerPix);
                        case 'CytWS'
                            NucChan=ImageAnalyses{k,:}{3}{1};
                             CytChan=ImageAnalyses{k,:}{3}{2};
                            Cyt=myStruct{CytChan}.AnaImage;
                            Nuc_bw4=myStruct{NucChan}.bw4;
                            Cyt_bw4=myStruct{CytChan}.bw4;
                         [Label,bw4_perim,Data] = CytNucWaterShed(Nuc_bw4,Cyt,Cyt_bw4);
%                              CytWS_Label=Label;
%                              CytWS_bw4_perim = bw4_perim;
                        case 'Gal8'    
                         [bw4_perim,bw4,Label,Data] = Gal8(AnaImage,AnaSettings,Cyt_bw4,MiPerPix);
%                              Gal8_Label=Label;
%                              Gal8_bw4_perim = bw4_perim;
%                              Gal8_bw4 = bw4;
                    end
                    myStruct{k}.AnaImage = AnaImage;
                    myStruct{k}.bw4 = bw4;
                    myStruct{k}.bw4_perim = bw4_perim;
                    myStruct{k}.Label=Label;
                    myStruct{k}.Data=Data;

%                     if ~isempty(ImageAnalyses{k,:}{7}) 
%                        for i = 1
%                         Varnames{i} = matlab.lang.makeValidName(ImageAnalyses{k,:}{7}{i});
%                         myStruct.(Varnames{i}) = randi(20,1,1);%Add Values and STuff to store
%                         end
% %                         myStruct.(Varnames{1,1}) % should give you a value of a random number
% %                         myStruct.Indiv_Reg_01 % same result above
                        
                        
%                     end    
%                     if ~isempty(ImageAnalyses{k,:}{4})
%                                     Img_eq=imadjust(AnaImage);
%                                     RGBExportImage(:,:,ImageAnalyses{k,:}{4}{1})=Img_eq;
%                     end
                  
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
%         Varnames{i} = matlab.lang.makeValidName();
%                         myStruct.(Varnames{i}) = randi(20,1,1);%Add Values and STuff to store
%                         
            for stella=1:length(myStruct)
                wellname=matlab.lang.makeValidName(strcat('w',Well));
                timename=matlab.lang.makeValidName(strcat('t',Timepoint));
                wellnumber=fname+1;
%               
                 area= nnz(myStruct{1,stella}.bw4);
                 AllData.(wellname).(timename)(stella,1)= stella;
                AllData.(wellname).(timename)(stella,2)= area;
                for milo=1:numPlanes
                    DataImage=Img2(:,:,milo);
                    SumInt=sum(DataImage(myStruct{1,stella}.bw4));
                    InvInt=sum(DataImage(~myStruct{1,stella}.bw4));
                    Place=2+milo*2;
                    Place2=3+milo*2;
                    SumInt_s=matlab.lang.makeValidName(strcat('Sum',num2str(milo)));
                    InvInt_s=matlab.lang.makeValidName(strcat('Inv',num2str(milo)));
                    AllData.(wellname).(timename)(stella,Place)= SumInt;
                     AllData.(wellname).(timename)(stella,Place2)= InvInt;
                   
                end
                
               
              
            end
    %% ExportSegment        
    
%     SegFile=strcat(BaxSegFolderCell,'\',BaxterName,'.tif');
%     imwrite(eval(BaxMask),SegFile);
%     
    %%
    


%              for z=1:length(ImageAnalyses)
%                         if ~isempty(ImageAnalyses{z,:}{5})
%                             RGBExportImage=imoverlay(RGBExportImage,ImageAnalyses{z,:}{5}{2}),ImageAnalyses{z,:}{5}{2});
%                         end
%                 end  
             if  logical(MakeExampleImage)               
                        
                    %##Need to add more if statements here
%                     RGBExportImage=uint8(RGBExportImage);
%                     RGBExportImage
                    OverlayName=fullfile(OverlaidDirectory,BaxterName);
                    imwrite(RGBExportImage, strcat(OverlayName,'.tif'),'tif');
                    RGBExportImage=[];
             end
           
            RGBExportImage=[];
                %% Measure Image Data
            %##Write Code here that uses parameters set in the GUI to take
            %all of the data we'd be interested in analyzing. Will probably
            %need to get clever with the analysis function output names in
            %order to make it all work with an arbitrary number of analyses
            %and image planes
    
end   
end   
end
%% Write Analysis Data to File
%  
% D=[Categories;C];
% WritingHere=strcat(exportdir,'\','Gal8','_',run);
%  writecell(D,strcat(WritingHere,'.xlsx')); % Exports an XLSX sheet of your data
% 
%% add code that writes the text of this code with the timestamp to a record every time it is run