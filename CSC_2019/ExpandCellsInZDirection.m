function ExpandCellsInZDirection(aCells, aImData)

for i = 1:length(aCells)
    cell = aCells(i);
    blobs = cell.blob;
    for j = 1:length(blobs)
        blob = blobs(j);
        blob.boundingBox(3) = 0.5;
        blob.boundingBox(6) = aImData.numZ;
        slice = max(blob.image,  [], 3);
        blob.image = repmat(slice, 1, 1, aImData.numZ);
    end
end
end