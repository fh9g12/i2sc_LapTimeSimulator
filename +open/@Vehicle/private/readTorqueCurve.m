function data = readTorqueCurve(workbookFile, sheetName, startRow, endRow)
    % Reads the two-column "Engine_Speed_rpm, Torque_Nm" sheet of a
    % vehicle Excel file into a table.
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
    opts.VariableNames = ["Engine_Speed_rpm", "Torque_Nm"] ;
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
