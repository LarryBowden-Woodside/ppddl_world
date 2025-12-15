def end_state_accepting_automaton_variable_definitions():
    
    str_list = []
    # Initialize the state of the end state accepting automaton. ONLY ONE.
    # array[STAGES] of var endStateAcceptAutomatonL : endStateAcceptAutomatonTraj;
    # array[endStateAcceptAutomatonTr, STAGES] of var bool: endStateAcceptAutomatonTrTraj;
    # var int: stageWhenAccepted;
    str_list.append(f"array[STAGES] of var endStateAcceptAutomatonL : endStateAcceptAutomatonTraj;")
    str_list.append(f"array[endStateAcceptAutomatonTr, STAGES] of var bool: endStateAcceptAutomatonTrTraj;")
    str_list.append(f"var int: stageWhenAccepted;")

    return str_list

def end_state_accepting_automaton_constraints(state_plan):
    
    str_list = []

    #### DYNAMICS CONSTRAINTS - VARY BASED ON STATE PLAN ####

    # maintenance constraint
    # predicate maintenanceConstraint(int : i) = true;
    str_list.append(f"predicate maintenanceConstraint(int : i) = {state_plan['end_state']['maintenance_constraint']};")
    
    # goal constraint
    # predicate goalConstraint(int : i) = compl[i+1]==compOff /\ connl[i+1]==disconnected /\ projl[i+1]==projOff /\ epAcceptAutomatonTraj[i+1]=epAccepted /\ temporalAcceptConstraint_2_Traj[i+1]==tempAccepted;
    # Iterate over episodal and temporal constraints
    ep_temporal_constraints = []
    
    for episode_name in state_plan['constraints']['episodes']:
        ep_temporal_constraints.append(f"epAcceptAutomatonTraj_{episode_name}[i+1]==epAccepted")
    for tc_name in state_plan['constraints']['temporal']:
        ep_temporal_constraints.append(f"temporalAcceptConstraint_Traj_{tc_name}[i+1]==tempAccepted")
        
    ep_temporal_str = ' /\\ '.join(ep_temporal_constraints)
    
    str_list.append(f"predicate goalConstraint(int : i) = {state_plan['end_state']['goal_constraint']}" + " /\\ " + ep_temporal_str + ";")

    #### STATIC CONSTRAINTS

    # % end state accepting automaton transitions
    # constraint forall(i in STAGESm1)(endStateAcceptAutomatonTrTraj[28,i] -> 
    # endStateAcceptAutomatonTraj[i]==waiting /\ endStateAcceptAutomatonTraj[i+1]==waiting /\ 
    # maintenanceConstraint(i) /\ (not goalConstraint(i)));

    str_list.append(f"constraint forall(i in STAGESm1)(endStateAcceptAutomatonTrTraj[28,i] -> endStateAcceptAutomatonTraj[i]==waiting /\\ endStateAcceptAutomatonTraj[i+1]==waiting /\\ maintenanceConstraint(i) /\\ (not goalConstraint(i)));")

    # constraint forall(i in STAGESm1)(endStateAcceptAutomatonTrTraj[29,i] -> 
    # endStateAcceptAutomatonTraj[i]==waiting /\ endStateAcceptAutomatonTraj[i+1]==accepted /\ stageWhenAccepted==i+1 /\
    # goalConstraint(i));
    
    str_list.append(f"constraint forall(i in STAGESm1)(endStateAcceptAutomatonTrTraj[29,i] -> endStateAcceptAutomatonTraj[i]==waiting /\\ endStateAcceptAutomatonTraj[i+1]==accepted /\\ stageWhenAccepted==i+1 /\\ goalConstraint(i));")
    
    # constraint forall(i in STAGESm1)(endStateAcceptAutomatonTrTraj[30,i] -> 
    # endStateAcceptAutomatonTraj[i]==waiting /\ endStateAcceptAutomatonTraj[i+1]==failed /\ 
    # (not maintenanceConstraint(i)) /\ (not goalConstraint(i)));
    
    str_list.append(f"constraint forall(i in STAGESm1)(endStateAcceptAutomatonTrTraj[30,i] -> endStateAcceptAutomatonTraj[i]==waiting /\\ endStateAcceptAutomatonTraj[i+1]==failed /\\ (not maintenanceConstraint(i)) /\\ (not goalConstraint(i)));")
    
    # constraint forall(i in STAGESm1)(endStateAcceptAutomatonTrTraj[31,i] -> 
    # endStateAcceptAutomatonTraj[i]==accepted /\ endStateAcceptAutomatonTraj[i+1]==accepted);
    
    str_list.append(f"constraint forall(i in STAGESm1)(endStateAcceptAutomatonTrTraj[31,i] -> endStateAcceptAutomatonTraj[i]==accepted /\\ endStateAcceptAutomatonTraj[i+1]==accepted);")
    
    # constraint forall(i in STAGESm1)(endStateAcceptAutomatonTrTraj[32,i] -> 
    # endStateAcceptAutomatonTraj[i]==failed /\ endStateAcceptAutomatonTraj[i+1]==failed);

    str_list.append(f"constraint forall(i in STAGESm1)(endStateAcceptAutomatonTrTraj[32,i] -> endStateAcceptAutomatonTraj[i]==failed /\\ endStateAcceptAutomatonTraj[i+1]==failed);")

    # % ensure that only one transition occurs in a given stage.
    # constraint forall(i in STAGES)(sum(t in endStateAcceptAutomatonTr)(endStateAcceptAutomatonTrTraj[t, i]) == 1);

    str_list.append(f"constraint forall(i in STAGES)(sum(t in endStateAcceptAutomatonTr)(endStateAcceptAutomatonTrTraj[t, i]) == 1);")

    return str_list