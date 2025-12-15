% Use this editor as a MiniZinc scratch book
% ADJUSTABLE Parameter for float upper limit

float : Fupper = 25000;
% ADJUSTABLE Parameter for horizon
int : h = 10; 
% stage numbering
set of int : STAGES = 0..h-1;
set of int : STAGESm1 = 0..h-2; % m1 = minus 1
set of int : STAGESp1 = 0..h;   % p1 = plus 1pyya

% HARDCODED Parameter for number of transitions
int : tr = 27;
% HARDCODED transition numbering
set of int : TRANSITIONS = 1..tr;

set of int : TRANSITIONS_comp_idle = {5,6,7,8};
set of int : TRANSITIONS_conn_idle = {11,12};
set of int : TRANSITIONS_proj_idle = {21,22,23,24,25,26};

set of int : TRANSITIONS_compc_reset = {1,2,3,4};
set of int : TRANSITIONS_connc_reset = {9,10};
set of int : TRANSITIONS_projc_reset = {13,14,15,16,17,18,19,20,27};
set of int : TRANSITIONS_state_changing = {1,2,3,4,9,10,13,14,15,16,17,18,19,20,27};

% HARDCODED Automaton enum types
% Note: There is an explicit enum for each location and control variable
%       because you cannot mix enums (create unions of enums)
enum CompL = {compOn, compShutdown, compOff, compBooting};
enum ConnL = {connected, disconnected};
enum ProjL = {projWaiting, projConfirm, projOn, projCoolDown, projWarmUp, projOff};
enum CompU = {compTurnOn, compTurnOff};
enum ConnU = {connect, disconnect};
enum ProjU = {projTurnOn, projTurnOff};

% End state accepting automaton.
% 28- waiting to waiting, 29 - waiting to accepted, 30 - waiting to failed, 31 - accepted to accepted, 32 - failed to failed.
set of int : endStateAcceptAutomatonTr = {28, 29, 30, 31, 32};
enum endStateAcceptAutomatonL = {waiting, accepted, failed};

% proj=On episode accepting automaton
% 33 - waiting to waiting, 34 - accepted to accepted, 35 - failed to failed, 36 - waiting to active, 37 - active to active, 38 - active to accepted, 39 - active to failed, WAITING TO FAILED?
set of int : epAcceptAutomatonTr = {33, 34, 35, 36, 37, 38, 39};
enum epAcceptAutomatonL = {epWaiting, epActive, epAccepted, epFailed};

% temporal constraint accepting automaton
% 41 - waiting to waiting, 42 - waiting to accepted, 43 - waiting to active, 44 - active to active, 45 - Active to Accepted, 46 - Accepted to Accepted.
set of int : temporalAcceptAutomatonTr = {41, 42, 43, 44, 45, 46};
enum tempAcceptAutomatonL = {tempWaiting, tempActive, tempAccepted};

%% STATE PLAN INITIALIZATIONS 

array[STAGES] of var endStateAcceptAutomatonL : endStateAcceptAutomatonTraj;
array[endStateAcceptAutomatonTr, STAGES] of var bool: endStateAcceptAutomatonTrTraj;
var int: stageWhenAccepted;

array[STAGES] of var epAcceptAutomatonL : epAcceptAutomatonTraj;
array[epAcceptAutomatonTr, STAGES] of var bool: epAcceptAutomatonTrTraj;

var int : epAcceptStartEvent;
var int : epAcceptEndEvent;
var float : epAcceptClockWhenStart;
var float : epAcceptClockWhenEnd;
var float : epAcceptClockParameter;

constraint epAcceptStartEvent >=0 /\ epAcceptStartEvent <= h;
constraint epAcceptEndEvent >=0 /\ epAcceptEndEvent <= h;
constraint epAcceptClockWhenStart >= 0 /\ epAcceptClockWhenStart<=Fupper;
constraint epAcceptClockWhenEnd >= 0 /\ epAcceptClockWhenEnd<=Fupper;
constraint epAcceptClockParameter >= 0 /\ epAcceptClockParameter<=Fupper;

%%%%%% TEMPORAL CONSTRAINT ACCEPTING AUTOMATON
% second [600, 600] constraint
array[STAGES] of var tempAcceptAutomatonL : temporalAcceptConstraint_2_Traj;
array[temporalAcceptAutomatonTr, STAGES] of var bool : temporalAcceptConstraint_2_TrTraj;

var int : temporalAcceptConstraint_2_event1;
var int : temporalAcceptConstraint_2_event2;
var float : temporalAcceptConstraint_2_event1Clock;
var float : temporalAcceptConstraint_2_event2Clock;
var float : temporalAcceptConstraint_2_ClockWhenActivated;
var float : temporalAcceptConstraint_2_ClockWhenAccepted;
var float : temporalAcceptConstraint_2_ClockParameter;

constraint temporalAcceptConstraint_2_event1>=0 /\ temporalAcceptConstraint_2_event1<=h;
constraint temporalAcceptConstraint_2_event2>=0 /\ temporalAcceptConstraint_2_event2<=h;
constraint temporalAcceptConstraint_2_event1Clock>=0 /\ temporalAcceptConstraint_2_event1Clock<=Fupper;
constraint temporalAcceptConstraint_2_event2Clock>=0 /\ temporalAcceptConstraint_2_event2Clock<=Fupper;
constraint temporalAcceptConstraint_2_ClockWhenActivated>=0 /\ temporalAcceptConstraint_2_ClockWhenActivated<=Fupper;
constraint temporalAcceptConstraint_2_ClockWhenAccepted>=0 /\ temporalAcceptConstraint_2_ClockWhenAccepted<=Fupper;
constraint temporalAcceptConstraint_2_ClockParameter>=0 /\ temporalAcceptConstraint_2_ClockParameter<=Fupper;

%%%% Starting state constraints
% if e1=e2=e0
predicate startingConstraint1() = temporalAcceptConstraint_2_event1==temporalAcceptConstraint_2_event2 /\ temporalAcceptConstraint_2_event2==0;
constraint (startingConstraint1())->(temporalAcceptConstraint_2_Traj[0]==tempAccepted /\ temporalAcceptConstraint_2_ClockWhenActivated==e[0] /\ temporalAcceptConstraint_2_ClockWhenAccepted==e[0] /\ temporalAcceptConstraint_2_event1Clock==e[0] /\ temporalAcceptConstraint_2_event2Clock==e[0] /\ temporalAcceptConstraint_2_acceptingEvent1(0) /\ temporalAcceptConstraint_2_acceptingEvent2(0));
% if e1=e0!=e2
predicate startingConstraint2() = temporalAcceptConstraint_2_event1==0 /\ 0!=temporalAcceptConstraint_2_event2;
constraint (startingConstraint2())->(temporalAcceptConstraint_2_Traj[0]==tempActive /\ temporalAcceptConstraint_2_ClockParameter<=temporalAcceptConstraint_2_upperBound /\ temporalAcceptConstraint_2_event1Clock==e[0] /\ temporalAcceptConstraint_2_ClockWhenActivated==e[0] /\ temporalAcceptConstraint_2_acceptingEvent1(0));
% if e2=e0!=e1
predicate startingConstraint3() =  temporalAcceptConstraint_2_event2==0 /\ 0!=temporalAcceptConstraint_2_event1;
constraint (startingConstraint3())->(temporalAcceptConstraint_2_Traj[0]==tempActive /\ temporalAcceptConstraint_2_ClockParameter<=(-1 * temporalAcceptConstraint_2_lowerBound) /\ temporalAcceptConstraint_2_event2Clock==e[0] /\ temporalAcceptConstraint_2_ClockWhenActivated==e[0] /\ temporalAcceptConstraint_2_acceptingEvent2(0));
% else e1!=e2!=e0
constraint (not (startingConstraint1() \/ startingConstraint2() \/ startingConstraint3()))->(temporalAcceptConstraint_2_Traj[0]==tempWaiting);

%%%%% Parameter constraints
constraint abs(temporalAcceptConstraint_2_event2Clock - temporalAcceptConstraint_2_event1Clock)==temporalAcceptConstraint_2_ClockParameter;
constraint temporalAcceptConstraint_2_ClockWhenAccepted - temporalAcceptConstraint_2_ClockWhenActivated == temporalAcceptConstraint_2_ClockParameter;

%% VARIABLE DEFINITIONS

% events for all stages: forall 0<i<h, ei < ei+1
array[STAGESp1] of var float : e; 
constraint forall(i in STAGES)(e[i] < e[i+1]);
constraint forall(i in STAGESp1)(e[i]>=0 /\ e[i]<=Fupper); % Bound the variable to be positive

% clocks for all stages
array[AUTOMATA, STAGES] of var float : c;
constraint forall(a in AUTOMATA, i in STAGES)(c[a,i]>=0 /\ c[a,i]<=Fupper); % Bound the variable to be positive 

% clock offsets for all stages
array[AUTOMATA, STAGESp1] of var float : co; 
constraint forall(a in AUTOMATA, i in STAGESp1)(co[a,i]>=0 /\ co[a,i]<=Fupper); % Bound the variable to be positive 

constraint forall(a in AUTOMATA, i in STAGESm1)(c[a,i] = e[i+1] - co[a,i]); % encoding that c_j = e_{i}^{+} - c_{ij}

% clock parameters for all stages
array[AUTOMATA, STAGES] of var float : cl;
array[AUTOMATA, STAGES] of var float : cu;
constraint forall(a in AUTOMATA, i in STAGES)(cl[a,i]>=0 /\ cl[a,i]<=Fupper); % Bound the variable to be positive 
constraint forall(a in AUTOMATA, i in STAGES)(cu[a,i]>=0 /\ cu[a,i]<=Fupper); % Bound the variable to be positive 
constraint forall(a in AUTOMATA, i in STAGES)(cu[a,i]>=(cl[a,i]));

%%%%%%% END STATE ACCEPTING AUTOMATON

predicate maintenanceConstraint(int: i) = true;
predicate goalConstraint(int : i) = comp1l[i+1]==compOff /\ conn1l[i+1]==disconnected /\ proj1l[i+1]==projOff /\ 
                         epAcceptAutomatonTraj[i+1]=epAccepted /\ temporalAcceptConstraint_2_Traj[i+1]==tempAccepted;

% end state accepting automaton transitions
constraint forall(i in STAGESm1)(endStateAcceptAutomatonTrTraj[28,i] -> 
  endStateAcceptAutomatonTraj[i]==waiting /\ endStateAcceptAutomatonTraj[i+1]==waiting /\ 
  maintenanceConstraint(i) /\ (not goalConstraint(i)));

constraint forall(i in STAGESm1)(endStateAcceptAutomatonTrTraj[29,i] -> 
  endStateAcceptAutomatonTraj[i]==waiting /\ endStateAcceptAutomatonTraj[i+1]==accepted /\ stageWhenAccepted==i+1 /\
  goalConstraint(i));
  
constraint forall(i in STAGESm1)(endStateAcceptAutomatonTrTraj[30,i] -> 
  endStateAcceptAutomatonTraj[i]==waiting /\ endStateAcceptAutomatonTraj[i+1]==failed /\ 
  (not maintenanceConstraint(i)) /\ (not goalConstraint(i)));
  
constraint forall(i in STAGESm1)(endStateAcceptAutomatonTrTraj[31,i] -> 
  endStateAcceptAutomatonTraj[i]==accepted /\ endStateAcceptAutomatonTraj[i+1]==accepted);
  
constraint forall(i in STAGESm1)(endStateAcceptAutomatonTrTraj[32,i] -> 
  endStateAcceptAutomatonTraj[i]==failed /\ endStateAcceptAutomatonTraj[i+1]==failed);

% ensure that only one transition occurs in a given stage.
constraint forall(i in STAGES)(sum(t in endStateAcceptAutomatonTr)(endStateAcceptAutomatonTrTraj[t, i]) == 1);

%%%%%% EPISODE ACCEPTING AUTOMATON
predicate epAcceptAcceptingConstraint(int : i) = proj1l[i]==projOn;
predicate epAcceptStateConstraint(int : i) = proj1l[i]==projOn;

% Upper and lower bounds on epAcceptClockParameter
float : epAcceptLowerBound=1800;
float : epAcceptUpperBound=1800;

constraint epAcceptClockParameter >= epAcceptLowerBound /\ epAcceptClockParameter <= epAcceptUpperBound;

% Parameter constraints
constraint (epAcceptClockWhenEnd - epAcceptClockWhenStart)==epAcceptClockParameter;

% initial state of the episode accepting automaton
constraint (proj1l[0]==projOn)->(epAcceptAutomatonTraj[0]==epActive);
constraint (proj1l[0]!=projOn)->(epAcceptAutomatonTraj[0]==epWaiting);

% 33 - waiting to waiting
constraint forall(i in STAGESm1)(epAcceptAutomatonTrTraj[33,i] -> 
  epAcceptAutomatonTraj[i]==epWaiting /\ epAcceptAutomatonTraj[i+1]==epWaiting /\ 
  not epAcceptAcceptingConstraint(i));

% 34 - accepted to accepted
constraint forall(i in STAGESm1)(epAcceptAutomatonTrTraj[34,i] -> 
  epAcceptAutomatonTraj[i]==epAccepted /\ epAcceptAutomatonTraj[i+1]==epAccepted);
  
% 35 - failed to failed
constraint forall(i in STAGESm1)(epAcceptAutomatonTrTraj[35,i] -> 
  epAcceptAutomatonTraj[i]==epFailed /\ epAcceptAutomatonTraj[i+1]==epFailed);

% 36 - waiting to active
constraint forall(i in STAGESm1)(epAcceptAutomatonTrTraj[36,i] -> 
  epAcceptAutomatonTraj[i]==epWaiting /\ epAcceptAutomatonTraj[i+1]==epActive /\
  epAcceptAcceptingConstraint(i) /\ epAcceptStartEvent==(i+1) /\ epAcceptClockWhenStart==e[i+1]);

% 37 - active to active
constraint forall(i in STAGESm1)(epAcceptAutomatonTrTraj[37,i] -> 
  epAcceptAutomatonTraj[i]==epActive /\ epAcceptAutomatonTraj[i+1]==epActive /\ 
  epAcceptStateConstraint(i) /\ (e[i+1] - epAcceptClockWhenStart < epAcceptClockParameter));

% 38 - active to accepted
constraint forall(i in STAGESm1)(epAcceptAutomatonTrTraj[38,i] -> 
  epAcceptAutomatonTraj[i]==epActive /\ epAcceptAutomatonTraj[i+1]==epAccepted /\
  epAcceptStateConstraint(i) /\ (e[i+1] - epAcceptClockWhenStart >= epAcceptClockParameter) /\ epAcceptEndEvent==(i+1) /\ epAcceptClockWhenEnd==e[i+1]) ;

% 39 - active to failed
constraint forall(i in STAGESm1)(epAcceptAutomatonTrTraj[39,i] -> 
  epAcceptAutomatonTraj[i]==epActive /\ epAcceptAutomatonTraj[i+1]==epFailed /\ 
  not epAcceptStateConstraint(i));

% ensure that only one transition occurs in a given stage.
constraint forall(i in STAGES)(sum(t in epAcceptAutomatonTr)(epAcceptAutomatonTrTraj[t, i]) == 1);

%%%% Transition constraints
% 41 - waiting to waiting, 42 - waiting to accepted, 43 - waiting to active, 44 - active to active, 45 - active to accepted, 46 - accepted to accepted.

predicate temporalAcceptConstraint_2_acceptingEvent1(int : i) = proj1l[i]==projOn /\ proj1l[i+1]==projConfirm;
predicate temporalAcceptConstraint_2_acceptingEvent2(int : i) = proj1l[i+1]==projOff /\ conn1l[i+1]==disconnected /\ comp1l[i+1]=compOff /\ temporalAcceptConstraint_2_Traj[i]==tempActive;

float : temporalAcceptConstraint_2_lowerBound=600;
float : temporalAcceptConstraint_2_upperBound=600;

% Upper and Lower bounds on the clock parameter
constraint temporalAcceptConstraint_2_ClockParameter >= temporalAcceptConstraint_2_lowerBound /\
           temporalAcceptConstraint_2_ClockParameter <= temporalAcceptConstraint_2_upperBound;

% 41 - waiting to waiting
constraint forall(i in STAGESm1)(temporalAcceptConstraint_2_TrTraj[41,i] -> 
  temporalAcceptConstraint_2_Traj[i]==tempWaiting /\ temporalAcceptConstraint_2_Traj[i+1]==tempWaiting /\ 
  not temporalAcceptConstraint_2_acceptingEvent1(i) /\ not temporalAcceptConstraint_2_acceptingEvent2(i));

% 42 - waiting to accepted
constraint forall(i in STAGESm1)(temporalAcceptConstraint_2_TrTraj[42,i] -> 
  temporalAcceptConstraint_2_Traj[i]==tempWaiting /\ temporalAcceptConstraint_2_Traj[i+1]==tempAccepted /\ 
  temporalAcceptConstraint_2_acceptingEvent1(i) /\ temporalAcceptConstraint_2_acceptingEvent2(i) /\
  temporalAcceptConstraint_2_event1==i+1 /\ temporalAcceptConstraint_2_event2==i+1 /\ 
  temporalAcceptConstraint_2_event1Clock==e[i+1] /\ temporalAcceptConstraint_2_event2Clock==e[i+1]);

% 43 - waiting to active
predicate e1BeforeE2(int: i) = temporalAcceptConstraint_2_Traj[i]==tempWaiting /\ temporalAcceptConstraint_2_Traj[i+1]==tempActive /\ temporalAcceptConstraint_2_acceptingEvent1(i) /\ not temporalAcceptConstraint_2_acceptingEvent2(i) /\ temporalAcceptConstraint_2_event1Clock==e[i+1] /\ temporalAcceptConstraint_2_event1==i+1 /\ temporalAcceptConstraint_2_ClockWhenActivated==e[i+1] /\ temporalAcceptConstraint_2_ClockParameter <= temporalAcceptConstraint_2_upperBound /\ temporalAcceptConstraint_2_event1Clock <= temporalAcceptConstraint_2_event2Clock;

