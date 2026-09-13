function obj = FromShapeFile(filename, options)
    % Track.FromShapeFile - build a Track from an "OpenTRACK Shape
    % tmp.xlsx"-format Excel file (Info/Shape/Elevation/Banking/Grip
    % Factors/Sectors sheets).
    %
    % Name-value options:
    %   MeshSize (default 1)    - fine mesh spacing [m]
    %   Rotation (default 0)    - track map rotation [deg]
    %   Kappa    (default 1000) - long corner point-injection angle [deg]
    arguments
        filename
        options.MeshSize (1,1) double = 1
        options.Rotation (1,1) double = 0
        options.Kappa (1,1) double = 1000
    end

    info = readInfo(filename, 'Info') ;
    table_shape = readShapeData(filename, 'Shape') ;
    table_el = readAuxData(filename, 'Elevation') ;
    table_bk = readAuxData(filename, 'Banking') ;
    table_gf = readAuxData(filename, 'Grip Factors') ;
    table_sc = readAuxData(filename, 'Sectors') ;

    printBanner(filename, 'File read successfully') ;

    coarse = preprocessShapeData(info, table_shape, table_el, table_bk, table_gf, table_sc, options.Kappa) ;

    obj = buildFromCoarseData(info, coarse, options.MeshSize, options.Rotation) ;
end
