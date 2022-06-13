%% Section 1 - Import images

ControlFilename = '/Users/sarahreilly/Desktop/Sarepto_Analysis_Images/M11_muscle1_fixed_dTomato.tif';
TreatmentFilename = '/Users/sarahreilly/Desktop/Sarepto_Analysis_Images/M15_muscle1_fixed001_dTomato.tif';
ExportDir = '/Users/sarahreilly/Desktop/Sarepto_Analysis_Images/Data/SareptoData.xlsx';

ControlImg = imread(ControlFilename);
TreatmentImg = imread(TreatmentFilename);


%% Section 2 - Make Histograms of Pixel Intensity

nbins = 100;
xscale = 30;

% Histogram of Control Image
figure
hold on
MaxPixelValue = (intmax('uint16'));
ControlImgPosMask = ControlImg > 0;
ControlImgPosNorm = (double(ControlImg(ControlImgPosMask))/double(MaxPixelValue)) * 100;
histogram(ControlImgPosNorm,nbins)
xlabel('Percent of Possible Pixel Brightness (%)')
ylabel('Frequency')
title('dTomato Expression in Ai9 Mice M11 Muscle')
xlim([0 xscale]);
hold off

% Histogram of Treatment Image
figure
hold on
TreatmentImgPosMask = TreatmentImg > 0;
TreatmentImgPosNorm = (double(TreatmentImg(TreatmentImgPosMask))/double(MaxPixelValue)) * 100;
histogram(TreatmentImgPosNorm,nbins)
xlabel('Percent of Possible Pixel Brightness (%)')
ylabel('Frequency')
title('dTomato Expression in Ai9 Mice M15 Muscle')
xlim([0 xscale])
hold off

% Overlay Histogram
figure
hold on
histogram(TreatmentImgPosNorm,nbins)
histogram(ControlImgPosNorm,nbins)
legend('M15 Muscle 1','M11 Muscle 1')
xlabel('Percent of Possible Pixel Brightness (%)')
ylabel('Frequency')
title('dTomato Expression in Ai9 Mice Muscle')
xlim([0 xscale])
hold off


%% Section 3 - Image Analysis on Control Image

% Control Thresholding Parameters
MiPerPix = 0.1234;
ControlCytLow1 = 0;  % 0-20
ControlCytMax = 0.0002;   % 0-1

% Control Image Segmentation
[M11FiberMask,M11FiberPerim,M11HistoMask,M11HistoPerim] = Histo(ControlImg,MiPerPix);


%% Section 4 - Image Analysis on Treatment Image

% Treatment Thresholding Parameters
MiPerPix = 0.1234;
TreatmentCytLow = 0;  % 0-20
TreatmentCytMax = 0.2;   % 0-1
TreatmentAnaSettings = {TreatmentCytLow, TreatmentCytMax};

% Treatment Image Segmentation
[M15FiberMask,M15FiberPerim,M15HistoMask,M15HistoPerim] = Histo(TreatmentImg,MiPerPix); 


%% Section 5 - Show Segmentation Images
M11FiberPerimThick = imdilate(M11FiberPerim,strel('disk',10));
M11HistoPerimThick = imdilate(M11HistoPerim,strel('disk',10));

% Plot Control Image Segmentation
M11FibersOutlined = imoverlay(imadjust(ControlImg), M11FiberPerimThick, [0.3010 0.7450 0.9330]);
M11SegmentedImage = imoverlay(M11FibersOutlined,M11HistoPerimThick,[0.9290 0.6940 0.1250]);

figure
imshow(M11SegmentedImage)

% Plot Treatment Image Segmentation
M15FiberPerimThick = imdilate(M15FiberPerim,strel('disk',10));
M15HistoPerimThick = imdilate(M15HistoPerim,strel('disk',10));

% Plot Control Image Segmentation
M15FibersOutlined = imoverlay(imadjust(TreatmentImg), M15FiberPerimThick, [0.3010 0.7450 0.9330]);
M15SegmentedImage = imoverlay(M15FibersOutlined,M15HistoPerimThick,[0.9290 0.6940 0.1250]);

figure
imshow(M15SegmentedImage)

%% Section 6 - Calculations

%
% Entire Image
TreatmentSum = sum(double(TreatmentImg),'all');
ControlSum = sum(double(ControlImg),'all');
SumRatio = TreatmentSum / ControlSum;

% Average percent pixel brightness
TreatmentAvgPix_full = (sum(TreatmentImg,'all') * 100) / (size(TreatmentImg,1) * size(TreatmentImg,2) * double(MaxPixelValue)); 
ControlAvgPix_full = (sum(ControlImg,'all') * 100) / (size(ControlImg,1) * size(ControlImg,2) * double(MaxPixelValue));     
PerPixelRatio_full = TreatmentAvgPix_full / ControlAvgPix_full;

% Relative Area
ControlRelArea_full = 1;
TreatmentRelArea_full = 1;
RelAreaRatio_full = TreatmentRelArea_full / ControlRelArea_full;


%
% Segmentation based on CytLow > 0 with 20 quant
BrightSumTreatment = sum(TreatmentImg(TreatmentMask));  % Total cyt signal of treatment image
BrightSumControl = sum(ControlImg(ControlMask));        % Total cyt signal of control image
BrightRatio = BrightSumTreatment / BrightSumControl;    % Ratio of treatment:control brightness

% Average percent pixel brightness
TreatmentAvgPix = (BrightSumTreatment * 100) / (sum(TreatmentMask,'all') * double(MaxPixelValue)); 
ControlAvgPix = (BrightSumControl * 100) / (sum(ControlMask,'all') * double(MaxPixelValue));     
PerPixelRatio = TreatmentAvgPix / ControlAvgPix;

% Relative Area
ControlRelArea = sum(ControlMask,'all') / (size(ControlImg,1) * size(ControlImg,2));
TreatmentRelArea = sum(TreatmentMask,'all') / (size(TreatmentImg,1) * size(TreatmentImg,2));
RelAreaRatio = TreatmentRelArea / ControlRelArea;


%
% Extra Bright Segmentation







% Table 1D array variables
M11Muscle = {'Entire Image', 'In Mask';
            ControlSum, BrightSumControl; 
            ControlAvgPix_full, ControlAvgPix;
            ControlRelArea_full, ControlRelArea};
        
M15Muscle = {'Entire Image', 'In Mask';
            TreatmentSum, BrightSumTreatment; 
            TreatmentAvgPix_full, TreatmentAvgPix;
            TreatmentRelArea_full, TreatmentRelArea};
        
M15toM11Ratio = {'Entire Image', 'In Mask';
                SumRatio, BrightRatio;          
                PerPixelRatio_full, PerPixelRatio;
                RelAreaRatio_full, RelAreaRatio};
            
Measurement = [{'Segmentation Threshold'};
                {'Total Signal Intensity'}; 
                {'Average Pixel Percent Brightness'};
                {'Relative Area'}];

HistologyDataTable = table(Measurement,M11Muscle,M15Muscle,M15toM11Ratio);

writetable(HistologyDataTable,ExportDir,'Sheet',1,'Range','A1')

%%
% Relative Areas
M11RelHistArea = sum(M11HistoMask,'all')/sum(M11FiberMask,'all');
M15RelHistArea = sum(M15HistoMask,'all')/sum(M15FiberMask,'all');