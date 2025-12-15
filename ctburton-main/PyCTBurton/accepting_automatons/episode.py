def episode_accepting_automaton_variable_definitions(episode_name, episode_data):
    
    str_list = []
    
    # array[STAGES] of var epAcceptAutomatonL : epAcceptAutomatonTraj_{indexNum};
    # array[epAcceptAutomatonTr, STAGES] of var bool: epAcceptAutomatonTrTraj_{indexNum};
    # var int : epAcceptStartEvent_{indexNum};
    # var int : epAcceptEndEvent_{indexNum};
    # var float : epAcceptClockWhenStart_{indexNum};
    # var float : epAcceptClockWhenEnd_{indexNum};
    # var float : epAcceptClockParameter_{indexNum};

    str_list.append(f"array[STAGES] of var epAcceptAutomatonL : epAcceptAutomatonTraj_{episode_name};")
    str_list.append(f"array[epAcceptAutomatonTr, STAGES] of var bool: epAcceptAutomatonTrTraj_{episode_name};")
    str_list.append(f"var int : epAcceptStartEvent_{episode_name};")
    str_list.append(f"var int : epAcceptEndEvent_{episode_name};")
    str_list.append(f"var float : epAcceptClockWhenStart_{episode_name};")
    str_list.append(f"var float : epAcceptClockWhenEnd_{episode_name};")
    str_list.append(f"var float : epAcceptClockParameter_{episode_name};")

    # constraint epAcceptStartEvent_{indexNum} >=0 /\ epAcceptStartEvent_{indexNum} <= h;
    # constraint epAcceptEndEvent_{indexNum} >=0 /\ epAcceptEndEvent_{indexNum} <= h;
    # constraint epAcceptClockWhenStart_{indexNum} >= 0 /\ epAcceptClockWhenStart_{indexNum} <= Fupper;
    # constraint epAcceptClockWhenEnd_{indexNum} >= 0 /\ epAcceptClockWhenEnd_{indexNum} <= Fupper;
    # constraint epAcceptClockParameter_{indexNum} >= 0 /\ epAcceptClockParameter_{indexNum} <= Fupper;

    str_list.append(f"constraint epAcceptStartEvent_{episode_name} >=0 /\ epAcceptStartEvent_{episode_name} <= h;")
    str_list.append(f"constraint epAcceptEndEvent_{episode_name} >=0 /\ epAcceptEndEvent_{episode_name} <= h;")
    str_list.append(f"constraint epAcceptClockWhenStart_{episode_name} >= 0 /\ epAcceptClockWhenStart_{episode_name} <= Fupper;")
    str_list.append(f"constraint epAcceptClockWhenEnd_{episode_name} >= 0 /\ epAcceptClockWhenEnd_{episode_name} <= Fupper;")
    str_list.append(f"constraint epAcceptClockParameter_{episode_name} >= 0 /\ epAcceptClockParameter_{episode_name} <= Fupper;")

    return str_list

