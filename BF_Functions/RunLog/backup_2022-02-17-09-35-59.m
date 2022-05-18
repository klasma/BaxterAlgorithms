%% Gal8 Recruitment MATLAB Program
%% Image Folder Location
clc, clear, close all
reader = bfGetReader(char("D:\Dropbox (VU Basic Sciences)\Duvall Confocal\Duvall Lab\Brock Fletcher\2021-09-21-DB-Addition\PSINPsDB Screen001.nd2"));
exportdir=char('D:\Dropbox (VU Basic Sciences)\Duvall Confocal\Duvall Lab\Brock Fletcher\2021-09-21-DB-Addition\2022-02-09-Crazy');
if ~exist(exportdir,'file')
mkdir(exportdir);
end
%% Directory Code

run=char(datetime(clock),"yyyy-MM-dd-hh-mm-ss");    % The Run number is used to track multiple runs of the software, and is used in
          
readeromeMeta=reader.getMetadataStore();
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



            %##Need to universalize the Segmentation stuff for whatever the
            %GUI needs, so that it can be arbitrarily named and assigned.
            %Might be a good idea to write this all into a function

%%Log Data
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
%Bit Depth    
    bitdepthin= 12; %Bit depth of original image, usually 8, 12, or 16
    bitConvert=(2^16/2^bitdepthin); %This assures that whatever the bit depth of the input image, the analyzed images are all 16 bit.
%Input Planes
    numPlanes=3; %Which image Planes to analyze ##Integrate with GUI 
    Nuc_bw4_perim=0;
    %{{'function'},{ImageToAnalyze},{InputParameter},{OverlayImage(1=Red
    %Plane 2=G 3=B)},{Mask/Perimeter to Overlay});
    ImageAnalyses=    {
                        {{'Cyt'},{1},{1 0.4},{2},{},{false}};
                         {{'Nuc_Cyt'},{3},{4 0.4 0.2},{3},{'Nuc_bw4_perim' [0.8500 0.3250 0.0980]},{true}};
                        {{'CytWS'},{1},{0.1},{},{'Cyt_WS_perim' [0.4940, 0.1840, 0.5560]},{true}};
                        {{'Gal8'},{1},{0.1},{},{'Gal_bw4_Perim' [0.4940, 0.1840, 0.5560]},{true}};
         
                            };%Which Image analysis/functions to call. ##NEed to solve problem of secondary analyses like watershed of Nuc and Cytosol or gal8 and cytosol
    
                        
    BaxExport=true; %#Integrate with GUI
    
    
%     eval(ImageAnalyses{z,:}{5}{1})
%     if BaxExport
%         for z=1:length(ImageAnalyses)
%             exportbaseBAXTSeg=fullfile(SegDirectory,strcat(ImageAnalyses{z,:}{1}{1},'_',num2str(z)));
%             mkdir(exportbaseBAXTSeg);
%         end 
%     end
    
    BaxMask='Cyt_WS';
    MakeExampleImage=0; %#Integrate with GUI
    MakeOverlayImage=0;%Logical Yes or no to make overlay image #Integrate with GUI
    % ##Add selection for what to overlay on the overlay image, for example,
    % showing the cytosol perimeter analysis or Not

    % ##Add selection for data of interest from each analysis, i.e. what to
    % export from each function
    %
    
%% Image Thresholding EDIT HERE BASIC 
    %##Need to make these into GUI, and make universal so that as we call
    %each function we can set the function parameters in the GUI. I believe
    %Baxter has a very good solution for doing this
    %Nuclear Stain
        NucMax=0.8;%Number 0-1, removes Cell Debris brighter than this value in order to allow low end to remain visible. 0.2 is usually a good start 
        NucLow=100;%
     %Cytosol    
        CytMax= 0.5; %Number 0-1, removes Cell Debris brighter than this value. 0.2 is usually a good start  
        CytLow=0; %Choose number 0-20, start at 0. Higher numbers remove more dim cells and background.
    %Gal8
        Gal8MinThreshold=0.2;%Number 0-1, removes Puncta Dimmer than this value. 0.05 is usually a good start 
    %Drugamine
        Drug_threshold = 0.01; %Number 0-1, removes Drugmine signal dimmer than threshold
