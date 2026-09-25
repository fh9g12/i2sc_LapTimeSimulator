classdef SmoothTest < matlab.unittest.TestCase
    % Unit tests for open.smooth, the dependency-free replacement for
    % the Curve Fitting Toolbox's smooth(y)/smooth(y,span) used by
    % Track/editMap.m and Track/loadLoggedTrackData.m.
    %
    % Run with: results = runtests('tests') (from the repo root, so
    % +open is resolvable as a package).

    methods (Test)
        function constantVectorIsUnchanged(testCase)
            y = 5*ones(1,9) ;
            testCase.verifyEqual(open.smooth(y),y,'AbsTol',1e-12) ;
            testCase.verifyEqual(open.smooth(y,3),y,'AbsTol',1e-12) ;
        end

        function linearRampIsUnchanged(testCase)
            % A moving average centred symmetrically on i (even with a
            % shrinking window at the edges) reproduces a perfectly
            % linear input exactly at every point, for any span.
            y = 1:10 ;
            testCase.verifyEqual(open.smooth(y),double(y),'AbsTol',1e-10) ;
            testCase.verifyEqual(open.smooth(y,3),double(y),'AbsTol',1e-10) ;
            testCase.verifyEqual(open.smooth(y,9),double(y),'AbsTol',1e-10) ;
        end

        function smoothsASpike(testCase)
            y = [1 1 1 1 100 1 1 1 1] ;
            ys = open.smooth(y,3) ;
            testCase.verifyEqual(ys(5),(1+100+1)/3,'AbsTol',1e-10) ;
            testCase.verifyLessThan(ys(5),y(5)) ;
        end

        function edgesUseShrinkingWindow(testCase)
            % First and last points are never smoothed against
            % neighbours they don't have -- span 5 with a spike right at
            % the start should still show it, undiluted (window=1).
            y = [100 1 1 1 1 1 1] ;
            ys = open.smooth(y) ; % default span 5
            testCase.verifyEqual(ys(1),100) ;
            testCase.verifyEqual(ys(2),mean(y(1:3))) ;
        end

        function evenSpanIsReducedByOne(testCase)
            y = [1 5 2 8 3 9 4 7 6] ;
            testCase.verifyEqual(open.smooth(y,4),open.smooth(y,3)) ;
        end

        function spanBelowOneActsAsIdentity(testCase)
            y = [3 1 4 1 5 9 2 6] ;
            testCase.verifyEqual(open.smooth(y,0),double(y)) ;
            testCase.verifyEqual(open.smooth(y,-3),double(y)) ;
        end

        function preservesColumnOrientation(testCase)
            testCase.verifyTrue(iscolumn(open.smooth((1:6)'))) ;
        end

        function preservesRowOrientation(testCase)
            testCase.verifyTrue(isrow(open.smooth(1:6))) ;
        end
    end
end
