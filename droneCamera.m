classdef droneCamera
    % we need this to make simulated products
    
    properties
        
        % spectral band, string
        b;
        
        % image list, cell array
        img;
        
        
        % intrinsic parameters
        
        % number of rows on the sensor array, double
        nr;
        
        % number of columns on the sensor array, double
        nc;
        
        % reference row, double
        v0;
        
        % reference column, double
        u0;
        
        % focal length (in units of length), double
        f;
        
        % pixel pitch, double
        pp;
        
        % optical distortion, let's use k6, p2 for now
        k; % radial
        p; % tangential
        
        
        % extrinsic parameters, which are cell arrays because there are typically many frames
        
        % position, each entry is ecef [ x; y; z ], cell array of 3x1 doubles
        X;
        
        % orientation
        R_ecef2camera; % cell array of 3x3 doubles
        
    end
    
    methods
        
        function obj = droneCamera(band, nrows, ncols, focal, pitch, k_array, p_array, metadataFile, gimbal)
            
            % spectral band, so we never forget which pixels these are
            obj.b = band;
            
            
            % array dimensions
            obj.nr = nrows;
            obj.nc = ncols;
            
            % reference row and col shall be the financially rounded midpoint
            obj.v0 = round(nrows/2);
            obj.u0 = round(ncols/2);
            
            % focal length
            obj.f = focal;
            
            % pixel pitch
            obj.pp = pitch;
            
            % optical distortion 
            obj.k = k_array;
            obj.p = p_array;
            
            
            % extrinsics cell arrays are filled from the metadata file
                        
            % fill helping arrays
            fid = fopen(metadataFile, 'r');
            data = textscan(fid, '%s %f %f %f %f %f %f');
            fclose(fid);
            % columns go img lat lon hae roll pitch yaw
            
            % images
            obj.img = data{1};
            
            % needed in the loop
            ellipsoid = referenceEllipsoid('WGS 84', 'meters');
   
            % final members must be computed
            for i = 1:size(data{1},1)
                
                % compose position vector
                obj.X{i} = geodetic2ecef(ellipsoid, data{2}{i}, data{3}{i}, data{4}{i});
              
                % compose ecef2camera with all the pieces
                
                % first compose body2ned from the body angles
                % this might be ned2body, it will be clear during debugging
                R_body2ned = angle2dcm(deg2rad(data{7}{i}), deg2rad(data{6}{i}), deg2rad(data{5}{i}));
                
                % there's also the gimbal roll that gets us from the body to the camera frame
                % gimbal is a pitch angle so -90 means looking down, 0 means looking at the horizon
                R_body2camera = angle2dcm(deg2rad(gimbal)+pi/2, 0, -pi/2);
                
                % there's also how to get from ned2ecef. Silly MATLAB makes me build the matrix by columns
                R_ned2ecef(1:3,1) = ned2ecef(1, 0, 0, data{2}{i}, data{3}{i}, data{4}{i}, ellipsoid);
                R_ned2ecef(1:3,2) = ned2ecef(0, 1, 0, data{2}{i}, data{3}{i}, data{4}{i}, ellipsoid);
                R_ned2ecef(1:3,3) = ned2ecef(0, 0, 1, data{2}{i}, data{3}{i}, data{4}{i}, ellipsoid);
                
                % finally, we get there
                obj.R_ecef2camera{i} = R_body2camera*R_body2ned'*R_ned2ecef';
                
            end
                        
            
        end
        
        function outputArg = method1(obj,inputArg)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputArg = obj.Property1 + inputArg;
        end
    end
end

