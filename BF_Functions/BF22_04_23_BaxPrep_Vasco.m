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
GitLog=sprintf('%sbackup_%s.m',Gitdir,Version);
% GitLog=sprintf('%sbackup_%s.m',LogFolder,Version);
% mkdir(RunLog);
currentfile=strcat(FileNameAndLocation, '.m');
copyfile(currentfile,newbackup);
copyfile(currentfile,GitLog)
% A = exist(newbackup,'file');
% if (A~=0)
% warning('Backup already exists for the current version')
% end
%##This may not be the best way to be logging the data and directory, since
%it's in a new folder every time, but we can figure htis otu later. Also
%might be possible to write this all into a function


%% Sizing/Resolution Parameters EDIT HERE ADVANCED

        %NEED TO ADD microns per Pixel %NEED TO ADD Cell size (Small, Medium, Large)%Go through this and make all disks calculated on the microns per pixel and %the Cell Size

MiPerPix=0.34;        
CellSize=1; %Scale as needed for different Cells        
            %Disks  
            
 
            
%% Analysis Functions
%Input Planes
    numPlanes=3; %Which image Planes to analyze ##Integrate with GUI 
    Nuc_bw4_perim=0;
    %{{'function'},{ImageToAnalyze},{InputParameter},{OverlayImage(1=Red
    %Plane 2=G 3=B)},{Mask/Perimeter to Overlay});
    
    
    ImageAnalyses=    {
                        {{'Nuc'},{1},{4 0.4 0.2},{3},{'Nuc_bw4_perim' [0.8500 0.3250 0.0980]},{true},{}};
                        {{'Cyt'},{2},{1 0.3},{2},{},{false},{}};
                        {{'CytWS'},{2},{1,2},{},{'Cyt_WS_perim' [0.4940, 0.1840, 0.5560]},{true},{}};
                        {{'Gal8'},{2},{0.1},{},{'Gal_bw4_Perim' [0.4940, 0.1840, 0.5560]},{true},{}};
                            };%Which Image analysis/functions to call. ##NEed to solve problem of secondary analyses like watershed of Nuc and Cytosol or gal8 and cytosol
    
    
       DataName = {};                  
       myStruct = {};                 
    BaxExport=true; %#Integrate with GUI
    
    
%     eval(ImageAnalyses{z,:}{5}{1})
%     if BaxExport
%         for z=1:length(ImageAnalyses)
%             exportbaseBAXTSeg=fullfile(SegDirectory,strcat(ImageAnalyses{z,:}{1}{1},'_',num2str(z)));
%             mkdir(exportbaseBAXTSeg);
%         end 
%     end
    
%     BaxMask='Cyt_WS';
    MakeExampleImage=0; %#Integrate with GUI
    MakeOverlayImage=0;%Logical Yes or no to make overlay image #Integrate with GUI
    % ##Add selection for what to overlay on the overlay image, for example,
    % showing the cytosol perimeter analysis or Not

    % ##Add selection for data of interest from each analysis, i.e. what to
    % export from each function
    %
    
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

% C = cell(NumImg,length(Categories)); 
%##C is something that will probably have be edited to allow data output
%from this scale of the analysis. Don't even know if it's correct right now
%or even neccessary at all


%% SARA: Making Variables for GUI
NumWells=NumSeries+1; %Put this Variable in the GUI (in the parameters tab) so the user knows how many images they have. Also might be useful to do the same as I did here for NumColors NumTimepoint NumImg 
WellStart=1; % Have this update by user in GUI
WellStart=WellStart-1;
WellEnd= 1; % Have this update by user in GUI
WellEnd=WellEnd-1;
%


%% Analysis Program 
% j=0:NumSeries-1
% for j=0:1
% 
% 
% end
%WriteGUI so that first step edits below, then "go" button runs this all,
%or "test" button runs just selected image in the series
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