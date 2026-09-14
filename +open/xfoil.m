function [pol,foil] = xfoil(coord,alpha,Re,Mach,iterCap,extraCommands)
% Run XFoil and return the results.
% [pol,foil] = open.xfoil(coord,alpha,Re,Mach,iterCap,extraCommands...)
%
% Xfoil.exe needs to be in the same directory as this m function.
% For more information on XFoil visit these websites;
%  http://web.mit.edu/drela/Public/web/xfoil
%
% Inputs:
%    coord: Normalised foil co-ordinates (n by 2 array, of x & y
%           from the TE-top passed the LE to the TE bottom)
%           or a filename of the XFoil co-ordinate file
%           or a NACA 4 or 5 digit descriptor (e.g. 'NACA0012')
%    alpha: Angle-of-attack, can be a vector for an alpha polar
%       Re: Reynolds number (use Re=0 for inviscid mode)
%     Mach: Mach number
%  iterCap: max Newton iterations per operating point (default 100).
%           XFoil's own built-in default is a mere 10, often not enough
%           to converge from a fresh viscous start at anything but a
%           small angle of attack. This is issued as its own 'iter ##'
%           command in the correct place (inside the OPER submenu, after
%           VISC) -- do NOT try to set this via extraCommands instead:
%           XFoil takes one command per line, so 'oper iter 150' as a
%           single extra-command string either gets silently ignored
%           (OPER itself takes no arguments) or has '150' land as a bare
%           number at the OPER prompt, which XFoil reads as a shortcut
%           for 'set angle of attack', not an iteration count.
% extraCommands: any number of trailing extra XFoil command strings, run
%           BEFORE entering the OPER submenu (i.e. for geometry-stage
%           commands, not OPER-submenu settings like iter/Ncrit -- see
%           iterCap above for the latter, which OPER-submenu settings
%           need instead, and for why). Each command STRING can pack
%           several menu-hops separated by '/' (each becomes its own
%           line) -- but NOT by plain spaces, since a real command's own
%           inline arguments are themselves space-separated (e.g. 'flap
%           0.6 0 5' must stay on one line) and there is no way to tell
%           those apart from a deliberate menu-hop using spaces alone.
%           When in doubt, just pass each command as its own separate
%           extraCommands entry instead of packing several into one
%           '/'-joined string.
%
% A flap deflection can be added using the following extra commands,
% 'gdes','flap {xhinge} {yhinge} {flap_defelction}','exec'
% (sanity-check this against a live XFoil run before relying on it)
%
% Outputs:
%  pol: structure with the polar coefficients (alpha,CL,CD,CDp,CM,
%          Top_Xtr,Bot_Xtr)
% foil: structure with the per-alpha panel/boundary-layer data (s,x,y,
%          UeVinf,Dstar,Theta,Cf,H) and surface pressure (xcp,cp), one
%          column per angle-of-attack. Only computed if requested (i.e.
%          nargout>1) -- a single-output call skips reading/parsing the
%          per-alpha dump/cp files entirely, which is both faster and
%          all you need for a bare Cl/Cd polar.
%
% If the output array does not have all requested alphas in it, that
% indicates a genuine convergence failure (e.g. AoA is at/past stall) --
% try a higher iterCap first; if it still doesn't converge, that alpha is
% likely just not solvable for this geometry/Re/Mach.
%
% Examples:
%    % Raise the iteration cap for a harder-to-converge polar sweep
%    [pol,foil] = open.xfoil('NACA0012',5,1e6,0.2,150)
%
%    % Deflect the trailing edge by 20deg at 60% chord and run multiple
%    % incidence angles -- each extraCommand is one exact command line;
%    % note flap's 3 numeric args stay on one line, but 'exec' is its own
%    [pol,foil] = open.xfoil('NACA0012',[-5:15],1e6,0.2,150,'gdes','flap 0.6 0 5','exec')
%
%    % Only a polar is needed -- faster, since foil dump/cp files are skipped
%    pol = open.xfoil('NACA0012',[-5:15],1e6,0.2)
%
%    % Plot the results
%    figure;
%    plot(pol.alpha,pol.CL); xlabel('alpha [\circ]'); ylabel('C_L'); title(pol.name);
%    figure; subplot(3,1,[1 2]);
%    plot(foil.xcp,foil.cp(:,end)); xlabel('x');
%    ylabel('C_p'); title(sprintf('%s @ %g\\circ',pol.name,foil.alpha(end)));
%    set(gca,'ydir','reverse');
%    subplot(3,1,3);
%    I = (foil.x(:,end)<=1);
%    plot(foil.x(I,end),foil.y(I,end)); xlabel('x');
%    ylabel('y'); axis('equal');

arguments
    coord = 'NACA0012'
    alpha (1,:) double = 0
    Re (1,1) double {mustBeNonnegative} = 1e6
    Mach (1,1) double {mustBeNonnegative} = 0.2
    iterCap (1,1) double {mustBePositive,mustBeInteger} = 1000
end
arguments (Repeating)
    extraCommands (1,1) string
end

Nalpha = length(alpha) ; % Number of alphas swept

% wd is where xfoil.exe (and every temp file this run produces) must
% live -- it is fed to the xfoil PROCESS as bare (unqualified) filenames
% below, since XFoil's own command parser splits on whitespace and would
% break on a path containing spaces (as this project's OneDrive path
% does). Only the outer cmd.exe invocation (which DOES support quoted
% paths) uses a fully-qualified, quoted path.
wd = fileparts(mfilename('fullpath')) ; % this file's own folder, unambiguously (avoids which() ambiguity)
fname = mfilename ;
foil_name = fname ;

isNacaString = (ischar(coord) || isstring(coord)) && ~isempty(regexpi(char(coord),'^NACA *[0-9]{4,5}$','once')) ;

% Bare (unqualified) filenames -- these are what gets written INTO the
% xfoil command script for its own load/dump/cpwr/pwrt commands.
file_coord_bare = [foil_name '.foil'] ;
file_dump_bare = arrayfun(@(a) sprintf('%s_a%06.3f_dump.dat',fname,a), alpha, 'UniformOutput', false) ;
file_cpwr_bare = arrayfun(@(a) sprintf('%s_a%06.3f_cpwr.dat',fname,a), alpha, 'UniformOutput', false) ;
file_pwrt_bare = sprintf('%s_pwrt.dat',fname) ;

% Fully-qualified paths -- what MATLAB itself uses to write/read/delete
% those same files (MATLAB's own cwd need not be wd).
file_coord = fullfile(wd,file_coord_bare) ;
file_dump = cellfun(@(f) fullfile(wd,f), file_dump_bare, 'UniformOutput', false) ;
file_cpwr = cellfun(@(f) fullfile(wd,f), file_cpwr_bare, 'UniformOutput', false) ;
file_pwrt = fullfile(wd,file_pwrt_bare) ;
file_inp = fullfile(wd,[fname '.inp']) ;
file_out = fullfile(wd,[fname '.out']) ;

% Save coordinates
if ischar(coord) || isstring(coord)
    if isNacaString
        loadTarget = '' ; % not used -- 'naca' command is issued instead, below
    else
        % Filename supplied, as-is (relative to wd, or an absolute path
        % the caller supplied) -- xfoil's own load command reads it.
        loadTarget = char(coord) ;
    end
else
    % Coordinates supplied as an n-by-2 array -- write an XFoil ordinate
    % file next to xfoil.exe, referenced by its bare name.
    if isfile(file_coord), delete(file_coord) ; end
    fid = fopen(file_coord,'w') ;
    if fid<=0
        error([mfilename ':io'],'Unable to create file %s',file_coord) ;
    end
    fprintf(fid,'%s\n',foil_name) ;
    fprintf(fid,'%9.5f   %9.5f\n',coord') ;
    fclose(fid) ;
    loadTarget = file_coord_bare ;
end

% Clean up every temp file this run can produce, even if something below
% errors partway through (a read error, a failed system() call, etc).
tempFiles = [{file_inp, file_out, file_pwrt}, file_dump, file_cpwr] ;
if ~(ischar(coord)||isstring(coord))
    tempFiles = [tempFiles, {file_coord}] ;
end
cleanupTemp = onCleanup(@() cellfun(@deleteIfExists, tempFiles)) ; %#ok<NASGU>

% Write xfoil command file
fid = fopen(file_inp,'w') ;
if fid<=0
    error([mfilename ':io'],'Unable to create xfoil.inp file') ;
end

if isNacaString
    fprintf(fid,'naca %s\n',regexprep(char(coord),'^NACA *','')) ;
else
    fprintf(fid,'load %s\n',loadTarget) ;
end

% Extra Xfoil commands (geometry-stage only -- see header). '/' is an
% explicit menu-navigation separator; plain spaces are left alone, since
% a real command's own inline arguments are space-separated too and
% there's no way to tell those apart from a deliberate menu-hop.
for ii = 1:numel(extraCommands)
    txt = regexprep(extraCommands{ii},'[\\/]+','\n') ;
    fprintf(fid,'%s\n\n',txt) ;
end

fprintf(fid,'\n\noper\n') ;
fprintf(fid,'re %g\n',Re) ;
fprintf(fid,'mach %g\n',Mach) ;
if Re>0
    fprintf(fid,'visc\n') ; % viscous mode
    fprintf(fid,'iter %d\n',iterCap) ; % must come AFTER visc -- see iterCap in the header
end

fprintf(fid,'pacc\n\n\n') ; % polar accumulation
for ii = 1:Nalpha
    fprintf(fid,'alfa %g\n',alpha(ii)) ;
    fprintf(fid,'dump %s\n',file_dump_bare{ii}) ;
    fprintf(fid,'cpwr %s\n',file_cpwr_bare{ii}) ;
end
fprintf(fid,'pwrt\n%s\n',file_pwrt_bare) ;
fprintf(fid,'plis\n') ;
fprintf(fid,'\nquit\n') ;
fclose(fid) ;

% Execute xfoil. Needs BOTH: (a) cd'ing into wd first, so xfoil.exe's
% own process cwd resolves the bare load/dump/cpwr/pwrt filenames it was
% just told to use above, and (b) invoking it by its fully-qualified
% path -- a bare "xfoil.exe" does not reliably resolve via cmd.exe's
% current-directory search when invoked through system(). Every path here
% is quoted since wd may contain spaces; xfoil.exe itself never sees
% these quoted/qualified paths, only cmd.exe does -- see the
% bare-vs-qualified filename split above.
exePath = fullfile(wd,'xfoil.exe') ;
cmd = sprintf('cd /d "%s" && "%s" < "%s" > "%s"',wd,exePath,file_inp,file_out) ;
[status,result] = system(cmd) ;
if status~=0
    disp(result) ;
    error([mfilename ':system'],'Xfoil execution failed! %s',cmd) ;
end

if nargout>1
    foil = readFoilData(file_dump,file_cpwr,alpha) ;
end

pol = readPolarFile(file_pwrt,Nalpha) ;

end

%% ============================================================ local functions

function deleteIfExists(f)
    if isfile(f), delete(f) ; end
end

function foil = readFoilData(file_dump,file_cpwr,alpha)
% readFoilData - parse the per-alpha "dump" (panel/boundary-layer) and
% "cpwr" (surface pressure) files XFoil was asked to write for every
% requested angle of attack, into one Npanel-by-Nalpha struct.
%
% Assumes a constant panel count across the whole alpha sweep, which
% holds for one XFoil session against one fixed geometry (paneling is
% set once, independent of alpha) -- the only case this is ever called
% with, since coord/geometry is fixed for the whole of one xfoil() call.
    Nalpha = numel(alpha) ;
    foil.alpha = zeros(1,Nalpha) ;
    Npanel = [] ;
    NCp = [] ;

    for jj = 1:Nalpha
        %    #    s        x        y     Ue/Vinf    Dstar     Theta      Cf       H
        fid = fopen(file_dump{jj},'r') ;
        if fid<=0
            error([mfilename ':io'],'Unable to read xfoil output file %s',file_dump{jj}) ;
        end
        D = textscan(fid,'%f%f%f%f%f%f%f%f','Delimiter',' ','MultipleDelimsAsOne',true,'CollectOutput',1,'HeaderLines',1) ;
        fclose(fid) ;

        if isempty(Npanel)
            Npanel = size(D{1},1) ;
            [foil.s, foil.x, foil.y, foil.UeVinf, foil.Dstar, foil.Theta, foil.Cf, foil.H] = deal(zeros(Npanel,Nalpha)) ;
        end

        foil.s(:,jj)      = D{1}(:,1) ;
        foil.x(:,jj)      = D{1}(:,2) ;
        foil.y(:,jj)      = D{1}(:,3) ;
        foil.UeVinf(:,jj) = D{1}(:,4) ;
        foil.Dstar(:,jj)  = D{1}(:,5) ;
        foil.Theta(:,jj)  = D{1}(:,6) ;
        foil.Cf(:,jj)     = D{1}(:,7) ;
        foil.H(:,jj)      = D{1}(:,8) ;
        foil.alpha(1,jj)  = alpha(jj) ;

        fid = fopen(file_cpwr{jj},'r') ;
        if fid<=0
            error([mfilename ':io'],'Unable to read xfoil output file %s',file_cpwr{jj}) ;
        end
        C = textscan(fid,'%10f%9f%f','Delimiter','','WhiteSpace','','HeaderLines',3,'ReturnOnError',false) ;
        fclose(fid) ;

        if isempty(NCp)
            NCp = length(C{1}) ;
            foil.cp = zeros(NCp,Nalpha) ;
            foil.xcp = C{1}(:,1) ; % panel x-locations are alpha-independent
        end
        foil.cp(:,jj) = C{3}(:,1) ;
    end
end

function pol = readPolarFile(file_pwrt,Nalpha)
% readPolarFile - parse the polar file XFoil's "pwrt" command wrote,
% e.g.:
%
%       XFOIL         Version 6.96
%
% Calculated polar for: NACA 0012
%
% 1 1 Reynolds number fixed          Mach number fixed
%
% xtrf =   1.000 (top)        1.000 (bottom)
% Mach =   0.000     Re =     1.000 e 6     Ncrit =  12.000
%
%   alpha    CL        CD       CDp       CM     Top_Xtr  Bot_Xtr
%  ------ -------- --------- --------- -------- -------- --------
    fid = fopen(file_pwrt,'r') ;
    if fid<=0
        error([mfilename ':io'],'Unable to read xfoil polar file %s',file_pwrt) ;
    end

    P = textscan(fid,' Calculated polar for: %[^\n]','Delimiter',' ','MultipleDelimsAsOne',true,'HeaderLines',3) ;
    pol.name = strtrim(P{1}{1}) ;
    P = textscan(fid,'%*s%*s%f%*s%f%s%s%s%s%s%s',1,'Delimiter',' ','MultipleDelimsAsOne',true,'HeaderLines',2,'ReturnOnError',false) ;
    pol.xtrf_top = P{1}(1) ;
    pol.xtrf_bot = P{2}(1) ;
    P = textscan(fid,'%*s%*s%f%*s%*s%f%*s%f%*s%*s%f',1,'Delimiter',' ','MultipleDelimsAsOne',true,'HeaderLines',0,'ReturnOnError',false) ;
    pol.Re = P{2}(1)*10^P{3}(1) ;
    pol.Ncrit = P{4}(1) ;

    P = textscan(fid,'%f%f%f%f%f%f%f%*s%*s%*s%*s','Delimiter',' ','MultipleDelimsAsOne',true,'HeaderLines',4,'ReturnOnError',false) ;
    fclose(fid) ;

    pol.alpha   = P{1}(:,1) ;
    pol.CL      = P{2}(:,1) ;
    pol.CD      = P{3}(:,1) ;
    pol.CDp     = P{4}(:,1) ;
    pol.Cm      = P{5}(:,1) ;
    pol.Top_xtr = P{6}(:,1) ;
    pol.Bot_xtr = P{7}(:,1) ;

    if isempty(pol.alpha)
        warning([mfilename ':noConverge'], ...
            'No requested alpha converged. Try a higher iterCap, or a less extreme AoA/Re/Mach.') ;
    elseif length(pol.alpha) ~= Nalpha
        warning([mfilename ':noConverge'], ...
            'One or more alpha values failed to converge. Last converged was alpha = %g. Try a higher iterCap.', ...
            pol.alpha(end)) ;
    end
end