def episode_accepting_automaton_constraints(episode_name, episode_data):

    str_list = []
    
    ## DYNAMICS CONSTRAINTS - VARY BASED ON STATE PLAN ##
    
    # predicate epAcceptAcceptingConstraint(int : i) = projl[i]==projOn;
    str_list.append(f"predicate epAcceptAcceptingConstraint_{episode_name}(int : i) = {episode_data['accepting_constraint']};")
    
    # predicate epAcceptStateConstraint(int : i) = projl[i]==projOn;
    str_list.append(f"predicate epAcceptStateConstraint_{episode_name}(int : i) = {episode_data['state_constraint']};")

    # % Upper and lower bounds on epAcceptClockParameter
    # float : epAcceptLowerBound=1800;
    str_list.append(f"float : epAcceptLowerBound_{episode_name}={episode_data['lower_bound']};")
    
    # float : epAcceptUpperBound=1800;
    str_list.append(f"float : epAcceptUpperBound_{episode_name}={episode_data['upper_bound']};")

    # constraint epAcceptClockParameter >= epAcceptLowerBound /\ epAcceptClockParameter <= epAcceptUpperBound;
    str_list.append(f"constraint epAcceptClockParameter_{episode_name} >= epAcceptLowerBound_{episode_name} /\\ epAcceptClockParameter_{episode_name} <= epAcceptUpperBound_{episode_name};")

    # % Parameter constraints
    # constraint (epAcceptClockWhenEnd - epAcceptClockWhenStart)==epAcceptClockParameter;
    str_list.append(f"constraint (epAcceptClockWhenEnd_{episode_name} - epAcceptClockWhenStart_{episode_name})==epAcceptClockParameter_{episode_name};")

    # % initial state of the episode accepting automaton
    # constraint (projl[0]==projOn)->(epAcceptAutomatonTraj[0]==epActive);
    # constraint (projl[0]!=projOn)->(epAcceptAutomatonTraj[0]==epWaiting);
    str_list.append(f"constraint ({episode_data['accepting_constraint'].replace('[i]', '[0]')})->(epAcceptAutomatonTraj_{episode_name}[0]==epActive);")
    str_list.append(f"constraint ((not ({episode_data['accepting_constraint'].replace('[i]', '[0]')})))->(epAcceptAutomatonTraj_{episode_name}[0]==epWaiting);")

    # % 33 - waiting to waiting
    # constraint forall(i in STAGESm1)(epAcceptAutomatonTrTraj[33,i] -> 
    # epAcceptAutomatonTraj[i]==epWaiting /\ epAcceptAutomatonTraj[i+1]==epWaiting /\ 
    # not epAcceptAcceptingConstraint(i));

    str_list.append(f"constraint forall(i in STAGESm1)(epAcceptAutomatonTrTraj_{episode_name}[33,i] -> epAcceptAutomatonTraj_{episode_name}[i]==epWaiting /\\ epAcceptAutomatonTraj_{episode_name}[i+1]==epWaiting /\\ not epAcceptAcceptingConstraint_{episode_name}(i));")

    # % 34 - accepted to accepted
    # constraint forall(i in STAGESm1)(epAcceptAutomatonTrTraj[34,i] -> 
    # epAcceptAutomatonTraj[i]==epAccepted /\ epAcceptAutomatonTraj[i+1]==epAccepted);
    
    str_list.append(f"constraint forall(i in STAGESm1)(epAcceptAutomatonTrTraj_{episode_name}[34,i] -> epAcceptAutomatonTraj_{episode_name}[i]==epAccepted /\\ epAcceptAutomatonTraj_{episode_name}[i+1]==epAccepted);")
    
    # % 35 - failed to failed
    # constraint forall(i in STAGESm1)(epAcceptAutomatonTrTraj[35,i] -> 
    # epAcceptAutomatonTraj[i]==epFailed /\ epAcceptAutomatonTraj[i+1]==epFailed);

    str_list.append(f"constraint forall(i in STAGESm1)(epAcceptAutomatonTrTraj_{episode_name}[35,i] -> epAcceptAutomatonTraj_{episode_name}[i]==epFailed /\\ epAcceptAutomatonTraj_{episode_name}[i+1]==epFailed);")

    # % 36 - waiting to active
    # constraint forall(i in STAGESm1)(epAcceptAutomatonTrTraj[36,i] -> 
    # epAcceptAutomatonTraj[i]==epWaiting /\ epAcceptAutomatonTraj[i+1]==epActive /\
    # epAcceptAcceptingConstraint(i) /\ epAcceptStartEvent==(i+1) /\ epAcceptClockWhenStart==e[i+1]);

    str_list.append(f"constraint forall(i in STAGESm1)(epAcceptAutomatonTrTraj_{episode_name}[36,i] -> epAcceptAutomatonTraj_{episode_name}[i]==epWaiting /\\ epAcceptAutomatonTraj_{episode_name}[i+1]==epActive /\\ epAcceptAcceptingConstraint_{episode_name}(i) /\\ epAcceptStartEvent_{episode_name}==(i+1) /\\ epAcceptClockWhenStart_{episode_name}==e[i+1]);")

    # % 37 - active to active
    # constraint forall(i in STAGESm1)(epAcceptAutomatonTrTraj[37,i] -> 
    # epAcceptAutomatonTraj[i]==epActive /\ epAcceptAutomatonTraj[i+1]==epActive /\ 
    # epAcceptStateConstraint(i) /\ (e[i+1] - epAcceptClockWhenStart < epAcceptClockParameter));

    str_list.append(f"constraint forall(i in STAGESm1)(epAcceptAutomatonTrTraj_{episode_name}[37,i] -> epAcceptAutomatonTraj_{episode_name}[i]==epActive /\\ epAcceptAutomatonTraj_{episode_name}[i+1]==epActive /\\ epAcceptStateConstraint_{episode_name}(i) /\\ (e[i+1] - epAcceptClockWhenStart_{episode_name} < epAcceptClockParameter_{episode_name}));")

    # % 38 - active to accepted
    # constraint forall(i in STAGESm1)(epAcceptAutomatonTrTraj[38,i] -> 
    # epAcceptAutomatonTraj[i]==epActive /\ epAcceptAutomatonTraj[i+1]==epAccepted /\
    # epAcceptStateConstraint(i) /\ (e[i+1] - epAcceptClockWhenStart >= epAcceptClockParameter) /\ epAcceptEndEvent==(i+1) /\ epAcceptClockWhenEnd==e[i+1]) ;

    str_list.append(f"constraint forall(i in STAGESm1)(epAcceptAutomatonTrTraj_{episode_name}[38,i] -> epAcceptAutomatonTraj_{episode_name}[i]==epActive /\\ epAcceptAutomatonTraj_{episode_name}[i+1]==epAccepted /\\ epAcceptStateConstraint_{episode_name}(i) /\\ (e[i+1] - epAcceptClockWhenStart_{episode_name} >= epAcceptClockParameter_{episode_name}) /\\ epAcceptEndEvent_{episode_name}==(i+1) /\\ epAcceptClockWhenEnd_{episode_name}==e[i+1]) ;")

    # % 39 - active to failed
    # constraint forall(i in STAGESm1)(epAcceptAutomatonTrTraj[39,i] -> 
    # epAcceptAutomatonTraj[i]==epActive /\ epAcceptAutomatonTraj[i+1]==epFailed /\ 
    # not epAcceptStateConstraint(i));
    
    str_list.append(f"constraint forall(i in STAGESm1)(epAcceptAutomatonTrTraj_{episode_name}[39,i] -> epAcceptAutomatonTraj_{episode_name}[i]==epActive /\\ epAcceptAutomatonTraj_{episode_name}[i+1]==epFailed /\\ not epAcceptStateConstraint_{episode_name}(i));")

    # % ensure that only one transition occurs in a given stage.
    # constraint forall(i in STAGES)(sum(t in epAcceptAutomatonTr)(epAcceptAutomatonTrTraj[t, i]) == 1);
    # tonTrTraj[t, i]) == 1);
    
    str_list.append(f"constraint forall(i in STAGES)(sum(t in epAcceptAutomatonTr)(epAcceptAutomatonTrTraj_{episode_name}[t, i]) == 1);")
    
    return str_list