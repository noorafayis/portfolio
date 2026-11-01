% ==========================================================
       % SMART AMBULANCE ROUTE FINDING SYSTEM
% ==========================================================


% ==========================================================
% ROAD INFORMATION
% road(Start, End, Distance, Time).
% ==========================================================

road(colombo, kadawatha, 15, 25).
road(colombo, kaduwela, 18, 30).
road(kadawatha, kiribathgoda, 10, 15).
road(kadawatha, gampaha, 20, 35).
road(kaduwela, malabe, 12, 20).
road(kaduwela, kadawatha, 14, 22).
road(malabe, battaramulla, 8, 12).
road(battaramulla, colombo, 7, 15).
road(kiribathgoda, kelaniya, 6, 10).
road(kelaniya, colombo, 9, 14).
road(kiribathgoda, gampaha, 22, 35).
road(gampaha, jaela, 18, 28).
road(jaela, negombo, 15, 25).
road(kelaniya, jaela, 25, 40).


% ==========================================================
                        % BLOCKED ROADS
% ==========================================================

blocked(kadawatha, gampaha).


% ==========================================================
                 % TRAFFIC CONDITIONS
% ==========================================================

traffic(colombo, kadawatha, high).
traffic(colombo, kaduwela, medium).
traffic(kadawatha, kiribathgoda, low).
traffic(kaduwela, malabe, medium).
traffic(kaduwela, kadawatha, low).
traffic(malabe, battaramulla, low).
traffic(kiribathgoda, kelaniya, medium).
traffic(kelaniya, colombo, high).
traffic(kiribathgoda, gampaha, high).
traffic(gampaha, jaela, medium).
traffic(jaela, negombo, low).
traffic(kelaniya, jaela, high).


% ==========================================================
                     % TRAFFIC COST
% ==========================================================

traffic_cost(low, 1).
traffic_cost(medium, 2).
traffic_cost(high, 3).


% ==========================================================
               % CHECK WHETHER ROAD IS AVAILABLE
% ==========================================================

available(X, Y, Distance, Time) :-
    road(X, Y, Distance, Time),
    \+ blocked(X, Y),
    \+ blocked(Y, X).

available(X, Y, Distance, Time) :-
    road(Y, X, Distance, Time),
    \+ blocked(X, Y),
    \+ blocked(Y, X).


% ==========================================================
                   % GET TRAFFIC LEVEL
% ==========================================================

get_traffic(X, Y, Level) :-
    traffic(X, Y, Level).

get_traffic(X, Y, Level) :-
    traffic(Y, X, Level).


% ==========================================================
                 % CALCULATE ROAD COST
% ==========================================================

road_cost(X, Y, Cost) :-
    available(X, Y, Distance, _),
    get_traffic(X, Y, Level),
    traffic_cost(Level, TrafficValue),
    Cost is Distance + TrafficValue * 5.


% ==========================================================
                % QUICK ROUTE SEARCH
% Internal implementation: Depth First Search
% ==========================================================

dfs(Start, Goal, Path, Distance) :-
    dfs_visit(Start, Goal, [Start], Path),
    calculate_distance(Path, Distance).

dfs_visit(Goal, Goal, Visited, Path) :-
    reverse(Visited, Path).

dfs_visit(Current, Goal, Visited, Path) :-
    available(Current, Next, _, _),
    \+ member(Next, Visited),
    dfs_visit(Next, Goal, [Next|Visited], Path).


% ==========================================================
            % SHORTEST ROUTE SEARCH
% Internal implementation: Breadth First Search
% ==========================================================

bfs(Start, Goal, Path, Distance) :-
    bfs_queue([[Start]], Goal, Path),
    calculate_distance(Path, Distance).

bfs_queue([[Goal|Rest]|_], Goal, Path) :-
    reverse([Goal|Rest], Path).

bfs_queue([CurrentPath|OtherPaths], Goal, Path) :-
    CurrentPath = [Current|_],

    findall(
        [Next|CurrentPath],
        (
            available(Current, Next, _, _),
            \+ member(Next, CurrentPath)
        ),
        NewPaths
    ),

    append(OtherPaths, NewPaths, NewQueue),

    bfs_queue(NewQueue, Goal, Path).


% ==========================================================
                % DISTANCE CALCULATION
% ==========================================================

calculate_distance([_], 0).

calculate_distance([A,B|Rest], Total) :-
    available(A, B, Distance, _),
    calculate_distance([B|Rest], Remaining),
    Total is Distance + Remaining.


% ==========================================================
% SMART ROUTE ESTIMATION VALUES
% ==========================================================

heuristic(colombo, 45).
heuristic(kadawatha, 35).
heuristic(kaduwela, 40).
heuristic(kiribathgoda, 30).
heuristic(gampaha, 25).
heuristic(malabe, 35).
heuristic(battaramulla, 40).
heuristic(kelaniya, 25).
heuristic(jaela, 15).
heuristic(negombo, 0).


