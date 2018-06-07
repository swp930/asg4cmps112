radians(degmin(Deg, Min), Y) :-
  Y is (Deg + (Min/60))*pi/180.

to_upper( Lower, Upper) :-
   atom_chars( Lower, Lowerlist),
   maplist( lower_upper, Lowerlist, Upperlist),
   atom_chars( Upper, Upperlist).

haversine_distance(degmin(Deg1, Min1), degmin(Deg2, Min2),
                   degmin(Deg3, Min3), degmin(Deg4, Min4), X) :-
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

/* Self Explanatory */
to_hours( Hours, Minutes, HM ) :-
   HM is Hours + Minutes / 60.

to_minutes( Hours, Minutes ) :-
   Minutes is Hours * 60.

/*Converts decimal hour to minutes*/
convertDHour(Hour, Min) :-
  Min is truncate(60*Hour).

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

format_time(Time) :-
  Time < 10,
  write('0'),write(Time).
format_time(Time) :- write(Time).

print_time( HoursMinutes ) :-
    Hours is floor( HoursMinutes * 60 ) // 60,
    Minutes is floor( HoursMinutes * 60 ) mod 60,
    format_time(Hours),write(':'),format_time(Minutes).

arrival_time(flight(Airport1, Airport2, time(DH, DM)), ArrivalTime) :-
  findAirtime(Airport1, Airport2, FlightTime),
  DepartureTime is DH + DM/60,
  ArrivalTime is DepartureTime + FlightTime.

/* Write the first path available */
writepath( [] ).

writepath( [flight(Depart, Arrive, time(DH, DM))|List]) :-
   airport( Depart, DName, _, _),
   airport( Arrive, AName, _, _),
   to_hours( DH, DM, DepartTime ),
   arrival_time( flight(Depart, Arrive, time(DH, DM)), ArrivalTime),
   to_upper(Depart, UDepart),
   to_upper(Arrive, UArrive),
   format( 'depart   ~w    ~w', [UDepart, DName]),
   print_time( DepartTime ), nl,
   format( 'arrive   ~w    ~w', [UArrive, AName]),
   print_time( ArrivalTime ), nl,
   writepath( List ).

checktime( H1, time( TH1, TM1 )) :-
   to_hours( TH1, TM1, H2 ),
   to_minutes( H1, M1 ),
   to_minutes( H2, M2 ),
   M1 + 29 < M2.

checkarrival( flight( Dep,Arr,DepTime )) :-
  arrival_time( flight( Dep,Arr,DepTime ), ArrivTime ),
  ArrivTime < 24.

/* Generate a list of a path from Node to End */
listpath( Node, End, [flight( Node, Next, NDep)|Outlist] ) :-
   not(Node = End),
   flight(Node, Next, NDep),
   listpath( Next, End, [flight( Node, Next, NDep)], Outlist ).
listpath( Node, Node, _, [] ).
listpath( Node, End,
   [flight( PDep, PArr, PDepTime )| Tried],
   [flight( Node, Next, NDep )| List] ) :-
   flight( Node, Next, NDep),
   arrival_time( flight( PDep, PArr, PDepTime ), PArriv),
   checktime( PArriv, NDep ),
   checkarrival( flight( Node, Next, NDep )),
   Tried2 = append( [flight( PDep, PArr, PDepTime )], Tried ),
   not( member( Next, Tried2 )),
   not( Next = PArr ),
   listpath( Next, End,
   [flight( Node, Next, NDep )|Tried2],
   List ).

fly(From, To) :-
  listpath(From, To, List),
  nl,
  writepath(List),!.
fly(From, From):-
  write('Both departure and destination airports are the same.'), !,
  fail.
