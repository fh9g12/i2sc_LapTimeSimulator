function ys = smooth(y,span)
% smooth - dependency-free replacement for the Curve Fitting Toolbox's
% smooth(y)/smooth(y,span), covering exactly the usage this project
% needs: 1-D moving-average smoothing with a shrinking window at the
% edges. Avoids requiring students to have that toolbox installed.
%
% ys = open.smooth(y)
% ys = open.smooth(y,span)
%
%   y      a numeric vector
%   span   window width in samples (default 5, matching the toolbox
%          function's own default for its default 'moving' method).
%          Must be odd; an even span is reduced by 1, matching the
%          toolbox function. Values below 1 are treated as 1 (no
%          smoothing).
%
% ys has the same orientation as y. For interior points, ys(i) is the
% mean of the span samples centred on y(i). Near the ends, where a full
% window doesn't fit, the window shrinks symmetrically (ys(1)=y(1),
% ys(2)=mean(y(1:3)), ys(3)=mean(y(1:5)), ... up to span), matching the
% toolbox function's own edge behaviour for the 'moving' method.
%
% NOT REPLICATED: the toolbox function's other smoothing methods
% ('lowess','loess','sgolay','rlowess','rloess') and its outlier-robust
% weighting -- this project only ever calls the default moving-average
% method with no method argument.
    if nargin < 2 || isempty(span)
        span = 5 ;
    end
    span = max(1,round(span)) ;
    if mod(span,2)==0
        span = span-1 ;
    end

    isRowInput = isrow(y) ;
    v = y(:) ;
    n = numel(v) ;
    ys = zeros(n,1,'like',v) ;
    halfWindow = (span-1)/2 ;
    for i = 1:n
        w = min([halfWindow,i-1,n-i]) ;
        ys(i) = mean(v(i-w:i+w)) ;
    end
    if isRowInput
        ys = ys.' ;
    end
end