% ==========================================================
                % SMART ROUTE SEARCH
% Internal implementation: A* Search
% ==========================================================

astar(Start, Goal, Path, Cost) :-
    heuristic(Start, H),
    astar_search(
        [node(Start, [Start], 0, H)],
        Goal,
        Path,
        Cost
    ).


astar_search(
    [node(Goal, Path, Cost, _)|_],
    Goal,
    FinalPath,
    Cost
) :-
    reverse(Path, FinalPath).

astar_search(
    [node(Current, Path, G, _)|Rest],
    Goal,
    FinalPath,
    Cost
) :-

    findall(
        node(
            Next,
            [Next|Path],
            NewG,
            F
        ),
        (
            available(Current, Next, _, _),
            \+ member(Next, Path),

            road_cost(Current, Next, RoadCost),

            NewG is G + RoadCost,

            heuristic(Next, H),

            F is NewG + H
        ),
        Children
    ),

    append(Rest, Children, Queue),
    sort_nodes(Queue, SortedQueue),

    astar_search(
        SortedQueue,
        Goal,
        FinalPath,
        Cost
    ).


% ==========================================================
               % SORT SMART ROUTE NODES
% ==========================================================

sort_nodes(Nodes, Sorted) :-
    predsort(compare_nodes, Nodes, Sorted).

compare_nodes(Order, node(_,_,_,F1), node(_,_,_,F2)) :-
    compare(Order, F1, F2).


% ==========================================================
                    % DISPLAY ROUTE
% ==========================================================

show_route(Path) :-
    write('Route: '),
    write(Path),
    nl.


% ==========================================================
               % COMPARE ROUTE OPTIONS
% ==========================================================

compare_routes(Start, Goal) :-

    write('=========================================='), nl,
    write('         ROUTE COMPARISON '), nl,
    write('=========================================='), nl,

    write('Start: '),
    write(Start),
    nl,

    write('Destination: '),
    write(Goal),
    nl,
    nl,


    % ------------------------------------------------------
                     % QUICK ROUTE
    % ------------------------------------------------------

    write(' QUICK ROUTE '), nl,

    (
        dfs(Start, Goal, QuickPath, QuickDistance)
        ->
        show_route(QuickPath),

        write('Distance: '),
        write(QuickDistance),
        write(' km'),
        nl
        ;

        write('No route found.'), nl
    ),

    nl,


    % ------------------------------------------------------
                     % SHORTEST ROUTE
    % ------------------------------------------------------

    write('----------- SHORTEST ROUTE --------------'), nl,

    (bfs(Start, Goal, ShortestPath, ShortestDistance)
        ->
        show_route(ShortestPath),

        write('Distance: '),
        write(ShortestDistance),
        write('km'),
        nl;
        write('No route found'), nl
    ),

    nl,


    % ------------------------------------------------------
                     % SMART ROUTE
    % ------------------------------------------------------

    write(' SMART ROUTE '), nl,

    (
        astar(Start, Goal, SmartPath, SmartCost)
        ->
        show_route(SmartPath),
        write('Route Cost: '),
        write(SmartCost),
        nl;
        write('No route found'), nl
    ),

    nl,
    write('=========================================='), nl.


% ==========================================================
            % CHECK BLOCKED & AVAILABLE ROAD
% ==========================================================

check_road(X, Y) :-

    (blocked(X, Y)
        ->

        write('Road is Blocked.'), nl
        ;

        blocked(Y, X)
        ->

        write('Road is Blocked.'), nl
        ;

        available(X, Y, Distance, Time)
        ->

        write('Road is Available.'), nl,

        write('Distance: '),
        write(Distance),
        write(' km'),
        nl,

        write('Time: '),
        write(Time),
        write(' minutes'),
        nl;

        write('Road does not exist.'), nl
    ).


% ==========================================================
                  % SHOW ALL ROADS
% ==========================================================

show_roads :-

    nl,
    write('=========================================='), nl,
    write('ROAD INFORMATION'), nl,
    write('=========================================='), nl,

    show_all_roads.


show_all_roads :-
    road(X, Y, Distance, Time),

    write(X),
    write(' -> '),
    write(Y),

    write(' | Distance: '),
    write(Distance),
    write(' km'),

    write(' | Time: '),
    write(Time),
    write(' minutes'),

    nl,
    fail.
show_all_roads.


% ==========================================================
               % SHOW TRAFFIC INFORMATION
% ==========================================================

show_traffic :-
    nl,

    write('=========================================='), nl,
    write('TRAFFIC INFORMATION'), nl,
    write('=========================================='), nl,

    show_all_traffic.


