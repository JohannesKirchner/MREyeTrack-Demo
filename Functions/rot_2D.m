function R = rot_2D(phi)
% clockwise rotation
R = [  cosd(phi), sind(phi); ...
      -sind(phi), cosd(phi)];
end