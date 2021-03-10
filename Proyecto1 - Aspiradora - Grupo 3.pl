variable(en(robot, h2)).
variable(en(caja1, h2)).
variable(en(caja2, h2)).
variable(pinza(vacia)).

puerta(h1, h2).

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
    dif(X, robot), %no puede agarrarse a si mismo
    puede(en(X, L), S),
    puede(en(robot, L), S),
    puede(pinza(vacia), S).

accion(ir_a(L), S) :-
    puede(en(robot, X), S),
    puede(puerta(h1, h2), S).

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

