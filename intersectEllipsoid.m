function [ xi yi zi ] = intersectEllipsoid(x, y, z, vx, vy, vz, hae)
%
% returns [ xi yi zi ], the intersection of a unit vector vx, vy, vz from a camera located at x, y, z 
%  with an elliptical surface hae above (or below) the ellipsoid
%
% all variables are in ecef
%
% Byron Smiley
% 13 Jul 2021
%----------------------------------------------------------------------------------------------------

    % load constants from u2x
    C = u2x();
    
    % fill the ellipsoid constants in METERS, noting that hae is in addition to the typical a,b,c that come in from WGS-84
    a = C.Re_avEq.value*1000 + hae;
    b = a;
    c = C.Re_avPole.value*1000 + hae;

    % compute intermediate quantities
    value = -a^2*b^2*vz*z - a^2*c^2*vy*y - b^2*c^2*vx*x;
    radical = a^2*b^2*vz^2 + a^2*c^2*vy^2 - a^2*vy^2*z^2 + 2*a^2*vy*vz*y*z - a^2*vz^2*y^2 + b^2*c^2*vx^2 - b^2*vx^2*z^2 + 2*b^2*vx*vz*x*z - b^2*vz^2*x^2 - c^2*vx^2*y^2 + 2*c^2*vx*vy*x*y - c^2*vy^2*x^2;
    magnitude = a^2*b^2*vz^2 + a^2*c^2*vy^2 + b^2*c^2*vx^2;

    % sanity check
    if (radical < 0)
        error("no intersection");
    end
    
    % compute the scaling factor that touches exactly hae above or below the ellipsoid
    d = (value-a*b*c*sqrt(radical))/magnitude;

    % another sanity check
    if d < 0
        error("no intersection");
    end
    
    % compute the intersection by scaling the view vector by d and adding it to the pinhole position
    xi = x + d*vx;
    yi = y + d*vy;
    zi = z + d*vz;

end
