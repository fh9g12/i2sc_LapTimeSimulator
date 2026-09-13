function info = readInfo(workbookFile, sheetName, startRow, endRow)
    % Reads the "Info" sheet of a shape-data track Excel file into a
    % struct with name/country/city/type/config/direction/mirror.
    if nargin == 1 || isempty(sheetName)
        sheetName = 1 ;
    end
    if nargin <= 3
        startRow = 1 ;
        endRow = 7 ;
    end
    opts = spreadsheetImportOptions("NumVariables", 2) ;
    opts.Sheet = sheetName ;
    opts.DataRange = "A" + startRow(1) + ":B" + endRow(1) ;
    opts.VariableNames = ["info", "data"] ;
    opts.VariableTypes = ["string", "string"] ;
    opts = setvaropts(opts, [1, 2], "WhitespaceRule", "preserve") ;
    opts = setvaropts(opts, [1, 2], "EmptyFieldRule", "auto") ;
    tbl = readtable(workbookFile, opts, "UseExcel", false) ;
    for idx = 2:length(startRow)
        opts.DataRange = "A" + startRow(idx) + ":B" + endRow(idx) ;
        tb = readtable(workbookFile, opts, "UseExcel", false) ;
        tbl = [tbl; tb] ; %#ok<AGROW>
    end
    data = tbl.data ;
    info.name = data(1) ;
    info.country = data(2) ;
    info.city = data(3) ;
    info.type = data(4) ;
    info.config = data(5) ;
    info.direction = data(6) ;
    info.mirror = data(7) ;
end
