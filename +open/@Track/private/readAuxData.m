function data = readAuxData(workbookFile, sheetName, startRow, endRow)
    % Reads a two-column "Point, Data" sheet (Elevation, Banking, Grip
    % Factors or Sectors) of a shape-data track Excel file.
    if nargin == 1 || isempty(sheetName)
        sheetName = 1 ;
    end
    if nargin <= 3
        startRow = 2 ;
        endRow = 10000 ;
    end
    opts = spreadsheetImportOptions("NumVariables", 2) ;
    opts.Sheet = sheetName ;
    opts.DataRange = "A" + startRow(1) + ":B" + endRow(1) ;
    opts.VariableNames = ["Point", "Data"] ;
    opts.VariableTypes = ["double", "double"] ;
    opts.MissingRule = "omitrow" ;
    opts = setvaropts(opts, [1, 2], "TreatAsMissing", '') ;
    data = readtable(workbookFile, opts, "UseExcel", false) ;
    for idx = 2:length(startRow)
        opts.DataRange = "A" + startRow(idx) + ":B" + endRow(idx) ;
        tb = readtable(workbookFile, opts, "UseExcel", false) ;
        data = [data; tb] ; %#ok<AGROW>
    end
end