%         Drug_threshold_Big = 100;
%% Analysis Variables

% Categories=[{'run'},{'well'},{'areacell'},{'CellSum'},{'areaGal8'},{'galsum'},{'areaDrug'},{'Drugsum'},{'DrugAvgInCell'},{'DrugAvgOutCell'}]; 
%##Categories are manually typed out here, but it should integrate so that
%these are auto-populated or selectable within the GUI, might have to get
%clever for this to work

NumSeries=reader.getSeriesCount(); %The number of different wells you imaged
NumColors=reader.getEffectiveSizeC(); %The number of colors of each well you imaged
NumTimepoint=(reader.getImageCount())/NumColors; %The number of timepoints you imaged
NumImg=NumSeries*NumTimepoint*NumColors; %The total number of images, combining everything

% C = cell(NumImg,length(Categories)); 
%##C is something that will probably have be edited to allow data output
%from this scale of the analysis. Don't even know if it's correct right now
%or even neccessary at all
%% Analysis Program 
% j=0:NumSeries-1
% for j=0:1
% 
% 
% end
for j=0:1% Number of wells in ND2 File  
    % Set Current Well and other important values
    %##Would be very useful to figure out how to make this work as a parfor
    %loop, but might be quite difficult
    CurrSeries=j; %The current well that we're looking at
    reader.setSeries(CurrSeries); %##uses BioFormats function, can be swapped with something else (i forget what) if it's buggy with the GUI
    fname = reader.getSeries; %gets the name of the series using BioFormats
    Well=num2str(fname,'%05.f'); %Formats the well name for up to 5 decimal places of different wells, could increase but 5 already feels like overkill 
%     PositionX = readeromeMeta.getPlanePositionX(CurrSeries,1).value(); %May be useful someday, but not needed here
%     PositionY = readeromeMeta.getPlanePositionY(CurrSeries,1).value(); %May be useful someday, but not needed yet. Get's the position of the actual image. Useful for checking stuff
    T_Value = reader.getSizeT()-1; %Very important, the timepoints of the images. Returns the total number of timepoints, the -1 is important.
    
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
Img=zeros(2048,2048,numPlanes,T_Value+1);
for i=0:2 
% Timepoint = num2str(i,'%03.f'); %Creates a string so taht the BioFormats can read it
iplane=reader.getIndex(0,0,i);
    for n=1:numPlanes             
                    Img(:,:,n,i+1)= bitConvert*bfGetPlane(reader,iplane+n);
    end
end
Img=uint16(Img);

