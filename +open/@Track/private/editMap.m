function [x, r, apex, r_apex, incl, bank, factor_grip, sector, X, Y, Z] = editMap(x, r, apex, r_apex, incl, bank, factor_grip, sector, X, Y, Z, L, info, rotation)
    % Applies track direction, map rotation, and (for closed tracks) a
    % start/end tangency correction to the fine mesh and map coordinates.

    % track direction
    if strcmp(info.direction,'Backward')
        x = x(end)-flipud(x) ;
        r = -flipud(r) ;
        apex = length(x)-flipud(apex) ;
        r_apex = -flipud(r_apex) ;
        incl = -flipud(incl) ;
        bank = -flipud(bank) ;
        factor_grip = flipud(factor_grip) ; % NB: original script had a typo here ("factor_frip") that silently left factor_grip unflipped; fixed.
        sector = flipud(sector) ;
        X = flipud(X) ;
        Y = flipud(Y) ;
        Z = flipud(Z) ;
    end

    % track rotation
    xyz = open.rotz(rotation)*[X';Y';Z'] ;
    X = xyz(1,:)' ;
    Y = xyz(2,:)' ;
    Z = xyz(3,:)' ;

    % closing map if necessary
    if strcmp(info.config,'Closed') % closed track
        DX = x/L*(X(1)-X(end)) ;
        DY = x/L*(Y(1)-Y(end)) ;
        DZ = x/L*(Z(1)-Z(end)) ;
        db = x/L*(bank(1)-bank(end)) ;
        X = X+DX ;
        Y = Y+DY ;
        Z = Z+DZ ;
        bank = bank+db ;
        incl = -atand((diff(Z)./diff(x))) ;
        incl = [incl;(incl(end-1)+incl(1))/2] ;
    end
    % smoothing track inclination
    incl = open.smooth(incl) ;
end
