function [pks,locs] = localMaxima(y)
% localMaxima - dependency-free replacement for the Signal Processing
% Toolbox's findpeaks(y), covering exactly the usage this project needs
% (a plain call with no name-value options): every index that is a
% strict local maximum (greater than both its immediate neighbours).
% Avoids requiring students to have that toolbox installed.
%
% [pks,locs] = open.localMaxima(y)
%
%   y      a numeric vector
%
% pks, locs have the same orientation as y (row in, row out; column in,
% column out), same as findpeaks. locs is always in ascending order and
% never includes 1 or numel(y) -- a peak needs a neighbour on both
% sides, matching findpeaks' own default behaviour.
%
% NOT REPLICATED: findpeaks' name-value options (MinPeakHeight,
% MinPeakDistance, etc, none of which this project uses) and its
% flat-plateau handling (a run of exactly equal values at a peak) -- an
% exact tie between neighbouring samples is not expected in this
% project's interpolated curvature/speed data, and is not treated as a
% peak here.
    isRowInput = isrow(y) ;
    v = y(:) ;
    n = numel(v) ;
    if n >= 3
        isPeak = [false; v(2:end-1) > v(1:end-2) & v(2:end-1) > v(3:end); false] ;
    else
        isPeak = false(n,1) ;
    end
    locs = find(isPeak) ;
    pks = v(locs) ;
    if isRowInput
        pks = pks.' ;
        locs = locs.' ;
    end
end
