function obj = buildFromCoarseData(info, coarse, mesh_size, rotation)
    % Shared tail end of both Track factories: meshing, map generation,
    % apex finding, direction/rotation/closing correction and the finish
    % arrow, followed by construction and the console summary.

    [x,dx,n,r,Z,bank,incl,factor_grip,sector] = computeMesh(coarse, mesh_size) ;
    [X,Y] = generateMap(x, dx, r, coarse.L, info) ;
    [apex,r_apex] = findApexes(r) ;
    [x,r,apex,r_apex,incl,bank,factor_grip,sector,X,Y,Z] = editMap(x,r,apex,r_apex,incl,bank,factor_grip,sector,X,Y,Z,coarse.L,info,rotation) ;
    arrow = computeFinishArrow(X,Y,Z) ;

    params.info = info ;
    params.x = x ;
    params.dx = dx ;
    params.n = n ;
    params.r = r ;
    params.bank = bank ;
    params.incl = incl ;
    params.factor_grip = factor_grip ;
    params.sector = sector ;
    params.r_apex = r_apex ;
    params.apex = apex ;
    params.X = X ;
    params.Y = Y ;
    params.Z = Z ;
    params.arrow = arrow ;

    obj = open.Track(params) ;

    disp("Name:          "+obj.info.name)
    disp("City:          "+obj.info.city)
    disp("Country:       "+obj.info.country)
    disp("Type:          "+obj.info.type)
    disp("Configuration: "+obj.info.config)
    disp("Direction:     "+obj.info.direction)
    disp("Mirror:        "+obj.info.mirror)
    disp("Date:          "+datestr(now,'dd/mm/yyyy'))
    disp("Time:          "+datestr(now,'HH:MM:SS'))
    disp('==================================================================')
end
