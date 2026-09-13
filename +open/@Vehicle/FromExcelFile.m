function obj = FromExcelFile(filename)
    % Vehicle.FromExcelFile - build a Vehicle from an OpenVEHICLE-format
    % Excel file (an "Info" sheet plus a "Torque Curve" sheet).

    info = readInfo(filename, 'Info') ;
    torqueCurveTable = readTorqueCurve(filename, 'Torque Curve') ;

    printBanner(filename, 'File read successfully') ;

    raw = extractInfoFields(info) ;
    brake = computeBrakeModel(raw) ;
    steering = computeSteeringModel(raw) ;
    driveline = computeDrivelineModel(raw, torqueCurveTable) ;
    shifting = computeShiftPoints(driveline, raw.nog) ;
    force = computeForceModel(raw, driveline) ;
    GGV = computeGGVMap(raw, driveline, force) ;

    params = mergeStruct(raw, brake) ;
    params = mergeStruct(params, steering) ;
    params = mergeStruct(params, driveline) ;
    params.shifting = shifting ;
    params = mergeStruct(params, force) ;
    params.GGV = GGV ;

    obj = open.Vehicle(params) ;

    disp("Name: "+obj.name)
    disp("Type: "+obj.type)
    disp("Date: "+datestr(now,'dd/mm/yyyy'))
    disp("Time: "+datestr(now,'HH:MM:SS'))
    disp('====================================================================================')
end

function out = mergeStruct(a, b)
    out = a ;
    f = fieldnames(b) ;
    for k = 1:numel(f)
        out.(f{k}) = b.(f{k}) ;
    end
end
