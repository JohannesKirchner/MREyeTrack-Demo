function ang = R2ang(R)

if ~all(size(R) == 3)
    error('You need a 3x3 rotation matrix as input')
end

% % anticlockwise
% ang(1) = atand(R(3,2)/R(2,2));
% ang(2) = atand(R(1,3)/R(1,1));
% ang(3) = -asind(R(1,2));

% clockwise
ang(1) = -atand(R(3,2)/R(2,2));
ang(2) = -atand(R(1,3)/R(1,1));
ang(3) = asind(R(1,2));