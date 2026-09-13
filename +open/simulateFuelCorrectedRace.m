function result = simulateFuelCorrectedRace(veh, tr, nLaps, options)
    % simulateFuelCorrectedRace - low-fidelity fuel-mass-corrected race
    % simulation: finds the starting fuel load needed to complete nLaps
    % (plus a reserve) around tr, and how lap time trades off against
    % fuel mass burning off over the race distance.
    %
    % result = open.simulateFuelCorrectedRace(veh, tr, nLaps)
    % result = open.simulateFuelCorrectedRace(veh, tr, nLaps, options)
    %
    %   veh   a Vehicle. By default its M is taken as the car's DRY mass
    %         (no fuel) -- pass options.dryMass_kg explicitly instead if
    %         veh.M already includes a fuel load, rather than silently
    %         double-counting or omitting it.
    %   tr    a Track
    %   nLaps race distance in laps
    %
    % WHY THIS IS "LOW-FIDELITY": rather than re-running the full
    % point-mass solver for every single lap of the race (accurate, but
    % ~nLaps x slower per outer iteration), this samples lap time and
    % fuel burn at only options.nMassSamples mass points spanning the
    % race's fuel range, then linearly interpolates both as a function
    % of instantaneous mass to step through the race lap by lap. This is
    % a reasonable approximation because lap time and fuel burn are both
    % smooth, close-to-linear functions of mass over a single race's
    % fuel range (a few tens of kg against a ~700+ kg car) -- it is NOT
    % appropriate if you push M over a much wider range.
    %
    % CONVERGENCE: starting fuel mass is solved by fixed-point iteration
    % -- simulate the race with the current guess, see how much fuel it
    % actually burned, set the next guess to (fuel burned + reserve),
    % repeat. This converges in only a couple of iterations in practice
    % because the feedback loop is weak: more starting fuel adds mass,
    % which very slightly increases fuel burn per lap (more rolling
    % resistance, slightly more induced drag/accel losses), which very
    % slightly increases the fuel needed to carry it -- there is no
    % strong sensitivity here to fight.
    %
    % options (all optional):
    %   .dryMass_kg         the car's fuel-free mass [kg] (default veh.M
    %                       -- i.e. veh is ASSUMED already dry unless you
    %                       override this). Always printed when verbose,
    %                       so a wrong assumption here is visible rather
    %                       than silently baked into the result.
    %   .fuelReserve_kg     fuel mass left in the tank at the flag, as a
    %                       safety margin (default 1.5)
    %   .initialFuelGuess_kg  first guess for starting fuel [kg]
    %                       (default [] -> auto, from one dry-mass lap)
    %   .nMassSamples       mass points sampled per outer iteration,
    %                       spanning [dryMass+fuelReserve, dryMass+
    %                       currentFuelGuess] (default 5 -- each sample
    %                       costs one full LapSimulation.Run, so this is
    %                       the main speed/fidelity knob)
    %   .maxOuterIter       cap on fixed-point iterations (default 6)
    %   .tol_kg             convergence tolerance on starting fuel mass,
    %                       between successive outer iterations [kg]
    %                       (default 0.05)
    %   .verbose            print per-iteration progress (default true)
    %
    % Returns a struct:
    %   .startingFuel_kg, .totalFuelBurned_kg, .totalTime_s, .converged,
    %   .iterations
    %   .lap            table: lapNumber, fuelRemaining_kg, mass_kg,
    %                   lapTime_s -- for plotting how pace falls off (or
    %                   picks up) as fuel burns off
    %   .massSamples_kg, .lapTimeSamples_s, .fuelBurnSamples_kg
    %                   the final iteration's raw sample points, for
    %                   sanity-checking the interpolation this all rests on
    arguments
        veh (1,1) open.Vehicle
        tr (1,1) open.Track
        nLaps (1,1) double {mustBePositive, mustBeInteger}
        options.dryMass_kg (1,1) double {mustBePositive} = veh.M
        options.fuelReserve_kg (1,1) double {mustBeNonnegative} = 1.5
        options.initialFuelGuess_kg double {mustBeNonnegative} = [] % [] => auto
        options.nMassSamples (1,1) double {mustBeInteger, mustBeGreaterThanOrEqual(options.nMassSamples,2)} = 5
        options.maxOuterIter (1,1) double {mustBePositive, mustBeInteger} = 6
        options.tol_kg (1,1) double {mustBePositive} = 0.05
        options.verbose (1,1) logical = true
    end

    dryMass = options.dryMass_kg ;
    if options.verbose
        fprintf('simulateFuelCorrectedRace: assuming dry mass %.2f kg%s\n', dryMass, ...
            repmat(' (from veh.M -- pass options.dryMass_kg explicitly if veh.M already includes fuel)', 1, dryMass==veh.M)) ;
    end
    vehDry = veh.withMass(dryMass) ;

    if isempty(options.initialFuelGuess_kg)
        % Auto first guess: one lap at dry mass gives a rough burn rate;
        % assume every lap costs roughly that much fuel, plus margin,
        % as a starting point for the fixed-point iteration below.
        simDry = open.LapSimulation.Run(vehDry, tr) ;
        fuelGuess = simDry.fuel_cons_total.data*nLaps*1.05 + options.fuelReserve_kg ;
    else
        fuelGuess = options.initialFuelGuess_kg ;
    end

    converged = false ;
    for iter = 1:options.maxOuterIter
        massGrid = linspace(dryMass+options.fuelReserve_kg, dryMass+fuelGuess, options.nMassSamples) ;
        lapTimeSamples = zeros(size(massGrid)) ;
        fuelBurnSamples = zeros(size(massGrid)) ;
        for k = 1:numel(massGrid)
            vehK = vehDry.withMass(massGrid(k)) ;
            simK = open.LapSimulation.Run(vehK, tr) ;
            lapTimeSamples(k) = simK.laptime.data ;
            fuelBurnSamples(k) = simK.fuel_cons_total.data ;
        end

        % Step through the race lap by lap, reading lap time/fuel burn
        % for the CURRENT instantaneous mass off the interpolants above.
        fuelRemaining = zeros(nLaps,1) ;
        massPerLap = zeros(nLaps,1) ;
        lapTime = zeros(nLaps,1) ;
        fuel = fuelGuess ;
        for lapNum = 1:nLaps
            m = dryMass+fuel ;
            lapTime(lapNum) = interp1(massGrid, lapTimeSamples, m, 'linear', 'extrap') ;
            burn = interp1(massGrid, fuelBurnSamples, m, 'linear', 'extrap') ;
            fuelRemaining(lapNum) = fuel ;
            massPerLap(lapNum) = m ;
            fuel = fuel-burn ;
        end
        totalFuelBurned = fuelGuess-fuel ;
        fuelGuessNext = totalFuelBurned+options.fuelReserve_kg ;

        if options.verbose
            fprintf('simulateFuelCorrectedRace: iter %d -- starting fuel %.2f kg -> burned %.2f kg over %d laps (next guess %.2f kg)\n', ...
                iter, fuelGuess, totalFuelBurned, nLaps, fuelGuessNext) ;
        end

        if abs(fuelGuessNext-fuelGuess) < options.tol_kg
            % Leave fuelGuess as the value the lap-by-lap breakdown above
            % was actually computed with (fuelGuessNext is only within
            % tol_kg of it by definition here), so result.startingFuel_kg
            % below matches result.lap.fuelRemaining_kg(1) exactly.
            converged = true ;
            break
        end
        fuelGuess = fuelGuessNext ;
    end

    if ~converged
        warning('open:simulateFuelCorrectedRace:notConverged', ...
            'Starting fuel mass did not converge to within %.2f kg after %d iterations (last change: %.2f kg) -- treat the result as indicative only.', ...
            options.tol_kg, options.maxOuterIter, abs(fuelGuessNext-fuelGuess)) ;
    end

    result.startingFuel_kg = fuelGuess ;
    result.totalFuelBurned_kg = totalFuelBurned ;
    result.totalTime_s = sum(lapTime) ;
    result.converged = converged ;
    result.iterations = iter ;
    result.lap = table((1:nLaps)', fuelRemaining, massPerLap, lapTime, ...
        'VariableNames', {'lapNumber','fuelRemaining_kg','mass_kg','lapTime_s'}) ;
    result.massSamples_kg = massGrid ;
    result.lapTimeSamples_s = lapTimeSamples ;
    result.fuelBurnSamples_kg = fuelBurnSamples ;

    if options.verbose
        fprintf(['simulateFuelCorrectedRace: %s at %s -- %d laps, starting fuel %.2f kg, ' ...
                 'total time %.1f s (%s), pace change lap 1 -> lap %d: %+.3f s\n'], ...
            char(veh.name), tr.info.name, nLaps, result.startingFuel_kg, result.totalTime_s, ...
            duration(0,0,result.totalTime_s), nLaps, lapTime(end)-lapTime(1)) ;
    end
end