predicate e2BeforeE1(int: i) = temporalAcceptConstraint_2_Traj[i]==tempWaiting /\ temporalAcceptConstraint_2_Traj[i+1]==tempActive /\ not temporalAcceptConstraint_2_acceptingEvent1(i) /\ temporalAcceptConstraint_2_acceptingEvent2(i) /\ temporalAcceptConstraint_2_event2Clock==e[i+1] /\ temporalAcceptConstraint_2_event2==i+1 /\ temporalAcceptConstraint_2_event2Clock <= temporalAcceptConstraint_2_event1Clock /\ temporalAcceptConstraint_2_ClockWhenActivated==e[i+1] /\ temporalAcceptConstraint_2_ClockParameter<=(-1 * temporalAcceptConstraint_2_lowerBound);

constraint forall(i in STAGESm1)(temporalAcceptConstraint_2_TrTraj[43,i] -> (e1BeforeE2(i) \/ e2BeforeE1(i)));

% 44 - active to active
constraint forall(i in STAGESm1)(temporalAcceptConstraint_2_TrTraj[44,i] -> 
  temporalAcceptConstraint_2_Traj[i]==tempActive /\ temporalAcceptConstraint_2_Traj[i+1]==tempActive /\ 
  e[i+1]-temporalAcceptConstraint_2_ClockWhenActivated < temporalAcceptConstraint_2_ClockParameter);

% 45 - active to accepted
predicate endsOnE2(int: i) = temporalAcceptConstraint_2_Traj[i]==tempActive /\ temporalAcceptConstraint_2_Traj[i+1]==tempAccepted /\ 
  (e[i+1]-temporalAcceptConstraint_2_ClockWhenActivated) >= temporalAcceptConstraint_2_ClockParameter /\ 
  temporalAcceptConstraint_2_event1Clock < temporalAcceptConstraint_2_event2Clock /\ temporalAcceptConstraint_2_event2==i+1 /\ 
  temporalAcceptConstraint_2_acceptingEvent2(i);

predicate endsOnE1(int: i) = temporalAcceptConstraint_2_Traj[i]==tempActive /\ temporalAcceptConstraint_2_Traj[i+1]==tempAccepted /\ 
  (e[i+1]-temporalAcceptConstraint_2_ClockWhenActivated) >= temporalAcceptConstraint_2_ClockParameter /\ 
  temporalAcceptConstraint_2_event2Clock < temporalAcceptConstraint_2_event1Clock /\ temporalAcceptConstraint_2_event1==i+1 /\    temporalAcceptConstraint_2_acceptingEvent1(i);

constraint forall(i in STAGESm1)(temporalAcceptConstraint_2_TrTraj[45,i] -> (endsOnE2(i) \/ endsOnE1(i)));

% 46 - accepted to accepted
constraint forall(i in STAGESm1)(temporalAcceptConstraint_2_TrTraj[46,i] -> 
  (temporalAcceptConstraint_2_Traj[i]==tempAccepted /\ temporalAcceptConstraint_2_Traj[i+1]==tempAccepted));

% ensure that only one transition occurs in a given stage.
constraint forall(i in STAGES)(sum(t in temporalAcceptAutomatonTr)(temporalAcceptConstraint_2_TrTraj[t, i]) == 1);

%%%%% HARDCODED BELOW

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

% HARDCODED Parameter for number of automata
enum Automata = {comp1, conn1, proj1, comp2, conn2, proj2, comp3, conn3, proj3, comp4, conn4, proj4, comp5, conn5, proj5, comp6, conn6, proj6, comp7, conn7, proj7, comp8, conn8, proj8};
set of Automata : AUTOMATA = {comp1, conn1, proj1, comp2, conn2, proj2, comp3, conn3, proj3, comp4, conn4, proj4, comp5, conn5, proj5, comp6, conn6, proj6, comp7, conn7, proj7, comp8, conn8, proj8};

% Open interval enablement
array[TRANSITIONS, STAGES] of var bool: Eno1;
array[TRANSITIONS, STAGES] of var bool: Eno2;
array[TRANSITIONS, STAGES] of var bool: Eno3;
array[TRANSITIONS, STAGES] of var bool: Eno4;
array[TRANSITIONS, STAGES] of var bool: Eno5;
array[TRANSITIONS, STAGES] of var bool: Eno6;
array[TRANSITIONS, STAGES] of var bool: Eno7;
array[TRANSITIONS, STAGES] of var bool: Eno8;

% End interval enablement
array[TRANSITIONS, STAGES] of var bool: Ene1;
array[TRANSITIONS, STAGES] of var bool: Ene2;
array[TRANSITIONS, STAGES] of var bool: Ene3;
array[TRANSITIONS, STAGES] of var bool: Ene4;
array[TRANSITIONS, STAGES] of var bool: Ene5;
array[TRANSITIONS, STAGES] of var bool: Ene6;
array[TRANSITIONS, STAGES] of var bool: Ene7;
array[TRANSITIONS, STAGES] of var bool: Ene8;

% Making clock variables and parameters persist 
constraint forall(i in STAGESm1)((forall([(not Ene1[t, i]) | t in TRANSITIONS_compc_reset])) -> (co[comp1,i]==co[comp1,i+1]));
constraint forall(i in STAGESm1)((forall([(not Ene1[t, i]) | t in TRANSITIONS_connc_reset])) -> (co[conn1,i]==co[conn1,i+1]));
constraint forall(i in STAGESm1)((forall([(not Ene1[t, i]) | t in TRANSITIONS_projc_reset])) -> (co[proj1,i]==co[proj1,i+1]));

constraint forall(i in STAGESm1)((forall([(not Ene2[t, i]) | t in TRANSITIONS_compc_reset])) -> (co[comp2,i]==co[comp2,i+1]));
constraint forall(i in STAGESm1)((forall([(not Ene2[t, i]) | t in TRANSITIONS_connc_reset])) -> (co[conn2,i]==co[conn2,i+1]));
constraint forall(i in STAGESm1)((forall([(not Ene2[t, i]) | t in TRANSITIONS_projc_reset])) -> (co[proj2,i]==co[proj2,i+1]));

constraint forall(i in STAGESm1)((forall([(not Ene3[t, i]) | t in TRANSITIONS_compc_reset])) -> (co[comp3,i]==co[comp3,i+1]));
constraint forall(i in STAGESm1)((forall([(not Ene3[t, i]) | t in TRANSITIONS_connc_reset])) -> (co[conn3,i]==co[conn3,i+1]));
constraint forall(i in STAGESm1)((forall([(not Ene3[t, i]) | t in TRANSITIONS_projc_reset])) -> (co[proj3,i]==co[proj3,i+1]));

constraint forall(i in STAGESm1)((forall([(not Ene4[t, i]) | t in TRANSITIONS_compc_reset])) -> (co[comp4,i]==co[comp4,i+1]));
constraint forall(i in STAGESm1)((forall([(not Ene4[t, i]) | t in TRANSITIONS_connc_reset])) -> (co[conn4,i]==co[conn4,i+1]));
constraint forall(i in STAGESm1)((forall([(not Ene4[t, i]) | t in TRANSITIONS_projc_reset])) -> (co[proj4,i]==co[proj4,i+1]));

constraint forall(i in STAGESm1)((forall([(not Ene5[t, i]) | t in TRANSITIONS_compc_reset])) -> (co[comp5,i]==co[comp5,i+1]));
constraint forall(i in STAGESm1)((forall([(not Ene5[t, i]) | t in TRANSITIONS_connc_reset])) -> (co[conn5,i]==co[conn5,i+1]));
constraint forall(i in STAGESm1)((forall([(not Ene5[t, i]) | t in TRANSITIONS_projc_reset])) -> (co[proj5,i]==co[proj5,i+1]));

constraint forall(i in STAGESm1)((forall([(not Ene6[t, i]) | t in TRANSITIONS_compc_reset])) -> (co[comp6,i]==co[comp6,i+1]));
constraint forall(i in STAGESm1)((forall([(not Ene6[t, i]) | t in TRANSITIONS_connc_reset])) -> (co[conn6,i]==co[conn6,i+1]));
constraint forall(i in STAGESm1)((forall([(not Ene6[t, i]) | t in TRANSITIONS_projc_reset])) -> (co[proj6,i]==co[proj6,i+1]));

constraint forall(i in STAGESm1)((forall([(not Ene7[t, i]) | t in TRANSITIONS_compc_reset])) -> (co[comp7,i]==co[comp7,i+1]));
constraint forall(i in STAGESm1)((forall([(not Ene7[t, i]) | t in TRANSITIONS_connc_reset])) -> (co[conn7,i]==co[conn7,i+1]));
constraint forall(i in STAGESm1)((forall([(not Ene7[t, i]) | t in TRANSITIONS_projc_reset])) -> (co[proj7,i]==co[proj7,i+1]));

constraint forall(i in STAGESm1)((forall([(not Ene8[t, i]) | t in TRANSITIONS_compc_reset])) -> (co[comp8,i]==co[comp8,i+1]));
constraint forall(i in STAGESm1)((forall([(not Ene8[t, i]) | t in TRANSITIONS_connc_reset])) -> (co[conn8,i]==co[conn8,i+1]));
constraint forall(i in STAGESm1)((forall([(not Ene8[t, i]) | t in TRANSITIONS_projc_reset])) -> (co[proj8,i]==co[proj8,i+1]));

% Constraints that Ensure Deterministic Execution
% Computer1
constraint forall(i in STAGES)(sum([Eno1[t, i] | t in TRANSITIONS_comp_idle]) = 1);
constraint forall(i in STAGES)(sum([Ene1[t, i] | t in (TRANSITIONS_comp_idle union TRANSITIONS_compc_reset)]) = 1);
% Connection1
constraint forall(i in STAGES)(sum([Eno1[t, i] | t in TRANSITIONS_conn_idle]) = 1);
constraint forall(i in STAGES)(sum([Ene1[t, i] | t in (TRANSITIONS_conn_idle union TRANSITIONS_connc_reset)]) = 1);
% Projector1
constraint forall(i in STAGES)(sum([Eno1[t, i] | t in TRANSITIONS_proj_idle]) = 1);
constraint forall(i in STAGES)(sum([Ene1[t, i] | t in (TRANSITIONS_proj_idle union TRANSITIONS_projc_reset)]) = 1);

% Computer2
constraint forall(i in STAGES)(sum([Eno2[t, i] | t in TRANSITIONS_comp_idle]) = 1);
constraint forall(i in STAGES)(sum([Ene2[t, i] | t in (TRANSITIONS_comp_idle union TRANSITIONS_compc_reset)]) = 1);
% Connection2
constraint forall(i in STAGES)(sum([Eno2[t, i] | t in TRANSITIONS_conn_idle]) = 1);
constraint forall(i in STAGES)(sum([Ene2[t, i] | t in (TRANSITIONS_conn_idle union TRANSITIONS_connc_reset)]) = 1);
% Projector2
constraint forall(i in STAGES)(sum([Eno2[t, i] | t in TRANSITIONS_proj_idle]) = 1);
constraint forall(i in STAGES)(sum([Ene2[t, i] | t in (TRANSITIONS_proj_idle union TRANSITIONS_projc_reset)]) = 1);

% Computer3
constraint forall(i in STAGES)(sum([Eno3[t, i] | t in TRANSITIONS_comp_idle]) = 1);
constraint forall(i in STAGES)(sum([Ene3[t, i] | t in (TRANSITIONS_comp_idle union TRANSITIONS_compc_reset)]) = 1);
% Connection3
constraint forall(i in STAGES)(sum([Eno3[t, i] | t in TRANSITIONS_conn_idle]) = 1);
constraint forall(i in STAGES)(sum([Ene3[t, i] | t in (TRANSITIONS_conn_idle union TRANSITIONS_connc_reset)]) = 1);
% Projector3
constraint forall(i in STAGES)(sum([Eno3[t, i] | t in TRANSITIONS_proj_idle]) = 1);
constraint forall(i in STAGES)(sum([Ene3[t, i] | t in (TRANSITIONS_proj_idle union TRANSITIONS_projc_reset)]) = 1);

% Computer4
constraint forall(i in STAGES)(sum([Eno4[t, i] | t in TRANSITIONS_comp_idle]) = 1);
constraint forall(i in STAGES)(sum([Ene4[t, i] | t in (TRANSITIONS_comp_idle union TRANSITIONS_compc_reset)]) = 1);
% Connection4
constraint forall(i in STAGES)(sum([Eno4[t, i] | t in TRANSITIONS_conn_idle]) = 1);
constraint forall(i in STAGES)(sum([Ene4[t, i] | t in (TRANSITIONS_conn_idle union TRANSITIONS_connc_reset)]) = 1);
% Projector4
constraint forall(i in STAGES)(sum([Eno4[t, i] | t in TRANSITIONS_proj_idle]) = 1);
constraint forall(i in STAGES)(sum([Ene4[t, i] | t in (TRANSITIONS_proj_idle union TRANSITIONS_projc_reset)]) = 1);

% Computer5
constraint forall(i in STAGES)(sum([Eno5[t, i] | t in TRANSITIONS_comp_idle]) = 1);
constraint forall(i in STAGES)(sum([Ene5[t, i] | t in (TRANSITIONS_comp_idle union TRANSITIONS_compc_reset)]) = 1);
% Connection5
constraint forall(i in STAGES)(sum([Eno5[t, i] | t in TRANSITIONS_conn_idle]) = 1);
constraint forall(i in STAGES)(sum([Ene5[t, i] | t in (TRANSITIONS_conn_idle union TRANSITIONS_connc_reset)]) = 1);
% Projector5
constraint forall(i in STAGES)(sum([Eno5[t, i] | t in TRANSITIONS_proj_idle]) = 1);
constraint forall(i in STAGES)(sum([Ene5[t, i] | t in (TRANSITIONS_proj_idle union TRANSITIONS_projc_reset)]) = 1);

% Computer6
constraint forall(i in STAGES)(sum([Eno6[t, i] | t in TRANSITIONS_comp_idle]) = 1);
constraint forall(i in STAGES)(sum([Ene6[t, i] | t in (TRANSITIONS_comp_idle union TRANSITIONS_compc_reset)]) = 1);
% Connection6
constraint forall(i in STAGES)(sum([Eno6[t, i] | t in TRANSITIONS_conn_idle]) = 1);
constraint forall(i in STAGES)(sum([Ene6[t, i] | t in (TRANSITIONS_conn_idle union TRANSITIONS_connc_reset)]) = 1);
% Projector6
constraint forall(i in STAGES)(sum([Eno6[t, i] | t in TRANSITIONS_proj_idle]) = 1);
constraint forall(i in STAGES)(sum([Ene6[t, i] | t in (TRANSITIONS_proj_idle union TRANSITIONS_projc_reset)]) = 1);

% Computer7
constraint forall(i in STAGES)(sum([Eno7[t, i] | t in TRANSITIONS_comp_idle]) = 1);
constraint forall(i in STAGES)(sum([Ene7[t, i] | t in (TRANSITIONS_comp_idle union TRANSITIONS_compc_reset)]) = 1);
% Connection7
constraint forall(i in STAGES)(sum([Eno7[t, i] | t in TRANSITIONS_conn_idle]) = 1);
constraint forall(i in STAGES)(sum([Ene7[t, i] | t in (TRANSITIONS_conn_idle union TRANSITIONS_connc_reset)]) = 1);
% Projector7
constraint forall(i in STAGES)(sum([Eno7[t, i] | t in TRANSITIONS_proj_idle]) = 1);
constraint forall(i in STAGES)(sum([Ene7[t, i] | t in (TRANSITIONS_proj_idle union TRANSITIONS_projc_reset)]) = 1);

% Computer8
constraint forall(i in STAGES)(sum([Eno8[t, i] | t in TRANSITIONS_comp_idle]) = 1);
constraint forall(i in STAGES)(sum([Ene8[t, i] | t in (TRANSITIONS_comp_idle union TRANSITIONS_compc_reset)]) = 1);
% Connection8
constraint forall(i in STAGES)(sum([Eno8[t, i] | t in TRANSITIONS_conn_idle]) = 1);
constraint forall(i in STAGES)(sum([Ene8[t, i] | t in (TRANSITIONS_conn_idle union TRANSITIONS_connc_reset)]) = 1);
% Projector8
constraint forall(i in STAGES)(sum([Eno8[t, i] | t in TRANSITIONS_proj_idle]) = 1);
constraint forall(i in STAGES)(sum([Ene8[t, i] | t in (TRANSITIONS_proj_idle union TRANSITIONS_projc_reset)]) = 1);

% Constraints That Ensure Concise Runs
constraint forall(i in STAGESm1)((exists([Ene1[t,i] | t in TRANSITIONS_state_changing]) \/ exists([Ene2[t,i] | t in TRANSITIONS_state_changing]) \/ exists([Ene3[t,i] | t in TRANSITIONS_state_changing]) \/ exists([Ene4[t,i] | t in TRANSITIONS_state_changing]) \/ exists([Ene5[t,i] | t in TRANSITIONS_state_changing]) \/ exists([Ene6[t,i] | t in TRANSITIONS_state_changing]) \/ exists([Ene7[t,i] | t in TRANSITIONS_state_changing]) \/ exists([Ene8[t,i] | t in TRANSITIONS_state_changing])) xor endStateAcceptAutomatonTraj[i]==accepted);

% Initial State Encoding
constraint comp1l[0]==compOff;
constraint conn1l[0]==disconnected;
constraint proj1l[0]==projOff;

constraint comp2l[0]==compOff;
constraint conn2l[0]==disconnected;
constraint proj2l[0]==projOff;

constraint comp3l[0]==compOff;
constraint conn3l[0]==disconnected;
constraint proj3l[0]==projOff;

constraint comp4l[0]==compOff;
constraint conn4l[0]==disconnected;
constraint proj4l[0]==projOff;

constraint comp5l[0]==compOff;
constraint conn5l[0]==disconnected;
constraint proj5l[0]==projOff;

constraint comp6l[0]==compOff;
constraint conn6l[0]==disconnected;
constraint proj6l[0]==projOff;

constraint comp7l[0]==compOff;
constraint conn7l[0]==disconnected;
constraint proj7l[0]==projOff;

constraint comp8l[0]==compOff;
constraint conn8l[0]==disconnected;
constraint proj8l[0]==projOff;

%% end state accepting
constraint endStateAcceptAutomatonTraj[0]==waiting;

% Goal State Encoding
constraint comp2l[h-1]==compOn;
constraint conn2l[h-1]==connected;
constraint proj2l[h-1]==projOn;

constraint comp3l[h-1]==compOn;
constraint conn3l[h-1]==connected;
constraint proj3l[h-1]==projOn;

constraint comp4l[h-1]==compOn;
constraint conn4l[h-1]==connected;
constraint proj4l[h-1]==projOn;

constraint comp5l[h-1]==compOn;
constraint conn5l[h-1]==connected;
constraint proj5l[h-1]==projOn;

constraint comp6l[h-1]==compOn;
constraint conn6l[h-1]==connected;
constraint proj6l[h-1]==projOn;

constraint comp7l[h-1]==compOn;
constraint conn7l[h-1]==connected;
constraint proj7l[h-1]==projOn;

constraint comp8l[h-1]==compOn;
constraint conn8l[h-1]==connected;
constraint proj8l[h-1]==projOn;

constraint exists(i in STAGES)(endStateAcceptAutomatonTraj[i]==accepted);

% location vars for all stages
array[STAGES] of var CompL : comp1l;
array[STAGES] of var ConnL : conn1l;
array[STAGES] of var ProjL : proj1l;
array[STAGES] of var CompL : comp2l;
array[STAGES] of var ConnL : conn2l;
array[STAGES] of var ProjL : proj2l;
array[STAGES] of var CompL : comp3l;
array[STAGES] of var ConnL : conn3l;
array[STAGES] of var ProjL : proj3l;
array[STAGES] of var CompL : comp4l;
array[STAGES] of var ConnL : conn4l;
array[STAGES] of var ProjL : proj4l;
array[STAGES] of var CompL : comp5l;
array[STAGES] of var ConnL : conn5l;
array[STAGES] of var ProjL : proj5l;
array[STAGES] of var CompL : comp6l;
array[STAGES] of var ConnL : conn6l;
array[STAGES] of var ProjL : proj6l;
array[STAGES] of var CompL : comp7l;
array[STAGES] of var ConnL : conn7l;
array[STAGES] of var ProjL : proj7l;
array[STAGES] of var CompL : comp8l;
array[STAGES] of var ConnL : conn8l;
array[STAGES] of var ProjL : proj8l;

% command vars for all stages
array[STAGES] of var CompU : comp1u;
array[STAGES] of var ConnU : conn1u;
array[STAGES] of var ProjU : proj1u;
array[STAGES] of var CompU : comp2u;
array[STAGES] of var ConnU : conn2u;
array[STAGES] of var ProjU : proj2u;
array[STAGES] of var CompU : comp3u;
array[STAGES] of var ConnU : conn3u;
array[STAGES] of var ProjU : proj3u;
array[STAGES] of var CompU : comp4u;
array[STAGES] of var ConnU : conn4u;
array[STAGES] of var ProjU : proj4u;
array[STAGES] of var CompU : comp5u;
array[STAGES] of var ConnU : conn5u;
array[STAGES] of var ProjU : proj5u;
array[STAGES] of var CompU : comp6u;
array[STAGES] of var ConnU : conn6u;
array[STAGES] of var ProjU : proj6u;
array[STAGES] of var CompU : comp7u;
array[STAGES] of var ConnU : conn7u;
array[STAGES] of var ProjU : proj7u;
array[STAGES] of var CompU : comp8u;
array[STAGES] of var ConnU : conn8u;
array[STAGES] of var ProjU : proj8u;

constraint forall(i in STAGES)(not Eno1[1,i]); % state changing
constraint forall(i in STAGES)(not Eno1[2,i]); % state changing
constraint forall(i in STAGES)(not Eno1[3,i]); % state changing
constraint forall(i in STAGES)(not Eno1[4,i]); % state changing

constraint forall(i in STAGES)(Eno1[5,i] -> comp1l[i]==compOn /\ openIdlingClock(c, cl, cu, e, co, comp1, i)); % idling
constraint forall(i in STAGES)(Eno1[6,i] -> comp1l[i]==compShutdown /\ openIdlingClock(c, cl, cu, e, co, comp1, i)); % idling
constraint forall(i in STAGES)(Eno1[7,i] -> comp1l[i]==compOff /\ openIdlingClock(c, cl, cu, e, co, comp1, i)); % idling
constraint forall(i in STAGES)(Eno1[8,i] -> comp1l[i]==compBooting /\ openIdlingClock(c, cl, cu, e, co, comp1, i)); % idling

constraint forall(i in STAGESm1)(Ene1[1,i] -> 
  comp1l[i]==compOn /\ comp1l[i+1]==compShutdown /\ 
  comp1u[i]==compTurnOff /\ 
  closeChangeClock(c, cl, cu, e, co, comp1, i) /\ 
  cvs(e, co, comp1, i) /\ cps(co, cl, cu, comp1, i)); % state changing
constraint forall(i in STAGESm1)(Ene1[2,i] -> 
  comp1l[i]==compShutdown /\ comp1l[i+1]==compOff /\ 
  c[comp1,i]==30 /\
  closeChangeClock(c, cl, cu, e, co, comp1, i) /\ 
  cvs(e, co, comp1, i) /\ cps(co, cl, cu, comp1, i)); % state changing
constraint forall(i in STAGESm1)(Ene1[3,i] ->
  comp1l[i]==compOff /\ comp1l[i+1]==compBooting /\ 
  comp1u[i]==compTurnOn /\
  closeChangeClock(c, cl, cu, e, co, comp1, i) /\ 
  cvs(e, co, comp1, i) /\ cps(co, cl, cu, comp1, i)); % state changing
constraint forall(i in STAGESm1)(Ene1[4,i] ->
  comp1l[i]==compBooting /\ comp1l[i+1]==compOn /\ 
  c[comp1,i]==15 /\
  closeChangeClock(c, cl, cu, e, co, comp1, i) /\ 
  cvs(e, co, comp1, i) /\ cps(co, cl, cu, comp1, i)); % state changing

constraint forall(i in STAGESm1)(Ene1[5,i] ->
  comp1l[i]==compOn /\ comp1l[i+1]==compOn /\ comp1u[i]!=compTurnOff /\
  closeIdlingClock(c, cl, cu, e, co, comp1, i) /\ 
  cps(co, cl, cu, comp1, i)); % idling
constraint forall(i in STAGESm1)(Ene1[6,i] ->
  comp1l[i]==compShutdown /\ comp1l[i+1]==compShutdown /\
  closeIdlingClock(c, cl, cu, e, co, comp1, i) /\ 
  cps(co, cl, cu, comp1, i)); % idling
constraint forall(i in STAGESm1)(Ene1[7,i] ->
  comp1l[i]==compOff /\ comp1l[i+1]==compOff /\ comp1u[i]!=compTurnOn /\
  closeIdlingClock(c, cl, cu, e, co, comp1, i)  /\ 
  cps(co, cl, cu, comp1, i)); % idling
constraint forall(i in STAGESm1)(Ene1[8,i] ->
  comp1l[i]==compBooting /\ comp1l[i+1]==compBooting /\
  closeIdlingClock(c, cl, cu, e, co, comp1, i) /\ 
  cps(co, cl, cu, comp1, i)); % idling

% HARDCODED transition constraints for CONNECTION
constraint forall(i in STAGES)(not Eno1[9,i]); % state changing
constraint forall(i in STAGES)(not Eno1[10,i]); % state changing

constraint forall(i in STAGES)(Eno1[11,i] -> conn1l[i]==connected /\ openIdlingClock(c, cl, cu, e, co, conn1, i)); % idling
constraint forall(i in STAGES)(Eno1[12,i] -> conn1l[i]==disconnected /\ openIdlingClock(c, cl, cu, e, co, conn1, i)); % idling

constraint forall(i in STAGESm1)(Ene1[9,i] -> 
  conn1l[i]==connected /\ conn1l[i+1]==disconnected /\
  conn1u[i]==disconnect /\
  closeChangeClock(c, cl, cu, e, co, conn1, i) /\ 
  cvs(e, co, conn1, i) /\ cps(co, cl, cu, conn1, i)); % state changing

constraint forall(i in STAGESm1)(Ene1[10,i] ->
  conn1l[i]==disconnected /\ conn1l[i+1]==connected /\ 
  conn1u[i]==connect /\ comp1l[i]==compOff /\
  closeChangeClock(c, cl, cu, e, co, conn1, i) /\ 
  cvs(e, co, conn1, i) /\ cps(co, cl, cu, conn1, i)); % state changing

constraint forall(i in STAGESm1)(Ene1[11,i] -> 
  conn1l[i]==connected /\ conn1l[i+1]=connected /\ conn1u[i]!=disconnect /\
  closeIdlingClock(c, cl, cu, e, co, conn1, i) /\ 
  cps(co, cl, cu, conn1, i)); % idling

constraint forall(i in STAGESm1)(Ene1[12,i] -> 
  conn1l[i]==disconnected /\ conn1l[i+1]=disconnected /\ conn1u[i]!=connect /\
  closeIdlingClock(c, cl, cu, e, co, conn1, i) /\ 
  cps(co, cl, cu, conn1, i)); % idling

% % HARDCODED transition constraints for PROJECTOR
constraint forall(i in STAGES)(not Eno1[13,i]); % state changing
constraint forall(i in STAGES)(not Eno1[14,i]); % state changing
constraint forall(i in STAGES)(not Eno1[15,i]); % state changing
constraint forall(i in STAGES)(not Eno1[16,i]); % state changing
constraint forall(i in STAGES)(not Eno1[17,i]); % state changing
constraint forall(i in STAGES)(not Eno1[18,i]); % state changing
constraint forall(i in STAGES)(not Eno1[19,i]); % state changing
constraint forall(i in STAGES)(not Eno1[20,i]); % state changing
constraint forall(i in STAGES)(not Eno1[27,i]); % state changing
constraint forall(i in STAGES)(Eno1[21,i] -> proj1l[i]==projOff /\ openIdlingClock(c, cl, cu, e, co, proj1, i)); % idling
constraint forall(i in STAGES)(Eno1[22,i] -> proj1l[i]==projWarmUp /\ openIdlingClock(c, cl, cu, e, co, proj1, i)); % idling
constraint forall(i in STAGES)(Eno1[23,i] -> proj1l[i]==projOn /\ openIdlingClock(c, cl, cu, e, co, proj1, i)); % idling
constraint forall(i in STAGES)(Eno1[24,i] -> proj1l[i]==projConfirm /\ openIdlingClock(c, cl, cu, e, co, proj1, i)); % idling
constraint forall(i in STAGES)(Eno1[25,i] -> proj1l[i]==projCoolDown /\ openIdlingClock(c, cl, cu, e, co, proj1, i)); % idling
constraint forall(i in STAGES)(Eno1[26,i] -> proj1l[i]==projWaiting /\ openIdlingClock(c, cl, cu, e, co, proj1, i)); % idling
  
constraint forall(i in STAGESm1)(Ene1[13,i] ->
  proj1l[i]==projOff /\ proj1l[i+1]==projWarmUp /\ 
  proj1u[i]==projTurnOn /\
  closeChangeClock(c, cl, cu, e, co, proj1, i) /\ 
  cvs(e, co, proj1, i) /\ cps(co, cl, cu, proj1, i)); % state changing
  
constraint forall(i in STAGESm1)(Ene1[14,i] -> 
  proj1l[i]==projWarmUp /\ proj1l[i+1]==projOn /\ 
  c[proj1,i] == 30 /\
  closeChangeClock(c, cl, cu, e, co, proj1, i) /\ 
  cvs(e, co, proj1, i) /\ cps(co, cl, cu, proj1, i)); % state changing
  
constraint forall(i in STAGESm1)(Ene1[15,i] -> 
  proj1l[i]==projOn /\ proj1l[i+1]==projConfirm /\ 
  proj1u[i]==projTurnOff /\
  closeChangeClock(c, cl, cu, e, co, proj1, i) /\ 
  cvs(e, co, proj1, i) /\ cps(co, cl, cu, proj1, i)); % state changing
  
constraint forall(i in STAGESm1)(Ene1[16,i] -> 
  proj1l[i]==projOn /\ proj1l[i+1]==projWaiting /\ 
  (comp1l[i]!=compOn \/ conn1l[i]!=connected) /\ proj1u[i]!=projTurnOff /\
  closeChangeClock(c, cl, cu, e, co, proj1, i) /\ 
  cvs(e, co, proj1, i) /\ cps(co, cl, cu, proj1, i)); % state changing
  
constraint forall(i in STAGESm1)(Ene1[17,i] -> 
  proj1l[i]==projConfirm /\ proj1l[i+1]==projCoolDown /\ 
  proj1u[i]==projTurnOff /\ inRange(c[proj1,i],cl[proj1,i],cu[proj1,i]) /\
  closeChangeClock(c, cl, cu, e, co, proj1, i) /\ 
  cvs(e, co, proj1, i) /\ cps(co, cl, cu, proj1, i)); % state changing
  
constraint forall(i in STAGESm1)(Ene1[18,i] -> 
  proj1l[i]==projWaiting /\ proj1l[i+1]==projCoolDown /\ 
  (comp1l[i]!=compOn \/ conn1l[i]!=connected) /\ c[proj1,i]==60 /\
  closeChangeClock(c, cl, cu, e, co, proj1, i) /\ 
  cvs(e, co, proj1, i) /\ cps(co, cl, cu, proj1, i)); % state changing

constraint forall(i in STAGESm1)(Ene1[19,i] -> 
  proj1l[i]==projWaiting /\ proj1l[i+1]==projOn /\ 
  comp1l[i]==compOn /\ conn1l[i]==connected /\
  closeChangeClock(c, cl, cu, e, co, proj1, i) /\ 
  cvs(e, co, proj1, i) /\ cps(co, cl, cu, proj1, i)); % state changing
  
constraint forall(i in STAGESm1)(Ene1[20,i] -> 
  proj1l[i]==projConfirm /\ proj1l[i+1]==projOn /\ 
  proj1u[i]!=projTurnOff /\ c[proj1,i]==5 /\
  closeChangeClock(c, cl, cu, e, co, proj1, i) /\ 
  cvs(e, co, proj1, i) /\ cps(co, cl, cu, proj1, i)); % state changing

constraint forall(i in STAGESm1)(Ene1[27,i] -> 
  proj1l[i]==projCoolDown /\ proj1l[i+1]==projOff /\ 
  c[proj1,i]==60 /\
  closeChangeClock(c, cl, cu, e, co, proj1, i) /\ 
  cvs(e, co, proj1, i) /\ cps(co, cl, cu, proj1, i)); % state changing

constraint forall(i in STAGESm1)(Ene1[21,i] -> 
  proj1l[i]==projOff /\ proj1l[i+1]==projOff /\
  proj1u[i]!=projTurnOn /\
  closeIdlingClock(c, cl, cu, e, co, proj1, i) /\ 
  cps(co, cl, cu, proj1, i)); % idling
  
constraint forall(i in STAGESm1)(Ene1[22,i] -> 
  proj1l[i]==projWarmUp /\ proj1l[i+1]==projWarmUp /\
  closeIdlingClock(c, cl, cu, e, co, proj1, i) /\ 
  cps(co, cl, cu, proj1, i)); % idling
  
constraint forall(i in STAGESm1)(Ene1[23,i] -> 
  proj1l[i]==projOn /\ proj1l[i+1]==projOn /\ comp1l[i+1]==compOn /\ conn1l[i+1]==connected /\
  closeIdlingClock(c, cl, cu, e, co, proj1, i) /\ 
  cps(co, cl, cu, proj1, i)); % idling
  
constraint forall(i in STAGESm1)(Ene1[24,i] -> 
  proj1l[i]==projConfirm /\ proj1l[i+1]=projConfirm /\
  closeIdlingClock(c, cl, cu, e, co, proj1, i) /\ 
  cps(co, cl, cu, proj1, i)); % idling
  
constraint forall(i in STAGESm1)(Ene1[25,i] -> 
  proj1l[i]==projCoolDown /\ proj1l[i+1]==projCoolDown /\
  closeIdlingClock(c, cl, cu, e, co, proj1, i) /\ 
  cps(co, cl, cu, proj1, i)); % idling
  
constraint forall(i in STAGESm1)(Ene1[26,i] -> 
  proj1l[i]==projWaiting /\ proj1l[i+1]==projWaiting /\
  closeIdlingClock(c, cl, cu, e, co, proj1, i) /\ 
  cps(co, cl, cu, proj1, i)); % idling


% SET 2 Transitions

constraint forall(i in STAGES)(not Eno2[1,i]); % state changing
constraint forall(i in STAGES)(not Eno2[2,i]); % state changing
constraint forall(i in STAGES)(not Eno2[3,i]); % state changing
constraint forall(i in STAGES)(not Eno2[4,i]); % state changing

constraint forall(i in STAGES)(Eno2[5,i] -> comp2l[i]==compOn /\ openIdlingClock(c, cl, cu, e, co, comp2, i)); % idling
constraint forall(i in STAGES)(Eno2[6,i] -> comp2l[i]==compShutdown /\ openIdlingClock(c, cl, cu, e, co, comp2, i)); % idling
constraint forall(i in STAGES)(Eno2[7,i] -> comp2l[i]==compOff /\ openIdlingClock(c, cl, cu, e, co, comp2, i)); % idling
constraint forall(i in STAGES)(Eno2[8,i] -> comp2l[i]==compBooting /\ openIdlingClock(c, cl, cu, e, co, comp2, i)); % idling

constraint forall(i in STAGESm1)(Ene2[1,i] -> 
  comp2l[i]==compOn /\ comp2l[i+1]==compShutdown /\ 
  comp2u[i]==compTurnOff /\ 
  closeChangeClock(c, cl, cu, e, co, comp2, i) /\ 
  cvs(e, co, comp2, i) /\ cps(co, cl, cu, comp2, i)); % state changing
constraint forall(i in STAGESm1)(Ene2[2,i] -> 
  comp2l[i]==compShutdown /\ comp2l[i+1]==compOff /\ 
  c[comp2,i]==30 /\
  closeChangeClock(c, cl, cu, e, co, comp2, i) /\ 
  cvs(e, co, comp2, i) /\ cps(co, cl, cu, comp2, i)); % state changing
constraint forall(i in STAGESm1)(Ene2[3,i] ->
  comp2l[i]==compOff /\ comp2l[i+1]==compBooting /\ 
  comp2u[i]==compTurnOn /\
  closeChangeClock(c, cl, cu, e, co, comp2, i) /\ 
  cvs(e, co, comp2, i) /\ cps(co, cl, cu, comp2, i)); % state changing
constraint forall(i in STAGESm1)(Ene2[4,i] ->
  comp2l[i]==compBooting /\ comp2l[i+1]==compOn /\ 
  c[comp2,i]==15 /\
  closeChangeClock(c, cl, cu, e, co, comp2, i) /\ 
  cvs(e, co, comp2, i) /\ cps(co, cl, cu, comp2, i)); % state changing

constraint forall(i in STAGESm1)(Ene2[5,i] ->
  comp2l[i]==compOn /\ comp2l[i+1]==compOn /\ comp2u[i]!=compTurnOff /\
  closeIdlingClock(c, cl, cu, e, co, comp2, i) /\ 
  cps(co, cl, cu, comp2, i)); % idling
constraint forall(i in STAGESm1)(Ene2[6,i] ->
  comp2l[i]==compShutdown /\ comp2l[i+1]==compShutdown /\
  closeIdlingClock(c, cl, cu, e, co, comp2, i) /\ 
  cps(co, cl, cu, comp2, i)); % idling
constraint forall(i in STAGESm1)(Ene2[7,i] ->
  comp2l[i]==compOff /\ comp2l[i+1]==compOff /\ comp2u[i]!=compTurnOn /\
  closeIdlingClock(c, cl, cu, e, co, comp2, i)  /\ 
  cps(co, cl, cu, comp2, i)); % idling
constraint forall(i in STAGESm1)(Ene2[8,i] ->
  comp2l[i]==compBooting /\ comp2l[i+1]==compBooting /\
  closeIdlingClock(c, cl, cu, e, co, comp2, i) /\ 
  cps(co, cl, cu, comp2, i)); % idling

% HARDCODED transition constraints for CONNECTION
constraint forall(i in STAGES)(not Eno2[9,i]); % state changing
constraint forall(i in STAGES)(not Eno2[10,i]); % state changing

constraint forall(i in STAGES)(Eno2[11,i] -> conn2l[i]==connected /\ openIdlingClock(c, cl, cu, e, co, conn2, i)); % idling
constraint forall(i in STAGES)(Eno2[12,i] -> conn2l[i]==disconnected /\ openIdlingClock(c, cl, cu, e, co, conn2, i)); % idling

constraint forall(i in STAGESm1)(Ene2[9,i] -> 
  conn2l[i]==connected /\ conn2l[i+1]==disconnected /\
  conn2u[i]==disconnect /\
  closeChangeClock(c, cl, cu, e, co, conn2, i) /\ 
  cvs(e, co, conn2, i) /\ cps(co, cl, cu, conn2, i)); % state changing

constraint forall(i in STAGESm1)(Ene2[10,i] ->
  conn2l[i]==disconnected /\ conn2l[i+1]==connected /\ 
  conn2u[i]==connect /\ comp2l[i]==compOff /\
  closeChangeClock(c, cl, cu, e, co, conn2, i) /\ 
  cvs(e, co, conn2, i) /\ cps(co, cl, cu, conn2, i)); % state changing

constraint forall(i in STAGESm1)(Ene2[11,i] -> 
  conn2l[i]==connected /\ conn2l[i+1]=connected /\ conn2u[i]!=disconnect /\
  closeIdlingClock(c, cl, cu, e, co, conn2, i) /\ 
  cps(co, cl, cu, conn2, i)); % idling

constraint forall(i in STAGESm1)(Ene2[12,i] -> 
  conn2l[i]==disconnected /\ conn2l[i+1]=disconnected /\ conn2u[i]!=connect /\
  closeIdlingClock(c, cl, cu, e, co, conn2, i) /\ 
  cps(co, cl, cu, conn2, i)); % idling

% % HARDCODED transition constraints for PROJECTOR
constraint forall(i in STAGES)(not Eno2[13,i]); % state changing
constraint forall(i in STAGES)(not Eno2[14,i]); % state changing
constraint forall(i in STAGES)(not Eno2[15,i]); % state changing
constraint forall(i in STAGES)(not Eno2[16,i]); % state changing
constraint forall(i in STAGES)(not Eno2[17,i]); % state changing
constraint forall(i in STAGES)(not Eno2[18,i]); % state changing
constraint forall(i in STAGES)(not Eno2[19,i]); % state changing
constraint forall(i in STAGES)(not Eno2[20,i]); % state changing
constraint forall(i in STAGES)(not Eno2[27,i]); % state changing
constraint forall(i in STAGES)(Eno2[21,i] -> proj2l[i]==projOff /\ openIdlingClock(c, cl, cu, e, co, proj2, i)); % idling
constraint forall(i in STAGES)(Eno2[22,i] -> proj2l[i]==projWarmUp /\ openIdlingClock(c, cl, cu, e, co, proj2, i)); % idling
constraint forall(i in STAGES)(Eno2[23,i] -> proj2l[i]==projOn /\ openIdlingClock(c, cl, cu, e, co, proj2, i)); % idling
constraint forall(i in STAGES)(Eno2[24,i] -> proj2l[i]==projConfirm /\ openIdlingClock(c, cl, cu, e, co, proj2, i)); % idling
constraint forall(i in STAGES)(Eno2[25,i] -> proj2l[i]==projCoolDown /\ openIdlingClock(c, cl, cu, e, co, proj2, i)); % idling
constraint forall(i in STAGES)(Eno2[26,i] -> proj2l[i]==projWaiting /\ openIdlingClock(c, cl, cu, e, co, proj2, i)); % idling
  
constraint forall(i in STAGESm1)(Ene2[13,i] ->
  proj2l[i]==projOff /\ proj2l[i+1]==projWarmUp /\ 
  proj2u[i]==projTurnOn /\
  closeChangeClock(c, cl, cu, e, co, proj2, i) /\ 
  cvs(e, co, proj2, i) /\ cps(co, cl, cu, proj2, i)); % state changing
  
constraint forall(i in STAGESm1)(Ene2[14,i] -> 
  proj2l[i]==projWarmUp /\ proj2l[i+1]==projOn /\ 
  c[proj2,i] == 30 /\
  closeChangeClock(c, cl, cu, e, co, proj2, i) /\ 
  cvs(e, co, proj2, i) /\ cps(co, cl, cu, proj2, i)); % state changing
  
constraint forall(i in STAGESm1)(Ene2[15,i] -> 
  proj2l[i]==projOn /\ proj2l[i+1]==projConfirm /\ 
  proj2u[i]==projTurnOff /\
  closeChangeClock(c, cl, cu, e, co, proj2, i) /\ 
  cvs(e, co, proj2, i) /\ cps(co, cl, cu, proj2, i)); % state changing
  
constraint forall(i in STAGESm1)(Ene2[16,i] -> 
  proj2l[i]==projOn /\ proj2l[i+1]==projWaiting /\ 
  (comp2l[i]!=compOn \/ conn2l[i]!=connected) /\ proj2u[i]!=projTurnOff /\
  closeChangeClock(c, cl, cu, e, co, proj2, i) /\ 
  cvs(e, co, proj2, i) /\ cps(co, cl, cu, proj2, i)); % state changing
  
constraint forall(i in STAGESm1)(Ene2[17,i] -> 
  proj2l[i]==projConfirm /\ proj2l[i+1]==projCoolDown /\ 
  proj2u[i]==projTurnOff /\ inRange(c[proj2,i],cl[proj2,i],cu[proj2,i]) /\
  closeChangeClock(c, cl, cu, e, co, proj2, i) /\ 
  cvs(e, co, proj2, i) /\ cps(co, cl, cu, proj2, i)); % state changing
  
constraint forall(i in STAGESm1)(Ene2[18,i] -> 
  proj2l[i]==projWaiting /\ proj2l[i+1]==projCoolDown /\ 
  (comp2l[i]!=compOn \/ conn2l[i]!=connected) /\ c[proj2,i]==60 /\
  closeChangeClock(c, cl, cu, e, co, proj2, i) /\ 
  cvs(e, co, proj2, i) /\ cps(co, cl, cu, proj2, i)); % state changing

constraint forall(i in STAGESm1)(Ene2[19,i] -> 
  proj2l[i]==projWaiting /\ proj2l[i+1]==projOn /\ 
  comp2l[i]==compOn /\ conn2l[i]==connected /\
  closeChangeClock(c, cl, cu, e, co, proj2, i) /\ 
  cvs(e, co, proj2, i) /\ cps(co, cl, cu, proj2, i)); % state changing
  
constraint forall(i in STAGESm1)(Ene2[20,i] -> 
  proj2l[i]==projConfirm /\ proj2l[i+1]==projOn /\ 
  proj2u[i]!=projTurnOff /\ c[proj2,i]==5 /\
  closeChangeClock(c, cl, cu, e, co, proj2, i) /\ 
  cvs(e, co, proj2, i) /\ cps(co, cl, cu, proj2, i)); % state changing

constraint forall(i in STAGESm1)(Ene2[27,i] -> 
  proj2l[i]==projCoolDown /\ proj2l[i+1]==projOff /\ 
  c[proj2,i]==60 /\
  closeChangeClock(c, cl, cu, e, co, proj2, i) /\ 
  cvs(e, co, proj2, i) /\ cps(co, cl, cu, proj2, i)); % state changing

constraint forall(i in STAGESm1)(Ene2[21,i] -> 
  proj2l[i]==projOff /\ proj2l[i+1]==projOff /\
  proj2u[i]!=projTurnOn /\
  closeIdlingClock(c, cl, cu, e, co, proj2, i) /\ 
  cps(co, cl, cu, proj2, i)); % idling
  
constraint forall(i in STAGESm1)(Ene2[22,i] -> 
  proj2l[i]==projWarmUp /\ proj2l[i+1]==projWarmUp /\
  closeIdlingClock(c, cl, cu, e, co, proj2, i) /\ 
  cps(co, cl, cu, proj2, i)); % idling
  
constraint forall(i in STAGESm1)(Ene2[23,i] -> 
  proj2l[i]==projOn /\ proj2l[i+1]==projOn /\ comp2l[i+1]==compOn /\ conn2l[i+1]==connected /\
  closeIdlingClock(c, cl, cu, e, co, proj2, i) /\ 
  cps(co, cl, cu, proj2, i)); % idling
  
constraint forall(i in STAGESm1)(Ene2[24,i] -> 
  proj2l[i]==projConfirm /\ proj2l[i+1]=projConfirm /\
  closeIdlingClock(c, cl, cu, e, co, proj2, i) /\ 
  cps(co, cl, cu, proj2, i)); % idling
  
constraint forall(i in STAGESm1)(Ene2[25,i] -> 
  proj2l[i]==projCoolDown /\ proj2l[i+1]==projCoolDown /\
  closeIdlingClock(c, cl, cu, e, co, proj2, i) /\ 
  cps(co, cl, cu, proj2, i)); % idling
  
constraint forall(i in STAGESm1)(Ene2[26,i] -> 
  proj2l[i]==projWaiting /\ proj2l[i+1]==projWaiting /\
  closeIdlingClock(c, cl, cu, e, co, proj2, i) /\ 
  cps(co, cl, cu, proj2, i)); % idling

%%%% SET 3 TRANSITIONS

constraint forall(i in STAGES)(not Eno3[1,i]); % state changing
constraint forall(i in STAGES)(not Eno3[2,i]); % state changing
constraint forall(i in STAGES)(not Eno3[3,i]); % state changing
constraint forall(i in STAGES)(not Eno3[4,i]); % state changing

constraint forall(i in STAGES)(Eno3[5,i] -> comp3l[i]==compOn /\ openIdlingClock(c, cl, cu, e, co, comp3, i)); % idling
constraint forall(i in STAGES)(Eno3[6,i] -> comp3l[i]==compShutdown /\ openIdlingClock(c, cl, cu, e, co, comp3, i)); % idling
constraint forall(i in STAGES)(Eno3[7,i] -> comp3l[i]==compOff /\ openIdlingClock(c, cl, cu, e, co, comp3, i)); % idling
constraint forall(i in STAGES)(Eno3[8,i] -> comp3l[i]==compBooting /\ openIdlingClock(c, cl, cu, e, co, comp3, i)); % idling

constraint forall(i in STAGESm1)(Ene3[1,i] -> 
  comp3l[i]==compOn /\ comp3l[i+1]==compShutdown /\ 
  comp3u[i]==compTurnOff /\ 
  closeChangeClock(c, cl, cu, e, co, comp3, i) /\ 
  cvs(e, co, comp3, i) /\ cps(co, cl, cu, comp3, i)); % state changing
constraint forall(i in STAGESm1)(Ene3[2,i] -> 
  comp3l[i]==compShutdown /\ comp3l[i+1]==compOff /\ 
  c[comp3,i]==30 /\
  closeChangeClock(c, cl, cu, e, co, comp3, i) /\ 
  cvs(e, co, comp3, i) /\ cps(co, cl, cu, comp3, i)); % state changing
constraint forall(i in STAGESm1)(Ene3[3,i] ->
  comp3l[i]==compOff /\ comp3l[i+1]==compBooting /\ 
  comp3u[i]==compTurnOn /\
  closeChangeClock(c, cl, cu, e, co, comp3, i) /\ 
  cvs(e, co, comp3, i) /\ cps(co, cl, cu, comp3, i)); % state changing
constraint forall(i in STAGESm1)(Ene3[4,i] ->
  comp3l[i]==compBooting /\ comp3l[i+1]==compOn /\ 
  c[comp3,i]==15 /\
  closeChangeClock(c, cl, cu, e, co, comp3, i) /\ 
  cvs(e, co, comp3, i) /\ cps(co, cl, cu, comp3, i)); % state changing

constraint forall(i in STAGESm1)(Ene3[5,i] ->
  comp3l[i]==compOn /\ comp3l[i+1]==compOn /\ comp3u[i]!=compTurnOff /\
  closeIdlingClock(c, cl, cu, e, co, comp3, i) /\ 
  cps(co, cl, cu, comp3, i)); % idling
constraint forall(i in STAGESm1)(Ene3[6,i] ->
  comp3l[i]==compShutdown /\ comp3l[i+1]==compShutdown /\
  closeIdlingClock(c, cl, cu, e, co, comp3, i) /\ 
  cps(co, cl, cu, comp3, i)); % idling
constraint forall(i in STAGESm1)(Ene3[7,i] ->
  comp3l[i]==compOff /\ comp3l[i+1]==compOff /\ comp3u[i]!=compTurnOn /\
  closeIdlingClock(c, cl, cu, e, co, comp3, i)  /\ 
  cps(co, cl, cu, comp3, i)); % idling
constraint forall(i in STAGESm1)(Ene3[8,i] ->
  comp3l[i]==compBooting /\ comp3l[i+1]==compBooting /\
  closeIdlingClock(c, cl, cu, e, co, comp3, i) /\ 
  cps(co, cl, cu, comp3, i)); % idling

% HARDCODED transition constraints for CONNECTION
constraint forall(i in STAGES)(not Eno3[9,i]); % state changing
constraint forall(i in STAGES)(not Eno3[10,i]); % state changing

constraint forall(i in STAGES)(Eno3[11,i] -> conn3l[i]==connected /\ openIdlingClock(c, cl, cu, e, co, conn3, i)); % idling
constraint forall(i in STAGES)(Eno3[12,i] -> conn3l[i]==disconnected /\ openIdlingClock(c, cl, cu, e, co, conn3, i)); % idling

constraint forall(i in STAGESm1)(Ene3[9,i] -> 
  conn3l[i]==connected /\ conn3l[i+1]==disconnected /\
  conn3u[i]==disconnect /\
  closeChangeClock(c, cl, cu, e, co, conn3, i) /\ 
  cvs(e, co, conn3, i) /\ cps(co, cl, cu, conn3, i)); % state changing

constraint forall(i in STAGESm1)(Ene3[10,i] ->
  conn3l[i]==disconnected /\ conn3l[i+1]==connected /\ 
  conn3u[i]==connect /\ comp3l[i]==compOff /\
  closeChangeClock(c, cl, cu, e, co, conn3, i) /\ 
  cvs(e, co, conn3, i) /\ cps(co, cl, cu, conn3, i)); % state changing

constraint forall(i in STAGESm1)(Ene3[11,i] -> 
  conn3l[i]==connected /\ conn3l[i+1]=connected /\ conn3u[i]!=disconnect /\
  closeIdlingClock(c, cl, cu, e, co, conn3, i) /\ 
  cps(co, cl, cu, conn3, i)); % idling

constraint forall(i in STAGESm1)(Ene3[12,i] -> 
  conn3l[i]==disconnected /\ conn3l[i+1]=disconnected /\ conn3u[i]!=connect /\
  closeIdlingClock(c, cl, cu, e, co, conn3, i) /\ 
  cps(co, cl, cu, conn3, i)); % idling

% % HARDCODED transition constraints for PROJECTOR
constraint forall(i in STAGES)(not Eno3[13,i]); % state changing
constraint forall(i in STAGES)(not Eno3[14,i]); % state changing
constraint forall(i in STAGES)(not Eno3[15,i]); % state changing
constraint forall(i in STAGES)(not Eno3[16,i]); % state changing
constraint forall(i in STAGES)(not Eno3[17,i]); % state changing
constraint forall(i in STAGES)(not Eno3[18,i]); % state changing
constraint forall(i in STAGES)(not Eno3[19,i]); % state changing
constraint forall(i in STAGES)(not Eno3[20,i]); % state changing
constraint forall(i in STAGES)(not Eno3[27,i]); % state changing
constraint forall(i in STAGES)(Eno3[21,i] -> proj3l[i]==projOff /\ openIdlingClock(c, cl, cu, e, co, proj3, i)); % idling
constraint forall(i in STAGES)(Eno3[22,i] -> proj3l[i]==projWarmUp /\ openIdlingClock(c, cl, cu, e, co, proj3, i)); % idling
constraint forall(i in STAGES)(Eno3[23,i] -> proj3l[i]==projOn /\ openIdlingClock(c, cl, cu, e, co, proj3, i)); % idling
constraint forall(i in STAGES)(Eno3[24,i] -> proj3l[i]==projConfirm /\ openIdlingClock(c, cl, cu, e, co, proj3, i)); % idling
constraint forall(i in STAGES)(Eno3[25,i] -> proj3l[i]==projCoolDown /\ openIdlingClock(c, cl, cu, e, co, proj3, i)); % idling
constraint forall(i in STAGES)(Eno3[26,i] -> proj3l[i]==projWaiting /\ openIdlingClock(c, cl, cu, e, co, proj3, i)); % idling
  
constraint forall(i in STAGESm1)(Ene3[13,i] ->
  proj3l[i]==projOff /\ proj3l[i+1]==projWarmUp /\ 
  proj3u[i]==projTurnOn /\
  closeChangeClock(c, cl, cu, e, co, proj3, i) /\ 
  cvs(e, co, proj3, i) /\ cps(co, cl, cu, proj3, i)); % state changing
  
constraint forall(i in STAGESm1)(Ene3[14,i] -> 
  proj3l[i]==projWarmUp /\ proj3l[i+1]==projOn /\ 
  c[proj3,i] == 30 /\
  closeChangeClock(c, cl, cu, e, co, proj3, i) /\ 
  cvs(e, co, proj3, i) /\ cps(co, cl, cu, proj3, i)); % state changing
  
constraint forall(i in STAGESm1)(Ene3[15,i] -> 
  proj3l[i]==projOn /\ proj3l[i+1]==projConfirm /\ 
  proj3u[i]==projTurnOff /\
  closeChangeClock(c, cl, cu, e, co, proj3, i) /\ 
  cvs(e, co, proj3, i) /\ cps(co, cl, cu, proj3, i)); % state changing
  
constraint forall(i in STAGESm1)(Ene3[16,i] -> 
  proj3l[i]==projOn /\ proj3l[i+1]==projWaiting /\ 
  (comp3l[i]!=compOn \/ conn3l[i]!=connected) /\ proj3u[i]!=projTurnOff /\
  closeChangeClock(c, cl, cu, e, co, proj3, i) /\ 
  cvs(e, co, proj3, i) /\ cps(co, cl, cu, proj3, i)); % state changing
  
constraint forall(i in STAGESm1)(Ene3[17,i] -> 
  proj3l[i]==projConfirm /\ proj3l[i+1]==projCoolDown /\ 
  proj3u[i]==projTurnOff /\ inRange(c[proj3,i],cl[proj3,i],cu[proj3,i]) /\
  closeChangeClock(c, cl, cu, e, co, proj3, i) /\ 
  cvs(e, co, proj3, i) /\ cps(co, cl, cu, proj3, i)); % state changing
  
constraint forall(i in STAGESm1)(Ene3[18,i] -> 
  proj3l[i]==projWaiting /\ proj3l[i+1]==projCoolDown /\ 
  (comp3l[i]!=compOn \/ conn3l[i]!=connected) /\ c[proj3,i]==60 /\
  closeChangeClock(c, cl, cu, e, co, proj3, i) /\ 
  cvs(e, co, proj3, i) /\ cps(co, cl, cu, proj3, i)); % state changing

constraint forall(i in STAGESm1)(Ene3[19,i] -> 
  proj3l[i]==projWaiting /\ proj3l[i+1]==projOn /\ 
  comp3l[i]==compOn /\ conn3l[i]==connected /\
  closeChangeClock(c, cl, cu, e, co, proj3, i) /\ 
  cvs(e, co, proj3, i) /\ cps(co, cl, cu, proj3, i)); % state changing
  
constraint forall(i in STAGESm1)(Ene3[20,i] -> 
  proj3l[i]==projConfirm /\ proj3l[i+1]==projOn /\ 
  proj3u[i]!=projTurnOff /\ c[proj3,i]==5 /\
  closeChangeClock(c, cl, cu, e, co, proj3, i) /\ 
  cvs(e, co, proj3, i) /\ cps(co, cl, cu, proj3, i)); % state changing

constraint forall(i in STAGESm1)(Ene3[27,i] -> 
  proj3l[i]==projCoolDown /\ proj3l[i+1]==projOff /\ 
  c[proj3,i]==60 /\
  closeChangeClock(c, cl, cu, e, co, proj3, i) /\ 
  cvs(e, co, proj3, i) /\ cps(co, cl, cu, proj3, i)); % state changing

constraint forall(i in STAGESm1)(Ene3[21,i] -> 
  proj3l[i]==projOff /\ proj3l[i+1]==projOff /\
  proj3u[i]!=projTurnOn /\
  closeIdlingClock(c, cl, cu, e, co, proj3, i) /\ 
  cps(co, cl, cu, proj3, i)); % idling
  
constraint forall(i in STAGESm1)(Ene3[22,i] -> 
  proj3l[i]==projWarmUp /\ proj3l[i+1]==projWarmUp /\
  closeIdlingClock(c, cl, cu, e, co, proj3, i) /\ 
  cps(co, cl, cu, proj3, i)); % idling
  
constraint forall(i in STAGESm1)(Ene3[23,i] -> 
  proj3l[i]==projOn /\ proj3l[i+1]==projOn /\ comp3l[i+1]==compOn /\ conn3l[i+1]==connected /\
  closeIdlingClock(c, cl, cu, e, co, proj3, i) /\ 
  cps(co, cl, cu, proj3, i)); % idling
  
constraint forall(i in STAGESm1)(Ene3[24,i] -> 
  proj3l[i]==projConfirm /\ proj3l[i+1]=projConfirm /\
  closeIdlingClock(c, cl, cu, e, co, proj3, i) /\ 
  cps(co, cl, cu, proj3, i)); % idling
  
constraint forall(i in STAGESm1)(Ene3[25,i] -> 
  proj3l[i]==projCoolDown /\ proj3l[i+1]==projCoolDown /\
  closeIdlingClock(c, cl, cu, e, co, proj3, i) /\ 
  cps(co, cl, cu, proj3, i)); % idling
  
constraint forall(i in STAGESm1)(Ene3[26,i] -> 
  proj3l[i]==projWaiting /\ proj3l[i+1]==projWaiting /\
  closeIdlingClock(c, cl, cu, e, co, proj3, i) /\ 
  cps(co, cl, cu, proj3, i)); % idling

%%% SET 4 Transitions

constraint forall(i in STAGES)(not Eno4[1,i]); % state changing
constraint forall(i in STAGES)(not Eno4[2,i]); % state changing
constraint forall(i in STAGES)(not Eno4[3,i]); % state changing
constraint forall(i in STAGES)(not Eno4[4,i]); % state changing

constraint forall(i in STAGES)(Eno4[5,i] -> comp4l[i]==compOn /\ openIdlingClock(c, cl, cu, e, co, comp4, i)); % idling
constraint forall(i in STAGES)(Eno4[6,i] -> comp4l[i]==compShutdown /\ openIdlingClock(c, cl, cu, e, co, comp4, i)); % idling
constraint forall(i in STAGES)(Eno4[7,i] -> comp4l[i]==compOff /\ openIdlingClock(c, cl, cu, e, co, comp4, i)); % idling
constraint forall(i in STAGES)(Eno4[8,i] -> comp4l[i]==compBooting /\ openIdlingClock(c, cl, cu, e, co, comp4, i)); % idling

constraint forall(i in STAGESm1)(Ene4[1,i] -> 
  comp4l[i]==compOn /\ comp4l[i+1]==compShutdown /\ 
  comp4u[i]==compTurnOff /\ 
  closeChangeClock(c, cl, cu, e, co, comp4, i) /\ 
  cvs(e, co, comp4, i) /\ cps(co, cl, cu, comp4, i)); % state changing
constraint forall(i in STAGESm1)(Ene4[2,i] -> 
  comp4l[i]==compShutdown /\ comp4l[i+1]==compOff /\ 
  c[comp4,i]==30 /\
  closeChangeClock(c, cl, cu, e, co, comp4, i) /\ 
  cvs(e, co, comp4, i) /\ cps(co, cl, cu, comp4, i)); % state changing
constraint forall(i in STAGESm1)(Ene4[3,i] ->
  comp4l[i]==compOff /\ comp4l[i+1]==compBooting /\ 
  comp4u[i]==compTurnOn /\
  closeChangeClock(c, cl, cu, e, co, comp4, i) /\ 
  cvs(e, co, comp4, i) /\ cps(co, cl, cu, comp4, i)); % state changing
constraint forall(i in STAGESm1)(Ene4[4,i] ->
  comp4l[i]==compBooting /\ comp4l[i+1]==compOn /\ 
  c[comp4,i]==15 /\
  closeChangeClock(c, cl, cu, e, co, comp4, i) /\ 
  cvs(e, co, comp4, i) /\ cps(co, cl, cu, comp4, i)); % state changing

constraint forall(i in STAGESm1)(Ene4[5,i] ->
  comp4l[i]==compOn /\ comp4l[i+1]==compOn /\ comp4u[i]!=compTurnOff /\
  closeIdlingClock(c, cl, cu, e, co, comp4, i) /\ 
  cps(co, cl, cu, comp4, i)); % idling
constraint forall(i in STAGESm1)(Ene4[6,i] ->
  comp4l[i]==compShutdown /\ comp4l[i+1]==compShutdown /\
  closeIdlingClock(c, cl, cu, e, co, comp4, i) /\ 
  cps(co, cl, cu, comp4, i)); % idling
constraint forall(i in STAGESm1)(Ene4[7,i] ->
  comp4l[i]==compOff /\ comp4l[i+1]==compOff /\ comp4u[i]!=compTurnOn /\
  closeIdlingClock(c, cl, cu, e, co, comp4, i)  /\ 
  cps(co, cl, cu, comp4, i)); % idling
constraint forall(i in STAGESm1)(Ene4[8,i] ->
  comp4l[i]==compBooting /\ comp4l[i+1]==compBooting /\
  closeIdlingClock(c, cl, cu, e, co, comp4, i) /\ 
  cps(co, cl, cu, comp4, i)); % idling

% HARDCODED transition constraints for CONNECTION
constraint forall(i in STAGES)(not Eno4[9,i]); % state changing
constraint forall(i in STAGES)(not Eno4[10,i]); % state changing

constraint forall(i in STAGES)(Eno4[11,i] -> conn4l[i]==connected /\ openIdlingClock(c, cl, cu, e, co, conn4, i)); % idling
constraint forall(i in STAGES)(Eno4[12,i] -> conn4l[i]==disconnected /\ openIdlingClock(c, cl, cu, e, co, conn4, i)); % idling

constraint forall(i in STAGESm1)(Ene4[9,i] -> 
  conn4l[i]==connected /\ conn4l[i+1]==disconnected /\
  conn4u[i]==disconnect /\
  closeChangeClock(c, cl, cu, e, co, conn4, i) /\ 
  cvs(e, co, conn4, i) /\ cps(co, cl, cu, conn4, i)); % state changing

constraint forall(i in STAGESm1)(Ene4[10,i] ->
  conn4l[i]==disconnected /\ conn4l[i+1]==connected /\ 
  conn4u[i]==connect /\ comp4l[i]==compOff /\
  closeChangeClock(c, cl, cu, e, co, conn4, i) /\ 
  cvs(e, co, conn4, i) /\ cps(co, cl, cu, conn4, i)); % state changing

constraint forall(i in STAGESm1)(Ene4[11,i] -> 
  conn4l[i]==connected /\ conn4l[i+1]=connected /\ conn4u[i]!=disconnect /\
  closeIdlingClock(c, cl, cu, e, co, conn4, i) /\ 
  cps(co, cl, cu, conn4, i)); % idling

constraint forall(i in STAGESm1)(Ene4[12,i] -> 
  conn4l[i]==disconnected /\ conn4l[i+1]=disconnected /\ conn4u[i]!=connect /\
  closeIdlingClock(c, cl, cu, e, co, conn4, i) /\ 
  cps(co, cl, cu, conn4, i)); % idling

% % HARDCODED transition constraints for PROJECTOR
constraint forall(i in STAGES)(not Eno4[13,i]); % state changing
constraint forall(i in STAGES)(not Eno4[14,i]); % state changing
constraint forall(i in STAGES)(not Eno4[15,i]); % state changing
constraint forall(i in STAGES)(not Eno4[16,i]); % state changing
constraint forall(i in STAGES)(not Eno4[17,i]); % state changing
constraint forall(i in STAGES)(not Eno4[18,i]); % state changing
constraint forall(i in STAGES)(not Eno4[19,i]); % state changing
constraint forall(i in STAGES)(not Eno4[20,i]); % state changing
constraint forall(i in STAGES)(not Eno4[27,i]); % state changing
constraint forall(i in STAGES)(Eno4[21,i] -> proj4l[i]==projOff /\ openIdlingClock(c, cl, cu, e, co, proj4, i)); % idling
constraint forall(i in STAGES)(Eno4[22,i] -> proj4l[i]==projWarmUp /\ openIdlingClock(c, cl, cu, e, co, proj4, i)); % idling
constraint forall(i in STAGES)(Eno4[23,i] -> proj4l[i]==projOn /\ openIdlingClock(c, cl, cu, e, co, proj4, i)); % idling
constraint forall(i in STAGES)(Eno4[24,i] -> proj4l[i]==projConfirm /\ openIdlingClock(c, cl, cu, e, co, proj4, i)); % idling
constraint forall(i in STAGES)(Eno4[25,i] -> proj4l[i]==projCoolDown /\ openIdlingClock(c, cl, cu, e, co, proj4, i)); % idling
constraint forall(i in STAGES)(Eno4[26,i] -> proj4l[i]==projWaiting /\ openIdlingClock(c, cl, cu, e, co, proj4, i)); % idling
  
constraint forall(i in STAGESm1)(Ene4[13,i] ->
  proj4l[i]==projOff /\ proj4l[i+1]==projWarmUp /\ 
  proj4u[i]==projTurnOn /\
  closeChangeClock(c, cl, cu, e, co, proj4, i) /\ 
  cvs(e, co, proj4, i) /\ cps(co, cl, cu, proj4, i)); % state changing
  
constraint forall(i in STAGESm1)(Ene4[14,i] -> 
  proj4l[i]==projWarmUp /\ proj4l[i+1]==projOn /\ 
  c[proj4,i] == 30 /\
  closeChangeClock(c, cl, cu, e, co, proj4, i) /\ 
  cvs(e, co, proj4, i) /\ cps(co, cl, cu, proj4, i)); % state changing
  
constraint forall(i in STAGESm1)(Ene4[15,i] -> 
  proj4l[i]==projOn /\ proj4l[i+1]==projConfirm /\ 
  proj4u[i]==projTurnOff /\
  closeChangeClock(c, cl, cu, e, co, proj4, i) /\ 
  cvs(e, co, proj4, i) /\ cps(co, cl, cu, proj4, i)); % state changing
  
constraint forall(i in STAGESm1)(Ene4[16,i] -> 
  proj4l[i]==projOn /\ proj4l[i+1]==projWaiting /\ 
  (comp4l[i]!=compOn \/ conn4l[i]!=connected) /\ proj4u[i]!=projTurnOff /\
  closeChangeClock(c, cl, cu, e, co, proj4, i) /\ 
  cvs(e, co, proj4, i) /\ cps(co, cl, cu, proj4, i)); % state changing
  
constraint forall(i in STAGESm1)(Ene4[17,i] -> 
  proj4l[i]==projConfirm /\ proj4l[i+1]==projCoolDown /\ 
  proj4u[i]==projTurnOff /\ inRange(c[proj4,i],cl[proj4,i],cu[proj4,i]) /\
  closeChangeClock(c, cl, cu, e, co, proj4, i) /\ 
  cvs(e, co, proj4, i) /\ cps(co, cl, cu, proj4, i)); % state changing
  
constraint forall(i in STAGESm1)(Ene4[18,i] -> 
  proj4l[i]==projWaiting /\ proj4l[i+1]==projCoolDown /\ 
  (comp4l[i]!=compOn \/ conn4l[i]!=connected) /\ c[proj4,i]==60 /\
  closeChangeClock(c, cl, cu, e, co, proj4, i) /\ 
  cvs(e, co, proj4, i) /\ cps(co, cl, cu, proj4, i)); % state changing

constraint forall(i in STAGESm1)(Ene4[19,i] -> 
  proj4l[i]==projWaiting /\ proj4l[i+1]==projOn /\ 
  comp4l[i]==compOn /\ conn4l[i]==connected /\
  closeChangeClock(c, cl, cu, e, co, proj4, i) /\ 
  cvs(e, co, proj4, i) /\ cps(co, cl, cu, proj4, i)); % state changing
  
constraint forall(i in STAGESm1)(Ene4[20,i] -> 
  proj4l[i]==projConfirm /\ proj4l[i+1]==projOn /\ 
  proj4u[i]!=projTurnOff /\ c[proj4,i]==5 /\
  closeChangeClock(c, cl, cu, e, co, proj4, i) /\ 
  cvs(e, co, proj4, i) /\ cps(co, cl, cu, proj4, i)); % state changing

constraint forall(i in STAGESm1)(Ene4[27,i] -> 
  proj4l[i]==projCoolDown /\ proj4l[i+1]==projOff /\ 
  c[proj4,i]==60 /\
  closeChangeClock(c, cl, cu, e, co, proj4, i) /\ 
  cvs(e, co, proj4, i) /\ cps(co, cl, cu, proj4, i)); % state changing

constraint forall(i in STAGESm1)(Ene4[21,i] -> 
  proj4l[i]==projOff /\ proj4l[i+1]==projOff /\
  proj4u[i]!=projTurnOn /\
  closeIdlingClock(c, cl, cu, e, co, proj4, i) /\ 
  cps(co, cl, cu, proj4, i)); % idling
  
constraint forall(i in STAGESm1)(Ene4[22,i] -> 
  proj4l[i]==projWarmUp /\ proj4l[i+1]==projWarmUp /\
  closeIdlingClock(c, cl, cu, e, co, proj4, i) /\ 
  cps(co, cl, cu, proj4, i)); % idling
  
constraint forall(i in STAGESm1)(Ene4[23,i] -> 
  proj4l[i]==projOn /\ proj4l[i+1]==projOn /\ comp4l[i+1]==compOn /\ conn4l[i+1]==connected /\
  closeIdlingClock(c, cl, cu, e, co, proj4, i) /\ 
  cps(co, cl, cu, proj4, i)); % idling
  
constraint forall(i in STAGESm1)(Ene4[24,i] -> 
  proj4l[i]==projConfirm /\ proj4l[i+1]=projConfirm /\
  closeIdlingClock(c, cl, cu, e, co, proj4, i) /\ 
  cps(co, cl, cu, proj4, i)); % idling
  
constraint forall(i in STAGESm1)(Ene4[25,i] -> 
  proj4l[i]==projCoolDown /\ proj4l[i+1]==projCoolDown /\
  closeIdlingClock(c, cl, cu, e, co, proj4, i) /\ 
  cps(co, cl, cu, proj4, i)); % idling
  
constraint forall(i in STAGESm1)(Ene4[26,i] -> 
  proj4l[i]==projWaiting /\ proj4l[i+1]==projWaiting /\
  closeIdlingClock(c, cl, cu, e, co, proj4, i) /\ 
  cps(co, cl, cu, proj4, i)); % idling

constraint forall(i in STAGES)(not Eno5[1,i]); % state changing
constraint forall(i in STAGES)(not Eno5[2,i]); % state changing
constraint forall(i in STAGES)(not Eno5[3,i]); % state changing
constraint forall(i in STAGES)(not Eno5[4,i]); % state changing

constraint forall(i in STAGES)(Eno5[5,i] -> comp5l[i]==compOn /\ openIdlingClock(c, cl, cu, e, co, comp5, i)); % idling
constraint forall(i in STAGES)(Eno5[6,i] -> comp5l[i]==compShutdown /\ openIdlingClock(c, cl, cu, e, co, comp5, i)); % idling
constraint forall(i in STAGES)(Eno5[7,i] -> comp5l[i]==compOff /\ openIdlingClock(c, cl, cu, e, co, comp5, i)); % idling
constraint forall(i in STAGES)(Eno5[8,i] -> comp5l[i]==compBooting /\ openIdlingClock(c, cl, cu, e, co, comp5, i)); % idling

constraint forall(i in STAGESm1)(Ene5[1,i] -> 
  comp5l[i]==compOn /\ comp5l[i+1]==compShutdown /\ 
  comp5u[i]==compTurnOff /\ 
  closeChangeClock(c, cl, cu, e, co, comp5, i) /\ 
  cvs(e, co, comp5, i) /\ cps(co, cl, cu, comp5, i)); % state changing
constraint forall(i in STAGESm1)(Ene5[2,i] -> 
  comp5l[i]==compShutdown /\ comp5l[i+1]==compOff /\ 
  c[comp5,i]==30 /\
  closeChangeClock(c, cl, cu, e, co, comp5, i) /\ 
  cvs(e, co, comp5, i) /\ cps(co, cl, cu, comp5, i)); % state changing
constraint forall(i in STAGESm1)(Ene5[3,i] ->
  comp5l[i]==compOff /\ comp5l[i+1]==compBooting /\ 
  comp5u[i]==compTurnOn /\
  closeChangeClock(c, cl, cu, e, co, comp5, i) /\ 
  cvs(e, co, comp5, i) /\ cps(co, cl, cu, comp5, i)); % state changing
constraint forall(i in STAGESm1)(Ene5[4,i] ->
  comp5l[i]==compBooting /\ comp5l[i+1]==compOn /\ 
  c[comp5,i]==15 /\
  closeChangeClock(c, cl, cu, e, co, comp5, i) /\ 
  cvs(e, co, comp5, i) /\ cps(co, cl, cu, comp5, i)); % state changing

constraint forall(i in STAGESm1)(Ene5[5,i] ->
  comp5l[i]==compOn /\ comp5l[i+1]==compOn /\ comp5u[i]!=compTurnOff /\
  closeIdlingClock(c, cl, cu, e, co, comp5, i) /\ 
  cps(co, cl, cu, comp5, i)); % idling
constraint forall(i in STAGESm1)(Ene5[6,i] ->
  comp5l[i]==compShutdown /\ comp5l[i+1]==compShutdown /\
  closeIdlingClock(c, cl, cu, e, co, comp5, i) /\ 
  cps(co, cl, cu, comp5, i)); % idling
constraint forall(i in STAGESm1)(Ene5[7,i] ->
  comp5l[i]==compOff /\ comp5l[i+1]==compOff /\ comp5u[i]!=compTurnOn /\
  closeIdlingClock(c, cl, cu, e, co, comp5, i)  /\ 
  cps(co, cl, cu, comp5, i)); % idling
constraint forall(i in STAGESm1)(Ene5[8,i] ->
  comp5l[i]==compBooting /\ comp5l[i+1]==compBooting /\
  closeIdlingClock(c, cl, cu, e, co, comp5, i) /\ 
  cps(co, cl, cu, comp5, i)); % idling

% HARDCODED transition constraints for CONNECTION
constraint forall(i in STAGES)(not Eno5[9,i]); % state changing
constraint forall(i in STAGES)(not Eno5[10,i]); % state changing

constraint forall(i in STAGES)(Eno5[11,i] -> conn5l[i]==connected /\ openIdlingClock(c, cl, cu, e, co, conn5, i)); % idling
constraint forall(i in STAGES)(Eno5[12,i] -> conn5l[i]==disconnected /\ openIdlingClock(c, cl, cu, e, co, conn5, i)); % idling

constraint forall(i in STAGESm1)(Ene5[9,i] -> 
  conn5l[i]==connected /\ conn5l[i+1]==disconnected /\
  conn5u[i]==disconnect /\
  closeChangeClock(c, cl, cu, e, co, conn5, i) /\ 
  cvs(e, co, conn5, i) /\ cps(co, cl, cu, conn5, i)); % state changing

constraint forall(i in STAGESm1)(Ene5[10,i] ->
  conn5l[i]==disconnected /\ conn5l[i+1]==connected /\ 
  conn5u[i]==connect /\ comp5l[i]==compOff /\
  closeChangeClock(c, cl, cu, e, co, conn5, i) /\ 
  cvs(e, co, conn5, i) /\ cps(co, cl, cu, conn5, i)); % state changing

constraint forall(i in STAGESm1)(Ene5[11,i] -> 
  conn5l[i]==connected /\ conn5l[i+1]=connected /\ conn5u[i]!=disconnect /\
  closeIdlingClock(c, cl, cu, e, co, conn5, i) /\ 
  cps(co, cl, cu, conn5, i)); % idling

constraint forall(i in STAGESm1)(Ene5[12,i] -> 
  conn5l[i]==disconnected /\ conn5l[i+1]=disconnected /\ conn5u[i]!=connect /\
  closeIdlingClock(c, cl, cu, e, co, conn5, i) /\ 
  cps(co, cl, cu, conn5, i)); % idling

% % HARDCODED transition constraints for PROJECTOR
constraint forall(i in STAGES)(not Eno5[13,i]); % state changing
constraint forall(i in STAGES)(not Eno5[14,i]); % state changing
constraint forall(i in STAGES)(not Eno5[15,i]); % state changing
constraint forall(i in STAGES)(not Eno5[16,i]); % state changing
constraint forall(i in STAGES)(not Eno5[17,i]); % state changing
constraint forall(i in STAGES)(not Eno5[18,i]); % state changing
constraint forall(i in STAGES)(not Eno5[19,i]); % state changing
constraint forall(i in STAGES)(not Eno5[20,i]); % state changing
constraint forall(i in STAGES)(not Eno5[27,i]); % state changing
constraint forall(i in STAGES)(Eno5[21,i] -> proj5l[i]==projOff /\ openIdlingClock(c, cl, cu, e, co, proj5, i)); % idling
constraint forall(i in STAGES)(Eno5[22,i] -> proj5l[i]==projWarmUp /\ openIdlingClock(c, cl, cu, e, co, proj5, i)); % idling
constraint forall(i in STAGES)(Eno5[23,i] -> proj5l[i]==projOn /\ openIdlingClock(c, cl, cu, e, co, proj5, i)); % idling
constraint forall(i in STAGES)(Eno5[24,i] -> proj5l[i]==projConfirm /\ openIdlingClock(c, cl, cu, e, co, proj5, i)); % idling
constraint forall(i in STAGES)(Eno5[25,i] -> proj5l[i]==projCoolDown /\ openIdlingClock(c, cl, cu, e, co, proj5, i)); % idling
constraint forall(i in STAGES)(Eno5[26,i] -> proj5l[i]==projWaiting /\ openIdlingClock(c, cl, cu, e, co, proj5, i)); % idling
  
constraint forall(i in STAGESm1)(Ene5[13,i] ->
  proj5l[i]==projOff /\ proj5l[i+1]==projWarmUp /\ 
  proj5u[i]==projTurnOn /\
  closeChangeClock(c, cl, cu, e, co, proj5, i) /\ 
  cvs(e, co, proj5, i) /\ cps(co, cl, cu, proj5, i)); % state changing
  
constraint forall(i in STAGESm1)(Ene5[14,i] -> 
  proj5l[i]==projWarmUp /\ proj5l[i+1]==projOn /\ 
  c[proj5,i] == 30 /\
  closeChangeClock(c, cl, cu, e, co, proj5, i) /\ 
  cvs(e, co, proj5, i) /\ cps(co, cl, cu, proj5, i)); % state changing
  
constraint forall(i in STAGESm1)(Ene5[15,i] -> 
  proj5l[i]==projOn /\ proj5l[i+1]==projConfirm /\ 
  proj5u[i]==projTurnOff /\
  closeChangeClock(c, cl, cu, e, co, proj5, i) /\ 
  cvs(e, co, proj5, i) /\ cps(co, cl, cu, proj5, i)); % state changing
  
constraint forall(i in STAGESm1)(Ene5[16,i] -> 
  proj5l[i]==projOn /\ proj5l[i+1]==projWaiting /\ 
  (comp5l[i]!=compOn \/ conn5l[i]!=connected) /\ proj5u[i]!=projTurnOff /\
  closeChangeClock(c, cl, cu, e, co, proj5, i) /\ 
  cvs(e, co, proj5, i) /\ cps(co, cl, cu, proj5, i)); % state changing
  
constraint forall(i in STAGESm1)(Ene5[17,i] -> 
  proj5l[i]==projConfirm /\ proj5l[i+1]==projCoolDown /\ 
  proj5u[i]==projTurnOff /\ inRange(c[proj5,i],cl[proj5,i],cu[proj5,i]) /\
  closeChangeClock(c, cl, cu, e, co, proj5, i) /\ 
  cvs(e, co, proj5, i) /\ cps(co, cl, cu, proj5, i)); % state changing
  
constraint forall(i in STAGESm1)(Ene5[18,i] -> 
  proj5l[i]==projWaiting /\ proj5l[i+1]==projCoolDown /\ 
  (comp5l[i]!=compOn \/ conn5l[i]!=connected) /\ c[proj5,i]==60 /\
  closeChangeClock(c, cl, cu, e, co, proj5, i) /\ 
  cvs(e, co, proj5, i) /\ cps(co, cl, cu, proj5, i)); % state changing

constraint forall(i in STAGESm1)(Ene5[19,i] -> 
  proj5l[i]==projWaiting /\ proj5l[i+1]==projOn /\ 
  comp5l[i]==compOn /\ conn5l[i]==connected /\
  closeChangeClock(c, cl, cu, e, co, proj5, i) /\ 
  cvs(e, co, proj5, i) /\ cps(co, cl, cu, proj5, i)); % state changing
  
constraint forall(i in STAGESm1)(Ene5[20,i] -> 
  proj5l[i]==projConfirm /\ proj5l[i+1]==projOn /\ 
  proj5u[i]!=projTurnOff /\ c[proj5,i]==5 /\
  closeChangeClock(c, cl, cu, e, co, proj5, i) /\ 
  cvs(e, co, proj5, i) /\ cps(co, cl, cu, proj5, i)); % state changing

constraint forall(i in STAGESm1)(Ene5[27,i] -> 
  proj5l[i]==projCoolDown /\ proj5l[i+1]==projOff /\ 
  c[proj5,i]==60 /\
  closeChangeClock(c, cl, cu, e, co, proj5, i) /\ 
  cvs(e, co, proj5, i) /\ cps(co, cl, cu, proj5, i)); % state changing

constraint forall(i in STAGESm1)(Ene5[21,i] -> 
  proj5l[i]==projOff /\ proj5l[i+1]==projOff /\
  proj5u[i]!=projTurnOn /\
  closeIdlingClock(c, cl, cu, e, co, proj5, i) /\ 
  cps(co, cl, cu, proj5, i)); % idling
  
constraint forall(i in STAGESm1)(Ene5[22,i] -> 
  proj5l[i]==projWarmUp /\ proj5l[i+1]==projWarmUp /\
  closeIdlingClock(c, cl, cu, e, co, proj5, i) /\ 
  cps(co, cl, cu, proj5, i)); % idling
  
constraint forall(i in STAGESm1)(Ene5[23,i] -> 
  proj5l[i]==projOn /\ proj5l[i+1]==projOn /\ comp5l[i+1]==compOn /\ conn5l[i+1]==connected /\
  closeIdlingClock(c, cl, cu, e, co, proj5, i) /\ 
  cps(co, cl, cu, proj5, i)); % idling
  
constraint forall(i in STAGESm1)(Ene5[24,i] -> 
  proj5l[i]==projConfirm /\ proj5l[i+1]=projConfirm /\
  closeIdlingClock(c, cl, cu, e, co, proj5, i) /\ 
  cps(co, cl, cu, proj5, i)); % idling
  
constraint forall(i in STAGESm1)(Ene5[25,i] -> 
  proj5l[i]==projCoolDown /\ proj5l[i+1]==projCoolDown /\
  closeIdlingClock(c, cl, cu, e, co, proj5, i) /\ 
  cps(co, cl, cu, proj5, i)); % idling
  
constraint forall(i in STAGESm1)(Ene5[26,i] -> 
  proj5l[i]==projWaiting /\ proj5l[i+1]==projWaiting /\
  closeIdlingClock(c, cl, cu, e, co, proj5, i) /\ 
  cps(co, cl, cu, proj5, i)); % idling

constraint forall(i in STAGES)(not Eno6[1,i]); % state changing
constraint forall(i in STAGES)(not Eno6[2,i]); % state changing
constraint forall(i in STAGES)(not Eno6[3,i]); % state changing
constraint forall(i in STAGES)(not Eno6[4,i]); % state changing

constraint forall(i in STAGES)(Eno6[5,i] -> comp6l[i]==compOn /\ openIdlingClock(c, cl, cu, e, co, comp6, i)); % idling
constraint forall(i in STAGES)(Eno6[6,i] -> comp6l[i]==compShutdown /\ openIdlingClock(c, cl, cu, e, co, comp6, i)); % idling
constraint forall(i in STAGES)(Eno6[7,i] -> comp6l[i]==compOff /\ openIdlingClock(c, cl, cu, e, co, comp6, i)); % idling
constraint forall(i in STAGES)(Eno6[8,i] -> comp6l[i]==compBooting /\ openIdlingClock(c, cl, cu, e, co, comp6, i)); % idling

constraint forall(i in STAGESm1)(Ene6[1,i] -> 
  comp6l[i]==compOn /\ comp6l[i+1]==compShutdown /\ 
  comp6u[i]==compTurnOff /\ 
  closeChangeClock(c, cl, cu, e, co, comp6, i) /\ 
  cvs(e, co, comp6, i) /\ cps(co, cl, cu, comp6, i)); % state changing
constraint forall(i in STAGESm1)(Ene6[2,i] -> 
  comp6l[i]==compShutdown /\ comp6l[i+1]==compOff /\ 
  c[comp6,i]==30 /\
  closeChangeClock(c, cl, cu, e, co, comp6, i) /\ 
  cvs(e, co, comp6, i) /\ cps(co, cl, cu, comp6, i)); % state changing
constraint forall(i in STAGESm1)(Ene6[3,i] ->
  comp6l[i]==compOff /\ comp6l[i+1]==compBooting /\ 
  comp6u[i]==compTurnOn /\
  closeChangeClock(c, cl, cu, e, co, comp6, i) /\ 
  cvs(e, co, comp6, i) /\ cps(co, cl, cu, comp6, i)); % state changing
constraint forall(i in STAGESm1)(Ene6[4,i] ->
  comp6l[i]==compBooting /\ comp6l[i+1]==compOn /\ 
  c[comp6,i]==15 /\
  closeChangeClock(c, cl, cu, e, co, comp6, i) /\ 
  cvs(e, co, comp6, i) /\ cps(co, cl, cu, comp6, i)); % state changing

constraint forall(i in STAGESm1)(Ene6[5,i] ->
  comp6l[i]==compOn /\ comp6l[i+1]==compOn /\ comp6u[i]!=compTurnOff /\
  closeIdlingClock(c, cl, cu, e, co, comp6, i) /\ 
  cps(co, cl, cu, comp6, i)); % idling
constraint forall(i in STAGESm1)(Ene6[6,i] ->
  comp6l[i]==compShutdown /\ comp6l[i+1]==compShutdown /\
  closeIdlingClock(c, cl, cu, e, co, comp6, i) /\ 
  cps(co, cl, cu, comp6, i)); % idling
constraint forall(i in STAGESm1)(Ene6[7,i] ->
  comp6l[i]==compOff /\ comp6l[i+1]==compOff /\ comp6u[i]!=compTurnOn /\
  closeIdlingClock(c, cl, cu, e, co, comp6, i)  /\ 
  cps(co, cl, cu, comp6, i)); % idling
constraint forall(i in STAGESm1)(Ene6[8,i] ->
  comp6l[i]==compBooting /\ comp6l[i+1]==compBooting /\
  closeIdlingClock(c, cl, cu, e, co, comp6, i) /\ 
  cps(co, cl, cu, comp6, i)); % idling

% HARDCODED transition constraints for CONNECTION
constraint forall(i in STAGES)(not Eno6[9,i]); % state changing
constraint forall(i in STAGES)(not Eno6[10,i]); % state changing

constraint forall(i in STAGES)(Eno6[11,i] -> conn6l[i]==connected /\ openIdlingClock(c, cl, cu, e, co, conn6, i)); % idling
constraint forall(i in STAGES)(Eno6[12,i] -> conn6l[i]==disconnected /\ openIdlingClock(c, cl, cu, e, co, conn6, i)); % idling

constraint forall(i in STAGESm1)(Ene6[9,i] -> 
  conn6l[i]==connected /\ conn6l[i+1]==disconnected /\
  conn6u[i]==disconnect /\
  closeChangeClock(c, cl, cu, e, co, conn6, i) /\ 
  cvs(e, co, conn6, i) /\ cps(co, cl, cu, conn6, i)); % state changing

constraint forall(i in STAGESm1)(Ene6[10,i] ->
  conn6l[i]==disconnected /\ conn6l[i+1]==connected /\ 
  conn6u[i]==connect /\ comp6l[i]==compOff /\
  closeChangeClock(c, cl, cu, e, co, conn6, i) /\ 
  cvs(e, co, conn6, i) /\ cps(co, cl, cu, conn6, i)); % state changing

constraint forall(i in STAGESm1)(Ene6[11,i] -> 
  conn6l[i]==connected /\ conn6l[i+1]=connected /\ conn6u[i]!=disconnect /\
  closeIdlingClock(c, cl, cu, e, co, conn6, i) /\ 
  cps(co, cl, cu, conn6, i)); % idling

constraint forall(i in STAGESm1)(Ene6[12,i] -> 
  conn6l[i]==disconnected /\ conn6l[i+1]=disconnected /\ conn6u[i]!=connect /\
  closeIdlingClock(c, cl, cu, e, co, conn6, i) /\ 
  cps(co, cl, cu, conn6, i)); % idling

% % HARDCODED transition constraints for PROJECTOR
constraint forall(i in STAGES)(not Eno6[13,i]); % state changing
constraint forall(i in STAGES)(not Eno6[14,i]); % state changing
constraint forall(i in STAGES)(not Eno6[15,i]); % state changing
constraint forall(i in STAGES)(not Eno6[16,i]); % state changing
constraint forall(i in STAGES)(not Eno6[17,i]); % state changing
constraint forall(i in STAGES)(not Eno6[18,i]); % state changing
constraint forall(i in STAGES)(not Eno6[19,i]); % state changing
constraint forall(i in STAGES)(not Eno6[20,i]); % state changing
constraint forall(i in STAGES)(not Eno6[27,i]); % state changing
constraint forall(i in STAGES)(Eno6[21,i] -> proj6l[i]==projOff /\ openIdlingClock(c, cl, cu, e, co, proj6, i)); % idling
constraint forall(i in STAGES)(Eno6[22,i] -> proj6l[i]==projWarmUp /\ openIdlingClock(c, cl, cu, e, co, proj6, i)); % idling
constraint forall(i in STAGES)(Eno6[23,i] -> proj6l[i]==projOn /\ openIdlingClock(c, cl, cu, e, co, proj6, i)); % idling
constraint forall(i in STAGES)(Eno6[24,i] -> proj6l[i]==projConfirm /\ openIdlingClock(c, cl, cu, e, co, proj6, i)); % idling
constraint forall(i in STAGES)(Eno6[25,i] -> proj6l[i]==projCoolDown /\ openIdlingClock(c, cl, cu, e, co, proj6, i)); % idling
constraint forall(i in STAGES)(Eno6[26,i] -> proj6l[i]==projWaiting /\ openIdlingClock(c, cl, cu, e, co, proj6, i)); % idling
  
constraint forall(i in STAGESm1)(Ene6[13,i] ->
  proj6l[i]==projOff /\ proj6l[i+1]==projWarmUp /\ 
  proj6u[i]==projTurnOn /\
  closeChangeClock(c, cl, cu, e, co, proj6, i) /\ 
  cvs(e, co, proj6, i) /\ cps(co, cl, cu, proj6, i)); % state changing
  
constraint forall(i in STAGESm1)(Ene6[14,i] -> 
  proj6l[i]==projWarmUp /\ proj6l[i+1]==projOn /\ 
  c[proj6,i] == 30 /\
  closeChangeClock(c, cl, cu, e, co, proj6, i) /\ 
  cvs(e, co, proj6, i) /\ cps(co, cl, cu, proj6, i)); % state changing
  
constraint forall(i in STAGESm1)(Ene6[15,i] -> 
  proj6l[i]==projOn /\ proj6l[i+1]==projConfirm /\ 
  proj6u[i]==projTurnOff /\
  closeChangeClock(c, cl, cu, e, co, proj6, i) /\ 
  cvs(e, co, proj6, i) /\ cps(co, cl, cu, proj6, i)); % state changing
  
constraint forall(i in STAGESm1)(Ene6[16,i] -> 
  proj6l[i]==projOn /\ proj6l[i+1]==projWaiting /\ 
  (comp6l[i]!=compOn \/ conn6l[i]!=connected) /\ proj6u[i]!=projTurnOff /\
  closeChangeClock(c, cl, cu, e, co, proj6, i) /\ 
  cvs(e, co, proj6, i) /\ cps(co, cl, cu, proj6, i)); % state changing
  
constraint forall(i in STAGESm1)(Ene6[17,i] -> 
  proj6l[i]==projConfirm /\ proj6l[i+1]==projCoolDown /\ 
  proj6u[i]==projTurnOff /\ inRange(c[proj6,i],cl[proj6,i],cu[proj6,i]) /\
  closeChangeClock(c, cl, cu, e, co, proj6, i) /\ 
  cvs(e, co, proj6, i) /\ cps(co, cl, cu, proj6, i)); % state changing
  
constraint forall(i in STAGESm1)(Ene6[18,i] -> 
  proj6l[i]==projWaiting /\ proj6l[i+1]==projCoolDown /\ 
  (comp6l[i]!=compOn \/ conn6l[i]!=connected) /\ c[proj6,i]==60 /\
  closeChangeClock(c, cl, cu, e, co, proj6, i) /\ 
  cvs(e, co, proj6, i) /\ cps(co, cl, cu, proj6, i)); % state changing

constraint forall(i in STAGESm1)(Ene6[19,i] -> 
  proj6l[i]==projWaiting /\ proj6l[i+1]==projOn /\ 
  comp6l[i]==compOn /\ conn6l[i]==connected /\
  closeChangeClock(c, cl, cu, e, co, proj6, i) /\ 
  cvs(e, co, proj6, i) /\ cps(co, cl, cu, proj6, i)); % state changing
  
constraint forall(i in STAGESm1)(Ene6[20,i] -> 
  proj6l[i]==projConfirm /\ proj6l[i+1]==projOn /\ 
  proj6u[i]!=projTurnOff /\ c[proj6,i]==5 /\
  closeChangeClock(c, cl, cu, e, co, proj6, i) /\ 
  cvs(e, co, proj6, i) /\ cps(co, cl, cu, proj6, i)); % state changing

constraint forall(i in STAGESm1)(Ene6[27,i] -> 
  proj6l[i]==projCoolDown /\ proj6l[i+1]==projOff /\ 
  c[proj6,i]==60 /\
  closeChangeClock(c, cl, cu, e, co, proj6, i) /\ 
  cvs(e, co, proj6, i) /\ cps(co, cl, cu, proj6, i)); % state changing

constraint forall(i in STAGESm1)(Ene6[21,i] -> 
  proj6l[i]==projOff /\ proj6l[i+1]==projOff /\
  proj6u[i]!=projTurnOn /\
  closeIdlingClock(c, cl, cu, e, co, proj6, i) /\ 
  cps(co, cl, cu, proj6, i)); % idling
  
constraint forall(i in STAGESm1)(Ene6[22,i] -> 
  proj6l[i]==projWarmUp /\ proj6l[i+1]==projWarmUp /\
  closeIdlingClock(c, cl, cu, e, co, proj6, i) /\ 
  cps(co, cl, cu, proj6, i)); % idling
  
constraint forall(i in STAGESm1)(Ene6[23,i] -> 
  proj6l[i]==projOn /\ proj6l[i+1]==projOn /\ comp6l[i+1]==compOn /\ conn6l[i+1]==connected /\
  closeIdlingClock(c, cl, cu, e, co, proj6, i) /\ 
  cps(co, cl, cu, proj6, i)); % idling
  
constraint forall(i in STAGESm1)(Ene6[24,i] -> 
  proj6l[i]==projConfirm /\ proj6l[i+1]=projConfirm /\
  closeIdlingClock(c, cl, cu, e, co, proj6, i) /\ 
  cps(co, cl, cu, proj6, i)); % idling
  
constraint forall(i in STAGESm1)(Ene6[25,i] -> 
  proj6l[i]==projCoolDown /\ proj6l[i+1]==projCoolDown /\
  closeIdlingClock(c, cl, cu, e, co, proj6, i) /\ 
  cps(co, cl, cu, proj6, i)); % idling
  
constraint forall(i in STAGESm1)(Ene6[26,i] -> 
  proj6l[i]==projWaiting /\ proj6l[i+1]==projWaiting /\
  closeIdlingClock(c, cl, cu, e, co, proj6, i) /\ 
  cps(co, cl, cu, proj6, i)); % idling
  

constraint forall(i in STAGES)(not Eno7[1,i]); % state changing
constraint forall(i in STAGES)(not Eno7[2,i]); % state changing
constraint forall(i in STAGES)(not Eno7[3,i]); % state changing
constraint forall(i in STAGES)(not Eno7[4,i]); % state changing

constraint forall(i in STAGES)(Eno7[5,i] -> comp7l[i]==compOn /\ openIdlingClock(c, cl, cu, e, co, comp7, i)); % idling
constraint forall(i in STAGES)(Eno7[6,i] -> comp7l[i]==compShutdown /\ openIdlingClock(c, cl, cu, e, co, comp7, i)); % idling
constraint forall(i in STAGES)(Eno7[7,i] -> comp7l[i]==compOff /\ openIdlingClock(c, cl, cu, e, co, comp7, i)); % idling
constraint forall(i in STAGES)(Eno7[8,i] -> comp7l[i]==compBooting /\ openIdlingClock(c, cl, cu, e, co, comp7, i)); % idling

constraint forall(i in STAGESm1)(Ene7[1,i] -> 
  comp7l[i]==compOn /\ comp7l[i+1]==compShutdown /\ 
  comp7u[i]==compTurnOff /\ 
  closeChangeClock(c, cl, cu, e, co, comp7, i) /\ 
  cvs(e, co, comp7, i) /\ cps(co, cl, cu, comp7, i)); % state changing
constraint forall(i in STAGESm1)(Ene7[2,i] -> 
  comp7l[i]==compShutdown /\ comp7l[i+1]==compOff /\ 
  c[comp7,i]==30 /\
  closeChangeClock(c, cl, cu, e, co, comp7, i) /\ 
  cvs(e, co, comp7, i) /\ cps(co, cl, cu, comp7, i)); % state changing
constraint forall(i in STAGESm1)(Ene7[3,i] ->
  comp7l[i]==compOff /\ comp7l[i+1]==compBooting /\ 
  comp7u[i]==compTurnOn /\
  closeChangeClock(c, cl, cu, e, co, comp7, i) /\ 
  cvs(e, co, comp7, i) /\ cps(co, cl, cu, comp7, i)); % state changing
constraint forall(i in STAGESm1)(Ene7[4,i] ->
  comp7l[i]==compBooting /\ comp7l[i+1]==compOn /\ 
  c[comp7,i]==15 /\
  closeChangeClock(c, cl, cu, e, co, comp7, i) /\ 
  cvs(e, co, comp7, i) /\ cps(co, cl, cu, comp7, i)); % state changing

constraint forall(i in STAGESm1)(Ene7[5,i] ->
  comp7l[i]==compOn /\ comp7l[i+1]==compOn /\ comp7u[i]!=compTurnOff /\
  closeIdlingClock(c, cl, cu, e, co, comp7, i) /\ 
  cps(co, cl, cu, comp7, i)); % idling
constraint forall(i in STAGESm1)(Ene7[6,i] ->
  comp7l[i]==compShutdown /\ comp7l[i+1]==compShutdown /\
  closeIdlingClock(c, cl, cu, e, co, comp7, i) /\ 
  cps(co, cl, cu, comp7, i)); % idling
constraint forall(i in STAGESm1)(Ene7[7,i] ->
  comp7l[i]==compOff /\ comp7l[i+1]==compOff /\ comp7u[i]!=compTurnOn /\
  closeIdlingClock(c, cl, cu, e, co, comp7, i)  /\ 
  cps(co, cl, cu, comp7, i)); % idling
constraint forall(i in STAGESm1)(Ene7[8,i] ->
  comp7l[i]==compBooting /\ comp7l[i+1]==compBooting /\
  closeIdlingClock(c, cl, cu, e, co, comp7, i) /\ 
  cps(co, cl, cu, comp7, i)); % idling

% HARDCODED transition constraints for CONNECTION
constraint forall(i in STAGES)(not Eno7[9,i]); % state changing
constraint forall(i in STAGES)(not Eno7[10,i]); % state changing

constraint forall(i in STAGES)(Eno7[11,i] -> conn7l[i]==connected /\ openIdlingClock(c, cl, cu, e, co, conn7, i)); % idling
constraint forall(i in STAGES)(Eno7[12,i] -> conn7l[i]==disconnected /\ openIdlingClock(c, cl, cu, e, co, conn7, i)); % idling

constraint forall(i in STAGESm1)(Ene7[9,i] -> 
  conn7l[i]==connected /\ conn7l[i+1]==disconnected /\
  conn7u[i]==disconnect /\
  closeChangeClock(c, cl, cu, e, co, conn7, i) /\ 
  cvs(e, co, conn7, i) /\ cps(co, cl, cu, conn7, i)); % state changing

constraint forall(i in STAGESm1)(Ene7[10,i] ->
  conn7l[i]==disconnected /\ conn7l[i+1]==connected /\ 
  conn7u[i]==connect /\ comp7l[i]==compOff /\
  closeChangeClock(c, cl, cu, e, co, conn7, i) /\ 
  cvs(e, co, conn7, i) /\ cps(co, cl, cu, conn7, i)); % state changing

constraint forall(i in STAGESm1)(Ene7[11,i] -> 
  conn7l[i]==connected /\ conn7l[i+1]=connected /\ conn7u[i]!=disconnect /\
  closeIdlingClock(c, cl, cu, e, co, conn7, i) /\ 
  cps(co, cl, cu, conn7, i)); % idling

constraint forall(i in STAGESm1)(Ene7[12,i] -> 
  conn7l[i]==disconnected /\ conn7l[i+1]=disconnected /\ conn7u[i]!=connect /\
  closeIdlingClock(c, cl, cu, e, co, conn7, i) /\ 
  cps(co, cl, cu, conn7, i)); % idling

% % HARDCODED transition constraints for PROJECTOR
constraint forall(i in STAGES)(not Eno7[13,i]); % state changing
constraint forall(i in STAGES)(not Eno7[14,i]); % state changing
constraint forall(i in STAGES)(not Eno7[15,i]); % state changing
constraint forall(i in STAGES)(not Eno7[16,i]); % state changing
constraint forall(i in STAGES)(not Eno7[17,i]); % state changing
constraint forall(i in STAGES)(not Eno7[18,i]); % state changing
constraint forall(i in STAGES)(not Eno7[19,i]); % state changing
constraint forall(i in STAGES)(not Eno7[20,i]); % state changing
constraint forall(i in STAGES)(not Eno7[27,i]); % state changing
constraint forall(i in STAGES)(Eno7[21,i] -> proj7l[i]==projOff /\ openIdlingClock(c, cl, cu, e, co, proj7, i)); % idling
constraint forall(i in STAGES)(Eno7[22,i] -> proj7l[i]==projWarmUp /\ openIdlingClock(c, cl, cu, e, co, proj7, i)); % idling
constraint forall(i in STAGES)(Eno7[23,i] -> proj7l[i]==projOn /\ openIdlingClock(c, cl, cu, e, co, proj7, i)); % idling
constraint forall(i in STAGES)(Eno7[24,i] -> proj7l[i]==projConfirm /\ openIdlingClock(c, cl, cu, e, co, proj7, i)); % idling
constraint forall(i in STAGES)(Eno7[25,i] -> proj7l[i]==projCoolDown /\ openIdlingClock(c, cl, cu, e, co, proj7, i)); % idling
constraint forall(i in STAGES)(Eno7[26,i] -> proj7l[i]==projWaiting /\ openIdlingClock(c, cl, cu, e, co, proj7, i)); % idling
  
constraint forall(i in STAGESm1)(Ene7[13,i] ->
  proj7l[i]==projOff /\ proj7l[i+1]==projWarmUp /\ 
  proj7u[i]==projTurnOn /\
  closeChangeClock(c, cl, cu, e, co, proj7, i) /\ 
  cvs(e, co, proj7, i) /\ cps(co, cl, cu, proj7, i)); % state changing
  
constraint forall(i in STAGESm1)(Ene7[14,i] -> 
  proj7l[i]==projWarmUp /\ proj7l[i+1]==projOn /\ 
  c[proj7,i] == 30 /\
  closeChangeClock(c, cl, cu, e, co, proj7, i) /\ 
  cvs(e, co, proj7, i) /\ cps(co, cl, cu, proj7, i)); % state changing
  
constraint forall(i in STAGESm1)(Ene7[15,i] -> 
  proj7l[i]==projOn /\ proj7l[i+1]==projConfirm /\ 
  proj7u[i]==projTurnOff /\
  closeChangeClock(c, cl, cu, e, co, proj7, i) /\ 
  cvs(e, co, proj7, i) /\ cps(co, cl, cu, proj7, i)); % state changing
  
