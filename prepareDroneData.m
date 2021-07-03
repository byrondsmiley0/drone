% prepareDroneData.m
%
% why are you always preparing? Just go!
%
% Byron Smiley
% 2 Jul 2021
%-------------------------------------------


clc
clear variables
close all





%% loading cell

% provide a directory with the following three ingredients:
%   many drone images
%   a converted flight log saved as CSV
%   a converted flight log saved as KMZ, but then resaved as KML in Google Earth so it's uncompressed
inDir = '/Users/bsmiley/work/drone flights/launch point 0';





%% filename cell

% get this early, supports finding all three flavors of input file
info = dir(inDir);



% find the image filenames, count them too
img0 = regexp({info.name}, 'DJI_\d+\.JPG', 'match', 'once')';
img = img0(~ismissing(img0));
I = length(img);

% confirm we have a VIS and IR exposure for each frameTime
if mod(I, 2) ~= 0
    error('Odd number of images, missing a VIS or IR frame!');
end



% find the flight log CSV
fl0 = regexp({info.name}, 'DJIFlightRecord_\d{4}-\d{2}-\d{2}_\[\d{2}-\d{2}-\d{2}\]\.csv', 'match', 'once')';
if nnz(~ismissing(fl0)) > 1
    error('too many flight logs, I''m confused!');
else
    fl = fl0{~ismissing(fl0)};  
end



% find the KML
k0 = regexp({info.name}, 'DJIFlightRecord_\d{4}-\d{2}-\d{2}_\[\d{2}-\d{2}-\d{2}\]\.kml', 'match', 'once')';
if nnz(~ismissing(k0)) > 1
    error('too many kml files, I''m confused!');
else
    k = k0{~ismissing(k0)};  
end





%% metadata assignment cell

% load the flight log, it will be needed in the upcoming loop
log = readtable(fullfile(inDir, fl));



% two things can be obtained from the KML

% coordinates of the home point

% load the Google Earth kml, place it in a structure
kml = readstruct(fullfile(inDir, k), 'FileType', 'xml');
names = {kml.Document.Placemark.name}';

% note the index of the point with "Home Point recorded", the crucial text tag
% note we ignore any "Home Point Updated", since we shouldn't be doing that in flight
% no way to do this in an arrayified fashion, I tried!
for h = 1:length(names)    
    if ~ismissing(names{h})
        if regexp(names{h}, 'Home Point recorded')
            break
        end
    end
end

% store in its own variable
points = {kml.Document.Placemark.Point};
home_point = points{h};

% remind the kids at home this height is above sea level
home_point.altitudeMode = 'orthometric';

% dig out the value, make numeric
a = regexp(home_point.coordinates, '(-?\d+\.\d+),(-?\d+\.\d+),(\d+\.\d+)', 'tokens', 'once');
home_point.msl = str2double(a{3});

% also whip up the hae equivalent
home_point.hae = home_point.msl + geoidheight(str2double(a{2}), str2double(a{1}), 'EGM2008');



% also the launch time, which needs conversion from decimal days to seconds
t0 = regexp(k, 'DJIFlightRecord_(\d{4}-\d{2}-\d{2}_\[\d{2}-\d{2}-\d{2}\])\.kml', 'tokens', 'once')';
launch_time = datenum(t0{1}, 'yyyy-mm-dd_[HH-MM-SS]')*60*60*24;

% add this launch_time to the time column of the CSV, makes an absolute time column
flight_time = log{:,2} + launch_time;


% for the outgoing data
out = table('Size', [ I 7 ], 'VariableTypes', {'string' 'double' 'double' 'double' 'double' 'double' 'double'}, ...
            'VariableNames', {'img' 'lat' 'lon' 'hae' 'roll' 'pitch' 'yaw'}, 'RowNames', img);


% this loop is over all VIS/IR img pairs
% here we associate each image with a frameTime, ATT, and EPH
for i = 1:I

    % do this for each imge, be it VIS or IR

    % obtain things from the headers of the VIS or IR image files, like
    % FileModDate: '29-Jun-2021 16:00:32'
    % GPSInfo.
    %         GPSLatitudeRef: 'N'
    %         GPSLatitude: [37 44 1.846730000000000e+01]
    %         GPSLongitudeRef: 'W'
    %         GPSLongitude: [122 28 5.899510000000000e+01]
    %         GPSAltitudeRef: 0
    %         GPSAltitude: 89    

    % image filename
    out{i,1} = string(img{i});

    % load the image file header
    info = imfinfo(fullfile(inDir, img{i}));

    % convert the date into datenum
    % note this is implictly rounded to the nearest second
    info.datenum_header = datenum(info.FileModDate, 'dd-mmm-yyyy HH:MM:SS')*60*60*24;

    % convert GPS location into signed decimal degrees

    % latitude
    switch info.GPSInfo.GPSLatitudeRef
        case 'N'
            sign_lat = 1;
        otherwise
            sign_lat = -1;
    end
    info.lat_header = sign_lat*dms2degrees(info.GPSInfo.GPSLatitude);

    % longitude
    switch info.GPSInfo.GPSLongitudeRef
        case 'E'
            sign_lon = 1;
        otherwise
            sign_lon = -1;
    end
    info.lon_header = sign_lon*dms2degrees(info.GPSInfo.GPSLongitude);

    % height, which sure looks like orthometric, meters above sea level
    info.msl_header = info.GPSInfo.GPSAltitude;

    % let's see what the height would be in hae
    info.hae_header = info.msl_header + geoidheight(info.lat_header, info.lon_header, 'EGM2008');



    % next, we exploit the info fields to find the lines of the CSV that applies to this image

    % what CSV line times would round to info.datenum_header?  
    theseLines = find( round(flight_time - info.datenum_header) == 0 );

    % take averages of all exportable quantities

    % latitude, or log{:,4}
    out{i,2} = mean(log{theseLines,4});   
    % compare
    fprintf('lat consistent to %e deg\n', info.lat_header - out{i,2});
    
    
    % longitude, or log{:,5}
    out{i,3} = mean(log{theseLines,5});
    % compare
    fprintf('lon consistent to %e deg\n', info.lon_header - out{i,3});

    % height, as height above ellipsoid, relative to the home point
    % relative height is log{:,8}
    out{i,4} = mean(log{theseLines,8}) + home_point.hae;
    % compare
    fprintf('hae consistent to %5.3f meters\n', info.hae_header - out{i,4});
    
    % body roll, or log{:,30}
    out{i,5} = mean(log{theseLines,30});
    
    % body pitch, or log{:,29}
    out{i,6} = mean(log{theseLines,29});
        
    % body yaw, or log{:,31}
    out{i,7} = mean(log{theseLines,31});

end % end of outer loop over img pairs


