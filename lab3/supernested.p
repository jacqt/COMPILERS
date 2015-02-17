(* lab3/supernested.p *)

proc a(x);
  var OMG;
  proc d(ok);
  begin
    return ok;
  end;
  proc b(y);
    proc c(z);
      proc BOOM(asdf);
      begin 
        return asdf + OMG;
      end;
    begin 
      return z + d(4) + BOOM(0);
    end;
  begin
    return y + c(5);
  end;
begin
  OMG := 3;
  return x + b(3);
end;

begin
  print a(0); newline
end.

(*<<
 15
>>*)
