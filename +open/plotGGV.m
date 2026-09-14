function [fig,surfHandle] = plotGGV(veh,options)
% plotGGV - plot a Vehicle's GGV map (its maximum lateral/longitudinal
% acceleration at every speed -- see Vehicle.GGV) as a 3-D surface.
%
% fig = open.plotGGV(veh)
% [fig,surfHandle] = open.plotGGV(veh,'FaceColor','r','DisplayName','Team A')
%
% Draws the same surface as the GGV panel in Vehicle.plotModel, but as
% its own standalone plot, TRIMMED to the vehicle's actual top speed (see
% options.TrimToTopSpeed below -- this is the one difference from
% Vehicle.plotModel's own GGV panel). Pass options.ax to plot onto an
% existing axes instead of a new figure -- this is how api.compareGGV
% overlays two vehicles' GGV maps on one set of axes.
%
% options:
%   .ax           axes to plot into (default: creates a new figure/axes)
%   .FaceColor    surface colour (default: MATLAB's next colour-order entry)
%   .FaceAlpha    surface transparency, 0 (invisible) to 1 (opaque), default 1
%   .DisplayName  legend entry for this surface (default veh.name)
%   .TrimToTopSpeed  default true. veh.GGV's speed axis runs up to
%                Vehicle.v_max, a purely MECHANICAL ceiling set by top
%                gear ratio and engine redline -- independent of Cd, so
%                two cars with the same gearing but different drag get
%                GGV tables spanning the identical speed range, with the
%                higher-drag car's longitudinal acceleration simply
%                going negative before reaching the top of it. Left
%                untrimmed, that makes two different-drag cars look like
%                they reach the same top speed. This option instead cuts
%                each surface off at open.topSpeed(veh) (the speed where
%                straight-line acceleration actually reaches zero), so a
%                lower-drag car's surface visibly reaches higher than a
%                higher-drag one's, as it should. Set false to see the
%                full untrimmed table instead (e.g. to match
%                Vehicle.plotModel's own GGV panel exactly).
    arguments
        veh (1,1) open.Vehicle
        options.ax = []
        options.FaceColor = []
        options.FaceAlpha (1,1) double {mustBeInRange(options.FaceAlpha,0,1)} = 1
        options.DisplayName (1,1) string = string(veh.name)
        options.TrimToTopSpeed (1,1) logical = true
    end

    if isempty(options.ax)
        fig = figure('Name','GGV Map') ;
        ax = axes(fig) ; %#ok<LAXES>
        hold(ax,'on') ;
        title(ax,'GGV Map')
        grid(ax,'on')
        view(ax,105,5)
        set(ax,'DataAspectRatio',[1 1 0.8])
    else
        ax = options.ax ;
        fig = ancestor(ax,'figure') ;
    end
    xlabel(ax,'Lat acc [m/s^2]','Interpreter','none')
    ylabel(ax,'Long acc [m/s^2]','Interpreter','none')
    zlabel(ax,'Speed [m/s]','Interpreter','none')

    GGV = veh.GGV ;
    if options.TrimToTopSpeed
        rows = GGV(:,1,3) <= open.topSpeed(veh) ;
        rows(find(rows,1,'last')+1) = true ; % keep one extra row so the cut edge isn't jagged
        rows = rows(1:size(GGV,1)) ;
        GGV = GGV(rows,:,:) ;
    end

    surfArgs = {'EdgeColor','none','FaceAlpha',options.FaceAlpha,'DisplayName',options.DisplayName} ;
    if ~isempty(options.FaceColor)
        surfArgs = [surfArgs, {'FaceColor',options.FaceColor}] ;
    end
    surfHandle = surf(ax, GGV(:,:,2), GGV(:,:,1), GGV(:,:,3), surfArgs{:}) ;
end
