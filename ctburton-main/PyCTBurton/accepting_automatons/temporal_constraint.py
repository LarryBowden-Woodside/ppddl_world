def temporal_constraint_accepting_automaton_variable_definitions(tc_name, tc_data):
    
    str_list = []
    
    # LOCATION AND TRANSITION TRAJECTORY
    # array[STAGES] of var tempAcceptAutomatonL : temporalAcceptConstraint_Traj_{indexNum};
    # array[temporalAcceptAutomatonTr, STAGES] of var bool : temporalAcceptConstraint_TrTraj_{indexNum};

    str_list.append(f"array[STAGES] of var tempAcceptAutomatonL : temporalAcceptConstraint_Traj_{tc_name};")
    str_list.append(f"array[temporalAcceptAutomatonTr, STAGES] of var bool : temporalAcceptConstraint_TrTraj_{tc_name};")

    # DEFAULT VARIABLES
    # var int : temporalAcceptConstraint_event1_{indexNum};
    # var int : temporalAcceptConstraint_event2_{indexNum};
    # var float : temporalAcceptConstraint_event1Clock_{indexNum};
    # var float : temporalAcceptConstraint_event2Clock_{indexNum};
    # var float : temporalAcceptConstraint_ClockWhenActivated_{indexNum};
    # var float : temporalAcceptConstraint_ClockWhenAccepted_{indexNum};
    # var float : temporalAcceptConstraint_ClockParameter_{indexNum};

    str_list.append(f"var int : temporalAcceptConstraint_event1_{tc_name};")
    str_list.append(f"var int : temporalAcceptConstraint_event2_{tc_name};")
    str_list.append(f"var float : temporalAcceptConstraint_event1Clock_{tc_name};")
    str_list.append(f"var float : temporalAcceptConstraint_event2Clock_{tc_name};")
    str_list.append(f"var float : temporalAcceptConstraint_ClockWhenActivated_{tc_name};")
    str_list.append(f"var float : temporalAcceptConstraint_ClockWhenAccepted_{tc_name};")
    str_list.append(f"var float : temporalAcceptConstraint_ClockParameter_{tc_name};")

    # DEFAULT CONSTRAINTS
    # constraint temporalAcceptConstraint_event1_{indexNum}>=0 /\ temporalAcceptConstraint_event1_{indexNum}<=h;
    # constraint temporalAcceptConstraint_event2_{indexNum}>=0 /\ temporalAcceptConstraint_event2_{indexNum}<=h;
    # constraint temporalAcceptConstraint_event1Clock_{indexNum}>=0 /\ temporalAcceptConstraint_event1Clock_{indexNum}<=Fupper;
    # constraint temporalAcceptConstraint_event2Clock_{indexNum}>=0 /\ temporalAcceptConstraint_event2Clock_{indexNum}<=Fupper;
    # constraint temporalAcceptConstraint_ClockWhenActivated_{indexNum}>=0 /\ temporalAcceptConstraint_ClockWhenActivated_{indexNum}<=Fupper;
    # constraint temporalAcceptConstraint_ClockWhenAccepted_{indexNum}>=0 /\ temporalAcceptConstraint_ClockWhenAccepted_{indexNum}<=Fupper;
    # constraint temporalAcceptConstraint_ClockParameter_{indexNum}>=-Fupper /\ temporalAcceptConstraint_ClockParameter_{indexNum}<=Fupper;

    str_list.append(f"constraint temporalAcceptConstraint_event1_{tc_name}>=0 /\ temporalAcceptConstraint_event1_{tc_name}<=h;")
    str_list.append(f"constraint temporalAcceptConstraint_event2_{tc_name}>=0 /\ temporalAcceptConstraint_event2_{tc_name}<=h;")
    str_list.append(f"constraint temporalAcceptConstraint_event1Clock_{tc_name}>=0 /\ temporalAcceptConstraint_event1Clock_{tc_name}<=Fupper;")
    str_list.append(f"constraint temporalAcceptConstraint_event2Clock_{tc_name}>=0 /\ temporalAcceptConstraint_event2Clock_{tc_name}<=Fupper;")
    str_list.append(f"constraint temporalAcceptConstraint_ClockWhenActivated_{tc_name}>=0 /\ temporalAcceptConstraint_ClockWhenActivated_{tc_name}<=Fupper;")
    str_list.append(f"constraint temporalAcceptConstraint_ClockWhenAccepted_{tc_name}>=0 /\ temporalAcceptConstraint_ClockWhenAccepted_{tc_name}<=Fupper;")
    str_list.append(f"constraint temporalAcceptConstraint_ClockParameter_{tc_name}>=-Fupper /\ temporalAcceptConstraint_ClockParameter_{tc_name}<=Fupper;")

    # Upper and Lower bounds on the clock parameter
    # constraint temporalAcceptConstraint_ClockParameter_{indexNum} >= temporalAcceptConstraint_lowerBound_{indexNum} /\ temporalAcceptConstraint_ClockParameter_{indexNum} <= temporalAcceptConstraint_upperBound_{indexNum};
    str_list.append(f"constraint temporalAcceptConstraint_ClockParameter_{tc_name} >= temporalAcceptConstraint_lowerBound_{tc_name} /\ temporalAcceptConstraint_ClockParameter_{tc_name} <= temporalAcceptConstraint_upperBound_{tc_name};")    

    # Add starting constraints for each temporal constraint accepting automaton.
    # Starting state constraints
    # % if e1=e2=e0
    # predicate startingConstraint1_{indexNum}() = temporalAcceptConstraint_event1_{indexNum}==temporalAcceptConstraint_event2_{indexNum} /\ temporalAcceptConstraint_event2_{indexNum}==0;
    # constraint (startingConstraint1_{indexNum}())->(temporalAcceptConstraint_Traj_{indexNum}[0]==tempAccepted /\ temporalAcceptConstraint_ClockWhenActivated_{indexNum}==e[0] /\ temporalAcceptConstraint_ClockWhenAccepted_{indexNum}==e[0] /\ temporalAcceptConstraint_event1Clock_{indexNum}==e[0] /\ temporalAcceptConstraint_event2Clock_{indexNum}==e[0] /\ temporalAcceptConstraint_acceptingEvent1_{indexNum}(0) /\ temporalAcceptConstraint_acceptingEvent2_{indexNum}(0));
    # % if e1=e0!=e2
    # predicate startingConstraint2_{indexNum}() = temporalAcceptConstraint_event1_{indexNum}==0 /\ 0!=temporalAcceptConstraint_event2_{indexNum};
    # constraint (startingConstraint2_{indexNum}())->(temporalAcceptConstraint_Traj_{indexNum}[0]==tempActive /\ temporalAcceptConstraint_event1Clock_{indexNum}==e[0] /\ temporalAcceptConstraint_ClockWhenActivated_{indexNum}==e[0] /\ temporalAcceptConstraint_acceptingEvent1_{indexNum}(0));
    # % if e2=e0!=e1
    # predicate startingConstraint3_{indexNum}() =  temporalAcceptConstraint_event2_{indexNum}==0 /\ 0!=temporalAcceptConstraint_event1_{indexNum};
    # constraint (startingConstraint3_{indexNum}())->(temporalAcceptConstraint_Traj_{indexNum}[0]==tempActive /\ temporalAcceptConstraint_event2Clock_{indexNum}==e[0] /\ temporalAcceptConstraint_ClockWhenActivated_{indexNum}==e[0] /\ temporalAcceptConstraint_acceptingEvent2_{indexNum}(0));
    # % else e1!=e2!=e0
    # constraint (not (startingConstraint1_{indexNum}() \/ startingConstraint2_{indexNum}() \/ startingConstraint3_{indexNum}()))->(temporalAcceptConstraint_Traj_{indexNum}[0]==tempWaiting);

    str_list.append(f"predicate startingConstraint1_{tc_name}() = temporalAcceptConstraint_event1_{tc_name}==temporalAcceptConstraint_event2_{tc_name} /\ temporalAcceptConstraint_event2_{tc_name}==0;")
    str_list.append(f"constraint (startingConstraint1_{tc_name}())->(temporalAcceptConstraint_Traj_{tc_name}[0]==tempAccepted /\ temporalAcceptConstraint_ClockWhenActivated_{tc_name}==e[0] /\ temporalAcceptConstraint_ClockWhenAccepted_{tc_name}==e[0] /\ temporalAcceptConstraint_event1Clock_{tc_name}==e[0] /\ temporalAcceptConstraint_event2Clock_{tc_name}==e[0] /\ temporalAcceptConstraint_acceptingEvent1_{tc_name}(0) /\ temporalAcceptConstraint_acceptingEvent2_{tc_name}(0));")
    
    str_list.append(f"predicate startingConstraint2_{tc_name}() = temporalAcceptConstraint_event1_{tc_name}==0 /\ 0!=temporalAcceptConstraint_event2_{tc_name};")
    str_list.append(f"constraint (startingConstraint2_{tc_name}())->(temporalAcceptConstraint_Traj_{tc_name}[0]==tempActive /\ temporalAcceptConstraint_event1Clock_{tc_name}==e[0] /\ temporalAcceptConstraint_ClockWhenActivated_{tc_name}==e[0] /\ temporalAcceptConstraint_acceptingEvent1_{tc_name}(0));")
    
    str_list.append(f"predicate startingConstraint3_{tc_name}() =  temporalAcceptConstraint_event2_{tc_name}==0 /\ 0!=temporalAcceptConstraint_event1_{tc_name};")
    str_list.append(f"constraint (startingConstraint3_{tc_name}())->(temporalAcceptConstraint_Traj_{tc_name}[0]==tempActive /\ temporalAcceptConstraint_event2Clock_{tc_name}==e[0] /\ temporalAcceptConstraint_ClockWhenActivated_{tc_name}==e[0] /\ temporalAcceptConstraint_acceptingEvent2_{tc_name}(0));")
    
    str_list.append(f"constraint (not (startingConstraint1_{tc_name}() \/ startingConstraint2_{tc_name}() \/ startingConstraint3_{tc_name}()))->(temporalAcceptConstraint_Traj_{tc_name}[0]==tempWaiting);")

    # Parameter constraints
    # constraint abs(temporalAcceptConstraint_event2Clock_{indexNum} - temporalAcceptConstraint_event1Clock_{indexNum})==temporalAcceptConstraint_ClockParameter_{indexNum};
    # constraint temporalAcceptConstraint_ClockWhenAccepted_{indexNum} - temporalAcceptConstraint_ClockWhenActivated_{indexNum} == temporalAcceptConstraint_ClockParameter_{indexNum};
    
    str_list.append(f"constraint abs(temporalAcceptConstraint_event2Clock_{tc_name} - temporalAcceptConstraint_event1Clock_{tc_name})==temporalAcceptConstraint_ClockParameter_{tc_name};")
    str_list.append(f"constraint temporalAcceptConstraint_ClockWhenAccepted_{tc_name} - temporalAcceptConstraint_ClockWhenActivated_{tc_name} == temporalAcceptConstraint_ClockParameter_{tc_name};")
    
    return str_list

