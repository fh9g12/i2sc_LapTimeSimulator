function s = toStruct(obj)
    % toStruct - dump all properties into a plain scalar struct.
    props = properties(obj) ;
    s = struct() ;
    for k = 1:numel(props)
        s.(props{k}) = obj.(props{k}) ;
    end
end
