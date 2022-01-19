%% Gal8 Recruitment MATLAB Program

% Written by Brock Fletcher in the Biomedical Engineering Department at
% Vanderbilt University 2017 - 2022 in the course of his PhD studies
% advised by Craig Duvall (https://my.vanderbilt.edu/duvall/). 
%Adapted from work by Kameron V Kilchrist, 2015 - 2018 in the course of his PhD studies
% advised by Craig Duvall (https://my.vanderbilt.edu/duvall/), published in
% Kilchrist, Dimobi, ..., Duvall; "Gal8
% Visualization of Endosome Disruption Predicts Carrier-mediated Biologic
% Drug Intracellular Bioavailability".

% University Email: brock.fletcher@vanderbilt.edu 
% Permanent Email: brockfletch@gmail.com 

% This code may be reused at will for non-commercial purposes. 
% Licensed under a Creative Commons Attribution 4.0 International License.

% Derivative code should be published at GitHub or FigShare. Derivative
% scientific works should cite _______________
%% Usage Guide (TL/DR):
    %Steps
        %Export your fluorescent microscopy as multipage TIFs
        %Grab a few example TIFs to test your parameters and put them
        %into a folder. (..\Test)
        %Create a Second Folder to output to (..\TestExports)
        
        %Copy the file paths from file explorer and paste them into the
        %"workingdir" and "exportdir"
        
        %Enter your "Calibration" value
        %Enter what programs to run on each Channel ("C1=[]")
        %Set your thresholds to a starting value
        %Run Program
        %Check output Images and Excel File
        %Change Threshold Values and Re-Run until results are good enough
            %If good analysis cannot be reached, edit advanced Values
            %If still not good enough, edit actual bulk of code
        %Once ready, change "workingdir" to a folder containing all images
        %to be analyzed, and "exportdir" to a new, empty folder
        
        %Run Program and wait. If too hard on your CPU, change "parfor" to
        %"for"
        
        %Review output images and analyze Data. 
            %Reccomended Analysis Steps:
                %Label Each row of Data using VLOOKUP in Excel.
                %Explore Data using JMP's Graphbuilder.
                %Graph Data in Prism.
%% Image Folder Location
clc, clear;
reader = bfGetReader('D:\Dropbox (VU Basic Sciences)\Duvall Confocal\Duvall Lab\Isa\2021-10-11-BigProteinFollowUp\Ai9Lipo48hrs002.nd2');
exportdir='D:\Dropbox (VU Basic Sciences)\Duvall Confocal\Duvall Lab\Isa\2021-10-11-BigProteinFollowUp\Analysis';
% filetype='tif';
% listing=dir(strcat(workingdir,'*.TIF'));
% ds=imageDatastore(workingdir);
%% Directory Code
readeromeMeta=reader.getMetadataStore();
destdirectory1 = fullfile(exportdir,'Overlaid');
BaxtDirectory= fullfile(exportdir,'Baxter');
exportbaseBAXTSegNuc=fullfile(BaxtDirectory,'Analysis','Segmentation_Nuc');
exportbaseBAXTSegCell=fullfile(BaxtDirectory,'Analysis','Segmentation_Cell');
mkdir(destdirectory1);   %create the directory
mkdir(BaxtDirectory);
mkdir(exportbaseBAXTSegNuc);
mkdir(exportbaseBAXTSegCell);
%% 
% This will measure the total Gal8 recruited to puncta and count cell
% nuclei or cytosol in each frame.

% This code assumes you have exported images as multipage TIF files, with
% any of the following stains in each channel:
    % nuclear Stain
    % Difuse Cytosolic Stain
    % Punctate Cytosolic Stain
    % Labeled Drug or other exogenous molecule (Cas9, siRNA)

% Images were exported to 2 page TIF images using Nikon NIS Elements. If
% you use alternate file formats or use separate export files for each
% channel, please edit the code as appropriate.

% You *must* edit the workingdir and exportdir variables for this code to
% work. 
%% Structuring Elements
% For conveience, a number of sizes of disk shaped structural elements are
% generated for data exploration.
sr1=strel('square',1);
se1=strel('disk',1);
sr2=strel('square',2);
se2=strel('disk',2);
se3=strel('disk',3);
sr3=strel('square',3);
se4=strel('disk',4);
se5=strel('disk',5);
se6=strel('disk',6);
se7=strel('disk',7);
se8=strel('disk',8);
se9=strel('disk',9);
se10=strel('disk',10);
se12=strel('disk',12);
se20=strel('disk',20);
se25=strel('disk',25);
se100=strel('disk',100);
%% Sizing/Resolution Parameters EDIT HERE ADVANCED

        %NEED TO ADD microns per Pixel %NEED TO ADD Cell size (Small, Medium, Large)%Go through this and make all disks calculated on the microns per pixel and %the Cell Size

MiPerPix=1.36;        
CellSize=1; %Scale as needed for different Cells        
            %Disks
            NucTophatDisk=strel('disk',round(250*(0.34/MiPerPix)));
            NucOpenDisk= strel('disk',round(5*(0.34/MiPerPix)));
            NucErodeDisk=strel('disk',round(6*(0.34/MiPerPix)));
            NucCloseDisk=strel('disk',round(4*(0.34/MiPerPix)));

            CytTophatDisk=strel('disk',round(250*(0.34/MiPerPix))); % EditHere
            CytOpenDisk =strel('disk',round(5*(0.34/MiPerPix)));
            CytErodeDisk=strel('disk',round(5*(0.34/MiPerPix)));
            CytCloseDisk=strel('disk',round(5*(0.34/MiPerPix)));

            Gal8TophatDisk=strel('disk',round(6*(0.34/MiPerPix)));% EditHere
            Gal8OpenDisk =strel('square',round(2*(0.34/MiPerPix)));
            Gal8DilateDisk=strel('disk',round(1*(0.34/MiPerPix)));
            Gal8OutlineDisk=strel('disk',round(2*(0.34/MiPerPix)));
%% Image Thresholding EDIT HERE BASIC
%Bit Depth    
    bitdepthin= 12; %Bit depth of original image, usually 8, 12, or 16
%Nuclear Stain
        NucMax=0.8;%Number 0-1, removes Cell Debris brighter than this value in order to allow low end to remain visible. 0.2 is usually a good start 
        NucLow=1000;%
     %Cytosol    
        CytMax= 1.1; %Number 0-1, removes Cell Debris brighter than this value. 0.2 is usually a good start  
        CytLow=1; %Choose number 0-20, start at 0. Higher numbers remove more dim cells and background.
    %Gal8
        Gal8MinThreshold=1;%Number 0-1, removes Puncta Dimmer than this value. 0.05 is usually a good start 
    %Rhodamine
        Rhoda_threshold = 1; %Number 0-1, removes rhodamine signal dimmer than threshold
%         Rhoda_threshold_Big = 100;
%% Analysis Variables
bitConvert=(2^16/2^bitdepthin);
run=char(datetime(clock),"yyyy-MM-dd-hh-mm-ss");    % The Run number is used to track multiple runs of the software, and is used in
            % export file names and in the DataCells array. Note: it is a character
            % array / string!
Categories=[{'run'},{'well'},{'areacell'},{'CellSum'},{'areaGal8'},{'galsum'},{'areaRhod'},{'Rhodsum'},{'RhodAvgInCell'},{'RhodAvgOutCell'}];
NumSeries=reader.getSeriesCount();
NumColors=reader.getEffectiveSizeC();
NumTimepoint=(reader.getImageCount())/NumColors;
NumImg=NumSeries*NumTimepoint*NumColors;

C = cell(NumImg,length(Categories));
%% Analysis Program 
for j=0:NumSeries% Number of images in ND2 File  
    %% Import TIFs
    % %The next few lines are specific to 2 page TIF images. Edit from here
    % if you have alternate arrangements.
%     currfile=strcat(workingdir,listing(j,1).name);
    CurrSeries=j;
    reader.setSeries(CurrSeries);
    fname = reader.getSeries;
    Well=num2str(fname,'%05.f');  
    
    BaxWellFolder=fullfile(BaxtDirectory,Well);
    mkdir(BaxWellFolder);
    PositionX = readeromeMeta.getPlanePositionX(CurrSeries,1).value();
    PositionY = readeromeMeta.getPlanePositionY(CurrSeries,1).value();
    T_Value = reader.getSizeT()-1;
    
    BaxSegFolderNuc=fullfile(exportbaseBAXTSegNuc,Well);
    mkdir(BaxSegFolderNuc);
    
    BaxSegFolderCell=fullfile(exportbaseBAXTSegCell,Well);
    mkdir(BaxSegFolderCell);
    
    for i=0:T_Value
    
%     T_Value = reader.getSizeT();
            Timepoint = num2str(i,'%03.f');
            iplane=reader.getIndex(0,0,i);
            WellTime = round(str2double(readeromeMeta.getPlaneDeltaT(CurrSeries,iplane).value()))

            Nuc = bitConvert*bfGetPlane(reader,iplane+2);

            cyt = bitConvert*bfGetPlane(reader,iplane+2);

            drug = bitConvert*bfGetPlane(reader,iplane+1);
    
                %% Analyze Images
            %%Nuclear Stain Code    
            [NucLabel,Nuc_bw4,NucPos,NucBrightEnough,NucMT1,NucOpen,Nuc_eq,NucTopHat,Nuc_bw4_perim,NucOverbright,NucQuant1,NucWeiner,NucArea] = NuclearStain(Nuc,NucTophatDisk,NucMax,NucOpenDisk,NucErodeDisk,NucLow,NucCloseDisk);   
            %     NucStats=regionprops(Nuc_bw4,'Centroid','Area');

            %%Cytosol Code
            [CytBright,CytArea,CytNucOverlay,cyt_bw4,CytPos,CytBrightEnough,CytMT1,CytOpen,cyt_eq,CytTopHat,cyt_bw4_perim] = Cytosol(cyt,CytTophatDisk,CytMax,CytOpenDisk,CytErodeDisk,CytLow,CytCloseDisk);

            %WaterShed Segmentation of Individual Cells
            [Cyt_WS,Cyt_WS_perim,L_n] = CytNucWaterShed(cyt,Nuc_bw4,CytTopHat,cyt_bw4);
            %   figure; imshow(imoverlay(cyt_eq,Cyt_WS, [.3 .3 1]));
            %Gal8 Puncta Segmentation
            [GalPals,Gal8Signal,RingMeanInt,Gal8Quant5,Gal8Quant4,Gal8Quant3,Gal8Open,Gal8TH,Gal8Quant2,Puncta,Ring] = Gal8(cyt,Gal8TophatDisk,Gal8OpenDisk,Gal8DilateDisk,Gal8MinThreshold,Cyt_WS,CytPos,Gal8OutlineDisk);    
            %     figure; imshow(imoverlay(cyt_eq,Gal8Quant5, [.3 .3 1]));

            %Rhodamine Code
            [RhodBright,areaRhod, Rhodsum, RhodAvgInCell, RhodAvgOutCell,rhod_eq,RhodMask] = Rhoda(drug, Rhoda_threshold, cyt_bw4);
            rhodPerim=bwperim(RhodMask);

                %All Data Images
                RGBExportImage=cat(3,rhod_eq,cyt_eq,Nuc_eq);
                WSArea = imoverlay(RGBExportImage, Cyt_WS_perim,[0.8500 0.3250 0.0980]);
                ExportImage=imoverlay(WSArea,Gal8Quant5,'m');
                    ExportImage=imoverlay(ExportImage,Nuc_bw4_perim, [0.3010 0.7450 0.9330]);
                    ExportImage=imoverlay(ExportImage,rhodPerim, 'y');
            %         figure; imshow(ExportImage);
            %

                %% Measure Image Data

                % measurement
                areacell=bwarea(Nuc_bw4(:));
                CellSum=sum(Nuc(Nuc_bw4));
                areaGal8=sum((vertcat(Puncta.Area)));
            %    
            % C(j,:)=[{run},{WellTime},{areacell},{CellSum},{areaGal8},{Gal8Signal},{areaRhod},{Rhodsum},{RhodAvgInCell},{RhodAvgOutCell}];
    %% Write Images to File
     %overlaid Image
    BaxterName=strcat('w',Well,'t',Timepoint)
     
     exportbase=strcat(destdirectory1,'\',run,'_',BaxterName);
    
    
    fulldestination = strcat(exportbase,'.png');  %name file relative to that directory
    imwrite(ExportImage, fulldestination);  %save the file there directory
    
    %BaxterImages    
    ImageName=fullfile(BaxWellFolder,BaxterName);    
    imwrite(Nuc, strcat(ImageName,'c01','.tif'),'tif');
    imwrite(cyt, strcat(ImageName,'c02','.tif'),'tif');
    imwrite(GalPals, strcat(ImageName,'c03','.tif'),'tif');
    imwrite(drug, strcat(ImageName,'c04','.tif'),'tif');
    imwrite(RhodBright, strcat(ImageName,'c05','.tif'),'tif');
     
    
    SegNameNuc=fullfile(BaxSegFolderNuc,BaxterName);
    imwrite(NucLabel, strcat(SegNameNuc,'c01','.tif'),'tif');
    
    
    SegNameCell=fullfile(BaxSegFolderCell,BaxterName);
    imwrite(Cyt_WS, strcat(SegNameCell,'c01','.tif'),'tif');
    
    
    end   
end
%% Write Analysis Data to File
 
D=[Categories;C];
WritingHere=strcat(exportdir,'\','Gal8','_',run);
 writecell(D,strcat(WritingHere,'.xlsx')); % Exports an XLSX sheet of your data