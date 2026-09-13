function progressBar(flag, prg_size)
    % updates the in-place console progress bar (no log-file mirroring)
    p = sum(flag,'all')/size(flag,1)/size(flag,2) ; % progress percentage
    n = floor(p*prg_size) ; % new number of lines
    e = prg_size-n ; % number of spaces
    fprintf(repmat('\b',1,prg_size+1+8)) % backspace to start of bar
    fprintf(repmat('|',1,n)) % writing lines
    fprintf(repmat(' ',1,e)) % writing spaces
    fprintf(']') % closing bar
    fprintf('%4.0f',p*100) % writing percentage
    fprintf(' [%%]') % writing % symbol
end
