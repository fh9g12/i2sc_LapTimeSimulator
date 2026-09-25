function [apex, r_apex] = findApexes(r)
    [~,apex] = open.localMaxima(abs(r)) ;
    r_apex = r(apex) ;
end
