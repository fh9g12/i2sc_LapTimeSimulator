function fig = plotModel(obj)
    % plotModel - the four-panel diagnostic figure (engine curve, gearing,
    % traction model, GGV map). Returns the figure handle; call
    % savefig(fig, path) yourself if you want to keep it.
    set(0,'units','pixels') ;
    SS = get(0,'screensize') ;
    H = 900-90 ;
    W = 900 ;
    Xpos = floor((SS(3)-W)/2) ;
    Ypos = floor((SS(4)-H)/2) ;
    fig = figure('Name','Vehicle Model','Position',[Xpos,Ypos,W,H]) ;
    sgtitle(obj.name)

    rows = 4 ;
    cols = 2 ;

    % engine curves
    subplot(rows,cols,1)
    hold on
    title('Engine Curve')
    xlabel('Engine Speed [rpm]')
    yyaxis left
    plot(obj.en_speed_curve, obj.factor_power*obj.en_torque_curve)
    ylabel('Engine Torque [Nm]')
    grid on
    xlim([obj.en_speed_curve(1), obj.en_speed_curve(end)])
    yyaxis right
    plot(obj.en_speed_curve, obj.factor_power*obj.en_power_curve/745.7)
    ylabel('Engine Power [Hp]')

    % gearing
    subplot(rows,cols,3)
    hold on
    title('Gearing')
    xlabel('Speed [m/s]')
    yyaxis left
    plot(obj.vehicle_speed, obj.engine_speed)
    ylabel('Engine Speed [rpm]')
    grid on
    xlim([obj.vehicle_speed(1), obj.vehicle_speed(end)])
    yyaxis right
    plot(obj.vehicle_speed, obj.gear)
    ylabel('Gear [-]')
    ylim([obj.gear(1)-1, obj.gear(end)+1])

    % traction model
    subplot(rows,cols,[5,7])
    hold on
    title('Traction Model')
    plot(obj.vehicle_speed, obj.factor_power*obj.fx_engine, 'k', 'LineWidth', 4)
    plot(obj.vehicle_speed, min([obj.factor_power*obj.fx_engine'; obj.fx_tyre']), 'r', 'LineWidth', 2)
    plot(obj.vehicle_speed, -obj.fx_aero)
    plot(obj.vehicle_speed, -obj.fx_roll)
    plot(obj.vehicle_speed, obj.fx_tyre)
    for i = 1:obj.nog
        plot(obj.vehicle_speed(2:end), obj.fx(:,i), 'k--')
    end
    grid on
    xlabel('Speed [m/s]')
    ylabel('Force [N]')
    xlim([obj.vehicle_speed(1), obj.vehicle_speed(end)])
    legend({'Engine tractive force','Final tractive force','Aero drag','Rolling resistance','Max tyre tractive force','Engine tractive force per gear'}, 'Location', 'southoutside')

    % ggv map
    subplot(rows,cols,[2,4,6,8])
    hold on
    title('GGV Map')
    surf(obj.GGV(:,:,2), obj.GGV(:,:,1), obj.GGV(:,:,3))
    grid on
    xlabel('Lat acc [$m/s^2$]')
    ylabel('Long acc [$m/s^2$]')
    zlabel('Speed [m/s]')
    view(105,5)
    set(gca,'DataAspectRatio',[1 1 0.8])
end
