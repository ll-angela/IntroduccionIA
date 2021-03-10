variable(en(robot, h2)).
variable(en(caja1, h2)).
variable(en(caja2, h2)).
variable(pinza(vacia)).

hecho(puerta(h1, h2)).

%s0 es la situación inicial del robot
s0(Situacion) :-
    setof(S, variable(S), Situacion).

% Tomar una lista de acciones y ejecutarlas
ejecutar_acciones(S1, [], S1). %Nada que hacer
ejecutar_acciones(S1, [Accion|Proceso], S2) :-
    accion(Accion, S1), % Asegurar que es un proceso válido
    resultado(S1, Accion, Sd),
    ejecutar_acciones(Sd, Proceso, S2).

%¿Se cumple (es verdadera) una variable en la Situación?
%Para consultar las situaciones
puede(Variable, Situacion) :-
    ground(Variable), ord_memberchk(Variable, Situacion), !.
puede(Variable, Situacion) :-
    member(Variable, Situacion).
remplazar_variable(S1, OldEl, NewEl, S2) :-
    ord_del_element(S1, OldEl, Sd),
    ord_add_element(Sd, NewEl, S2).

%Lista de acciones que puede hacer el robot
accion(cojer(X), S) :-
    dif(X, robot), %la pinza no puede cojer al robot
    puede(en(X, L), S),
    puede(en(robot, L), S),
    puede(pinza(vacia), S).

accion(ir_a(X), S) :-
    dif(X, h2),
    puede(en(robot, X), S).
    %puede(puerta(h1, h2), S).

accion(soltar(X), S) :-
    dif(X, vacia),
    puede(pinza(X), S).

resultado(S1, cojer(X), S2) :-
    %Robot tiene en la pinza X
    remplazar_variable(S1, pinza(vacia), pinza(X), S2).

resultado(S1, ir_a(L), S2) :-
    %Robot se mueve
    puede(en(robot, X), S1),
    remplazar_variable(S1, en(robot, X), en(robot, L), Sa),
    %Si lleva la caja en la pinza también se mueve
    dif(Caja, vacia),
    (   
    	puede(pinza(Caja), S1),
        remplazar_variable(Sa, en(Caja, X), en(Caja, L), S2)
    ;   \+ puede(pinza(Caja), S1),
        S2 = Sa
    ).

resultado(S1, soltar(X), S2) :-
    %Robot ya no tiene la caja en la pinza y su localización no cambia
    remplazar_variable(S1, pinza(X), pinza(vacia), S2).

%Los estados finales a los que se quiere llegar
objetivo(en(caja1, h1)).
objetivo(en(robot, h1)).
%objetivo(pinza(vacia)).

%  La situación objetivo 
situacion_objetivo(S) :-
    setof(G, objetivo(G), S).


%Prueba para ver si la situación satisfavce el objetivo
alcanzo_objetivo(SituacionObjetivo, Situacion) :-
    ord_subtract(SituacionObjetivo, Situacion, []).

% Mira si algo es una lista
lista([]).
lista([_|T]) :-
    lista(T).

busqueda_profundidad(Proceso) :-
    s0(S0),
    situacion_objetivo(SituacionObjetivo),
    %Generar una lista
    lista(Proceso),
    %Generar una solución
    ejecutar_acciones(S0, Proceso, Resultado),
    %Probar la solución
    alcanzo_objetivo(SituacionObjetivo, Resultado).

:- use_module(library(heaps)).

%Utilizar para ordenar la búsqueda
distancia_heuristica_al_objetivo(SituacionObjetivo, Situacion, Distancia) :-
    ord_subtract(SituacionObjetivo, Situacion, Dif),
    length(Dif, Distancia).

%
annadir_a_nodos_abiertos(CostoAcc, H1, Sit-Proceso, Objetivo, H2) :-
    distancia_heuristica_al_objetivo(Objetivo, Sit, D),
	succ(CostoAcc, CostoAct),
    Prioridad is CostoAct + D,
    add_to_heap(H1, Prioridad, CostoAct-Sit-Proceso, H2).

%Añadir a lista de pares Sit-Proceso
annadir_parejas_abiertas(_, Heap, _, [], _, Heap).
annadir_parejas_abiertas(CostoAcc, H1, Sits, [S-P|T], G, H2) :-
    (   ord_memberchk(S, Sits)
    ->  annadir_a_nodos_abiertos(CostoAcc, H1, S-P, G, Hd)
    ;   Hd = H1
    ),
    annadir_parejas_abiertas(CostoAcc, Hd, Sits, T, G, H2).

%
obtener_de_nodos_abiertos(H1, Sit-Proceso, H2) :-
    get_from_heap(H1, _Prioridad, Sit-Proceso, H2).

a_estrella(Sit, Proceso) :-
    s0(S0),
    situacion_objetivo(SituacionObjetivo),
    a_estrella(S0, SituacionObjetivo, Sit-Respuesta),
    reverse(Respuesta, Proceso).

%Configuración Busqueda A*
a_estrella(SituacionInicial, SituacionObjetivo, Respuesta) :-
    %Crear un heap/montículo de nodos de búsqueda abiertos
    distancia_heuristica_al_objetivo(SituacionObjetivo, SituacionInicial, D),
    singleton_heap(Abierto, D, 0-SituacionInicial-[]),
    %Hacer la búsqueda
    a_estrella(Abierto, SituacionObjetivo, [SituacionInicial], Respuesta).

a_estrella(Abierto, SituacionObjetivo, Cerrado, Respuesta) :-
    %Obtener la mejor pareja del Proceso Sit
    obtener_de_nodos_abiertos(Abierto, CostoAcc-Sit-Proceso, BusquedaRestante),
    %Si se llega al objetivo, devolver la respuesta
    (   alcanzo_objetivo(SituacionObjetivo, Sit), Respuesta = Sit-Proceso
    %Si no, seguir buscando
    ;   setof(S-[A|Proceso], (accion(A, Sit), resultado(Sit, A, S)), AS_Parejas),
        %Excluir nodos ya visitados
    	pairs_keys(AS_Parejas, Hijos),
        ord_union(Cerrado, Hijos, Cerrado1, Sits),
        %Añadir nuevos nodos abiertos
    	annadir_parejas_abiertas(CostoAcc, BusquedaRestante, Sits, AS_Parejas, SituacionObjetivo, Abierto1),
        %Seguir la búsqueda
    	a_estrella(Abierto1, SituacionObjetivo, Cerrado1, Respuesta)
    ).
