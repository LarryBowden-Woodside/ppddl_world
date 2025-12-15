# from typing import Union, Literal, Iterable, Dict
import os
import json

from accepting_automatons import end_state, episode, temporal_constraint


def generate_minizinc(system_config_file_path, experiment_config_file_path):
    print("Starting Minizinc generation")
    str_list = []
    
    # Read CTBurton system config parameters from the JSON
    with open(system_config_file_path, 'r') as file:
        system_config = json.load(file)
        
    transition_offset = system_config['transition_offset']
    end_state_AA = system_config['end_state_accepting_automaton']
    ep_AA = system_config['episode_accepting_automaton']
    temporal_constraint_AA = system_config['temporal_constraint_accepting_automaton']
    
    # Read experiment config parameters from the JSON
    with open(experiment_config_file_path, 'r') as file:
        experiment_config = json.load(file)
    
    Fupper = experiment_config['Fupper']
    h = experiment_config['h']
    automata_types = experiment_config['automata_types']
    instantiated_automata = experiment_config['instantiated_automata']
    tr = experiment_config['tr']
    transition_types = experiment_config['transition_types']
    transitions = experiment_config['transitions']
    automata_locations = experiment_config['automata_locations']
    automata_actions = experiment_config['automata_actions']
    
    # Read state plan data from the JSON
    state_plan_file_path = experiment_config['state_plan_file_path']
    with open(state_plan_file_path, 'r') as file:
        state_plan = json.load(file)
        
    print(state_plan)
        
    # TODO: Load the automaton graphs - out of scope

    # Add Fupper to the model string
    # float : Fupper = 25000;
    str_list.append(f"float : Fupper = {Fupper};")

    # Add horizon to the model string
    # int : h = 10;
    str_list.append(f"int : h = {h};")

    STAGES = "STAGES"
    STAGESm1 = "STAGESm1"
    STAGESp1 = "STAGESp1"
    
    str_list.append("")
    # Indices of stages only depends on h
    # set of int : STAGES = 0..h-1;
    # set of int : STAGESm1 = 0..h-2; % m1 = minus 1
    # set of int : STAGESp1 = 0..h;   % p1 = plus 1
    str_list.append(f"set of int : {STAGES} = 0..{h-1};")
    str_list.append(f"set of int : {STAGESm1} = 0..{h-2};")
    str_list.append(f"set of int : {STAGESp1} = 0..{h};")

    str_list.append("")
    # Load the types of automata
    # enum Automata = {comp, conn, proj};
    automata_list_string = ', '.join(automata_types)
    str_list.append("enum Automata = {" + automata_list_string + "};")

    str_list.append("")
    # Generate instances of the Automata in our planning problem.
    # set of Automata : AUTOMATA = {comp, conn, proj};
    instantiated_automata_string = ', '.join(instantiated_automata)
    str_list.append("set of Automata : AUTOMATA = {" + instantiated_automata_string + "};")

    str_list.append("")
    # For every automaton, the number of state changing transitions is the number of edges in the automaton graph. The number of idle transitions is the number of nodes in the automaton graph. Use this to compute the total number of transitions.
    # Generalizing automatons is out of scope
    # int : tr = 27;
    str_list.append(f"int : tr = {tr};")

    str_list.append("")
    # Start all automaton transition indices at 1001 to reserve the first 1000 indices for transitions of the special automata like end state accepting automatons.
    # set of int : TRANSITIONS = 1001..(1000 + tr);
    str_list.append(f"set of int : TRANSITIONS = {transition_offset + 1}..{transition_offset + tr};")

    # TODO: For every automaton, separate the transitions into idling transitions, clock resetting transitions.

    str_list.append("")
    # TODO: IDLING
    # set of int : TRANSITIONS_comp_idle = {5,6,7,8};
    # set of int : TRANSITIONS_conn_idle = {11,12};
    # set of int : TRANSITIONS_proj_idle = {21,22,23,24,25,26};
    # TODO: CLOCK RESETTING
    # set of int : TRANSITIONS_compc_reset = {1,2,3,4};
    # set of int : TRANSITIONS_connc_reset = {9,10};
    # set of int : TRANSITIONS_projc_reset = {13,14,15,16,17,18,19,20,27};
    
    def get_offset_string_transitions(numList, offset=0):
        return [str(item + offset) for item in numList]
    
    for transition_type in transition_types:
        for automaton in instantiated_automata:
            
            tr_list_string = ', '.join(get_offset_string_transitions(transitions[transition_type][automaton], transition_offset))
            
            str_list.append(f"set of int : TRANSITIONS_{automaton}_{transition_type} =" + "{" + tr_list_string + "};")
            
        str_list.append("")

    # Maintain another set of all the state changing transitions.
    # set of int : TRANSITIONS_state_changing = {1,2,3,4,9,10,13,14,15,16,17,18,19,20,27};
    state_changing_list_string = ', '.join(get_offset_string_transitions(transitions['state_changing'], transition_offset))
    str_list.append("set of int : TRANSITIONS_state_changing = {" + state_changing_list_string + "};")

    str_list.append("")
    # For every automaton, we define the location enum which is the set of possible locations of the automaton.
    # enum CompL = {compOn, compShutdown, compOff, compBooting};
    # enum ConnL = {connected, disconnected};
    # enum ProjL = {projWaiting, projConfirm, projOn, projCoolDown, projWarmUp, projOff};
    for automaton in instantiated_automata:
        automata_locations_list_string = ', '.join(automata_locations[automaton])
        str_list.append(f"enum {automaton}L =" + "{" + automata_locations_list_string + "};")

    str_list.append("")
    # For every automaton, we define an action enum that stores the set of possible actions that can be performed on the automaton.
    # enum CompU = {compTurnOn, compTurnOff};
    # enum ConnU = {connect, disconnect};
    # enum ProjU = {projTurnOn, projTurnOff};
    for automaton in instantiated_automata:
        automata_actions_list_string = ', '.join(automata_actions[automaton])
        str_list.append(f"enum {automaton}U =" + "{" + automata_actions_list_string + "};")

    str_list.append("")
    # For each automaton, we define the location variables for each stage
    # array[STAGES] of var CompL : compl;
    # array[STAGES] of var ConnL : connl;
    # array[STAGES] of var ProjL : projl;
    for automaton in instantiated_automata:
        str_list.append(f"array[{STAGES}] of var {automaton}L : {automaton}l;")

    str_list.append("")
    # For each automaton we define the command vars for all stages.
    # array[STAGES] of var CompU : compu;
    # array[STAGES] of var ConnU : connu;
    # array[STAGES] of var ProjU : proju;
    for automaton in instantiated_automata:
        str_list.append(f"array[{STAGES}] of var {automaton}U : {automaton}u;")

    str_list.append(""  )
    # End state accepting automaton locations and transitions. There's exactly one of these.
    # 28- waiting to waiting, 29 - waiting to accepted, 30 - waiting to failed, 31 - accepted to accepted, 32 - failed to failed.
    # set of int : endStateAcceptAutomatonTr = {28, 29, 30, 31, 32};
    # enum endStateAcceptAutomatonL = {waiting, accepted, failed};
    endstateAATr_list_string = ', '.join(get_offset_string_transitions(end_state_AA['transitions']))
    str_list.append("set of int : endStateAcceptAutomatonTr = {" + endstateAATr_list_string + "};")
    endstateAAL_list_string = ', '.join(end_state_AA['locations'])
    str_list.append("enum endStateAcceptAutomatonL = {" + endstateAAL_list_string + "};")

    str_list.append("")
    # Episode accepting automaton locations and transitions. There could multiple of these. 
    # set of int : epAcceptAutomatonTr = {33, 34, 35, 36, 37, 38, 39};
    # enum epAcceptAutomatonL = {epWaiting, epActive, epAccepted, epFailed};
    epAATr_list_string = ', '.join(get_offset_string_transitions(ep_AA['transitions']))
    str_list.append("set of int : epAcceptAutomatonTr = {" + epAATr_list_string + "};")
    epAAL_list_string = ', '.join(ep_AA['locations'])
    str_list.append("enum epAcceptAutomatonL = {" + epAAL_list_string + "};")

    str_list.append("")
    # Temporal constraint accepting automaton locations and transitions.
    # 41 - waiting to waiting, 42 - waiting to accepted, 43 - waiting to active, 44 - active to active, 45 - Active to Accepted, 46 - Accepted to Accepted.
    # set of int : temporalAcceptAutomatonTr = {41, 42, 43, 44, 45, 46};
    # enum tempAcceptAutomatonL = {tempWaiting, tempActive, tempAccepted};
    tempAATr_list_string = ', '.join(get_offset_string_transitions(temporal_constraint_AA['transitions']))
    str_list.append("set of int : temporalAcceptAutomatonTr = {" + tempAATr_list_string + "};")
    tempAAL_list_string = ', '.join(temporal_constraint_AA['locations'])
    str_list.append("enum tempAcceptAutomatonL = {" + tempAAL_list_string + "};")

    ## STATE PLAN INITIALIZATIONS
    
    str_list.append("")
    # End state accepting automaton initialization
    ESAA_variable_str = end_state.end_state_accepting_automaton_variable_definitions()
    str_list.extend(ESAA_variable_str)
    
    # For every episode, initialize the states of the episode accepting automaton and their relevant default constraints. Could be multiple depending on the state plan.
    for episode_name in state_plan['constraints']['episodes']:
        str_list.append("")
        
        episode_data = state_plan['constraints']['episodes'][episode_name]
        EPAA_variable_str = episode.episode_accepting_automaton_variable_definitions(episode_name, episode_data)
        str_list.extend(EPAA_variable_str)
    
    # For every temporal constraint, initialize the states of the temporal constraint accepting automaton and their relevant default constraints. Could be multiple depending on the number of temporal constraints in the state plan.
    for tc_name in state_plan['constraints']['temporal']:
        str_list.append("")

        tc_data = state_plan['constraints']['temporal'][tc_name]
        TCAA_variable_str = temporal_constraint.temporal_constraint_accepting_automaton_variable_definitions(tc_name, tc_data)
        str_list.extend(TCAA_variable_str)

    ##### GENERAL VARIABLE DECLARATIONS
    
    str_list.append("")
    # Events for all stages: forall 0<i<h, ei < ei+1
    # array[STAGESp1] of var float : e; 
    # constraint forall(i in STAGES)(e[i] < e[i+1]);
    # constraint forall(i in STAGESp1)(e[i]>=0 /\ e[i]<=Fupper); % Bound the variable to be positive
    str_list.append(f"array[{STAGESp1}] of var float : e;")
    str_list.append(f"constraint forall(i in {STAGES})(e[i] < e[i+1]);")
    str_list.append(f"constraint forall(i in {STAGESp1})(e[i]>=0 /\\ e[i]<=Fupper);")

    str_list.append("")
    # Clocks for all automata for all stages
    # clocks for all stages
    # array[AUTOMATA, STAGES] of var float : c;
    # constraint forall(a in AUTOMATA, i in STAGES)(c[a,i]>=0 /\ c[a,i]<=Fupper); % Bound the variable to be positive 
    str_list.append(f"array[AUTOMATA, STAGES] of var float : c;")
    str_list.append(f"constraint forall(a in AUTOMATA, i in STAGES)(c[a,i]>=0 /\\ c[a,i]<=Fupper);")

    str_list.append("")
    # Clock offsets for all automata for all stages
    # array[AUTOMATA, STAGESp1] of var float : co; 
    # constraint forall(a in AUTOMATA, i in STAGESp1)(co[a,i]>=0 /\ co[a,i]<=Fupper); % Bound the variable to be positive 
    str_list.append(f"array[AUTOMATA, {STAGESp1}] of var float : co;")
    str_list.append(f"constraint forall(a in AUTOMATA, i in {STAGESp1})(co[a,i]>=0 /\\ co[a,i]<=Fupper);")

    str_list.append("")
    # Constraint that clock is event time minus offset
    # constraint forall(a in AUTOMATA, i in STAGESm1)(c[a,i] = e[i+1] - co[a,i]); % encoding that c_j = e_{i}^{+} - c_{ij}
    str_list.append(f"constraint forall(a in AUTOMATA, i in {STAGESm1})(c[a,i] = e[i+1] - co[a,i]);")

    str_list.append("")
    # Clock parameters for all stages
    # array[AUTOMATA, STAGES] of var float : cl;
    # array[AUTOMATA, STAGES] of var float : cu;
    # constraint forall(a in AUTOMATA, i in STAGES)(cl[a,i]>=0 /\ cl[a,i]<=Fupper); % Bound the variable to be positive 
    # constraint forall(a in AUTOMATA, i in STAGES)(cu[a,i]>=0 /\ cu[a,i]<=Fupper); % Bound the variable to be positive 
    # constraint forall(a in AUTOMATA, i in STAGES)(cu[a,i]>=(cl[a,i]));
    str_list.append(f"array[AUTOMATA, {STAGES}] of var float : cl;")
    str_list.append(f"array[AUTOMATA, {STAGES}] of var float : cu;")
    str_list.append(f"constraint forall(a in AUTOMATA, i in STAGES)(cl[a,i]>=0 /\\ cl[a,i]<=Fupper);")
    str_list.append(f"constraint forall(a in AUTOMATA, i in STAGES)(cu[a,i]>=0 /\\ cu[a,i]<=Fupper);")
    str_list.append(f"constraint forall(a in AUTOMATA, i in STAGES)(cu[a,i]>=(cl[a,i]));")

    str_list.append("")
    # Open interval enablement
    # array[TRANSITIONS, STAGES] of var bool: Eno;
    str_list.append("array[TRANSITIONS, STAGES] of var bool: Eno;")

    # End interval enablement
    # array[TRANSITIONS, STAGES] of var bool: Ene;
    str_list.append("array[TRANSITIONS, STAGES] of var bool: Ene;")

    str_list.append("")
    # For each automaton, make the clock variables and parameters persist. 
    # constraint forall(i in STAGESm1)((forall([(not Ene[t, i]) | t in TRANSITIONS_compc_reset])) -> (co[comp,i]==co[comp,i+1]));
    # constraint forall(i in STAGESm1)((forall([(not Ene[t, i]) | t in TRANSITIONS_connc_reset])) -> (co[conn,i]==co[conn,i+1]));
    # constraint forall(i in STAGESm1)((forall([(not Ene[t, i]) | t in TRANSITIONS_projc_reset])) -> (co[proj,i]==co[proj,i+1]));
    for automaton in instantiated_automata:
        str_list.append(f"constraint forall(i in {STAGESm1})((forall([(not Ene[t, i]) | t in TRANSITIONS_{automaton}_reset])) -> (co[{automaton},i]==co[{automaton},i+1]));")

    str_list.append("")
    # For each automaton, add constraints that ensure deterministic execution
    # % Computer
    # constraint forall(i in STAGES)(sum([Eno[t, i] | t in TRANSITIONS_comp_idle]) = 1);
    # constraint forall(i in STAGES)(sum([Ene[t, i] | t in (TRANSITIONS_comp_idle union TRANSITIONS_compc_reset)]) = 1);
    # % Connection
    # constraint forall(i in STAGES)(sum([Eno[t, i] | t in TRANSITIONS_conn_idle]) = 1);
    # constraint forall(i in STAGES)(sum([Ene[t, i] | t in (TRANSITIONS_conn_idle union TRANSITIONS_connc_reset)]) = 1);
    # % Projector
    # constraint forall(i in STAGES)(sum([Eno[t, i] | t in TRANSITIONS_proj_idle]) = 1);
    # constraint forall(i in STAGES)(sum([Ene[t, i] | t in (TRANSITIONS_proj_idle union TRANSITIONS_projc_reset)]) = 1);
    for automaton in instantiated_automata:
        for transition_type in ["idle"]:
            str_list.append(f"constraint forall(i in STAGES)(sum([Eno[t, i] | t in TRANSITIONS_{automaton}_{transition_type}]) = 1);")
            str_list.append(f"constraint forall(i in STAGES)(sum([Ene[t, i] | t in (TRANSITIONS_{automaton}_{transition_type} union TRANSITIONS_{automaton}_reset)]) = 1);")
        
        str_list.append("")

    # Add constraints that ensure concise runs
    # constraint forall(i in STAGESm1)(exists([Ene[t,i] | t in TRANSITIONS_state_changing]) xor endStateAcceptAutomatonTraj[i]==accepted);
    str_list.append(f"constraint forall(i in {STAGESm1})(exists([Ene[t,i] | t in TRANSITIONS_state_changing]) xor endStateAcceptAutomatonTraj[i]==accepted);")

    str_list.append("")
    # TODO : Initial State Encoding
    # constraint compl[0]==compOff;
    # constraint connl[0]==disconnected;
    # constraint projl[0]==projOff;
    # constraint endStateAcceptAutomatonTraj[0]==waiting;
    for automaton in instantiated_automata:
        str_list.append(f"constraint {automaton}l[0]=={state_plan['initial_state'][automaton]};") 
    str_list.append(f"constraint endStateAcceptAutomatonTraj[0]==waiting;")

    str_list.append("")
    # Goal State Encoding
    # constraint exists(i in STAGES)(endStateAcceptAutomatonTraj[i]==accepted);
    str_list.append(f"constraint exists(i in {STAGES})(endStateAcceptAutomatonTraj[i]==accepted);")
    
    str_list.append("")
    # Add transition constraints for the end state accepting automaton
    ESAA_transition_constraints_str = end_state.end_state_accepting_automaton_constraints(state_plan)
    str_list.extend(ESAA_transition_constraints_str)
    
    # # Add transition constraints for EACH episode accepting automaton
    for episode_name in state_plan['constraints']['episodes']:
        str_list.append("")
        
        episode_data = state_plan['constraints']['episodes'][episode_name]
        EPAA_transition_constraints_str = episode.episode_accepting_automaton_constraints(episode_name, episode_data)
        str_list.extend(EPAA_transition_constraints_str)

    # Add transition constraints for EACH temporal constraint accepting automaton
    for tc_name in state_plan['constraints']['temporal']:
        str_list.append("")

        tc_data = state_plan['constraints']['temporal'][tc_name]
        TCAA_transition_constraints_str = temporal_constraint.temporal_constraint_accepting_automaton_constraints(tc_name, tc_data)
        str_list.extend(TCAA_transition_constraints_str)
    
    ### ------------------------------
    ##### HARDCODED CODE BELOW #######

    str_list.append("")
    HARCODED_STRING = """
% clock predicates
predicate inRange(var float: c, var float: l, var float: u) = 
    (c>l) /\ (c<u);
predicate inRangeWithEq(var float: c, var float: l, var float: u) = 
    (c>=l) /\ (c<=u);
predicate inOffsetRange(var float: eStart, var float: eEnd, var float: co, var float: l, var float: u) = 
    (eStart - co > l) /\ (eEnd - co < u); 
predicate lessThanUpper(var float: eStart, var float: eEnd, var float: co, var float: u) = 
    (eEnd - co <= u);
predicate inOffsetRangeWithEq(var float: eStart, var float: eEnd, var float: co, var float: l, var float: u) = 
    (eStart - co >= l) /\ (eEnd - co <= u);

% open interval of stage, idling transition, clock constraint
predicate openIdlingClock(array[Automata,int] of var float: c, 
                        array[Automata,int] of var float: l, 
                        array[Automata,int] of var float: u,
                        array[int] of var float: e,
                        array[Automata,int] of var float: co,
                        Automata: a, int: i) = 
            lessThanUpper(e[i], e[i+1], co[a,i], u[a,i]);
        
% predicate openIdlingClock(array[Automata,int] of var float: c, 
%                       array[Automata,int] of var float: l, 
%                       array[Automata,int] of var float: u,
%                       array[int] of var float: e,
%                       array[Automata,int] of var float: co, 
%                       Automata: a, int: i) = 
%           inOffsetRangeWithEq(e[i],e[i+1],co[a,i],l[a,i],u[a,i]); %% Shouldn't this just be lessThanUpper rather than inOffsetRangeWithEq

% end event of a stage, idling transition, clock constraint
predicate closeIdlingClock(array[Automata,int] of var float: c, 
                        array[Automata,int] of var float: l, 
                        array[Automata,int] of var float: u,
                        array[int] of var float: e,
                        array[Automata,int] of var float: co, 
                        Automata: a, int: i) = 
            lessThanUpper(e[i],e[i+1],co[a,i],u[a,i]);

% end event of a stage, state changing transition, clock constraint
predicate closeChangeClock(array[Automata,int] of var float: c, 
                        array[Automata,int] of var float: l,
                        array[Automata,int] of var float: u,
                        array[int] of var float: e,
                        array[Automata,int] of var float: co, 
                        Automata: a, int: i) = 
            inOffsetRangeWithEq(e[i],e[i+1],co[a,i],l[a,i],u[a,i]);

% "cvs" stands for clock variable reset
predicate cvs(array[int] of var float: e,
                array[Automata,int] of var float: co, 
                Automata: a,  int: i) = (co[a,i+1] == e[i+1]);

% "cps" stands for clock parameter reset
predicate cps(array[Automata,int] of var float: co,
                array[Automata,int] of var float: l,
                array[Automata,int] of var float: u,
                Automata: a,  int: i) = inRangeWithEq(co[a,i+1], l[a,i], u[a,i]);

% HARDCODED transition constraints for COMPUTER
constraint forall(i in STAGES)(not Eno[1,i]); % state changing
constraint forall(i in STAGES)(not Eno[2,i]); % state changing
constraint forall(i in STAGES)(not Eno[3,i]); % state changing
constraint forall(i in STAGES)(not Eno[4,i]); % state changing

constraint forall(i in STAGES)(Eno[5,i] -> compl[i]==compOn /\ openIdlingClock(c, cl, cu, e, co, comp, i)); % idling
constraint forall(i in STAGES)(Eno[6,i] -> compl[i]==compShutdown /\ openIdlingClock(c, cl, cu, e, co, comp, i)); % idling
constraint forall(i in STAGES)(Eno[7,i] -> compl[i]==compOff /\ openIdlingClock(c, cl, cu, e, co, comp, i)); % idling
constraint forall(i in STAGES)(Eno[8,i] -> compl[i]==compBooting /\ openIdlingClock(c, cl, cu, e, co, comp, i)); % idling

constraint forall(i in STAGESm1)(Ene[1,i] -> 
    compl[i]==compOn /\ compl[i+1]==compShutdown /\ 
    compu[i]==compTurnOff /\ 
    closeChangeClock(c, cl, cu, e, co, comp, i) /\ 
    cvs(e, co, comp, i) /\ cps(co, cl, cu, comp, i)); % state changing
constraint forall(i in STAGESm1)(Ene[2,i] -> 
    compl[i]==compShutdown /\ compl[i+1]==compOff /\ 
    c[comp,i]==30 /\ closeChangeClock(c, cl, cu, e, co, comp, i) /\ 
    cvs(e, co, comp, i) /\ cps(co, cl, cu, comp, i)); % state changing
constraint forall(i in STAGESm1)(Ene[3,i] ->
    compl[i]==compOff /\ compl[i+1]==compBooting /\ 
    compu[i]==compTurnOn /\ closeChangeClock(c, cl, cu, e, co, comp, i) /\ 
    cvs(e, co, comp, i) /\ cps(co, cl, cu, comp, i)); % state changing
constraint forall(i in STAGESm1)(Ene[4,i] ->
    compl[i]==compBooting /\ compl[i+1]==compOn /\ 
    c[comp,i]==15 /\ closeChangeClock(c, cl, cu, e, co, comp, i) /\ 
    cvs(e, co, comp, i) /\ cps(co, cl, cu, comp, i)); % state changing

constraint forall(i in STAGESm1)(Ene[5,i] ->
    compl[i]==compOn /\ compl[i+1]==compOn /\ compu[i]!=compTurnOff /\ 
    closeIdlingClock(c, cl, cu, e, co, comp, i) /\ 
    cps(co, cl, cu, comp, i)); % idling
constraint forall(i in STAGESm1)(Ene[6,i] ->
    compl[i]==compShutdown /\ compl[i+1]==compShutdown /\ 
    closeIdlingClock(c, cl, cu, e, co, comp, i) /\ 
    cps(co, cl, cu, comp, i)); % idling
constraint forall(i in STAGESm1)(Ene[7,i] ->
    compl[i]==compOff /\ compl[i+1]==compOff /\ compu[i]!=compTurnOn /\ 
    closeIdlingClock(c, cl, cu, e, co, comp, i)  /\ 
    cps(co, cl, cu, comp, i)); % idling
constraint forall(i in STAGESm1)(Ene[8,i] ->
    compl[i]==compBooting /\ compl[i+1]==compBooting /\ 
    closeIdlingClock(c, cl, cu, e, co, comp, i) /\ 
    cps(co, cl, cu, comp, i)); % idling

% HARDCODED transition constraints for CONNECTION
constraint forall(i in STAGES)(not Eno[9,i]); % state changing
constraint forall(i in STAGES)(not Eno[10,i]); % state changing

constraint forall(i in STAGES)(Eno[11,i] -> connl[i]==connected /\ openIdlingClock(c, cl, cu, e, co, conn, i)); % idling
constraint forall(i in STAGES)(Eno[12,i] -> connl[i]==disconnected /\ openIdlingClock(c, cl, cu, e, co, conn, i)); % idling

constraint forall(i in STAGESm1)(Ene[9,i] -> 
    connl[i]==connected /\ connl[i+1]==disconnected /\ 
    connu[i]==disconnect /\ 
    closeChangeClock(c, cl, cu, e, co, conn, i) /\ 
    cvs(e, co, conn, i) /\ cps(co, cl, cu, conn, i)); % state changing

constraint forall(i in STAGESm1)(Ene[10,i] ->
    connl[i]==disconnected /\ connl[i+1]==connected /\ 
    connu[i]==connect /\ compl[i]==compOff /\ 
    closeChangeClock(c, cl, cu, e, co, conn, i) /\ 
    cvs(e, co, conn, i) /\ cps(co, cl, cu, conn, i)); % state changing

constraint forall(i in STAGESm1)(Ene[11,i] -> 
    connl[i]==connected /\ connl[i+1]=connected /\ connu[i]!=disconnect /\ 
    closeIdlingClock(c, cl, cu, e, co, conn, i) /\ 
    cps(co, cl, cu, conn, i)); % idling

constraint forall(i in STAGESm1)(Ene[12,i] -> 
    connl[i]==disconnected /\ connl[i+1]=disconnected /\ connu[i]!=connect /\ 
    closeIdlingClock(c, cl, cu, e, co, conn, i) /\ 
    cps(co, cl, cu, conn, i)); % idling

% % HARDCODED transition constraints for PROJECTOR
constraint forall(i in STAGES)(not Eno[13,i]); % state changing
constraint forall(i in STAGES)(not Eno[14,i]); % state changing
constraint forall(i in STAGES)(not Eno[15,i]); % state changing
constraint forall(i in STAGES)(not Eno[16,i]); % state changing
constraint forall(i in STAGES)(not Eno[17,i]); % state changing
constraint forall(i in STAGES)(not Eno[18,i]); % state changing
constraint forall(i in STAGES)(not Eno[19,i]); % state changing
constraint forall(i in STAGES)(not Eno[20,i]); % state changing
constraint forall(i in STAGES)(not Eno[27,i]); % state changing
constraint forall(i in STAGES)(Eno[21,i] -> projl[i]==projOff /\ openIdlingClock(c, cl, cu, e, co, proj, i)); % idling
constraint forall(i in STAGES)(Eno[22,i] -> projl[i]==projWarmUp /\ openIdlingClock(c, cl, cu, e, co, proj, i)); % idling
constraint forall(i in STAGES)(Eno[23,i] -> projl[i]==projOn /\ openIdlingClock(c, cl, cu, e, co, proj, i)); % idling
constraint forall(i in STAGES)(Eno[24,i] -> projl[i]==projConfirm /\ openIdlingClock(c, cl, cu, e, co, proj, i)); % idling
constraint forall(i in STAGES)(Eno[25,i] -> projl[i]==projCoolDown /\ openIdlingClock(c, cl, cu, e, co, proj, i)); % idling
constraint forall(i in STAGES)(Eno[26,i] -> projl[i]==projWaiting /\ openIdlingClock(c, cl, cu, e, co, proj, i)); % idling

constraint forall(i in STAGESm1)(Ene[13,i] ->
    projl[i]==projOff /\ projl[i+1]==projWarmUp /\ 
    proju[i]==projTurnOn /\ closeChangeClock(c, cl, cu, e, co, proj, i) /\ 
    cvs(e, co, proj, i) /\ cps(co, cl, cu, proj, i)); % state changing

constraint forall(i in STAGESm1)(Ene[14,i] -> 
    projl[i]==projWarmUp /\ projl[i+1]==projOn /\ 
    c[proj,i] == 30 /\ closeChangeClock(c, cl, cu, e, co, proj, i) /\ 
    cvs(e, co, proj, i) /\ cps(co, cl, cu, proj, i)); % state changing

constraint forall(i in STAGESm1)(Ene[15,i] -> 
    projl[i]==projOn /\ projl[i+1]==projConfirm /\ 
    proju[i]==projTurnOff /\ closeChangeClock(c, cl, cu, e, co, proj, i) /\ 
    cvs(e, co, proj, i) /\ cps(co, cl, cu, proj, i)); % state changing

constraint forall(i in STAGESm1)(Ene[16,i] -> 
    projl[i]==projOn /\ projl[i+1]==projWaiting /\ 
    (compl[i]!=compOn \/ connl[i]!=connected) /\ proju[i]!=projTurnOff /\ 
    closeChangeClock(c, cl, cu, e, co, proj, i) /\ 
    cvs(e, co, proj, i) /\ cps(co, cl, cu, proj, i)); % state changing

constraint forall(i in STAGESm1)(Ene[17,i] -> 
    projl[i]==projConfirm /\ projl[i+1]==projCoolDown /\ 
    proju[i]==projTurnOff /\ inRange(c[proj,i],cl[proj,i],cu[proj,i]) /\ 
    closeChangeClock(c, cl, cu, e, co, proj, i) /\ 
    cvs(e, co, proj, i) /\ cps(co, cl, cu, proj, i)); % state changing

constraint forall(i in STAGESm1)(Ene[18,i] -> 
    projl[i]==projWaiting /\ projl[i+1]==projCoolDown /\ 
    (compl[i]!=compOn \/ connl[i]!=connected) /\ c[proj,i]==60 /\ 
    closeChangeClock(c, cl, cu, e, co, proj, i) /\ 
    cvs(e, co, proj, i) /\ cps(co, cl, cu, proj, i)); % state changing

constraint forall(i in STAGESm1)(Ene[19,i] -> 
    projl[i]==projWaiting /\ projl[i+1]==projOn /\ 
    compl[i]==compOn /\ connl[i]==connected /\ 
    closeChangeClock(c, cl, cu, e, co, proj, i) /\ 
    cvs(e, co, proj, i) /\ cps(co, cl, cu, proj, i)); % state changing

constraint forall(i in STAGESm1)(Ene[20,i] -> 
    projl[i]==projConfirm /\ projl[i+1]==projOn /\ 
    proju[i]!=projTurnOff /\ c[proj,i]==5 /\ 
    closeChangeClock(c, cl, cu, e, co, proj, i) /\ 
    cvs(e, co, proj, i) /\ cps(co, cl, cu, proj, i)); % state changing

constraint forall(i in STAGESm1)(Ene[27,i] -> 
    projl[i]==projCoolDown /\ projl[i+1]==projOff /\ 
    c[proj,i]==60 /\ 
    closeChangeClock(c, cl, cu, e, co, proj, i) /\ 
    cvs(e, co, proj, i) /\ cps(co, cl, cu, proj, i)); % state changing

constraint forall(i in STAGESm1)(Ene[21,i] -> 
    projl[i]==projOff /\ projl[i+1]==projOff /\ 
    proju[i]!=projTurnOn /\ 
    closeIdlingClock(c, cl, cu, e, co, proj, i) /\ 
    cps(co, cl, cu, proj, i)); % idling

constraint forall(i in STAGESm1)(Ene[22,i] -> 
    projl[i]==projWarmUp /\ projl[i+1]==projWarmUp /\ 
    closeIdlingClock(c, cl, cu, e, co, proj, i) /\ 
    cps(co, cl, cu, proj, i)); % idling

constraint forall(i in STAGESm1)(Ene[23,i] -> 
    projl[i]==projOn /\ projl[i+1]==projOn /\ compl[i+1]==compOn /\ connl[i+1]==connected /\ 
    closeIdlingClock(c, cl, cu, e, co, proj, i) /\ 
    cps(co, cl, cu, proj, i)); % idling

constraint forall(i in STAGESm1)(Ene[24,i] -> 
    projl[i]==projConfirm /\ projl[i+1]=projConfirm /\ 
    closeIdlingClock(c, cl, cu, e, co, proj, i) /\ 
    cps(co, cl, cu, proj, i)); % idling

constraint forall(i in STAGESm1)(Ene[25,i] -> 
    projl[i]==projCoolDown /\ projl[i+1]==projCoolDown /\ 
    closeIdlingClock(c, cl, cu, e, co, proj, i) /\ 
    cps(co, cl, cu, proj, i)); % idling

constraint forall(i in STAGESm1)(Ene[26,i] -> 
    projl[i]==projWaiting /\ projl[i+1]==projWaiting /\ 
    closeIdlingClock(c, cl, cu, e, co, proj, i) /\ 
    cps(co, cl, cu, proj, i)); % idling
    
    """

    str_list.append(HARCODED_STRING)

    #### ------------------------------
    #### HARDCODED CODE ENDS HERE ####
    
    

    # var float: totalCost = sum(i in STAGES)(sum(t in (TRANSITIONS_comp_idle union TRANSITIONS_conn_idle union TRANSITIONS_proj_idle))(Eno[t,i] * 1 * floor(e[i+1]-e[i])) + sum(t in TRANSITIONS_state_changing)(Ene[t,i])); % throws error - MLTP Cost - likely because gecode doesn't like floats

    # var float: totalCost = sum(i in STAGES)(sum(t in TRANSITIONS_state_changing)(1 * Ene[t,i])); % TOP cost

    # Define cost
    # var float: totalCost = e[h];
    str_list.append("var float: totalCost = e[h];")
    
    str_list.append("")
    # SOLVE THE PROBLEM
    # solve minimize totalCost;
    str_list.append("solve minimize totalCost;")

    # % output ["Total Cost: ", show(totalCost)];
    # % solve satisfy;
    
    full_model_str = "\n".join(str_list)

    return full_model_str