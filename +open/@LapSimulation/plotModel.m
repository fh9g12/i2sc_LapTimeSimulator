function fig = plotModel(obj, veh, tr)
    % plotModel - the seven-row diagnostic figure (speed, elevation &
    % curvature, accelerations, drive inputs, steering inputs, GGV
    % circle, track map). Needs the Vehicle and Track used to produce
    % this result, for the GGV envelope and track geometry. Returns the
    % figure handle; call savefig(fig, path) yourself if you want to
    % keep it.
    warning('off','MATLAB:handle_graphics:exceptions:SceneNode')
    set(0,'units','pixels') ;
    SS = get(0,'screensize') ;
    H = 900-90 ;
    W = 900 ;
    Xpos = floor((SS(3)-W)/2) ;
    Ypos = floor((SS(4)-H)/2) ;
    fig = figure('Name','OpenLAP Simulation Results','Position',[Xpos,Ypos,W,H]) ;
    figname = ["OpenLAP: "+char(veh.name)+" @ "+tr.info.name,"Date & Time: "+datestr(now,'yyyy/mm/dd')+" "+datestr(now,'HH:MM:SS')] ;
    sgtitle(figname)

    rows = 7 ;
    cols = 2 ;
    xlimit = [tr.x(1),tr.x(end)] ;
    loc = 'east' ;

    % speed
    subplot(rows,cols,[1,2])
    hold on
    plot(tr.x,obj.speed.data*3.6)
    legend({'Speed'},'Location',loc)
    xlabel('Distance [m]')
    xlim(xlimit)
    ylabel('Speed [m/s]')
    ylabel('Speed [km/h]')
    grid on

    % elevation and curvature
    subplot(rows,cols,[3,4])
    yyaxis left
    plot(tr.x,tr.Z)
    xlabel('Distance [m]')
    xlim(xlimit)
    ylabel('Elevation [m]')
    grid on
    yyaxis right
    plot(tr.x,tr.r)
    legend({'Elevation','Curvature'},'Location',loc)
    ylabel('Curvature [$m^-1$]')

    % accelerations
    subplot(rows,cols,[5,6])
    hold on
    plot(tr.x,obj.long_acc.data)
    plot(tr.x,obj.lat_acc.data)
    plot(tr.x,obj.sum_acc.data,'k:')
    legend({'LonAcc','LatAcc','GSum'},'Location',loc)
    xlabel('Distance [m]')
    xlim(xlimit)
    ylabel('Acceleration [$m/s^2$]')
    grid on

    % drive inputs
    subplot(rows,cols,[7,8])
    hold on
    plot(tr.x,obj.throttle.data*100)
    plot(tr.x,obj.brake_pres.data/10^5)
    legend({'tps','bps'},'Location',loc)
    xlabel('Distance [m]')
    xlim(xlimit)
    ylabel('input [%]')
    grid on
    ylim([-10,110])

    % steering inputs
    subplot(rows,cols,[9,10])
    hold on
    plot(tr.x,obj.steering.data)
    plot(tr.x,obj.delta.data)
    plot(tr.x,obj.beta.data)
    legend({'Steering wheel','Steering \delta','Vehicle slip angle \beta'},'Location',loc)
    xlabel('Distance [m]')
    xlim(xlimit)
    ylabel('angle [deg]')
    grid on

    % ggv circle
    subplot(rows,cols,[11,13])
    hold on
    scatter3(obj.lat_acc.data,obj.long_acc.data,obj.speed.data*3.6,50,'ro','filled','MarkerEdgeColor',[0,0,0])
    surf(veh.GGV(:,:,2),veh.GGV(:,:,1),veh.GGV(:,:,3)*3.6,'EdgeAlpha',0.3,'FaceAlpha',0.8)
    legend('OpenLAP','GGV','Location','northeast')
    xlabel('LatAcc [$m/s^2$]')
    ylabel('LonAcc [$m/s^2$]')
    zlabel('Speed [km/h]')
    grid on
    set(gca,'DataAspectRatio',[1 1 3])
    axis tight

    % track map
    subplot(rows,cols,[12,14])
    hold on
    scatter(tr.X,tr.Y,5,obj.speed.data*3.6)
    plot(tr.arrow(:,1),tr.arrow(:,2),'k','LineWidth',2)
    legend('Track Map','Location','northeast')
    xlabel('X [m]')
    ylabel('Y [m]')
    colorbar
    grid on
    axis equal
end
