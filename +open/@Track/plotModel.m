function fig = plotModel(obj)
    % plotModel - the five-panel diagnostic figure (3D map, curvature,
    % elevation, inclination, banking, grip factor). Returns the figure
    % handle; call savefig(fig, path) yourself if you want to keep it.
    set(0,'units','pixels') ;
    SS = get(0,'screensize') ;
    H = 900-90 ;
    W = 900 ;
    Xpos = floor((SS(3)-W)/2) ;
    Ypos = floor((SS(4)-H)/2) ;
    fig = figure('Name',char(obj.info.name),'Position',[Xpos,Ypos,W,H]) ;
    figtitle = ["OpenTRACK","Track Name: "+obj.info.name,"Configuration: "+obj.info.config,"Mirror: "+obj.info.mirror,"Date \& Time: "+datestr(now,'yyyy/mm/dd')+" "+datestr(now,'HH:MM:SS')] ;
    figtitle = strrep(figtitle,"_"," ") ;
    sgtitle(figtitle)

    rows = 5 ;
    cols = 2 ;

    % 3d map
    subplot(rows,cols,[1,3,5,7,9])
    title('3D Map')
    hold on
    grid on
    axis equal
    axis tight
    xlabel('x [m]')
    ylabel('y [m]')
    scatter3(obj.X, obj.Y, obj.Z, 20, obj.sector, '.')
    plot3(obj.arrow(:,1), obj.arrow(:,2), obj.arrow(:,3), 'k', 'LineWidth', 2)

    % curvature
    subplot(rows,cols,2)
    title('Curvature')
    hold on
    grid on
    xlabel('position [m]')
    ylabel('curvature [$m^-1$]')
    plot(obj.x, obj.r)
    scatter(obj.x(obj.apex), obj.r_apex, '.')
    xlim([obj.x(1), obj.x(end)])
    legend({'curvature','apex'})

    % elevation
    subplot(rows,cols,4)
    title('Elevation')
    hold on
    grid on
    xlabel('position [m]')
    ylabel('elevation [m]')
    plot(obj.x, obj.Z)
    xlim([obj.x(1), obj.x(end)])

    % inclination
    subplot(rows,cols,6)
    title('Inclination')
    hold on
    grid on
    xlabel('position [m]')
    ylabel('inclination [deg]')
    plot(obj.x, obj.incl)
    xlim([obj.x(1), obj.x(end)])

    % banking
    subplot(rows,cols,8)
    title('Banking')
    hold on
    grid on
    xlabel('position [m]')
    ylabel('banking [deg]')
    plot(obj.x, obj.bank)
    xlim([obj.x(1), obj.x(end)])

    % grip factors
    subplot(rows,cols,10)
    title('Grip Factor')
    hold on
    grid on
    xlabel('position [m]')
    ylabel('grip factor [-]')
    plot(obj.x, obj.factor_grip)
    xlim([obj.x(1), obj.x(end)])
end
