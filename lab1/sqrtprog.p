begin
  n := 200000000;
  l := 1;
  r := n;
  (* Invariant: l < intsqrt <= r *)
  while l < r do
    m := l + ((r - l + 1) div 2);
    msq := m * m;
    overflowed := m <> (msq div m);
    if (overflowed or (msq > n)) then
      r := m -1;
    else 
      l := m;
    end;
  end;
  print l; newline;
  print r; newline;
end.
