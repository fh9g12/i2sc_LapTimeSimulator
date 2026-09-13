function flag = flagUpdate(flag, j, k, prg_size)
    % current flag state
    p = sum(flag,'all')/size(flag,1)/size(flag,2) ;
    n_old = floor(p*prg_size) ; % old number of lines
    % new flag state
    flag(j,k) = true ;
    p = sum(flag,'all')/size(flag,1)/size(flag,2) ;
    n = floor(p*prg_size) ; % new number of lines
    % checking if state has changed enough to update progress bar
    if n>n_old
        progressBar(flag, prg_size) ;
    end
end
