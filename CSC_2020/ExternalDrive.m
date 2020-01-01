function oLetter = ExternalDriveLetter()

switch getenv('computername')
    case 'SE-00217-WKS'
        oLetter = 'D:';
    case 'KLASMA-LAPTOP'
        oLetter = 'E:';
end