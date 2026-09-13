function saveToJSON(obj, filepath)
    % saveToJSON - secondary, human-readable export. sectorTimes is a
    % cell array of (possibly different-length) vectors, which
    % jsonencode/jsondecode cannot round-trip as a cell array directly
    % (uniform-length nested arrays decode back as a plain matrix), so it
    % is flattened into a NaN-padded matrix plus per-row lengths here and
    % rebuilt by fromJSON.
    s = obj.toStruct() ;

    counts = cellfun(@numel, obj.sectorTimes) ;
    maxCount = max([counts(:);0]) ;
    padded = nan(numel(obj.sectorTimes), maxCount) ;
    for i = 1:numel(obj.sectorTimes)
        padded(i,1:counts(i)) = obj.sectorTimes{i}(:)' ;
    end
    s.sectorTimes = struct('data', padded, 'counts', counts) ;

    json = jsonencode(s, 'PrettyPrint', true) ;
    fid = fopen(filepath, 'w') ;
    if fid == -1
        error('open:SeasonResult:saveToJSON', 'Could not open file for writing: %s', filepath) ;
    end
    cleanupObj = onCleanup(@() fclose(fid)) ; %#ok<NASGU>
    fwrite(fid, json, 'char') ;
end
