radians(degmin(Deg, Min), Y) :-
  Y is (Deg + (Min/60))*pi/180.

haversine_distance(degmin(Deg1, Min1), degmin(Deg2, Min2), degmin(Deg3, Min3), degmin(Deg4, Min4), X) :-
  radians(degmin(Deg1, Min1), Lat1),
  radians(degmin(Deg2, Min2), Lon1),
  radians(degmin(Deg3, Min3), Lat2),
  radians(degmin(Deg4, Min4), Lon2),
  Dlon is Lon2 - Lon1,
  Dlat is Lat2 - Lat1,
  Tmpa is sin(Dlat/2)**2 + cos(Lat1)*cos(Lat2)*sin(Dlon/2)**2,
  Unitdist is 2 * atan2(sqrt(Tmpa), sqrt(1-Tmpa)),
  Distance is Unitdist * 3961,
  X is Distance.

not( X ) :- X, !, fail.
not( _ ).

ispath(L, M) :-
  ispath2(L, M, []).

ispath2(L, L, _).
ispath2(L, M, Path) :-
  flight(L, X, _),
  not( member( X, Path )),
  ispath2(X, M, [L|Path]).

/*Converts decimal hour to minutes*/
convertDHour(Hour, Min) :-
  Min is truncate(60*Hour).

concatStr(Str1, Str2, Out) :-
  name(Str1, StrList1),
  name(Str2, StrList2),
  append(StrList1, StrList2, StrList3),
  name(Out, StrList3).

getStringRep(time(H,M), Out) :-
  M =:= 0, concatStr(H,":",Out1),
  concatStr(Out1,"00",Out).

getStringRep(time(H,M), Out) :-
  M < 10, concatStr(H,":",Out1),
  concatStr(Out1,"0",Out2),
  concatStr(Out2,M,Out).

getStringRep(time(H,M), Out) :-
  concatStr(H,":",Out1),
  concatStr(Out1,M,Out).

convertToHourMin(Hour, time(H,M)) :-
  Min is truncate(60*Hour),
  H is Min//60,
  M is mod(Min, 60).

adjustMin(Mnew, time(H,M)) :-
  H is Mnew//60,
  M is mod(Mnew, 60).

addTimes(time(H1, M1), time(H2, M2), time(H3, M3)) :-
  Hnew is H1 + H2,
  Mnew is M1 + M2,
  adjustMin(Mnew, time(H,M)),
  H3 is Hnew + H,
  M3 is M.

findAirtime(Head, Head2, Airtime) :-
  airport(Head,_,Lat1,Lon1),
  airport(Head2,_,Lat2,Lon2),
  haversine_distance(Lat1, Lon1, Lat2, Lon2, Distance),
  Airtime is Distance/500.

writepath( [_] ) :-
   nl.

writepath(List) :-
  [Head|Tail] = List,
  [Head2|_] = Tail,
  findAirtime(Head, Head2, Airtime),
  convertToHourMin(Airtime, time(Airhour, Airmin)),
  flight(Head, Head2, time(Departh,Departm)),
  addTimes(time(Departh, Departm), time(Airhour, Airmin), time(Arrivalh, Arrivalm)),
  /*Arrivalh is Departh + Airhour,
  Arrivalm is Departm + Airmin,*/
  getStringRep(time(Departh, Departm), DepartTime),
  getStringRep(time(Arrivalh, Arrivalm), ArrivalTime),
  airport(Head, Name1, _,_),
  airport(Head2, Name2, _,_),
  format('depart ~w ~w ~w~n', [Head, Name1, DepartTime]),
  format('arrive ~w ~w ~w~n', [Head2, Name2, ArrivalTime]),
  writepath(Tail).

checkTime(time(-1, -1), _).
checkTime(_, time(-1, -1)).

checkTime(time(Hlast, Mlast), time(Hnew, Mnew)) :-
  Hlast > Hnew.
checkTime(time(Hlast, Mlast), time(Hnew, Mnew)) :- Hlast =:= Hnew, Mlast > Mnew.

listpath( Node, Node, _, [Node],_).
listpath(Node, End, [Node], List, _) :-
  flight(Node, End, _),
  List = [Node,End].
listpath( Node, End, Tried, [Node|List], time(Hlast,Mlast)) :-
   flight( Node, Next,_),
   not( member( Next, Tried )),
   flight(Node, Next, time(Hnew, Mnew)),
   findAirtime(Node, Next, Airtime),
   convertToHourMin(Airtime, AirtimeHourMin),
   addTimes(time(Hnew, Mnew), AirtimeHourMin, NextTime),
   write(time(Hnew, Mnew)), write(' '), write(time(Hlast, Mlast)), nl,
   listpath( Next, End, [Next|Tried], List, NextTime).

fly(From, To) :-
  listpath(From, To, [From], List, time(-1,-1)),
  writepath(List).
