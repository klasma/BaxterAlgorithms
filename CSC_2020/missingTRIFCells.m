imData = ImageData('C:\CTC2020\Challenge\Fluo-N3DL-TRIF\Fluo-N3DL-TRIF_01');
numZ = imData.Get('numZ');
frame = 88;
zStack = imData.GetShownZStack(frame, 'ZPlane', floor(numZ/2):numZ);
projection = max(zStack, [], 3);
figure;
imshow(projection*2)
hold on

blobFile = ['C:\CTC2020\Challenge\Fluo-N3DL-TRIF\Analysis\CellData_200226_021346_optimized_seg\Resume\Fluo-N3DL-TRIF_01\Segmentation\blobs' sprintf('%04d', frame) '.mat'];
tmp = load(blobFile);
blobs = tmp.blobs;
for i = 1:length(blobs)
    blob = blobs(i);
    if blob.centroid(3) > floor(numZ/2)
        plot(blob.centroid(1), blob.centroid(2), 'rx')
    end
end

blobFile = ['C:\CTC2020\Challenge\Fluo-N3DL-TRIF\Analysis\CellData_200226_021346_optimized_seg\Resume\Fluo-N3DL-TRIF_01\Segmentation\blobs' sprintf('%04d', frame-1) '.mat'];
tmp = load(blobFile);
blobs = tmp.blobs;
for i = 1:length(blobs)
    blob = blobs(i);
    if blob.centroid(3) > floor(numZ/2)
        plot(blob.centroid(1), blob.centroid(2), 'bx')
    end
end

blobFile = ['C:\CTC2020\Challenge\Fluo-N3DL-TRIF\Analysis\CellData_200226_021346_optimized_seg\Resume\Fluo-N3DL-TRIF_01\Segmentation\blobs' sprintf('%04d', frame-2) '.mat'];
tmp = load(blobFile);
blobs = tmp.blobs;
for i = 1:length(blobs)
    blob = blobs(i);
    if blob.centroid(3) > floor(numZ/2)
        plot(blob.centroid(1), blob.centroid(2), 'gx')
    end
end

% phdFile = ['C:\CTC2020\Challenge\Fluo-N3DL-TRIF\Analysis\CellData_200226_021346_optimized_seg\Resume\Fluo-N3DL-TRIF_01\GM-PHD\phd' sprintf('%04d', frame) '.mat'];
% tmp = load(phdFile);
% updatedPHD = tmp.updatedPHD;
% for i = 1:updatedPHD.J
%     if updatedPHD.m(3,i) > floor(numZ/2) && any(updatedPHD.m(4:6,i) ~= 0)
%         plot(updatedPHD.m(1,i), updatedPHD.m(2,i), 'bo')
%     end
% end
% 
% propagatedPHD = tmp.propagatedPHD;
% for i = 1:propagatedPHD.J
%     if propagatedPHD.m(3,i) > floor(numZ/2)
%         plot(propagatedPHD.m(1,i), propagatedPHD.m(2,i), 'go')
%     end
% end