show_all_traffic :-
    traffic(X, Y, Level),

    write(X),
    write(' -> '),
    write(Y),

    write('| Traffic: '),
    write(Level),

    nl,
    fail.

show_all_traffic.


% ==========================================================
                  % FIND ROUTE MENU
% ==========================================================

find_route_menu :-

    nl,
    write('=========================================='), nl,
    write('FIND ROUTE'), nl,
    write('=========================================='), nl,

    write('Enter Start Location: '),
    read(Start),

    write('Enter Destination: '),
    read(Goal),

    nl,

    write('Select Route Type: '), nl,
    write('1. Quick Route'), nl,
    write('2. Shortest Route'), nl,
    write('3. Smart Route'), nl,
    write('4. Compare Route Options'), nl,

    nl,
    write('Enter Choice: '),
    read(Choice),
    nl,
    run_algorithm(Choice, Start, Goal).


% ==========================================================
              % RUN SELECTED ROUTE TYPE
% ==========================================================

% ----------------------------------------------------------
% QUICK ROUTE
% ----------------------------------------------------------

run_algorithm(1, Start, Goal) :-

    write('=========================================='), nl,
    write('QUICK ROUTE RESULT'), nl,
    write('=========================================='), nl,

    (
        dfs(Start, Goal, Path, Distance)

        ->

        show_route(Path),

        write('Distance: '),
        write(Distance),
        write(' km'),
        nl;
        write('No route found.'), nl
    ).


% ----------------------------------------------------------
                   % SHORTEST ROUTE
% ----------------------------------------------------------

run_algorithm(2, Start, Goal) :-

    write('=========================================='), nl,
    write('SHORTEST ROUTE RESULT'), nl,
    write('=========================================='), nl,

    (
        bfs(Start, Goal, Path, Distance)

        ->

        show_route(Path),
        write('Distance: '),
        write(Distance),
        write('km'),
        nl;
        write('No route found.'), nl
    ).


% ----------------------------------------------------------
                       % SMART ROUTE
% ----------------------------------------------------------

run_algorithm(3, Start, Goal) :-

    write('=========================================='), nl,
    write('SMART ROUTE RESULT'), nl,
    write('=========================================='), nl,

    (astar(Start, Goal, Path, Cost)
        ->

        show_route(Path),
        write('Route Cost: '),
        write(Cost),
        nl;
        write('No route found.'), nl
    ).


% ----------------------------------------------------------
               % COMPARE ROUTE OPTIONS
% ----------------------------------------------------------

run_algorithm(4, Start, Goal) :-
    compare_routes(Start, Goal).


% ----------------------------------------------------------
                  % INVALID CHOICE
% ----------------------------------------------------------

run_algorithm(_, _, _) :-
    write('Invalid choice!'), nl.


% ==========================================================
                 % CHECK ROAD MENU
% ==========================================================

check_road_menu :-

    nl,
    write('=========================================='), nl,
    write('               CHECK ROAD'), nl,
    write('=========================================='), nl,

    write('Enter First Location: '),
    read(X),

    write('Enter Second Location: '),
    read(Y),

    nl,
    check_road(X, Y).


% ==========================================================
                      % MAIN MENU
% ==========================================================

menu :-

    nl,

    write('=========================================='), nl,
    write(' SMART AMBULANCE ROUTE SYSTEM'), nl,
    write('=========================================='), nl,

    write('1. Find Ambulance Route'), nl,
    write('2. Check Road Status'), nl,
    write('3. Show All Roads'), nl,
    write('4. Show Traffic Information'), nl,
    write('5. Compare Route Options'), nl,
    write('6. Exit'), nl,

    write('=========================================='), nl,

    write('Enter your choice: '),
    read(Choice),
    menu_choice(Choice).


% ==========================================================
                    % MENU CHOICES
% ==========================================================

menu_choice(1) :-
    find_route_menu,
    menu.


menu_choice(2) :-
    check_road_menu,
    menu.


menu_choice(3) :-
    show_roads,
    menu.


menu_choice(4) :-
    show_traffic,
    menu.


menu_choice(5) :-
    nl,

    write('Enter Start Location: '),
    read(Start),

    write('Enter Destination: '),
    read(Goal),

    compare_routes(Start, Goal),
    menu.


menu_choice(6) :-
    nl,
    write('=========================================='), nl,
    write(' Thank you for using Smart Ambulance System'), nl,
    write('=========================================='), nl.


menu_choice(_) :-
    write('Invalid choice! Please try again.'), nl,
    menu.


% ==========================================================
                  % START PROGRAM
% ==========================================================

start :-
    nl,
    write('******************************************'), nl,
    write('    SMART AMBULANCE ROUTE FINDER      '), nl,
    write('******************************************'), nl,
    nl,
    write('System Started Successfully!'), nl,
    nl,
    menu.