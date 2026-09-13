function saveToMat(obj, filepath)
    % saveToMat - primary serialisation format. Saves this LapSimulation
    % object natively under the variable name "lapSimulation", so that
    % loadFromMat can find it.
    lapSimulation = obj ; %#ok<NASGU>
    save(filepath, 'lapSimulation') ;
end
