function coarse = preprocessShapeData(info, table_shape, table_el, table_bk, table_gf, table_sc, kappa)
    % Converts the shape-data sheets (segment list + elevation/banking/
    % grip/sector breakpoints) into a common coarse track representation
    % ready for meshing: position vectors xx/xe/xb/xg/xs paired with
    % value vectors r/el/bk/gf/sc, plus the total track length L.

    R = table2array(table_shape(:,3)) ;
    l = table2array(table_shape(:,2)) ;
    type_tmp = table2array(table_shape(:,1)) ;
    % correcting straight segment radius
    R(R==0) = inf ;
    % total length
    L = sum(l) ;
    % segment type variable conversion to number
    type = zeros(length(l),1) ;
    type(string(type_tmp)=="Straight") = 0 ;
    type(string(type_tmp)=="Left") = 1 ;
    type(string(type_tmp)=="Right") = -1 ;
    if strcmp(info.mirror,'On')
        type = -type ;
    end
    % removing segments with zero length
    R(l==0) = [] ;
    type(l==0) = [] ;
    l(l==0) = [] ;
    % injecting points at long corners
    angle_seg = rad2deg(l./R) ;
    j = 1 ; % index
    RR = R ; % new vector containing injected points
    ll = l ; % new vector containing injected points
    tt = type ; % new vector containing injected points
    for i = 1:length(l)
        if angle_seg(i)>kappa
            l_inj = min([ll(j)/3,deg2rad(kappa)*R(i)]) ;
            ll = [...
                ll(1:j-1);...
                l_inj;...
                ll(j)-2*l_inj;...
                l_inj;...
                ll(j+1:end)...
                ] ;
            RR = [...
                RR(1:j-1);...
                RR(j);...
                RR(j);...
                RR(j);...
                RR(j+1:end)...
                ] ;
            tt = [...
                tt(1:j-1);...
                tt(j);...
                tt(j);...
                tt(j);...
                tt(j+1:end)...
                ] ;
            j = j+3 ;
        else
            j = j+1 ;
        end
    end
    R = RR ;
    l = ll ;
    type = tt ;
    % replacing consecutive straights
    for i = 1:length(l)-1
        j = 1 ;
        while true
            if type(i+j)==0 && type(i)==0 && l(i)~=-1
                l(i) = l(i)+l(i+j) ;
                l(i+j) = -1 ;
            else
                break
            end
            j = j+1 ;
        end
    end
    R(l==-1) = [] ;
    type(l==-1) = [] ;
    l(l==-1) = [] ;
    % final segment point calculation
    X = cumsum(l) ; % end position of each segment
    XC = cumsum(l)-l/2 ; % center position of each segment
    j = 1 ; % index
    x = zeros(length(X)+sum(R==inf),1) ; % preallocation
    r = zeros(length(X)+sum(R==inf),1) ; % preallocation
    for i = 1:length(X)
        if R(i)==inf % end of straight point injection
            x(j) = X(i)-l(i) ;
            x(j+1) = X(i) ;
            j = j+2 ;
        else % circular segment center
            x(j) = XC(i) ;
            r(j) = type(i)./R(i) ;
            j = j+1 ;
        end
    end
    % getting data from tables and ignoring points with x>L
    el = table2array(table_el) ;
    el(el(:,1)>L,:) = [] ;
    bk = table2array(table_bk) ;
    bk(bk(:,1)>L,:) = [] ;
    gf = table2array(table_gf) ;
    gf(gf(:,1)>L,:) = [] ;
    sc = table2array(table_sc) ;
    sc(sc(:,1)>=L,:) = [] ;
    sc = [sc;[L,sc(end,end)]] ;

    coarse.xx = x ;
    coarse.r = r ;
    coarse.L = L ;
    coarse.xe = el(:,1) ;
    coarse.el = el(:,2) ;
    coarse.xb = bk(:,1) ;
    coarse.bk = bk(:,2) ;
    coarse.xg = gf(:,1) ;
    coarse.gf = gf(:,2) ;
    coarse.xs = sc(:,1) ;
    coarse.sc = sc(:,2) ;
end
