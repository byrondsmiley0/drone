% unit_test_droneCamera.m
%
% makes this monster easy to instantiate
%
% Byron Smiley
% 13 Jul 2021
%-------------------------------------------


clc
clear variables
close all





%% setup cell

% prepare our constants to instantiate the object
metadataFile = fullfile('/Users/bsmiley/work/drone flights/launch point 0', 'metadata.txt');

% visible band
% the frightening truth is that gimbal angle is NOT in the metadata, but must be specified
test = droneCamera('VIS', 4056, 3040, 4.354719847435085e-3, 1.55e-6, [ 0 0 0 0 0 0 ], [ 0 0 ], metadataFile, -90);


