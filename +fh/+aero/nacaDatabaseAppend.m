setpref('xfoil','graphics',false)
warning('off','naca4Aero:noConverge')
warning('off','xfoil:noConverge')
%% ===== Append positive-alpha sweep to existing sectional database =====
% Loads +fh\bin\naca_db.mat (built by fh.aero.nacaDatabase), runs each section
% at alphas 0:0.25:5, merges the results into D.a / D.cl / D.cd and re-saves.
% The downforce branch (aB, clB, cdB, clcd, *Opt) is left untouched, as it is
% only defined for alpha <= 0.
clear all
file   = '+fh\bin\naca_db.mat';
alphaP = 0:0.25:5;

S  = load(file, 'db');
db = S.db;

nSec = numel(db);
parfor k = 1:nSec
    tic;
    D = db(k);
    util.Log.debug(sprintf('Run %.0f of %.0f (%s)', k, nSec, D.sec))

    % Skip alphas already in the database (e.g. alpha = 0 from the original sweep)
    aNew = alphaP(~ismembertol(alphaP, D.a, 1e-6, 'DataScale', 1));
    clN  = nan(size(aNew));  cdN = clN;
    for i = 1:numel(aNew)
        try, [clN(i), cdN(i)] = api.naca4Aero(D.sec, aNew(i)); end %#ok<TRYNC>
    end

    [a, s] = sort([D.a, aNew]);
    cl = [D.cl, clN];  cl = cl(s);
    cd = [D.cd, cdN];  cd = cd(s);
    D.a = a;  D.cl = cl;  D.cd = cd;

    db(k) = D;
    util.Log.debug(sprintf('Run %.0f (%s) - Complete in %.2f s', k, D.sec, toc))
end
save(file, 'db')
