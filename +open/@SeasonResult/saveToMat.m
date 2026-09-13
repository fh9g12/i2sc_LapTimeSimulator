function saveToMat(obj, filepath)
    % saveToMat - primary serialisation format. Saves this SeasonResult
    % object natively under the variable name "seasonResult", so that
    % loadFromMat can find it.
    seasonResult = obj ; %#ok<NASGU>
    save(filepath, 'seasonResult') ;
end
