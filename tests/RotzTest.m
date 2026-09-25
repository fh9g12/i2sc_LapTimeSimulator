classdef RotzTest < matlab.unittest.TestCase
    % Unit tests for open.rotz, the dependency-free replacement for the
    % Phased Array System/Robotics Toolbox's rotz(angle) used by
    % Track/computeFinishArrow.m, editMap.m and generateMap.m.
    %
    % Run with: results = runtests('tests') (from the repo root, so
    % +open is resolvable as a package).

    properties (Constant)
        Tol = 1e-10
    end

    methods (Test)
        function zeroAngleIsIdentity(testCase)
            testCase.verifyEqual(open.rotz(0),eye(3),'AbsTol',testCase.Tol) ;
        end

        function fullTurnIsIdentity(testCase)
            testCase.verifyEqual(open.rotz(360),eye(3),'AbsTol',testCase.Tol) ;
        end

        function ninetyDegreesRotatesXOntoY(testCase)
            v = [1;0;0] ;
            testCase.verifyEqual(open.rotz(90)*v,[0;1;0],'AbsTol',testCase.Tol) ;
        end

        function negativeNinetyRotatesXOntoMinusY(testCase)
            v = [1;0;0] ;
            testCase.verifyEqual(open.rotz(-90)*v,[0;-1;0],'AbsTol',testCase.Tol) ;
        end

        function zAxisIsUnaffected(testCase)
            v = [0;0;5] ;
            testCase.verifyEqual(open.rotz(37)*v,v,'AbsTol',testCase.Tol) ;
        end

        function isOrthogonalWithUnitDeterminant(testCase)
            R = open.rotz(23.7) ;
            testCase.verifyEqual(R*R',eye(3),'AbsTol',testCase.Tol) ;
            testCase.verifyEqual(det(R),1,'AbsTol',testCase.Tol) ;
        end

        function negativeAngleIsTranspose(testCase)
            % For a rotation matrix, R(-theta) == R(theta)' == R(theta)^-1.
            R = open.rotz(52) ;
            testCase.verifyEqual(open.rotz(-52),R','AbsTol',testCase.Tol) ;
        end

        function anglesCompose(testCase)
            testCase.verifyEqual(open.rotz(30)*open.rotz(60),open.rotz(90),'AbsTol',testCase.Tol) ;
        end
    end
end
