function exportCSV(obj, veh, tr, filepath, freq)
    % exportCSV - resamples every vector channel onto an evenly spaced
    % time base at the given frequency and writes it out in the MoTeC-
    % style channel/unit/data layout OpenLAP has always produced.
    arguments
        obj (1,1) open.LapSimulation
        veh (1,1) open.Vehicle
        tr (1,1) open.Track
        filepath
        freq (1,1) double = 50
    end

    freq = round(freq) ;
    % channel names
    all_names = properties(obj) ;
    % number of channels to export
    S = 0 ;
    % channel id vector
    I = (1:length(all_names))' ;
    % getting only vector channels (excluding matrices)
    for i=1:length(all_names)
        s = size(obj.(all_names{i}).data) ;
        if length(s)==2 && s(1)==tr.n && s(2)==1 % is vector
            S = S+1 ;
        else % is not vector
            I(i) = 0 ;
        end
    end
    I(I==0) = [] ;
    channel_names = all_names(I)' ;
    % memory preallocation
    data = single(zeros(tr.n,S)) ;
    channel_units = cell(1,length(I)) ;
    for i=1:length(I)
        data(:,i) = obj.(all_names{I(i)}).data ;
        channel_units(i) = {obj.(all_names{I(i)}).unit} ;
    end
    % new time vector for specified frequency
    t = (0:1/freq:obj.laptime.data)' ;
    j = strcmp(string(channel_names),"time") ;
    time_data = single(zeros(length(t),length(I))) ;
    for i=1:length(I)
        if i==j % time channel
            time_data(:,i) = t ;
        else % all other channels
            if strcmp(string(channel_names(i)),"gear") % gear needs to be integer
                time_data(:,i) = interp1(data(:,j),data(:,i),t,'nearest','extrap') ;
            else % all other channels are linearly interpolated
                time_data(:,i) = interp1(data(:,j),data(:,i),t,'linear','extrap') ;
            end
        end
    end

    disp('Export initialised.')
    fid = fopen(filepath, 'w') ;
    if fid == -1
        error('open:LapSimulation:exportCSV', 'Could not open file for writing: %s', filepath) ;
    end
    fprintf(fid,'%s,%s\n',["Format","OpenLAP Export"]) ;
    fprintf(fid,'%s,%s\n',["Venue",tr.info.name]) ;
    fprintf(fid,'%s,%s\n',["Vehicle",veh.name]) ;
    fprintf(fid,'%s,%s\n',["Driver",'OpenLap']) ;
    fprintf(fid,'%s\n',"Device") ;
    fprintf(fid,'%s\n',"Comment") ;
    fprintf(fid,'%s,%s\n',["Date",datestr(now,'dd/mm/yyyy')]) ;
    fprintf(fid,'%s,%s\n',["Time",datestr(now,'HH:MM:SS')]) ;
    fprintf(fid,'%s,%s\n',["Frequency",num2str(freq,'%d')]) ;
    fprintf(fid,'\n') ;
    fprintf(fid,'\n') ;
    fprintf(fid,'\n') ;
    fprintf(fid,'\n') ;
    fprintf(fid,'\n') ;
    form = [repmat('%s,',1,length(I)-1),'%s\n'] ;
    fprintf(fid,form,channel_names{:}) ;
    fprintf(fid,form,channel_names{:}) ;
    fprintf(fid,form,channel_units{:}) ;
    fprintf(fid,'\n') ;
    fprintf(fid,'\n') ;
    form = [repmat('%f,',1,length(I)-1),'%f\n'] ;
    for i=1:length(t)
        fprintf(fid,form,time_data(i,:)) ;
    end
    fclose(fid) ;
    disp('Exported .csv file successfully.')
end
