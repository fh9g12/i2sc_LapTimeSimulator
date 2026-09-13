function obj = loadFromMat(filepath)
    % SeasonResult.loadFromMat - load a SeasonResult previously saved
    % with saveToMat.
    data = load(filepath, 'seasonResult') ;
    obj = data.seasonResult ;
end
