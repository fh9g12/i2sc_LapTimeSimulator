function saveToMat(obj, filepath)
    % saveToMat - primary serialisation format. Saves this DragSimulation
    % object natively under the variable name "dragSimulation", so that
    % loadFromMat can find it.
    dragSimulation = obj ; %#ok<NASGU>
    save(filepath, 'dragSimulation') ;
end
