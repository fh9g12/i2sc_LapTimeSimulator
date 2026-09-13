function [x, dx, n, r, Z, bank, incl, factor_grip, sector] = computeMesh(coarse, mesh_size)
    % Resamples the coarse track representation onto a fine, evenly
    % spaced (except for a possible last short segment) position mesh.
    L = coarse.L ;
    if floor(L)<L % check for injecting last point
        x = [(0:mesh_size:floor(L))';L] ;
    else
        x = (0:mesh_size:floor(L))' ;
    end
    dx = diff(x) ;
    dx = [dx;dx(end)] ;
    n = length(x) ;
    r = interp1(coarse.xx, coarse.r, x, 'pchip', 'extrap') ;
    Z = interp1(coarse.xe, coarse.el, x, 'linear', 'extrap') ;
    bank = interp1(coarse.xb, coarse.bk, x, 'linear', 'extrap') ;
    incl = -atand((diff(Z)./diff(x))) ;
    incl = [incl;incl(end)] ;
    factor_grip = interp1(coarse.xg, coarse.gf, x, 'linear', 'extrap') ;
    sector = interp1(coarse.xs, coarse.sc, x, 'previous', 'extrap') ;
end
