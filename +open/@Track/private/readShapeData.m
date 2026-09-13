function tbl = readShapeData(workbookFile, sheetName, startRow, endRow)
    % Reads the "Shape" sheet (Type, SectionLength, CornerRadius) of a
    % shape-data track Excel file.
    if nargin == 1 || isempty(sheetName)
        sheetName = 1 ;
    end
    if nargin <= 3
        startRow = 2 ;
        endRow = 10000 ;
    end
    opts = spreadsheetImportOptions("NumVariables", 3) ;
    opts.Sheet = sheetName ;
    opts.DataRange = "A" + startRow(1) + ":C" + endRow(1) ;
    opts.VariableNames = ["Type", "SectionLength", "CornerRadius"] ;
    opts.VariableTypes = ["categorical", "double", "double"] ;
    opts = setvaropts(opts, 1, "EmptyFieldRule", "auto") ;
    opts.MissingRule = "omitrow" ;
    opts = setvaropts(opts, [2, 3], "TreatAsMissing", '') ;
    tbl = readtable(workbookFile, opts, "UseExcel", false) ;
    for idx = 2:length(startRow)
        opts.DataRange = "A" + startRow(idx) + ":C" + endRow(idx) ;
        tb = readtable(workbookFile, opts, "UseExcel", false) ;
        tbl = [tbl; tb] ; %#ok<AGROW>
    end
end
