function q = ikin(S, M, currentQ, targetPose)
% addpath('utils');
    qlim = [-pi pi;
            -125*pi/180 125*pi/180;
            -138*pi/180 138*pi/180;
            -3*pi/2 3*pi/2;
            -120*pi/180 133.5*pi/180;
            -3*pi/2 3*pi/2];
    iterations = 0;

    currentPose = MatrixLog6(M);
    currentPose = [currentPose(3,2) currentPose(1,3) currentPose(2,1) currentPose(1:3,4)']';
    while norm(targetPose - currentPose) > 1e-6 && iterations < 50000
        %J = ...
        % deltaQ = ...
        J = jacob0(S, currentQ);
        % alpha = 0.1;
        % deltaQ = alpha * J' * (targetPose - currentPose);

        lambda = 0.8;
        deltaQ = J' *  pinv(J*J' + lambda^2*eye(6)) * (targetPose - currentPose);

        currentQ = currentQ + deltaQ';

        if checklimits(currentQ, qlim) == 0
            % disp("Not in Limits")
            break
        end
        
        T = fkine(S,M,currentQ);
        currentPose = MatrixLog6(T);
        currentPose = [currentPose(3,2) ...
                       currentPose(1,3) ...
                       currentPose(2,1) ...
                       currentPose(1:3,4)']';
        iterations = iterations + 1;
        % disp(norm(targetPose - currentPose));
    end
    if norm(targetPose - currentPose) < 1e-6
        disp("Successfully found Solution")
    end
    q = currentQ;
end

function expmat = MatrixLog6(T)
% *** CHAPTER 3: RIGID-BODY MOTIONS ***
% Takes a transformation matrix T in SE(3).
% Returns the corresponding se(3) representation of exponential 
% coordinates.
% Example Input:
% 
% clear; clc;
% T = [[1, 0, 0, 0]; [0, 0, -1, 0]; [0, 1, 0, 3]; [0, 0, 0, 1]];
% expmat = MatrixLog6(T)
% 
% Output:
% expc6 =
%         0         0         0         0
%         0         0   -1.5708    2.3562
%         0    1.5708         0    2.3562
%         0         0         0         0

[R, p] = TransToRp(T);
omgmat = MatrixLog3(R);
if isequal(omgmat, zeros(3))
    expmat = [zeros(3), T(1: 3, 4); 0, 0, 0, 0];
else
    theta = acos((trace(R) - 1) / 2);
    expmat = [omgmat, (eye(3) - omgmat / 2 ...
                      + (1 / theta - cot(theta / 2) / 2) ...
                        * omgmat * omgmat / theta) * p;
              0, 0, 0, 0];    
end
end

function J = jacob0(S,q) 
% J = ...
    num_joints = size(S, 2); % Number of joints
    
    % Initialize the Jacobian matrix
    J = zeros(6, num_joints);
    
    % Initialize the homogeneous transformation matrix
    T = eye(4);
    
    for i = 1:num_joints
        % Extract the twist associated with the joint
        V = S(:, i);
        
        % Calculate the homogeneous transformation associated with the twist
        T = T * twist2ht(V, q(i));
        
        % Calculate the adjoint transformation of the twist
        adj = adjoint(V, T);
        
        % Assign the adjoint-transformed twist to the Jacobian matrix
        J(:, i) = adj;
    end
end


function T = twist2ht(S,theta)
% T = ...
    omega = S(1:3);
    v = S(4:6);
    K = skew(omega);
    R = axisangle2rot(omega,theta);

    if theta ~= 0
        % Use the formula for translation
        p = (eye(3) * theta + (1 - cos(theta)) * K + ...
            (theta - sin(theta)) * (K * K)) * v;
    else
        % When theta is zero, translation is straightforward
        p = v * theta;
    end
    
    T = [R, p; 0 0 0 1];
end

function S = skew(v)
%SKEW Returns the skew-symmetric matrix associated with the 3D vector
%passed as input

if length(v) == 3
    S = [  0   -v(3)  v(2)
        v(3)  0    -v(1)
        -v(2) v(1)   0];
else
    error('argument must be a 3-vector');
end

end


function T = fkine(S,M,q)
    %T = ...
    num_joints = size(S, 2);
    T = eye(4);

    % Perform the product of exponentials
    for i = 1:num_joints
        
        % Convert twist to homogeneous transformation matrix
        T_joint = twist2ht(S(:,i), q(i));
        
        % Update the cumulative transformation matrix
        T = T * T_joint;
    end
    
    T = T*M;
end

function withinLimits = checklimits(currentQ, qlim)
    % Check if each joint value is within the corresponding limits in qlim
    withinLimits = all(currentQ >= qlim(:,1)') && all(currentQ <= qlim(:,2)');
end

function R = axisangle2rot(omega,theta)% Skew-symmetric matrix K corresponding to the unit vector omega
    K = [0, -omega(3), omega(2);
         omega(3), 0, -omega(1);
         -omega(2), omega(1), 0];
    
    % Compute sine and cosine of theta
    sin_theta = sin(theta);
    cos_theta = cos(theta);
    
    % Compute rotation matrix using Rodrigues' rotation formula
    R = eye(3) + sin_theta * K + (1 - cos_theta) * (K^2);
end

function twist_inB = adjoint(twist_inA,T_AB)
% twist_inB = ...
    R = T_AB(1:3, 1:3); % Extract rotation matrix from T
    p = T_AB(1:3, 4);   % Extract translation vector from T

    p_cross = [0, -p(3), p(2); p(3), 0, -p(1); -p(2), p(1), 0]; % Skew-symmetric cross-product matrix

    Z = zeros(3);
    adj = [R Z;p_cross*R R]; 
    twist_inB = adj * twist_inA;
end

function [R, p] = TransToRp(T)
% *** CHAPTER 3: RIGID-BODY MOTIONS ***
% Takes the transformation matrix T in SE(3) 
% Returns R: the corresponding rotation matrix
%         p: the corresponding position vector .
% Example Input:
% 
% clear; clc;
% T = [[1, 0, 0, 0]; [0, 0, -1, 0]; [0, 1, 0, 3]; [0, 0, 0, 1]];
% [R, p] = TransToRp(T)
% 
% Output:
% R =
%     1     0     0
%     0     0    -1
%     0     1     0
% p =
%     0
%     0
%     3

R = T(1: 3, 1: 3);
p = T(1: 3, 4);
end

function so3mat = MatrixLog3(R)
% *** CHAPTER 3: RIGID-BODY MOTIONS ***
% Takes R (rotation matrix).
% Returns the corresponding so(3) representation of exponential 
% coordinates.
% Example Input:
% 
% clear; clc;
% R = [[0, 0, 1]; [1, 0, 0]; [0, 1, 0]];
% so3mat = MatrixLog3(R)
% 
% Output:
% angvmat =
%         0   -1.2092    1.2092
%    1.2092         0   -1.2092
%   -1.2092    1.2092         0

acosinput = (trace(R) - 1) / 2;
if acosinput >= 1
    so3mat = zeros(3);
elseif acosinput <= -1
    if ~NearZero(1 + R(3, 3))
        omg = (1 / sqrt(2 * (1 + R(3, 3)))) ...
              * [R(1, 3); R(2, 3); 1 + R(3, 3)];
    elseif ~NearZero(1 + R(2, 2))
        omg = (1 / sqrt(2 * (1 + R(2, 2)))) ...
              * [R(1, 2); 1 + R(2, 2); R(3, 2)];
    else
        omg = (1 / sqrt(2 * (1 + R(1, 1)))) ...
              * [1 + R(1, 1); R(2, 1); R(3, 1)];
    end
    so3mat = skew(pi * omg);
else
	theta = acos(acosinput);
    so3mat = theta * (1 / (2 * sin(theta))) * (R - R');
end
end
