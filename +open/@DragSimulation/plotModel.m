function fig = plotModel(obj)
    % plotModel - the seven-row diagnostic figure (distance, speed,
    % acceleration, engine speed, gear, throttle, brake pressure), each
    % against both time and distance. Returns the figure handle; call
    % savefig(fig, path) yourself if you want to keep it.
    set(0,'units','pixels') ;
    SS = get(0,'screensize') ;
    H = 900-90 ;
    W = 900 ;
    Xpos = floor((SS(3)-W)/2) ;
    Ypos = floor((SS(4)-H)/2) ;
    fig = figure('Name','OpenDRAG Simulation Results','Position',[Xpos,Ypos,W,H]) ;
    figtitle = ["OpenDRAG","Vehicle: "+obj.vehicleName,"Date & Time: "+datestr(now,'yyyy/mm/dd')+" "+datestr(now,'HH:MM:SS')] ;
    sgtitle(figtitle)

    row = 7 ;
    col = 2 ;
    i = 0 ;

    % distance
    i = i+1 ;
    subplot(row,col,i)
    hold on
    grid on
    xlabel('Time [s]')
    ylabel('Distance [m]')
    plot(obj.T,obj.X)
    i = i+1 ;

    % speed
    i = i+1 ;
    subplot(row,col,i)
    hold on
    grid on
    title('Speed')
    xlabel('Time [s]')
    ylabel('Speed [km/h]')
    plot(obj.T,obj.V*3.6)
    i = i+1 ;
    subplot(row,col,i)
    hold on
    grid on
    title('Speed')
    xlabel('Distance [m]')
    ylabel('Speed [km/h]')
    plot(obj.X,obj.V*3.6)

    % acceleration
    i = i+1 ;
    subplot(row,col,i)
    hold on
    grid on
    title('Acceleration')
    xlabel('Time [s]')
    ylabel('Acceleration [m/s2]')
    plot(obj.T,obj.A)
    i = i+1 ;
    subplot(row,col,i)
    hold on
    grid on
    title('Acceleration')
    xlabel('Distance [m]')
    ylabel('Acceleration [m/s2]')
    plot(obj.X,obj.A)

    % engine speed
    i = i+1 ;
    subplot(row,col,i)
    hold on
    grid on
    title('Engine Speed')
    xlabel('Time [s]')
    ylabel('Engine Speed [rpm]')
    plot(obj.T,obj.RPM)
    i = i+1 ;
    subplot(row,col,i)
    hold on
    grid on
    title('Engine Speed')
    xlabel('Distance [m]')
    ylabel('Engine Speed [rpm]')
    plot(obj.X,obj.RPM)

    % gear
    i = i+1 ;
    subplot(row,col,i)
    hold on
    grid on
    title('Selecetd Gear')
    xlabel('Time [s]')
    ylabel('Gear [-]')
    plot(obj.T,obj.GEAR)
    i = i+1 ;
    subplot(row,col,i)
    hold on
    grid on
    title('Selecetd Gear')
    xlabel('Distance [m]')
    ylabel('Gear [-]')
    plot(obj.X,obj.GEAR)

    % throttle
    i = i+1 ;
    subplot(row,col,i)
    hold on
    grid on
    title('Throttle Position')
    xlabel('Time [s]')
    ylabel('tps [%]')
    plot(obj.T,obj.TPS*100)
    i = i+1 ;
    subplot(row,col,i)
    hold on
    grid on
    title('Throttle Position')
    xlabel('Distance [m]')
    ylabel('tps [%]')
    plot(obj.X,obj.TPS*100)

    % brake
    i = i+1 ;
    subplot(row,col,i)
    hold on
    grid on
    title('Brake Pressure')
    xlabel('Time [s]')
    ylabel('bps [bar]')
    plot(obj.T,obj.BPS/10^5)
    i = i+1 ;
    subplot(row,col,i)
    hold on
    grid on
    title('Brake Pressure')
    xlabel('Distance [m]')
    ylabel('bps [bar]')
    plot(obj.X,obj.BPS/10^5)
end
