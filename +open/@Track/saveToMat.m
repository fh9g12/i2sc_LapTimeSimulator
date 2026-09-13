function saveToMat(obj, filepath)
    % saveToMat - primary serialisation format. Saves this Track object
    % natively under the variable name "track", so that loadFromMat can
    % find it.
    track = obj ; %#ok<NASGU>
    save(filepath, 'track') ;
end
