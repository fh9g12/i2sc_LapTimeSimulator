classdef GenCarAeroDataTest < matlab.unittest.TestCase
    % Unit tests for api.genCarAeroData. These run real (bundled) XFoil
    % solves via api.naca4Aero, so they are slower than the pure-math
    % tests in this folder and only work where +open/xfoil.exe can
    % actually run (Windows).
    %
    % Run with: results = runtests('tests') (from the repo root, so
    % +api/+open are resolvable as packages).

    methods (Test)
        function returnsDownforceSignConvention(testCase)
            % CL negative (downforce), CD positive (drag magnitude) --
            % the ordinary aerodynamics convention this whole project
            % uses (see docs/CODEBASE_OVERVIEW.md's sign-convention
            % section).
            [CL,CD,~] = api.genCarAeroData('0012',-4,'0012',-4) ;
            testCase.verifyLessThan(CL,0) ;
            testCase.verifyGreaterThan(CD,0) ;
        end

        function aeroBalanceIsAFraction(testCase)
            [~,~,aeroBalance] = api.genCarAeroData('0012',-4,'0012',-4) ;
            testCase.verifyGreaterThanOrEqual(aeroBalance,0) ;
            testCase.verifyLessThanOrEqual(aeroBalance,1) ;
        end

        function biggerFrontWingShiftsBalanceForward(testCase)
            % docs/CODEBASE_OVERVIEW.md's own stated verification
            % recipe: make one wing bigger (more negative AoA), confirm
            % aeroBalance moves toward that wing, not away.
            [~,~,abBaseline] = api.genCarAeroData('0012',-4,'0012',-4) ;
            [~,~,abBiggerFront] = api.genCarAeroData('0012',-9,'0012',-4) ;
            testCase.verifyGreaterThan(abBiggerFront,abBaseline) ;
        end

        function biggerRearWingShiftsBalanceRearward(testCase)
            [~,~,abBaseline] = api.genCarAeroData('0012',-4,'0012',-4) ;
            [~,~,abBiggerRear] = api.genCarAeroData('0012',-4,'0012',-9) ;
            testCase.verifyLessThan(abBiggerRear,abBaseline) ;
        end
    end
end
