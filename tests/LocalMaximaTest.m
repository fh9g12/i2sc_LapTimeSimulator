classdef LocalMaximaTest < matlab.unittest.TestCase
    % Unit tests for open.localMaxima, the dependency-free replacement
    % for the Signal Processing Toolbox's findpeaks(y) used by
    % Track/findApexes.m and LapSimulation/runSolver.m.
    %
    % Run with: results = runtests('tests') (from the repo root, so
    % +open is resolvable as a package).

    methods (Test)
        function singleInteriorPeak(testCase)
            [pks,locs] = open.localMaxima([0 1 3 1 0]) ;
            testCase.verifyEqual(locs,3) ;
            testCase.verifyEqual(pks,3) ;
        end

        function multiplePeaks(testCase)
            [pks,locs] = open.localMaxima([0 3 1 4 0]) ;
            testCase.verifyEqual(locs,[2 4]) ;
            testCase.verifyEqual(pks,[3 4]) ;
        end

        function monotonicHasNoPeaks(testCase)
            [pks,locs] = open.localMaxima([1 2 3 4 5]) ;
            testCase.verifyEmpty(pks) ;
            testCase.verifyEmpty(locs) ;
        end

        function endpointsAreNeverPeaks(testCase)
            % A peak needs a neighbour on both sides -- a big value at
            % index 1 or end must never be reported, even though it's
            % larger than everything else in the vector.
            [pks,locs] = open.localMaxima([5 1 5]) ;
            testCase.verifyEmpty(pks) ;
            testCase.verifyEmpty(locs) ;
        end

        function tooShortInputHasNoPeaks(testCase)
            [pks,locs] = open.localMaxima([1 2]) ;
            testCase.verifyEmpty(pks) ;
            testCase.verifyEmpty(locs) ;
        end

        function preservesColumnOrientation(testCase)
            [pks,locs] = open.localMaxima([0;1;3;1;0]) ;
            testCase.verifyTrue(iscolumn(pks)) ;
            testCase.verifyTrue(iscolumn(locs)) ;
        end

        function preservesRowOrientation(testCase)
            [pks,locs] = open.localMaxima([0 1 3 1 0]) ;
            testCase.verifyTrue(isrow(pks)) ;
            testCase.verifyTrue(isrow(locs)) ;
        end

        function matchesUsagePattern_negatedForMinima(testCase)
            % runSolver.m calls open.localMaxima(-v_max) to find speed
            % minima (apexes). Check that pattern directly.
            v = [50 30 45 10 60] ;
            [v_apex_neg,apex] = open.localMaxima(-v) ;
            testCase.verifyEqual(apex,[2 4]) ;
            testCase.verifyEqual(-v_apex_neg,v(apex)) ;
        end
    end
end
