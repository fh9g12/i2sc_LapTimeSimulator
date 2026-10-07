setpref('xfoil','graphics',false)
warning('off','naca4Aero:noConverge')
warning('off','xfoil:noConverge')
%% ===== Step 1: Sectional database (cl, cd vs alpha) =====
clear all
ms = [0 1 2 3 4 5 6 7 8 9];  ps = [1 2 3 4 5 6 7 8 9];  ts = 1:22;
alphas = 4:-0.25:-20;          % coarse sweep, downforce side
sgn    = -1;                % cl < 0 is downforce
dA     = 0.05;              % refinement step around max L/D (deg)
win    = 1;               % refinement window +/- (deg)
margin = 0.5;                 % stall margin (deg)

secs = {};
for m = ms, for p = ps, for tt = ts
            if m == 0, s = sprintf('00%02d', tt); else, s = sprintf('%d%d%02d', m, p, tt); end
            secs{end+1} = s; %#ok<SAGROW>
end, end, end
secs = unique(secs);

% One database per distinct wing chord (chord sets the XFOIL Reynolds number).
% Chords come from api.CarAeroParams so they match api.wingSectionAero.
par    = api.CarAeroParams();
chords = unique([par.frontChord_m, par.rearChord_m]);

tmpl = struct('sec','', 'a',[], 'cl',[], 'cd',[], ...
    'aB',[], 'clB',[], 'cdB',[], 'clcd',[], ...
    'aOpt',NaN, 'clOpt',NaN, 'cdOpt',NaN, 'LDopt',NaN);

for c = 1:numel(chords)
    chord_m = chords(c);
    db      = repmat(tmpl, 1, numel(secs));

    parfor k = 1:numel(secs)
        tic;
        util.Log.debug(sprintf('Chord %.3f m, run %.0f of %.0f (%s)', chord_m, k, numel(secs), secs{k}))
        % --- Coarse sweep ---
        cl = nan(size(alphas));  cd = cl;
        for i = 1:numel(alphas)
            try,[cl(i), cd(i)] = api.naca4Aero(secs{k}, alphas(i), 'chord_m', chord_m); end %#ok<TRYNC>
            if abs(alphas(i)) > 5 && isnan(cl(i)) && isnan(cl(i-1))
                break;
            end
        end
        a = alphas;

        % --- Refine around coarse max L/D ---
        [aB, clB, cdB] = linearBranch(a, cl, cd, margin);
        if numel(aB) >= 3
            [~, im] = max(sgn * clB ./ cdB);
            aNew = aB(im) + (-win:dA:win);
            aNew = aNew(aNew <= max(a) & aNew >= min(a));
            aNew = aNew(~ismembertol(aNew, a, 1e-6, 'DataScale', 1));
            clN = nan(size(aNew));  cdN = clN;
            for i = 1:numel(aNew)
                try, [clN(i), cdN(i)] = api.naca4Aero(secs{k}, aNew(i), 'chord_m', chord_m); end %#ok<TRYNC>
            end
            [a, s] = sort([a, aNew]);
            cl = [cl, clN];  cl = cl(s);
            cd = [cd, cdN];  cd = cd(s);
        end

        % --- Store ---
        D = tmpl;  D.sec = secs{k};  D.a = a;  D.cl = cl;  D.cd = cd;
        [D.aB, D.clB, D.cdB] = linearBranch(a, cl, cd, margin);
        D.clcd = sgn * D.clB ./ D.cdB;
        if ~isempty(D.clcd)
            [D.LDopt, io] = max(D.clcd);
            D.aOpt = D.aB(io);  D.clOpt = D.clB(io);  D.cdOpt = D.cdB(io);
        end
        db(k) = D;
        t = toc;
        util.Log.debug(sprintf('Chord %.3f m, run %.0f (%s) - Complete in %.2f s', chord_m, k, secs{k}, t))
    end
    save(sprintf('+fh\\bin\\naca_db_c%04.0f.mat', chord_m*1000), 'db', 'chord_m')
end

%% ===== Local functions =====
function [aB, clB, cdB] = linearBranch(a, cl, cd, margin)
% Monotonic pre-stall downforce branch, sorted by ascending alpha
% (so clB is ascending too, as needed by interp1(clB, aB) in bestSection).
aB = []; clB = []; cdB = [];
[a, s] = sort(a);  cl = cl(s);  cd = cd(s);
ok = ~isnan(cl) & ~isnan(cd);
a = a(ok); cl = cl(ok); cd = cd(ok);
if numel(a) < 3, return; end

% Walk from alpha = 0 towards negative alpha while downforce keeps growing
hi = numel(a);  lo = hi;
while lo > 1 && cl(lo-1) < cl(lo), lo = lo - 1; end

% Apply stall margin only if stall is inside the sweep (not at its edge)
idx = lo:hi;
if lo > 1
    idx = idx(a(idx) >= a(lo) + margin);
end
aB = a(idx);  clB = cl(idx);  cdB = cd(idx);
end