def temporal_constraint_accepting_automaton_constraints(tc_name, tc_data):
    
    str_list = []

    # predicate temporalAcceptConstraint_2_acceptingEvent1(int : i) = projl[i]==projOn /\ projl[i+1]==projConfirm;
    # predicate temporalAcceptConstraint_2_acceptingEvent2(int : i) = projl[i+1]==projOff /\ connl[i+1]==disconnected /\ compl[i+1]=compOff /\ temporalAcceptConstraint_2_Traj[i]==tempActive;

    str_list.append(f"predicate temporalAcceptConstraint_acceptingEvent1_{tc_name}(int : i) = {tc_data['accepting_event1_constraint']};")
    # THE tempActive constraint potentially needs to be made more dynamic/not hardcoded.
    str_list.append(f"predicate temporalAcceptConstraint_acceptingEvent2_{tc_name}(int : i) = {tc_data['accepting_event2_constraint']};")

    # float : temporalAcceptConstraint_2_lowerBound=600;
    # float : temporalAcceptConstraint_2_upperBound=600;
    
    str_list.append(f"float : temporalAcceptConstraint_lowerBound_{tc_name}={tc_data['lower_bound']};")
    str_list.append(f"float : temporalAcceptConstraint_upperBound_{tc_name}={tc_data['upper_bound']};")

    # % 41 - waiting to waiting
    # constraint forall(i in STAGESm1)(temporalAcceptConstraint_2_TrTraj[41,i] -> 
    #   temporalAcceptConstraint_2_Traj[i]==tempWaiting /\ temporalAcceptConstraint_2_Traj[i+1]==tempWaiting /\ 
    #   not temporalAcceptConstraint_2_acceptingEvent1(i) /\ not temporalAcceptConstraint_2_acceptingEvent2(i));

    str_list.append(f"constraint forall(i in STAGESm1)(temporalAcceptConstraint_TrTraj_{tc_name}[41,i] -> temporalAcceptConstraint_Traj_{tc_name}[i]==tempWaiting /\\ temporalAcceptConstraint_Traj_{tc_name}[i+1]==tempWaiting /\\ not temporalAcceptConstraint_acceptingEvent1_{tc_name}(i) /\\ not temporalAcceptConstraint_acceptingEvent2_{tc_name}(i));")

    # % 42 - waiting to accepted
    # constraint forall(i in STAGESm1)(temporalAcceptConstraint_2_TrTraj[42,i] -> 
    #   temporalAcceptConstraint_2_Traj[i]==tempWaiting /\ temporalAcceptConstraint_2_Traj[i+1]==tempAccepted /\ 
    #   temporalAcceptConstraint_2_acceptingEvent1(i) /\ temporalAcceptConstraint_2_acceptingEvent2(i) /\
    #   temporalAcceptConstraint_2_event1==i+1 /\ temporalAcceptConstraint_2_event2==i+1 /\ 
    #   temporalAcceptConstraint_2_event1Clock==e[i+1] /\ temporalAcceptConstraint_2_event2Clock==e[i+1]);

    str_list.append(f"constraint forall(i in STAGESm1)(temporalAcceptConstraint_TrTraj_{tc_name}[42,i] -> temporalAcceptConstraint_Traj_{tc_name}[i]==tempWaiting /\\ temporalAcceptConstraint_Traj_{tc_name}[i+1]==tempAccepted /\\ temporalAcceptConstraint_acceptingEvent1_{tc_name}(i) /\\ temporalAcceptConstraint_acceptingEvent2_{tc_name}(i) /\\ temporalAcceptConstraint_event1_{tc_name}==i+1 /\\ temporalAcceptConstraint_event2_{tc_name}==i+1 /\\ temporalAcceptConstraint_event1Clock_{tc_name}==e[i+1] /\\ temporalAcceptConstraint_event2Clock_{tc_name}==e[i+1]);")

    # % 43 - waiting to active
    # predicate e1BeforeE2(int: i) = temporalAcceptConstraint_2_Traj[i]==tempWaiting /\ temporalAcceptConstraint_2_Traj[i+1]==tempActive /\ temporalAcceptConstraint_2_acceptingEvent1(i) /\ not temporalAcceptConstraint_2_acceptingEvent2(i) /\ temporalAcceptConstraint_2_event1Clock==e[i+1] /\ temporalAcceptConstraint_2_event1==i+1 /\ temporalAcceptConstraint_2_ClockWhenActivated==e[i+1] /\ temporalAcceptConstraint_2_ClockParameter <= temporalAcceptConstraint_2_upperBound /\ temporalAcceptConstraint_2_event1Clock <= temporalAcceptConstraint_2_event2Clock;
    str_list.append(f"predicate e1BeforeE2_{tc_name}(int: i) = temporalAcceptConstraint_Traj_{tc_name}[i]==tempWaiting /\\ temporalAcceptConstraint_Traj_{tc_name}[i+1]==tempActive /\\ temporalAcceptConstraint_acceptingEvent1_{tc_name}(i) /\\ not temporalAcceptConstraint_acceptingEvent2_{tc_name}(i) /\\ temporalAcceptConstraint_event1Clock_{tc_name}==e[i+1] /\\ temporalAcceptConstraint_event1_{tc_name}==i+1 /\\ temporalAcceptConstraint_ClockWhenActivated_{tc_name}==e[i+1] /\\ temporalAcceptConstraint_ClockParameter_{tc_name} <= temporalAcceptConstraint_upperBound_{tc_name} /\\ temporalAcceptConstraint_event1Clock_{tc_name} <= temporalAcceptConstraint_event2Clock_{tc_name};")

    # predicate e2BeforeE1(int: i) = temporalAcceptConstraint_2_Traj[i]==tempWaiting /\ temporalAcceptConstraint_2_Traj[i+1]==tempActive /\ not temporalAcceptConstraint_2_acceptingEvent1(i) /\ temporalAcceptConstraint_2_acceptingEvent2(i) /\ temporalAcceptConstraint_2_event2Clock==e[i+1] /\ temporalAcceptConstraint_2_event2==i+1 /\ temporalAcceptConstraint_2_event2Clock <= temporalAcceptConstraint_2_event1Clock /\ temporalAcceptConstraint_2_ClockWhenActivated==e[i+1] /\ temporalAcceptConstraint_2_ClockParameter<=(-1 * temporalAcceptConstraint_2_lowerBound);
    str_list.append(f"predicate e2BeforeE1_{tc_name}(int: i) = temporalAcceptConstraint_Traj_{tc_name}[i]==tempWaiting /\\ temporalAcceptConstraint_Traj_{tc_name}[i+1]==tempActive /\\ not temporalAcceptConstraint_acceptingEvent1_{tc_name}(i) /\\ temporalAcceptConstraint_acceptingEvent2_{tc_name}(i) /\\ temporalAcceptConstraint_event2Clock_{tc_name}==e[i+1] /\\ temporalAcceptConstraint_event2_{tc_name}==i+1 /\\ temporalAcceptConstraint_event2Clock_{tc_name} <= temporalAcceptConstraint_event1Clock_{tc_name} /\\ temporalAcceptConstraint_ClockWhenActivated_{tc_name}==e[i+1] /\\ temporalAcceptConstraint_ClockParameter_{tc_name}<=(-1 * temporalAcceptConstraint_lowerBound_{tc_name});")

    # constraint forall(i in STAGESm1)(temporalAcceptConstraint_2_TrTraj[43,i] -> (e1BeforeE2(i) \/ e2BeforeE1(i)));
    str_list.append(f"constraint forall(i in STAGESm1)(temporalAcceptConstraint_TrTraj_{tc_name}[43,i] -> (e1BeforeE2_{tc_name}(i) \\/ e2BeforeE1_{tc_name}(i)));")

    # % 44 - active to active
    # constraint forall(i in STAGESm1)(temporalAcceptConstraint_2_TrTraj[44,i] -> 
    #   temporalAcceptConstraint_2_Traj[i]==tempActive /\ temporalAcceptConstraint_2_Traj[i+1]==tempActive /\ 
    #   e[i+1]-temporalAcceptConstraint_2_ClockWhenActivated < temporalAcceptConstraint_2_ClockParameter);
    str_list.append(f"constraint forall(i in STAGESm1)(temporalAcceptConstraint_TrTraj_{tc_name}[44,i] -> temporalAcceptConstraint_Traj_{tc_name}[i]==tempActive /\\ temporalAcceptConstraint_Traj_{tc_name}[i+1]==tempActive /\\ e[i+1]-temporalAcceptConstraint_ClockWhenActivated_{tc_name} < temporalAcceptConstraint_ClockParameter_{tc_name});")

    # % 45 - active to accepted
    # predicate endsOnE2(int: i) = temporalAcceptConstraint_2_Traj[i]==tempActive /\ temporalAcceptConstraint_2_Traj[i+1]==tempAccepted /\ 
    #   (e[i+1]-temporalAcceptConstraint_2_ClockWhenActivated) >= temporalAcceptConstraint_2_ClockParameter /\ 
    #   temporalAcceptConstraint_2_event1Clock < temporalAcceptConstraint_2_event2Clock /\ temporalAcceptConstraint_2_event2==i+1 /\ 
    #   temporalAcceptConstraint_2_acceptingEvent2(i);
    str_list.append(f"predicate endsOnE2_{tc_name}(int: i) = temporalAcceptConstraint_Traj_{tc_name}[i]==tempActive /\\ temporalAcceptConstraint_Traj_{tc_name}[i+1]==tempAccepted /\\ (e[i+1]-temporalAcceptConstraint_ClockWhenActivated_{tc_name}) >= temporalAcceptConstraint_ClockParameter_{tc_name} /\\ temporalAcceptConstraint_event1Clock_{tc_name} < temporalAcceptConstraint_event2Clock_{tc_name} /\\ temporalAcceptConstraint_event2_{tc_name}==i+1 /\\ temporalAcceptConstraint_acceptingEvent2_{tc_name}(i);")

    # predicate endsOnE1(int: i) = temporalAcceptConstraint_2_Traj[i]==tempActive /\ temporalAcceptConstraint_2_Traj[i+1]==tempAccepted /\ 
    #   (e[i+1]-temporalAcceptConstraint_2_ClockWhenActivated) >= temporalAcceptConstraint_2_ClockParameter /\ 
    #   temporalAcceptConstraint_2_event2Clock < temporalAcceptConstraint_2_event1Clock /\ temporalAcceptConstraint_2_event1==i+1 /\    temporalAcceptConstraint_2_acceptingEvent1(i);
    str_list.append(f"predicate endsOnE1_{tc_name}(int: i) = temporalAcceptConstraint_Traj_{tc_name}[i]==tempActive /\\ temporalAcceptConstraint_Traj_{tc_name}[i+1]==tempAccepted /\\ (e[i+1]-temporalAcceptConstraint_ClockWhenActivated_{tc_name}) >= temporalAcceptConstraint_ClockParameter_{tc_name} /\\ temporalAcceptConstraint_event2Clock_{tc_name} < temporalAcceptConstraint_event1Clock_{tc_name} /\\ temporalAcceptConstraint_event1_{tc_name}==i+1 /\\ temporalAcceptConstraint_acceptingEvent1_{tc_name}(i);")

    # constraint forall(i in STAGESm1)(temporalAcceptConstraint_2_TrTraj[45,i] -> (endsOnE2(i) \/ endsOnE1(i)));
    str_list.append(f"constraint forall(i in STAGESm1)(temporalAcceptConstraint_TrTraj_{tc_name}[45,i] -> (endsOnE2_{tc_name}(i) \\/ endsOnE1_{tc_name}(i)));")

    # % 46 - accepted to accepted
    # constraint forall(i in STAGESm1)(temporalAcceptConstraint_2_TrTraj[46,i] -> 
    #   (temporalAcceptConstraint_2_Traj[i]==tempAccepted /\ temporalAcceptConstraint_2_Traj[i+1]==tempAccepted));
    str_list.append(f"constraint forall(i in STAGESm1)(temporalAcceptConstraint_TrTraj_{tc_name}[46,i] -> (temporalAcceptConstraint_Traj_{tc_name}[i]==tempAccepted /\\ temporalAcceptConstraint_Traj_{tc_name}[i+1]==tempAccepted));")

    # % ensure that only one transition occurs in a given stage.
    # constraint forall(i in STAGES)(sum(t in temporalAcceptAutomatonTr)(temporalAcceptConstraint_2_TrTraj[t, i]) == 1);
    str_list.append(f"constraint forall(i in STAGES)(sum(t in temporalAcceptAutomatonTr)(temporalAcceptConstraint_TrTraj_{tc_name}[t, i]) == 1);")

    return str_list