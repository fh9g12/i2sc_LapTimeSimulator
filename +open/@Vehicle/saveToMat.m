function saveToMat(obj, filepath)
    % saveToMat - primary serialisation format. Saves this Vehicle object
    % natively (lossless, including the table and 3-D GGV properties)
    % under the variable name "vehicle", so that loadFromMat can find it.
    vehicle = obj ; %#ok<NASGU>
    save(filepath, 'vehicle') ;
end
