function [header, data] = readLoggedData(filename, header_startRow, header_endRow, data_startRow, data_endRow)
    % Reads an "OpenTRACK Logged Data tmp.csv"-format telemetry file into
    % a header cell array and a numeric data matrix.
    delimiter = ',' ;
    if nargin <= 2
        header_startRow = 1 ;
        header_endRow = 12 ;
        data_startRow = 14 ;
        data_endRow = inf ;
    end

    fileID = fopen(filename, 'r') ;

    header_formatSpec = '%s%s%s%s%s%s%s%s%s%s%s%[^\n\r]' ;
    headerArray = textscan(fileID, header_formatSpec, header_endRow(1)-header_startRow(1)+1, 'Delimiter', delimiter, 'TextType', 'string', 'HeaderLines', header_startRow(1)-1, 'ReturnOnError', false, 'EndOfLine', '\r\n') ;
    for block = 2:length(header_startRow)
        frewind(fileID) ;
        dataArrayBlock = textscan(fileID, header_formatSpec, header_endRow(block)-header_startRow(block)+1, 'Delimiter', delimiter, 'TextType', 'string', 'HeaderLines', header_startRow(block)-1, 'ReturnOnError', false, 'EndOfLine', '\r\n') ;
        for col = 1:length(headerArray)
            headerArray{col} = [headerArray{col};dataArrayBlock{col}] ;
        end
    end
    header = [headerArray{1:end-1}] ;

    fseek(fileID, 0, 'bof') ;
    data_formatSpec = '%f%f%f%f%f%f%f%f%f%f%f%[^\n\r]' ;
    dataArray = textscan(fileID, data_formatSpec, data_endRow(1)-data_startRow(1)+1, 'Delimiter', delimiter, 'TextType', 'string', 'HeaderLines', data_startRow(1)-1, 'ReturnOnError', false, 'EndOfLine', '\r\n') ;
    for block = 2:length(data_startRow)
        frewind(fileID) ;
        dataArrayBlock = textscan(fileID, data_formatSpec, data_endRow(block)-data_startRow(block)+1, 'Delimiter', delimiter, 'TextType', 'string', 'HeaderLines', data_startRow(block)-1, 'ReturnOnError', false, 'EndOfLine', '\r\n') ;
        for col = 1:length(dataArray)
            dataArray{col} = [dataArray{col};dataArrayBlock{col}] ;
        end
    end
    data = [dataArray{1:end-1}] ;

    fclose(fileID) ;
end
