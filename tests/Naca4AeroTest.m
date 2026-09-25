classdef Naca4AeroTest < matlab.unittest.TestCase
    % Unit tests for api.naca4Aero. These run a real (bundled) XFoil
    % solve, so they are slower than the pure-math tests in this folder
    % and only work where +open/xfoil.exe can actually run (Windows).
    %
    % Run with: results = runtests('tests') (from the repo root, so
    % +api/+open are resolvable as packages).

    methods (Test)
        function symmetricSectionAtZeroAoAHasNearZeroLift(testCase)
            % NACA 0012 is symmetric (zero camber) -- at zero AoA it
            % should produce ~zero lift regardless of InvertWing.
            [Cl,~] = api.naca4Aero('0012',0) ;
            testCase.verifyLessThan(abs(Cl),0.05) ;
        end

        function invertWingNegatesAoAAndLift(testCase)
            % docs/CODEBASE_OVERVIEW.md's own stated verification:
            % naca4Aero('2412',-10) (InvertWing default true) matches
            % -naca4Aero('2412',10,'InvertWing',false)'s Cl, with the
            % same Cd (drag doesn't care which way up the wing is).
            [ClInverted,CdInverted] = api.naca4Aero('2412',-10) ;
            [ClNormal,CdNormal] = api.naca4Aero('2412',10,'InvertWing',false) ;
            testCase.verifyEqual(ClInverted,-ClNormal,'AbsTol',1e-6) ;
            testCase.verifyEqual(CdInverted,CdNormal,'AbsTol',1e-6) ;
        end

        function negativeAoAWithDefaultInvertWingGivesDownforce(testCase)
            % Convention: with InvertWing=true (default), negative AoA
            % is a downforce-generating incidence -> negative Cl.
            [Cl,~] = api.naca4Aero('2412',-8) ;
            testCase.verifyLessThan(Cl,0) ;
        end

        function outputSizeMatchesInputAoA(testCase)
            aoas = [-8 -4 0 4 8] ;
            [Cl,Cd] = api.naca4Aero('0012',aoas) ;
            testCase.verifySize(Cl,size(aoas)) ;
            testCase.verifySize(Cd,size(aoas)) ;
        end
    end
end
