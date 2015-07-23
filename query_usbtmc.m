function [out_str] = query_usbtmc(fname, in_str)
    fname = '/dev/usbtmc0';

    string_terminator = 10;

    fhr = fopen( fname, 'r');
    fhw = fopen( fname, 'w');
    fwrite(fhw, in_str);

    out_str = [];
    [out_byte, cnt] = fread(fhr,1,'*uint8');
    while (out_byte ~= string_terminator) & (cnt ~= 0)
        out_str = [ out_str, char(out_byte) ];
        out_byte = fread(fhr,1,'*uint8');
    end

    fclose(fhr);
    fclose(fhw);

end
