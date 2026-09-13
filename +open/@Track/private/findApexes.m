function [apex, r_apex] = findApexes(r)
    [~,apex] = findpeaks(abs(r)) ;
    r_apex = r(apex) ;
end
