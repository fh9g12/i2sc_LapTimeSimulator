function R = rotz(angle_deg)
% rotz - dependency-free replacement for the Phased Array System / Robotics
% Toolbox's rotz(angle), covering exactly the usage this project needs: a
% 3-D rotation matrix about the z-axis for a scalar angle in degrees.
% Avoids requiring students to have that toolbox installed.
%
% R = open.rotz(angle_deg)
%
%   angle_deg   rotation angle about the z-axis [deg], positive
%               counter-clockwise looking down the +z axis onto the x-y
%               plane (the standard right-handed convention, matching
%               the toolbox function)
%
% R is the 3x3 matrix such that R*v rotates a column vector v by
% angle_deg about z.
    R = [cosd(angle_deg) -sind(angle_deg) 0 ; ...
         sind(angle_deg)  cosd(angle_deg) 0 ; ...
         0                0               1] ;
end
