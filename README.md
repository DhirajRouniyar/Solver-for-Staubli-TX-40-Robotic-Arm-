# Solver-for-Staubli-TX-40-Robotic-Arm

PROBLEM STATEMENT
The goal of this mini-project is to develop an inverse kinematics (IK) solver for the Staubli TX-40 robot. The solver 
must be implemented in the MATLAB programming language, and it must be encapsulated in a function with the 
following signature:
function q = ikin(S, M, currentQ, targetPose)
The expected inputs are:
S: 6xn matrix whose columns are the screw axes of the robot
M: Homogeneous transformation matrix representing the home configuration
currentQ: 1x6 vector of initial joint variables
targetPose: 6x1 twist representing the target pose
The function is expected to return a 1x6 vector of joint variables. To be acceptable, a solution will have to:
• Position the robot’s end effector within 1e-6 of the target pose (measured as the norm of the difference
between targetPose and the twist representing the final pose returned by the solver).
• Not contain joint values beyond the joint limits. For the TX-40 robot, the joint limits are:

