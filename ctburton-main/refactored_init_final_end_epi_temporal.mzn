% Use this editor as a MiniZinc scratch book
% ADJUSTABLE Parameter for float upper limit

float : Fupper = 25000;
% ADJUSTABLE Parameter for horizon
int : h = 10; 
% stage numbering
set of int : STAGES = 0..h-1;
set of int : STAGESm1 = 0..h-2; % m1 = minus 1
set of int : STAGESp1 = 0..h;   % p1 = plus 1pyya

% HARDCODED Parameter for number of automata
enum Automata = {comp, conn, proj};
set of Automata : AUTOMATA = {comp, conn, proj};

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

% location vars for all stages
array[STAGES] of var CompL : compl;
array[STAGES] of var ConnL : connl;
array[STAGES] of var ProjL : projl;

% command vars for all stages
array[STAGES] of var CompU : compu;
array[STAGES] of var ConnU : connu;
array[STAGES] of var ProjU : proju;

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

% Open interval enablement
array[TRANSITIONS, STAGES] of var bool: Eno;

% End interval enablement
array[TRANSITIONS, STAGES] of var bool: Ene;

% Making clock variables and parameters persist 
constraint forall(i in STAGESm1)((forall([(not Ene[t, i]) | t in TRANSITIONS_compc_reset])) -> (co[comp,i]==co[comp,i+1]));
constraint forall(i in STAGESm1)((forall([(not Ene[t, i]) | t in TRANSITIONS_connc_reset])) -> (co[conn,i]==co[conn,i+1]));
constraint forall(i in STAGESm1)((forall([(not Ene[t, i]) | t in TRANSITIONS_projc_reset])) -> (co[proj,i]==co[proj,i+1]));

% Constraints that Ensure Deterministic Execution
% Computer
constraint forall(i in STAGES)(sum([Eno[t, i] | t in TRANSITIONS_comp_idle]) = 1);
constraint forall(i in STAGES)(sum([Ene[t, i] | t in (TRANSITIONS_comp_idle union TRANSITIONS_compc_reset)]) = 1);

% Connection
constraint forall(i in STAGES)(sum([Eno[t, i] | t in TRANSITIONS_conn_idle]) = 1);
constraint forall(i in STAGES)(sum([Ene[t, i] | t in (TRANSITIONS_conn_idle union TRANSITIONS_connc_reset)]) = 1);

% Projector
constraint forall(i in STAGES)(sum([Eno[t, i] | t in TRANSITIONS_proj_idle]) = 1);
constraint forall(i in STAGES)(sum([Ene[t, i] | t in (TRANSITIONS_proj_idle union TRANSITIONS_projc_reset)]) = 1);

% Constraints That Ensure Concise Runs
constraint forall(i in STAGESm1)(exists([Ene[t,i] | t in TRANSITIONS_state_changing]) xor endStateAcceptAutomatonTraj[i]==accepted);
% constraint exists(i in STAGESm1, t in TRANSITIONS_state_changing)(Ene[t,i]); % OLD

% Initial State Encoding
constraint compl[0]==compOff;
constraint connl[0]==disconnected;
constraint projl[0]==projOff;
%% end state accepting
constraint endStateAcceptAutomatonTraj[0]==waiting;

% Goal State Encoding
% constraint compl[h-1]==compOn;
% constraint connl[h-1]==connected;
% constraint projl[h-1]==projOn;
constraint exists(i in STAGES)(endStateAcceptAutomatonTraj[i]==accepted);

%%%%%%% END STATE ACCEPTING AUTOMATON

predicate maintenanceConstraint(int: i) = true;
predicate goalConstraint(int : i) = compl[i+1]==compOff /\ connl[i+1]==disconnected /\ projl[i+1]==projOff /\ 
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
predicate epAcceptAcceptingConstraint(int : i) = projl[i]==projOn;
predicate epAcceptStateConstraint(int : i) = projl[i]==projOn;

% Upper and lower bounds on epAcceptClockParameter
float : epAcceptLowerBound=1800;
float : epAcceptUpperBound=1800;

constraint epAcceptClockParameter >= epAcceptLowerBound /\ epAcceptClockParameter <= epAcceptUpperBound;

% Parameter constraints
constraint (epAcceptClockWhenEnd - epAcceptClockWhenStart)==epAcceptClockParameter;

% initial state of the episode accepting automaton
constraint (projl[0]==projOn)->(epAcceptAutomatonTraj[0]==epActive);
constraint (projl[0]!=projOn)->(epAcceptAutomatonTraj[0]==epWaiting);

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

predicate temporalAcceptConstraint_2_acceptingEvent1(int : i) = projl[i]==projOn /\ projl[i+1]==projConfirm;
predicate temporalAcceptConstraint_2_acceptingEvent2(int : i) = projl[i+1]==projOff /\ connl[i+1]==disconnected /\ compl[i+1]=compOff /\ temporalAcceptConstraint_2_Traj[i]==tempActive;

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
  c[comp,i]==30 /\
  closeChangeClock(c, cl, cu, e, co, comp, i) /\ 
  cvs(e, co, comp, i) /\ cps(co, cl, cu, comp, i)); % state changing
constraint forall(i in STAGESm1)(Ene[3,i] ->
  compl[i]==compOff /\ compl[i+1]==compBooting /\ 
  compu[i]==compTurnOn /\
  closeChangeClock(c, cl, cu, e, co, comp, i) /\ 
  cvs(e, co, comp, i) /\ cps(co, cl, cu, comp, i)); % state changing
constraint forall(i in STAGESm1)(Ene[4,i] ->
  compl[i]==compBooting /\ compl[i+1]==compOn /\ 
  c[comp,i]==15 /\
  closeChangeClock(c, cl, cu, e, co, comp, i) /\ 
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
  proju[i]==projTurnOn /\
  closeChangeClock(c, cl, cu, e, co, proj, i) /\ 
  cvs(e, co, proj, i) /\ cps(co, cl, cu, proj, i)); % state changing
  
constraint forall(i in STAGESm1)(Ene[14,i] -> 
  projl[i]==projWarmUp /\ projl[i+1]==projOn /\ 
  c[proj,i] == 30 /\
  closeChangeClock(c, cl, cu, e, co, proj, i) /\ 
  cvs(e, co, proj, i) /\ cps(co, cl, cu, proj, i)); % state changing
  
constraint forall(i in STAGESm1)(Ene[15,i] -> 
  projl[i]==projOn /\ projl[i+1]==projConfirm /\ 
  proju[i]==projTurnOff /\
  closeChangeClock(c, cl, cu, e, co, proj, i) /\ 
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


%%%%%%% ENCODE COST

% var float: totalCost = sum(i in STAGES)(sum(t in (TRANSITIONS_comp_idle union TRANSITIONS_conn_idle union TRANSITIONS_proj_idle))(Eno[t,i] * 1 * floor(e[i+1]-e[i])) + sum(t in TRANSITIONS_state_changing)(Ene[t,i])); % throws error - MLTP Cost

% var float: totalCost = sum(i in STAGES)(sum(t in TRANSITIONS_state_changing)(1 * Ene[t,i])); % TOP cost

var float: totalCost = e[h];

solve minimize totalCost;

% output ["Total Cost: ", show(totalCost)];

% solve satisfy;