function [LiveData] = BronkSegment(ImageAnalyses,Img2,MiPerPix,SegDirectory,Well,BaxterName)
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here
for k =1:length(ImageAnalyses)
             
                Analysis=ImageAnalyses{k,:}{1}{1};
                    AnaChan=ImageAnalyses{k,:}{2}{1};
                    AnaImage=Img2(:,:,AnaChan);
                    AnaSettings= ImageAnalyses{k,:}{3};
%                     Storage
%                         DataName{k} = matlab.lang.makeValidName(Analysis);
%                         DataLoop=strcat(DataName{k},'_',num2str(k));

                    switch Analysis
                        case 'Nuc'
                         [bw4,bw4_perim,Label,Data]= NuclearStain(AnaImage,AnaSettings,MiPerPix);
                        case 'Cyt'
                         [bw4,bw4_perim,Label,Data] = Cytosol(AnaImage,AnaSettings,MiPerPix);  
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
end

