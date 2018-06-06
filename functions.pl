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
