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
Nalpha = length(alpha) ;

% Timeout: per-alpha limit (change with setpref('xfoil','timeoutPerAlpha',3))
% plus 1 s for start-up / file I/O.
timeoutPerAlpha = getpref('xfoil','timeoutPerAlpha',2) ;
timeout = 1 + timeoutPerAlpha*Nalpha ;

wd = fileparts(mfilename('fullpath')) ;
% Unique temp-file stem per process + call, so parallel workers sharing wd
% don't overwrite each other's .inp/.out/dump files. Kept short and
% space-free since XFoil sees these as bare filenames.
fname = sprintf('xf%d_%04d', feature('getpid'), randi(9999)) ;
foil_name = mfilename ;
isNacaString = (ischar(coord) || isstring(coord)) && ~isempty(regexpi(char(coord),'^NACA *[0-9]{4,5}$','once')) ;

file_coord_bare = [fname '.foil'] ;
file_dump_bare = arrayfun(@(a) sprintf('%s_a%06.3f_dump.dat',fname,a), alpha, 'UniformOutput', false) ;
file_cpwr_bare = arrayfun(@(a) sprintf('%s_a%06.3f_cpwr.dat',fname,a), alpha, 'UniformOutput', false) ;
file_pwrt_bare = sprintf('%s_pwrt.dat',fname) ;

file_coord = fullfile(wd,file_coord_bare) ;
file_dump = cellfun(@(f) fullfile(wd,f), file_dump_bare, 'UniformOutput', false) ;
file_cpwr = cellfun(@(f) fullfile(wd,f), file_cpwr_bare, 'UniformOutput', false) ;
file_pwrt = fullfile(wd,file_pwrt_bare) ;
file_inp = fullfile(wd,[fname '.inp']) ;
file_out = fullfile(wd,[fname '.out']) ;

% Save coordinates
if ischar(coord) || isstring(coord)
    if isNacaString
        loadTarget = '' ;
    else
        loadTarget = char(coord) ;
    end
else
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

cleanupTemp = onCleanup(@() cleanupStem(wd, fname)) ;

% Write xfoil command file
fid = fopen(file_inp,'w') ;
if fid<=0
    error([mfilename ':io'],'Unable to create xfoil.inp file') ;
end
% Headless: toggle PLOP graphics off before anything plots (no pltlib window,
% no focus stealing). Re-enable for debugging with setpref('xfoil','graphics',true).
if ~getpref('xfoil','graphics',false)
    fprintf(fid,'plop\ng\n\n') ;
end
if isNacaString
    fprintf(fid,'naca %s\n',regexprep(char(coord),'^NACA *','')) ;
else
    fprintf(fid,'load %s\n',loadTarget) ;
end
if isNacaString
    fprintf(fid,'naca %s\n',regexprep(char(coord),'^NACA *','')) ;
else
    fprintf(fid,'load %s\n',loadTarget) ;
end
for ii = 1:numel(extraCommands)
    txt = regexprep(extraCommands{ii},'[\\/]+','\n') ;
    fprintf(fid,'%s\n\n',txt) ;
end
fprintf(fid,'\n\noper\n') ;
fprintf(fid,'re %g\n',Re) ;
fprintf(fid,'mach %g\n',Mach) ;
if Re>0
    fprintf(fid,'visc\n') ;
    fprintf(fid,'iter %d\n',iterCap) ;
end
fprintf(fid,'pacc\n\n\n') ;
for ii = 1:Nalpha
    fprintf(fid,'alfa %g\n',alpha(ii)) ;
    fprintf(fid,'dump %s\n',file_dump_bare{ii}) ;
    fprintf(fid,'cpwr %s\n',file_cpwr_bare{ii}) ;
end
fprintf(fid,'pwrt\n%s\n',file_pwrt_bare) ;
fprintf(fid,'plis\n') ;
fprintf(fid,'\nquit\n') ;
fclose(fid) ;

% Execute xfoil with a hard time limit. Launched directly (no cmd.exe), with
% its working directory set to wd so the bare filenames above still resolve,
% and stdin/stdout redirected to the .inp/.out files.
exePath = fullfile(wd,'xfoil.exe') ;
[timedOut, status] = runWithTimeout(exePath, wd, file_inp, file_out, timeout) ;
if timedOut
    if ischar(coord) || isstring(coord), desc = char(coord) ; else, desc = 'coords' ; end
    warning([mfilename ':timeout'], ...
        'XFoil timed out after %.1f s (%s, alpha = %s); process killed.', ...
        timeout, desc, mat2str(alpha,4)) ;
    pol  = emptyPolar(foil_name) ;
    foil = struct([]) ;
    return
end
if status~=0
    if isfile(file_out), disp(fileread(file_out)) ; end
    error([mfilename ':system'],'Xfoil execution failed (exit code %d).',status) ;
end

if nargout>1
    foil = readFoilData(file_dump,file_cpwr,alpha) ;
end
pol = readPolarFile(file_pwrt,Nalpha) ;
clear cleanupTemp      % data extracted: delete temp files now
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
    % warning([mfilename ':noConverge'], ...
    %     'No requested alpha converged. Try a higher iterCap, or a less extreme AoA/Re/Mach.') ;
elseif length(pol.alpha) ~= Nalpha
    % warning([mfilename ':noConverge'], ...
    %     'One or more alpha values failed to converge. Last converged was alpha = %g. Try a higher iterCap.', ...
    %     pol.alpha(end)) ;
end
end

function [timedOut, status] = runWithTimeout(exePath, wd, inFile, outFile, timeout)
% Start exePath with stdin/stdout redirected to files; kill it if it runs
% longer than timeout (s). Also kills it if MATLAB is interrupted (Ctrl+C).
cmd = javaArray('java.lang.String',1) ;
cmd(1) = java.lang.String(exePath) ;
pb = java.lang.ProcessBuilder(cmd) ;
pb.directory(java.io.File(wd)) ;
pb.redirectInput(java.io.File(inFile)) ;
pb.redirectErrorStream(true) ;
pb.redirectOutput(java.io.File(outFile)) ;   % must be drained somewhere or XFoil blocks
p = pb.start() ;
killer = onCleanup(@() killIfAlive(p)) ; %#ok<NASGU>

t0 = tic ;  timedOut = false ;
while p.isAlive()
    if toc(t0) > timeout
        timedOut = true ;
        break
    end
    pause(0.005) ;
end
if timedOut
    p.destroyForcibly() ;
    p.waitFor(2, java.util.concurrent.TimeUnit.SECONDS) ;
    status = -1 ;
else
    status = p.exitValue() ;
end
end

function killIfAlive(p)
if p.isAlive(), p.destroyForcibly() ; end
end

function pol = emptyPolar(name)
e = zeros(0,1) ;
pol = struct('name',name,'xtrf_top',NaN,'xtrf_bot',NaN,'Re',NaN,'Ncrit',NaN, ...
    'alpha',e,'CL',e,'CD',e,'CDp',e,'Cm',e,'Top_xtr',e,'Bot_xtr',e) ;
end

function cleanupStem(wd, stem)
% Delete all files in wd beginning with this call's unique stem.
% Retries briefly in case Windows still holds a lock (e.g. just after a kill).
ws = warning('off','all') ;
restoreWarn = onCleanup(@() warning(ws)) ; %#ok<NASGU>
files = dir(fullfile(wd, [stem '*'])) ;
for i = 1:numel(files)
    f = fullfile(wd, files(i).name) ;
    for attempt = 1:10
        try, delete(f) ; catch, end
        if ~isfile(f), break ; end
        pause(0.05) ;
    end
end
end

