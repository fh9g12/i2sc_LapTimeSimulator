function printAsciiMap(obj)
    % printAsciiMap - prints a crude ASCII-art rendering of the track map
    % to the console.
    charh = 15 ; % font height [pixels]
    charw = 8 ; % font width [pixels]
    linew = 66 ; % line character width
    X = obj.X ;
    Y = obj.Y ;
    mapw = max(X)-min(X) ; % map width
    YY = round(Y/(charh/charw)/mapw*linew) ; % scales y values
    XX = round(X/mapw*linew) ; % scales x values
    YY = -YY-min(-YY) ; % flipping y and shifting to positive space
    XX = XX-min(XX) ; % shifting x to positive space
    p = unique([XX,YY],'rows') ; % getting unique points
    XX = p(:,1)+1 ; % saving x
    YY = p(:,2)+1 ; % saving y
    maph = max(YY) ; % getting new map height [lines]
    mapw = max(XX) ; % getting new map width [columns]
    map = char(maph,mapw) ; % character map preallocation
    for i = 1:maph
        for j = 1:mapw
            check = [XX,YY]==[j,i] ; % checking if pixel is on
            check = check(:,1).*check(:,2) ; % combining truth table
            if max(check)
                map(i,j) = 'o' ; % pixel is on
            else
                map(i,j) = ' ' ; % pixel is off
            end
        end
    end
    disp('Map:')
    disp(map)
end
