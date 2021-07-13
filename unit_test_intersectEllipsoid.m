% unit_test_intersectEllipsoid.m
%
% just making sure
%
% Byron Smiley
% 13 Jul 2021
%-------------------------------------------


clc
clear variables
close all





%% setup cell

% let's cook up some inputs to call intersectEllipsoid

% have this on hand in advance
ellipsoid = referenceEllipsoid('WGS 84');

% the ecef position of a satellite sitting over Byron's house at an altitude of 275km
latb = 37.707667;
lonb = -122.451362;
haeb = 106 + geoidheight(latb, lonb, 'EGM2008') + 275e3;
[ x y z ] = geodetic2ecef(ellipsoid, latb, lonb, haeb);

% add it's looking at this point on the ground. Let's use launch point 0
lat0 = 37.738434;
lon0 = -122.482999;
hae0 = 57 + geoidheight(lat0, lon0, 'EGM2008');
[ x0 y0 z0 ] = geodetic2ecef(ellipsoid, lat0, lon0, hae0);

% get the unit vector that points from the satellite to the point on the ground
v0 = [ x0 y0 z0 ] - [ x y z ];
v = v0/norm(v0);





%% testing cell

% this should reproduce lat0, lon0, hae0
[ xi yi zi ] = intersectEllipsoid(x, y, z, v(1), v(2), v(3), hae0);

% subtract em to check
delta = [ xi yi zi ] - [ x0 y0 z0 ];
nd = norm(delta);

% report using a millimeter threshold, 1/10th of a pixel at Albedo
thresh = 1e-3;

if (nd < thresh)
    fprintf('intersectEllipsoid good!\n');
else
    fprintf('intersectEllipsoid not good to thresh!');
end        




