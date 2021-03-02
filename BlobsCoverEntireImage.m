function oCovers = BlobsCoverEntireImage(aBlobs, aImData)

labelImage = ReconstructSegmentsBlob(aBlobs, aImData.GetSize());
oCovers = sum(labelImage(:) > 0) / prod(aImData.GetSize()) > 0.8;

end