parfor i=0:T_Value %For all of the time points in the series, should start at zero if T_Value has -1 built in, which it should
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

                    switch Analysis
                        case 'Nuc'
                         [bw4,bw4_perim,Label]= NuclearStain(AnaImage,AnaSettings,MiPerPix);   
                             if ~isempty(ImageAnalyses{k,:}{4})
                                    Img_eq=AnaImage;
                                    RGBExportImage(:,:,ImageAnalyses{k,:}{4}{1})=Img_eq;
                             end
                             if ImageAnalyses{k,:}{6}{1}
                                    SegDir=fullfile(strcat(SegDirectory,Analysis,'_',num2str(k)),Well);
                                        if ~exist(SegDir,'file')
                                        mkdir(SegDir);
                                        end
                                    ImName=strcat(BaxterName,'c' ,num2str(AnaChan,'%02.f'),'.tif');
                                    SegFile=fullfile(SegDir,ImName);
                                    imwrite(Label,SegFile);   
                              end
                        case 'Cyt'
                         [Cyt_bw4,bw4_perim] = Cytosol(AnaImage,AnaSettings,MiPerPix);   
                                Cyt=AnaImage;
                             if ~isempty(ImageAnalyses{k,:}{4})
                                    Img_eq=imadjust(AnaImage);
                                    RGBExportImage(:,:,ImageAnalyses{k,:}{4}{1})=Img_eq;
                             end
                             if ImageAnalyses{k,:}{6}{1}
                                     SegDir=fullfile(strcat(SegDirectory,Analysis,'_',num2str(k)),Well);
                                        if ~exist(SegDir,'file')
                                        mkdir(SegDir);
                                        end
                                    ImName=strcat(BaxterName,'c',num2str(AnaChan,'%02.f'),'.tif');
                                    SegFile=fullfile(SegDir,ImName);
                                    imwrite(Cyt_bw4,SegFile);   
                             end
                              
                        case 'Nuc_Cyt'
                               [Nuc_bw4,erim,NucLabel] = Nuc_Cyt(AnaImage,AnaSettings,Cyt,Cyt_bw4,MiPerPix);
                           if ~isempty(ImageAnalyses{k,:}{4})
                                    Img_eq=imadjust(AnaImage);
                                    RGBExportImage(:,:,ImageAnalyses{k,:}{4}{1})=Img_eq;
                           end
                             if ImageAnalyses{k,:}{6}{1}
                                     SegDir=fullfile(strcat(SegDirectory,Analysis,'_',num2str(k)),Well);
                                        if ~exist(SegDir,'file')
                                        mkdir(SegDir);
                                        end
                                    ImName=strcat(BaxterName,'c',num2str(AnaChan,'%02.f'),'.tif');
                                    SegFile=fullfile(SegDir,ImName);
                                    imwrite(NucLabel,SegFile);   
                              end
                                
                        case 'CytWS'
                            [Cyt_WS,Cyt_WS_perim] = CytNucWaterShed(Nuc_bw4,Cyt,Cyt_bw4);
                            if ~isempty(ImageAnalyses{k,:}{4})
                                    Img_eq=imadjust(AnaImage);
                                    RGBExportImage(:,:,ImageAnalyses{k,:}{4}{1})=Img_eq;
                             end
                             if ImageAnalyses{k,:}{6}{1}
                                     SegDir=fullfile(strcat(SegDirectory,Analysis,'_',num2str(k)),Well);
                                        if ~exist(SegDir,'file')
                                        mkdir(SegDir);
                                        end
                                    ImName=strcat(BaxterName,'c',num2str(AnaChan,'%02.f'),'.tif');
                                    SegFile=fullfile(SegDir,ImName);
                                    imwrite(Cyt_WS,SegFile);   
                              end
                                
                        case 'Gal8'    
                            [Gal_bw4_Perim,Gal_bw4,Gal_Label] = Gal8(AnaImage,AnaSettings,Cyt_bw4,MiPerPix);
                            if ~isempty(ImageAnalyses{k,:}{4})
                                    Img_eq=imadjust(AnaImage);
                                    RGBExportImage(:,:,ImageAnalyses{k,:}{4}{1})=Img_eq;
                                    PerimeterImg=Gal_bw4_Perim;
                             end
                             if ImageAnalyses{k,:}{6}{1}
                                     SegDir=fullfile(strcat(SegDirectory,Analysis,'_',num2str(k)),Well);
                                        if ~exist(SegDir,'file')
                                        mkdir(SegDir);
                                        end
                                    ImName=strcat(BaxterName,'c',num2str(AnaChan,'%02.f'),'.tif');
                                    SegFile=fullfile(SegDir,ImName);
                                    imwrite(Gal_Label,SegFile);
                                    
%                                         if ~isempty(ImageAnalyses{z,:}{5})
%                                             ImageAnalyses{k,:}{5}{2}
%                                         end
                              end
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
                    OverlayName=fullfile(OverlaidDirectory,BaxterName);
                    imwrite(RGBExportImage, strcat(OverlayName,'.tif'),'tif');
                    RGBExportImage=[];
             end
           
    
                %% Measure Image Data
            %##Write Code here that uses parameters set in the GUI to take
            %all of the data we'd be interested in analyzing. Will probably
            %need to get clever with the analysis function output names in
            %order to make it all work with an arbitrary number of analyses
            %and image planes
    
end   
end   

%% Write Analysis Data to File
%  
% D=[Categories;C];
% WritingHere=strcat(exportdir,'\','Gal8','_',run);
%  writecell(D,strcat(WritingHere,'.xlsx')); % Exports an XLSX sheet of your data
% 
%% add code that writes the text of this code with the timestamp to a record every time it is run