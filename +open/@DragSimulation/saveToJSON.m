function saveToJSON(obj, filepath)
    % saveToJSON - secondary, human-readable export. None of
    % DragSimulation's properties are tables or N-D arrays, so a plain
    % struct dump round-trips through jsonencode/jsondecode directly.
    s = obj.toStruct() ;
    json = jsonencode(s, 'PrettyPrint', true) ;
    fid = fopen(filepath, 'w') ;
    if fid == -1
        error('open:DragSimulation:saveToJSON', 'Could not open file for writing: %s', filepath) ;
    end
    cleanupObj = onCleanup(@() fclose(fid)) ; %#ok<NASGU>
    fwrite(fid, json, 'char') ;
end