constraint forall(i in STAGESm1)(Ene7[16,i] -> 
  proj7l[i]==projOn /\ proj7l[i+1]==projWaiting /\ 
  (comp7l[i]!=compOn \/ conn7l[i]!=connected) /\ proj7u[i]!=projTurnOff /\
  closeChangeClock(c, cl, cu, e, co, proj7, i) /\ 
  cvs(e, co, proj7, i) /\ cps(co, cl, cu, proj7, i)); % state changing
  
constraint forall(i in STAGESm1)(Ene7[17,i] -> 
  proj7l[i]==projConfirm /\ proj7l[i+1]==projCoolDown /\ 
  proj7u[i]==projTurnOff /\ inRange(c[proj7,i],cl[proj7,i],cu[proj7,i]) /\
  closeChangeClock(c, cl, cu, e, co, proj7, i) /\ 
  cvs(e, co, proj7, i) /\ cps(co, cl, cu, proj7, i)); % state changing
  
constraint forall(i in STAGESm1)(Ene7[18,i] -> 
  proj7l[i]==projWaiting /\ proj7l[i+1]==projCoolDown /\ 
  (comp7l[i]!=compOn \/ conn7l[i]!=connected) /\ c[proj7,i]==60 /\
  closeChangeClock(c, cl, cu, e, co, proj7, i) /\ 
  cvs(e, co, proj7, i) /\ cps(co, cl, cu, proj7, i)); % state changing

constraint forall(i in STAGESm1)(Ene7[19,i] -> 
  proj7l[i]==projWaiting /\ proj7l[i+1]==projOn /\ 
  comp7l[i]==compOn /\ conn7l[i]==connected /\
  closeChangeClock(c, cl, cu, e, co, proj7, i) /\ 
  cvs(e, co, proj7, i) /\ cps(co, cl, cu, proj7, i)); % state changing
  
constraint forall(i in STAGESm1)(Ene7[20,i] -> 
  proj7l[i]==projConfirm /\ proj7l[i+1]==projOn /\ 
  proj7u[i]!=projTurnOff /\ c[proj7,i]==5 /\
  closeChangeClock(c, cl, cu, e, co, proj7, i) /\ 
  cvs(e, co, proj7, i) /\ cps(co, cl, cu, proj7, i)); % state changing

constraint forall(i in STAGESm1)(Ene7[27,i] -> 
  proj7l[i]==projCoolDown /\ proj7l[i+1]==projOff /\ 
  c[proj7,i]==60 /\
  closeChangeClock(c, cl, cu, e, co, proj7, i) /\ 
  cvs(e, co, proj7, i) /\ cps(co, cl, cu, proj7, i)); % state changing

constraint forall(i in STAGESm1)(Ene7[21,i] -> 
  proj7l[i]==projOff /\ proj7l[i+1]==projOff /\
  proj7u[i]!=projTurnOn /\
  closeIdlingClock(c, cl, cu, e, co, proj7, i) /\ 
  cps(co, cl, cu, proj7, i)); % idling
  
constraint forall(i in STAGESm1)(Ene7[22,i] -> 
  proj7l[i]==projWarmUp /\ proj7l[i+1]==projWarmUp /\
  closeIdlingClock(c, cl, cu, e, co, proj7, i) /\ 
  cps(co, cl, cu, proj7, i)); % idling
  
constraint forall(i in STAGESm1)(Ene7[23,i] -> 
  proj7l[i]==projOn /\ proj7l[i+1]==projOn /\ comp7l[i+1]==compOn /\ conn7l[i+1]==connected /\
  closeIdlingClock(c, cl, cu, e, co, proj7, i) /\ 
  cps(co, cl, cu, proj7, i)); % idling
  
constraint forall(i in STAGESm1)(Ene7[24,i] -> 
  proj7l[i]==projConfirm /\ proj7l[i+1]=projConfirm /\
  closeIdlingClock(c, cl, cu, e, co, proj7, i) /\ 
  cps(co, cl, cu, proj7, i)); % idling
  
constraint forall(i in STAGESm1)(Ene7[25,i] -> 
  proj7l[i]==projCoolDown /\ proj7l[i+1]==projCoolDown /\
  closeIdlingClock(c, cl, cu, e, co, proj7, i) /\ 
  cps(co, cl, cu, proj7, i)); % idling
  
constraint forall(i in STAGESm1)(Ene7[26,i] -> 
  proj7l[i]==projWaiting /\ proj7l[i+1]==projWaiting /\
  closeIdlingClock(c, cl, cu, e, co, proj7, i) /\ 
  cps(co, cl, cu, proj7, i)); % idling
  
  
  
constraint forall(i in STAGES)(not Eno8[1,i]); % state changing
constraint forall(i in STAGES)(not Eno8[2,i]); % state changing
constraint forall(i in STAGES)(not Eno8[3,i]); % state changing
constraint forall(i in STAGES)(not Eno8[4,i]); % state changing

constraint forall(i in STAGES)(Eno8[5,i] -> comp8l[i]==compOn /\ openIdlingClock(c, cl, cu, e, co, comp8, i)); % idling
constraint forall(i in STAGES)(Eno8[6,i] -> comp8l[i]==compShutdown /\ openIdlingClock(c, cl, cu, e, co, comp8, i)); % idling
constraint forall(i in STAGES)(Eno8[7,i] -> comp8l[i]==compOff /\ openIdlingClock(c, cl, cu, e, co, comp8, i)); % idling
constraint forall(i in STAGES)(Eno8[8,i] -> comp8l[i]==compBooting /\ openIdlingClock(c, cl, cu, e, co, comp8, i)); % idling

constraint forall(i in STAGESm1)(Ene8[1,i] -> 
  comp8l[i]==compOn /\ comp8l[i+1]==compShutdown /\ 
  comp8u[i]==compTurnOff /\ 
  closeChangeClock(c, cl, cu, e, co, comp8, i) /\ 
  cvs(e, co, comp8, i) /\ cps(co, cl, cu, comp8, i)); % state changing
constraint forall(i in STAGESm1)(Ene8[2,i] -> 
  comp8l[i]==compShutdown /\ comp8l[i+1]==compOff /\ 
  c[comp8,i]==30 /\
  closeChangeClock(c, cl, cu, e, co, comp8, i) /\ 
  cvs(e, co, comp8, i) /\ cps(co, cl, cu, comp8, i)); % state changing
constraint forall(i in STAGESm1)(Ene8[3,i] ->
  comp8l[i]==compOff /\ comp8l[i+1]==compBooting /\ 
  comp8u[i]==compTurnOn /\
  closeChangeClock(c, cl, cu, e, co, comp8, i) /\ 
  cvs(e, co, comp8, i) /\ cps(co, cl, cu, comp8, i)); % state changing
constraint forall(i in STAGESm1)(Ene8[4,i] ->
  comp8l[i]==compBooting /\ comp8l[i+1]==compOn /\ 
  c[comp8,i]==15 /\
  closeChangeClock(c, cl, cu, e, co, comp8, i) /\ 
  cvs(e, co, comp8, i) /\ cps(co, cl, cu, comp8, i)); % state changing

constraint forall(i in STAGESm1)(Ene8[5,i] ->
  comp8l[i]==compOn /\ comp8l[i+1]==compOn /\ comp8u[i]!=compTurnOff /\
  closeIdlingClock(c, cl, cu, e, co, comp8, i) /\ 
  cps(co, cl, cu, comp8, i)); % idling
constraint forall(i in STAGESm1)(Ene8[6,i] ->
  comp8l[i]==compShutdown /\ comp8l[i+1]==compShutdown /\
  closeIdlingClock(c, cl, cu, e, co, comp8, i) /\ 
  cps(co, cl, cu, comp8, i)); % idling
constraint forall(i in STAGESm1)(Ene8[7,i] ->
  comp8l[i]==compOff /\ comp8l[i+1]==compOff /\ comp8u[i]!=compTurnOn /\
  closeIdlingClock(c, cl, cu, e, co, comp8, i)  /\ 
  cps(co, cl, cu, comp8, i)); % idling
constraint forall(i in STAGESm1)(Ene8[8,i] ->
  comp8l[i]==compBooting /\ comp8l[i+1]==compBooting /\
  closeIdlingClock(c, cl, cu, e, co, comp8, i) /\ 
  cps(co, cl, cu, comp8, i)); % idling

% HARDCODED transition constraints for CONNECTION
constraint forall(i in STAGES)(not Eno8[9,i]); % state changing
constraint forall(i in STAGES)(not Eno8[10,i]); % state changing

constraint forall(i in STAGES)(Eno8[11,i] -> conn8l[i]==connected /\ openIdlingClock(c, cl, cu, e, co, conn8, i)); % idling
constraint forall(i in STAGES)(Eno8[12,i] -> conn8l[i]==disconnected /\ openIdlingClock(c, cl, cu, e, co, conn8, i)); % idling

constraint forall(i in STAGESm1)(Ene8[9,i] -> 
  conn8l[i]==connected /\ conn8l[i+1]==disconnected /\
  conn8u[i]==disconnect /\
  closeChangeClock(c, cl, cu, e, co, conn8, i) /\ 
  cvs(e, co, conn8, i) /\ cps(co, cl, cu, conn8, i)); % state changing

constraint forall(i in STAGESm1)(Ene8[10,i] ->
  conn8l[i]==disconnected /\ conn8l[i+1]==connected /\ 
  conn8u[i]==connect /\ comp8l[i]==compOff /\
  closeChangeClock(c, cl, cu, e, co, conn8, i) /\ 
  cvs(e, co, conn8, i) /\ cps(co, cl, cu, conn8, i)); % state changing

constraint forall(i in STAGESm1)(Ene8[11,i] -> 
  conn8l[i]==connected /\ conn8l[i+1]=connected /\ conn8u[i]!=disconnect /\
  closeIdlingClock(c, cl, cu, e, co, conn8, i) /\ 
  cps(co, cl, cu, conn8, i)); % idling

constraint forall(i in STAGESm1)(Ene8[12,i] -> 
  conn8l[i]==disconnected /\ conn8l[i+1]=disconnected /\ conn8u[i]!=connect /\
  closeIdlingClock(c, cl, cu, e, co, conn8, i) /\ 
  cps(co, cl, cu, conn8, i)); % idling

% % HARDCODED transition constraints for PROJECTOR
constraint forall(i in STAGES)(not Eno8[13,i]); % state changing
constraint forall(i in STAGES)(not Eno8[14,i]); % state changing
constraint forall(i in STAGES)(not Eno8[15,i]); % state changing
constraint forall(i in STAGES)(not Eno8[16,i]); % state changing
constraint forall(i in STAGES)(not Eno8[17,i]); % state changing
constraint forall(i in STAGES)(not Eno8[18,i]); % state changing
constraint forall(i in STAGES)(not Eno8[19,i]); % state changing
constraint forall(i in STAGES)(not Eno8[20,i]); % state changing
constraint forall(i in STAGES)(not Eno8[27,i]); % state changing
constraint forall(i in STAGES)(Eno8[21,i] -> proj8l[i]==projOff /\ openIdlingClock(c, cl, cu, e, co, proj8, i)); % idling
constraint forall(i in STAGES)(Eno8[22,i] -> proj8l[i]==projWarmUp /\ openIdlingClock(c, cl, cu, e, co, proj8, i)); % idling
constraint forall(i in STAGES)(Eno8[23,i] -> proj8l[i]==projOn /\ openIdlingClock(c, cl, cu, e, co, proj8, i)); % idling
constraint forall(i in STAGES)(Eno8[24,i] -> proj8l[i]==projConfirm /\ openIdlingClock(c, cl, cu, e, co, proj8, i)); % idling
constraint forall(i in STAGES)(Eno8[25,i] -> proj8l[i]==projCoolDown /\ openIdlingClock(c, cl, cu, e, co, proj8, i)); % idling
constraint forall(i in STAGES)(Eno8[26,i] -> proj8l[i]==projWaiting /\ openIdlingClock(c, cl, cu, e, co, proj8, i)); % idling
  
constraint forall(i in STAGESm1)(Ene8[13,i] ->
  proj8l[i]==projOff /\ proj8l[i+1]==projWarmUp /\ 
  proj8u[i]==projTurnOn /\
  closeChangeClock(c, cl, cu, e, co, proj8, i) /\ 
  cvs(e, co, proj8, i) /\ cps(co, cl, cu, proj8, i)); % state changing
  
constraint forall(i in STAGESm1)(Ene8[14,i] -> 
  proj8l[i]==projWarmUp /\ proj8l[i+1]==projOn /\ 
  c[proj8,i] == 30 /\
  closeChangeClock(c, cl, cu, e, co, proj8, i) /\ 
  cvs(e, co, proj8, i) /\ cps(co, cl, cu, proj8, i)); % state changing
  
constraint forall(i in STAGESm1)(Ene8[15,i] -> 
  proj8l[i]==projOn /\ proj8l[i+1]==projConfirm /\ 
  proj8u[i]==projTurnOff /\
  closeChangeClock(c, cl, cu, e, co, proj8, i) /\ 
  cvs(e, co, proj8, i) /\ cps(co, cl, cu, proj8, i)); % state changing
  
constraint forall(i in STAGESm1)(Ene8[16,i] -> 
  proj8l[i]==projOn /\ proj8l[i+1]==projWaiting /\ 
  (comp8l[i]!=compOn \/ conn8l[i]!=connected) /\ proj8u[i]!=projTurnOff /\
  closeChangeClock(c, cl, cu, e, co, proj8, i) /\ 
  cvs(e, co, proj8, i) /\ cps(co, cl, cu, proj8, i)); % state changing
  
constraint forall(i in STAGESm1)(Ene8[17,i] -> 
  proj8l[i]==projConfirm /\ proj8l[i+1]==projCoolDown /\ 
  proj8u[i]==projTurnOff /\ inRange(c[proj8,i],cl[proj8,i],cu[proj8,i]) /\
  closeChangeClock(c, cl, cu, e, co, proj8, i) /\ 
  cvs(e, co, proj8, i) /\ cps(co, cl, cu, proj8, i)); % state changing
  
constraint forall(i in STAGESm1)(Ene8[18,i] -> 
  proj8l[i]==projWaiting /\ proj8l[i+1]==projCoolDown /\ 
  (comp8l[i]!=compOn \/ conn8l[i]!=connected) /\ c[proj8,i]==60 /\
  closeChangeClock(c, cl, cu, e, co, proj8, i) /\ 
  cvs(e, co, proj8, i) /\ cps(co, cl, cu, proj8, i)); % state changing

constraint forall(i in STAGESm1)(Ene8[19,i] -> 
  proj8l[i]==projWaiting /\ proj8l[i+1]==projOn /\ 
  comp8l[i]==compOn /\ conn8l[i]==connected /\
  closeChangeClock(c, cl, cu, e, co, proj8, i) /\ 
  cvs(e, co, proj8, i) /\ cps(co, cl, cu, proj8, i)); % state changing
  
constraint forall(i in STAGESm1)(Ene8[20,i] -> 
  proj8l[i]==projConfirm /\ proj8l[i+1]==projOn /\ 
  proj8u[i]!=projTurnOff /\ c[proj8,i]==5 /\
  closeChangeClock(c, cl, cu, e, co, proj8, i) /\ 
  cvs(e, co, proj8, i) /\ cps(co, cl, cu, proj8, i)); % state changing

constraint forall(i in STAGESm1)(Ene8[27,i] -> 
  proj8l[i]==projCoolDown /\ proj8l[i+1]==projOff /\ 
  c[proj8,i]==60 /\
  closeChangeClock(c, cl, cu, e, co, proj8, i) /\ 
  cvs(e, co, proj8, i) /\ cps(co, cl, cu, proj8, i)); % state changing

constraint forall(i in STAGESm1)(Ene8[21,i] -> 
  proj8l[i]==projOff /\ proj8l[i+1]==projOff /\
  proj8u[i]!=projTurnOn /\
  closeIdlingClock(c, cl, cu, e, co, proj8, i) /\ 
  cps(co, cl, cu, proj8, i)); % idling
  
constraint forall(i in STAGESm1)(Ene8[22,i] -> 
  proj8l[i]==projWarmUp /\ proj8l[i+1]==projWarmUp /\
  closeIdlingClock(c, cl, cu, e, co, proj8, i) /\ 
  cps(co, cl, cu, proj8, i)); % idling
  
constraint forall(i in STAGESm1)(Ene8[23,i] -> 
  proj8l[i]==projOn /\ proj8l[i+1]==projOn /\ comp8l[i+1]==compOn /\ conn8l[i+1]==connected /\
  closeIdlingClock(c, cl, cu, e, co, proj8, i) /\ 
  cps(co, cl, cu, proj8, i)); % idling
  
constraint forall(i in STAGESm1)(Ene8[24,i] -> 
  proj8l[i]==projConfirm /\ proj8l[i+1]=projConfirm /\
  closeIdlingClock(c, cl, cu, e, co, proj8, i) /\ 
  cps(co, cl, cu, proj8, i)); % idling
  
constraint forall(i in STAGESm1)(Ene8[25,i] -> 
  proj8l[i]==projCoolDown /\ proj8l[i+1]==projCoolDown /\
  closeIdlingClock(c, cl, cu, e, co, proj8, i) /\ 
  cps(co, cl, cu, proj8, i)); % idling
  
constraint forall(i in STAGESm1)(Ene8[26,i] -> 
  proj8l[i]==projWaiting /\ proj8l[i+1]==projWaiting /\
  closeIdlingClock(c, cl, cu, e, co, proj8, i) /\ 
  cps(co, cl, cu, proj8, i)); % idling

%%%%%%% ENCODE COST

% var float: totalCost = sum(i in STAGES)(sum(t in (TRANSITIONS_comp_idle union TRANSITIONS_conn_idle union TRANSITIONS_proj_idle))(Eno[t,i] * 1 * floor(e[i+1]-e[i])) + sum(t in TRANSITIONS_state_changing)(Ene[t,i])); % throws error - MLTP Cost

% var float: totalCost = sum(i in STAGES)(sum(t in TRANSITIONS_state_changing)(1 * Ene[t,i])); % TOP cost

var float: totalCost = e[h];

solve minimize totalCost;

% output ["Total Cost: ", show(totalCost)];

% solve satisfy;