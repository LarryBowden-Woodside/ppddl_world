% Use this editor as a MiniZinc scratch book
% ADJUSTABLE Parameter for float upper limit

float : Fupper = 25000;
% ADJUSTABLE Parameter for horizon
int : h = 7; 
% stage numbering
set of int : STAGES = 0..h-1;
set of int : STAGESm1 = 0..h-2; % m1 = minus 1
set of int : STAGESp1 = 0..h;   % p1 = plus 1pyya

% HARDCODED Parameter for number of automata
enum Automata = {arm1, arm2};
set of Automata : AUTOMATA = {arm1, arm2};

% HARDCODED Parameter for number of transitions
int : tr = 148;
% HARDCODED transition numbering
set of int : TRANSITIONS = 101..tr;

set of int : TRANSITIONS_arm_idle = {102,107,108,109, 117,122,123,124, 132,137,138,139, 146,148};
set of int : TRANSITIONS_armc_reset = {101,103,104,105,106,110,111,112,113,114,115, 116,118,119,120,121,125,126,127,128,129,130, 131,133,134,135,136,140,141,142,143,144,145, 147};

set of int : TRANSITIONS_state_changing = {101,103,104,105,106,110,111,112,113,114,115, 116,118,119,120,121,125,126,127,128,129,130, 131,133,134,135,136,140,141,142,143,144,145, 147};

% HARDCODED Automaton enum types
% Note: There is an explicit enum for each location and control variable
%       because you cannot mix enums (create unions of enums)
enum ArmL = {home, goingHome, pickingA, pickedA, placingAonFloor, placingAonB, placingAonC, placedAonFloor, placedAonB, placedAonC, pickingB, pickedB, placingBonFloor, placingBonA, placingBonC, placedBonFloor, placedBonA, placedBonC, pickingC, pickedC, placingConFloor, placingConA, placingConB, placedConFloor, placedConA, placedConB};
enum ArmU = {doNothing, pickA, placeAonFloor, placeAonB, placeAonC, pickB, placeBonFloor, placeBonA, placeBonC, pickC, placeConFloor, placeConA, placeConB};

enum BlockStates = {nothing, floor, gripper, blockA, blockB, blockC};

% location vars for all stages
array[STAGES] of var ArmL : arm1l;
array[STAGES] of var ArmL : arm2l;

% command vars for all stages
array[STAGES] of var ArmU : arm1u;
array[STAGES] of var ArmU : arm2u;

array[STAGES] of var BlockStates : blockAabove;
array[STAGES] of var BlockStates : blockAbelow;
array[STAGES] of var BlockStates : blockBabove;
array[STAGES] of var BlockStates : blockBbelow;
array[STAGES] of var BlockStates : blockCabove;
array[STAGES] of var BlockStates : blockCbelow;
array[STAGES] of var BlockStates : floorabove;

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

% array[STAGES] of var epAcceptAutomatonL : epAcceptAutomatonTraj;
% array[epAcceptAutomatonTr, STAGES] of var bool: epAcceptAutomatonTrTraj;

% var int : epAcceptStartEvent;
% var int : epAcceptEndEvent;
% var float : epAcceptClockWhenStart;
% var float : epAcceptClockWhenEnd;
% var float : epAcceptClockParameter;

% constraint epAcceptStartEvent >=0 /\ epAcceptStartEvent <= h;
% constraint epAcceptEndEvent >=0 /\ epAcceptEndEvent <= h;
% constraint epAcceptClockWhenStart >= 0 /\ epAcceptClockWhenStart<=Fupper;
% constraint epAcceptClockWhenEnd >= 0 /\ epAcceptClockWhenEnd<=Fupper;
% constraint epAcceptClockParameter >= 0 /\ epAcceptClockParameter<=Fupper;

%%%%%% TEMPORAL CONSTRAINT ACCEPTING AUTOMATON
% second [600, 600] constraint
% array[STAGES] of var tempAcceptAutomatonL : temporalAcceptConstraint_2_Traj;
% array[temporalAcceptAutomatonTr, STAGES] of var bool : temporalAcceptConstraint_2_TrTraj;

% var int : temporalAcceptConstraint_2_event1;
% var int : temporalAcceptConstraint_2_event2;
% var float : temporalAcceptConstraint_2_event1Clock;
% var float : temporalAcceptConstraint_2_event2Clock;
% var float : temporalAcceptConstraint_2_ClockWhenActivated;
% var float : temporalAcceptConstraint_2_ClockWhenAccepted;
% var float : temporalAcceptConstraint_2_ClockParameter;

% constraint temporalAcceptConstraint_2_event1>=0 /\ temporalAcceptConstraint_2_event1<=h;
% constraint temporalAcceptConstraint_2_event2>=0 /\ temporalAcceptConstraint_2_event2<=h;
% constraint temporalAcceptConstraint_2_event1Clock>=0 /\ temporalAcceptConstraint_2_event1Clock<=Fupper;
% constraint temporalAcceptConstraint_2_event2Clock>=0 /\ temporalAcceptConstraint_2_event2Clock<=Fupper;
% constraint temporalAcceptConstraint_2_ClockWhenActivated>=0 /\ temporalAcceptConstraint_2_ClockWhenActivated<=Fupper;
% constraint temporalAcceptConstraint_2_ClockWhenAccepted>=0 /\ temporalAcceptConstraint_2_ClockWhenAccepted<=Fupper;
% constraint temporalAcceptConstraint_2_ClockParameter>=0 /\ temporalAcceptConstraint_2_ClockParameter<=Fupper;

% %%%% Starting state constraints
% % if e1=e2=e0
% predicate startingConstraint1() = temporalAcceptConstraint_2_event1==temporalAcceptConstraint_2_event2 /\ temporalAcceptConstraint_2_event2==0;
% constraint (startingConstraint1())->(temporalAcceptConstraint_2_Traj[0]==tempAccepted /\ temporalAcceptConstraint_2_ClockWhenActivated==e[0] /\ temporalAcceptConstraint_2_ClockWhenAccepted==e[0] /\ temporalAcceptConstraint_2_event1Clock==e[0] /\ temporalAcceptConstraint_2_event2Clock==e[0] /\ temporalAcceptConstraint_2_acceptingEvent1(0) /\ temporalAcceptConstraint_2_acceptingEvent2(0));
% % if e1=e0!=e2
% predicate startingConstraint2() = temporalAcceptConstraint_2_event1==0 /\ 0!=temporalAcceptConstraint_2_event2;
% constraint (startingConstraint2())->(temporalAcceptConstraint_2_Traj[0]==tempActive /\ temporalAcceptConstraint_2_ClockParameter<=temporalAcceptConstraint_2_upperBound /\ temporalAcceptConstraint_2_event1Clock==e[0] /\ temporalAcceptConstraint_2_ClockWhenActivated==e[0] /\ temporalAcceptConstraint_2_acceptingEvent1(0));
% % if e2=e0!=e1
% predicate startingConstraint3() =  temporalAcceptConstraint_2_event2==0 /\ 0!=temporalAcceptConstraint_2_event1;
% constraint (startingConstraint3())->(temporalAcceptConstraint_2_Traj[0]==tempActive /\ temporalAcceptConstraint_2_ClockParameter<=(-1 * temporalAcceptConstraint_2_lowerBound) /\ temporalAcceptConstraint_2_event2Clock==e[0] /\ temporalAcceptConstraint_2_ClockWhenActivated==e[0] /\ temporalAcceptConstraint_2_acceptingEvent2(0));
% % else e1!=e2!=e0
% constraint (not (startingConstraint1() \/ startingConstraint2() \/ startingConstraint3()))->(temporalAcceptConstraint_2_Traj[0]==tempWaiting);

% %%%%% Parameter constraints
% constraint abs(temporalAcceptConstraint_2_event2Clock - temporalAcceptConstraint_2_event1Clock)==temporalAcceptConstraint_2_ClockParameter;
% constraint temporalAcceptConstraint_2_ClockWhenAccepted - temporalAcceptConstraint_2_ClockWhenActivated == temporalAcceptConstraint_2_ClockParameter;

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
array[TRANSITIONS, STAGES] of var bool: Eno1;
array[TRANSITIONS, STAGES] of var bool: Eno2;

% End interval enablement
array[TRANSITIONS, STAGES] of var bool: Ene1;
array[TRANSITIONS, STAGES] of var bool: Ene2;

% Making clock variables and parameters persist 
constraint forall(i in STAGESm1)((forall([(not Ene1[t, i]) | t in TRANSITIONS_armc_reset])) -> (co[arm1,i]==co[arm1,i+1]));
constraint forall(i in STAGESm1)((forall([(not Ene2[t, i]) | t in TRANSITIONS_armc_reset])) -> (co[arm2,i]==co[arm2,i+1]));

% Constraints that Ensure Deterministic Execution
% Robot 1
constraint forall(i in STAGES)(sum([Eno1[t, i] | t in TRANSITIONS_arm_idle]) = 1);
constraint forall(i in STAGES)(sum([Ene1[t, i] | t in (TRANSITIONS_arm_idle union TRANSITIONS_armc_reset)]) = 1);

% Robot 2
constraint forall(i in STAGES)(sum([Eno2[t, i] | t in TRANSITIONS_arm_idle]) = 1);
constraint forall(i in STAGES)(sum([Ene2[t, i] | t in (TRANSITIONS_arm_idle union TRANSITIONS_armc_reset)]) = 1);

% Constraints That Ensure Concise Runs
constraint forall(i in STAGESm1)((exists([Ene1[t,i] | t in TRANSITIONS_state_changing]) \/ exists([Ene2[t,i] | t in TRANSITIONS_state_changing])) xor endStateAcceptAutomatonTraj[i]==accepted);

% Initial State Encoding
constraint arm1l[0]==home;
constraint arm2l[0]==home;

constraint blockAabove[0]==nothing;
constraint blockAbelow[0]==blockB;
constraint blockBabove[0]==blockA;
constraint blockBbelow[0]==blockC;
constraint blockCabove[0]==blockB;
constraint blockCbelow[0]==floor;
constraint floorabove[0]==blockC;

% end state accepting
constraint endStateAcceptAutomatonTraj[0]==waiting;

% Goal State Encoding
% constraint compl[h-1]==compOn;
% constraint connl[h-1]==connected;
% constraint projl[h-1]==projOn;
constraint exists(i in STAGES)(endStateAcceptAutomatonTraj[i]==accepted);

%%%%%%% END STATE ACCEPTING AUTOMATON
predicate maintenanceConstraint(int: i) = true;
predicate goalConstraint(int : i) = (arm1l[i+1]==placedAonFloor /\ arm2l[i+1]==home /\ 
blockAabove[i+1]==nothing /\ blockAbelow[i+1]==floor /\
blockBabove[i+1]==nothing /\ blockBbelow[i+1]==blockC /\ 
blockCabove[i+1]==blockB /\ blockCbelow[i+1]==floor /\ 
floorabove[i+1]==blockA);

% constraint forall(i in STAGES)(arm2l[i]==home);

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

% predicate epAcceptAcceptingConstraint(int : i) = robot2l[i]==atDoor2;
% predicate epAcceptStateConstraint(int : i) = true;

% % % Upper and lower bounds on epAcceptClockParameter
% float : epAcceptLowerBound=1;
% float : epAcceptUpperBound=1;

% constraint epAcceptClockParameter >= epAcceptLowerBound /\ epAcceptClockParameter <= epAcceptUpperBound;

% % Parameter constraints
% constraint (epAcceptClockWhenEnd - epAcceptClockWhenStart)==epAcceptClockParameter;

% % initial state of the episode accepting automaton
% constraint (robot2l[0]==atDoor2)->(epAcceptAutomatonTraj[0]==epActive);
% constraint (robot2l[0]!=atDoor2)->(epAcceptAutomatonTraj[0]==epWaiting);

% % 33 - waiting to waiting
% constraint forall(i in STAGESm1)(epAcceptAutomatonTrTraj[33,i] -> 
%   epAcceptAutomatonTraj[i]==epWaiting /\ epAcceptAutomatonTraj[i+1]==epWaiting /\ 
%   not epAcceptAcceptingConstraint(i));

% % 34 - accepted to accepted
% constraint forall(i in STAGESm1)(epAcceptAutomatonTrTraj[34,i] -> 
%   epAcceptAutomatonTraj[i]==epAccepted /\ epAcceptAutomatonTraj[i+1]==epAccepted);
  
% % 35 - failed to failed
% constraint forall(i in STAGESm1)(epAcceptAutomatonTrTraj[35,i] -> 
%   epAcceptAutomatonTraj[i]==epFailed /\ epAcceptAutomatonTraj[i+1]==epFailed);

% % 36 - waiting to active
% constraint forall(i in STAGESm1)(epAcceptAutomatonTrTraj[36,i] -> 
%   epAcceptAutomatonTraj[i]==epWaiting /\ epAcceptAutomatonTraj[i+1]==epActive /\
%   epAcceptAcceptingConstraint(i) /\ epAcceptStartEvent==(i+1) /\ epAcceptClockWhenStart==e[i+1]);

% % 37 - active to active
% constraint forall(i in STAGESm1)(epAcceptAutomatonTrTraj[37,i] -> 
%   epAcceptAutomatonTraj[i]==epActive /\ epAcceptAutomatonTraj[i+1]==epActive /\ 
%   epAcceptStateConstraint(i) /\ (e[i+1] - epAcceptClockWhenStart < epAcceptClockParameter));

% % 38 - active to accepted
% constraint forall(i in STAGESm1)(epAcceptAutomatonTrTraj[38,i] -> 
%   epAcceptAutomatonTraj[i]==epActive /\ epAcceptAutomatonTraj[i+1]==epAccepted /\
%   epAcceptStateConstraint(i) /\ (e[i+1] - epAcceptClockWhenStart >= epAcceptClockParameter) /\ epAcceptEndEvent==(i+1) /\ epAcceptClockWhenEnd==e[i+1]) ;

% % 39 - active to failed
% constraint forall(i in STAGESm1)(epAcceptAutomatonTrTraj[39,i] -> 
%   epAcceptAutomatonTraj[i]==epActive /\ epAcceptAutomatonTraj[i+1]==epFailed /\ 
%   not epAcceptStateConstraint(i));

% % ensure that only one transition occurs in a given stage.
% constraint forall(i in STAGES)(sum(t in epAcceptAutomatonTr)(epAcceptAutomatonTrTraj[t, i]) == 1);

%%%% Transition constraints
% 41 - waiting to waiting, 42 - waiting to accepted, 43 - waiting to active, 44 - active to active, 45 - active to accepted, 46 - accepted to accepted.

% predicate temporalAcceptConstraint_2_acceptingEvent1(int : i) = projl[i]==projOn /\ projl[i+1]==projConfirm;
% predicate temporalAcceptConstraint_2_acceptingEvent2(int : i) = projl[i+1]==projOff /\ connl[i+1]==disconnected /\ compl[i+1]=compOff /\ temporalAcceptConstraint_2_Traj[i]==tempActive;

% float : temporalAcceptConstraint_2_lowerBound=600;
% float : temporalAcceptConstraint_2_upperBound=600;

% % Upper and Lower bounds on the clock parameter
% constraint temporalAcceptConstraint_2_ClockParameter >= temporalAcceptConstraint_2_lowerBound /\
%            temporalAcceptConstraint_2_ClockParameter <= temporalAcceptConstraint_2_upperBound;

% % 41 - waiting to waiting
% constraint forall(i in STAGESm1)(temporalAcceptConstraint_2_TrTraj[41,i] -> 
%   temporalAcceptConstraint_2_Traj[i]==tempWaiting /\ temporalAcceptConstraint_2_Traj[i+1]==tempWaiting /\ 
%   not temporalAcceptConstraint_2_acceptingEvent1(i) /\ not temporalAcceptConstraint_2_acceptingEvent2(i));

% % 42 - waiting to accepted
% constraint forall(i in STAGESm1)(temporalAcceptConstraint_2_TrTraj[42,i] -> 
%   temporalAcceptConstraint_2_Traj[i]==tempWaiting /\ temporalAcceptConstraint_2_Traj[i+1]==tempAccepted /\ 
%   temporalAcceptConstraint_2_acceptingEvent1(i) /\ temporalAcceptConstraint_2_acceptingEvent2(i) /\
%   temporalAcceptConstraint_2_event1==i+1 /\ temporalAcceptConstraint_2_event2==i+1 /\ 
%   temporalAcceptConstraint_2_event1Clock==e[i+1] /\ temporalAcceptConstraint_2_event2Clock==e[i+1]);

% % 43 - waiting to active
% predicate e1BeforeE2(int: i) = temporalAcceptConstraint_2_Traj[i]==tempWaiting /\ temporalAcceptConstraint_2_Traj[i+1]==tempActive /\ temporalAcceptConstraint_2_acceptingEvent1(i) /\ not temporalAcceptConstraint_2_acceptingEvent2(i) /\ temporalAcceptConstraint_2_event1Clock==e[i+1] /\ temporalAcceptConstraint_2_event1==i+1 /\ temporalAcceptConstraint_2_ClockWhenActivated==e[i+1] /\ temporalAcceptConstraint_2_ClockParameter <= temporalAcceptConstraint_2_upperBound /\ temporalAcceptConstraint_2_event1Clock <= temporalAcceptConstraint_2_event2Clock;

% predicate e2BeforeE1(int: i) = temporalAcceptConstraint_2_Traj[i]==tempWaiting /\ temporalAcceptConstraint_2_Traj[i+1]==tempActive /\ not temporalAcceptConstraint_2_acceptingEvent1(i) /\ temporalAcceptConstraint_2_acceptingEvent2(i) /\ temporalAcceptConstraint_2_event2Clock==e[i+1] /\ temporalAcceptConstraint_2_event2==i+1 /\ temporalAcceptConstraint_2_event2Clock <= temporalAcceptConstraint_2_event1Clock /\ temporalAcceptConstraint_2_ClockWhenActivated==e[i+1] /\ temporalAcceptConstraint_2_ClockParameter<=(-1 * temporalAcceptConstraint_2_lowerBound);

% constraint forall(i in STAGESm1)(temporalAcceptConstraint_2_TrTraj[43,i] -> (e1BeforeE2(i) \/ e2BeforeE1(i)));

% % 44 - active to active
% constraint forall(i in STAGESm1)(temporalAcceptConstraint_2_TrTraj[44,i] -> 
%   temporalAcceptConstraint_2_Traj[i]==tempActive /\ temporalAcceptConstraint_2_Traj[i+1]==tempActive /\ 
%   e[i+1]-temporalAcceptConstraint_2_ClockWhenActivated < temporalAcceptConstraint_2_ClockParameter);

% % 45 - active to accepted
% predicate endsOnE2(int: i) = temporalAcceptConstraint_2_Traj[i]==tempActive /\ temporalAcceptConstraint_2_Traj[i+1]==tempAccepted /\ 
%   (e[i+1]-temporalAcceptConstraint_2_ClockWhenActivated) >= temporalAcceptConstraint_2_ClockParameter /\ 
%   temporalAcceptConstraint_2_event1Clock < temporalAcceptConstraint_2_event2Clock /\ temporalAcceptConstraint_2_event2==i+1 /\ 
%   temporalAcceptConstraint_2_acceptingEvent2(i);

% predicate endsOnE1(int: i) = temporalAcceptConstraint_2_Traj[i]==tempActive /\ temporalAcceptConstraint_2_Traj[i+1]==tempAccepted /\ 
%   (e[i+1]-temporalAcceptConstraint_2_ClockWhenActivated) >= temporalAcceptConstraint_2_ClockParameter /\ 
%   temporalAcceptConstraint_2_event2Clock < temporalAcceptConstraint_2_event1Clock /\ temporalAcceptConstraint_2_event1==i+1 /\    temporalAcceptConstraint_2_acceptingEvent1(i);

% constraint forall(i in STAGESm1)(temporalAcceptConstraint_2_TrTraj[45,i] -> (endsOnE2(i) \/ endsOnE1(i)));

% % 46 - accepted to accepted
% constraint forall(i in STAGESm1)(temporalAcceptConstraint_2_TrTraj[46,i] -> 
%   (temporalAcceptConstraint_2_Traj[i]==tempAccepted /\ temporalAcceptConstraint_2_Traj[i+1]==tempAccepted));

% % ensure that only one transition occurs in a given stage.
% constraint forall(i in STAGES)(sum(t in temporalAcceptAutomatonTr)(temporalAcceptConstraint_2_TrTraj[t, i]) == 1);

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

%% Constrain the transitions for the block states
% array[STAGES] of var BlockStates : blockAabove;
% array[STAGES] of var BlockStates : blockAbelow;
% array[STAGES] of var BlockStates : blockBabove;
% array[STAGES] of var BlockStates : blockBbelow;
% array[STAGES] of var BlockStates : blockCabove;
% array[STAGES] of var BlockStates : blockCbelow;
% array[STAGES] of var BlockStates : floorabove;
% enum ArmU = {doNothing, pickA, placeAonFloor, placeAonB, placeAonC, pickB, placeBonFloor, placeBonA, placeBonC, pickC, placeConFloor, placeConA, placeConB};

constraint forall(i in STAGESm1)((blockAabove[i]==nothing /\ blockAabove[i+1]==gripper)->(arm1u[i]==pickA \/ arm2u[i]==pickA));
constraint forall(i in STAGESm1)((blockBabove[i]==nothing /\ blockBabove[i+1]==gripper)->(arm1u[i]==pickB \/ arm2u[i]==pickB));
constraint forall(i in STAGESm1)((blockCabove[i]==nothing /\ blockCabove[i+1]==gripper)->(arm1u[i]==pickC \/ arm2u[i]==pickC));

constraint forall(i in STAGESm1)((arm1u[i]!=pickA /\ arm2u[i]!=pickA)->(blockAbelow[i]==blockAbelow[i+1]));
constraint forall(i in STAGESm1)((arm1u[i]!=pickB /\ arm2u[i]!=pickB)->(blockBbelow[i]==blockBbelow[i+1]));
constraint forall(i in STAGESm1)((arm1u[i]!=pickC /\ arm2u[i]!=pickC)->(blockCbelow[i]==blockCbelow[i+1]));

% constraint forall(i in STAGESm1)((blockAbelow[i]!=nothing /\ blockAabove[i+1]==nothing)->(arm1u[i]==pickA \/ arm2u[i]==pickA));
% constraint forall(i in STAGESm1)((blockBbelow[i]!=nothing /\ blockBabove[i+1]==nothing)->(arm1u[i]==pickB \/ arm2u[i]==pickB));
% constraint forall(i in STAGESm1)((blockCbelow[i]!=nothing /\ blockCabove[i+1]==nothing)->(arm1u[i]==pickC \/ arm2u[i]==pickC));

constraint forall(i in STAGESm1)((floorabove[i]==nothing /\ floorabove[i+1]==blockC)->(arm1u[i]==placeConFloor \/ arm2u[i]==placeConFloor));
constraint forall(i in STAGESm1)((floorabove[i]==nothing /\ floorabove[i+1]==blockB)->(arm1u[i]==placeBonFloor \/ arm2u[i]==placeBonFloor));
constraint forall(i in STAGESm1)((floorabove[i]==nothing /\ floorabove[i+1]==blockA)->(arm1u[i]==placeAonFloor \/ arm2u[i]==placeAonFloor));

constraint forall(i in STAGESm1)(not ((floorabove[i]==blockA /\ floorabove[i+1]==blockB) \/ (floorabove[i]==blockB /\ floorabove[i+1]==blockA) \/ (floorabove[i]==blockA /\ floorabove[i+1]==blockC) \/ (floorabove[i]==blockC /\ floorabove[i+1]==blockA) \/ (floorabove[i]==blockB /\ floorabove[i+1]==blockC) \/ (floorabove[i]==blockC /\ floorabove[i+1]==blockB)));
constraint forall(i in STAGESm1)((arm1u[i]==placeConFloor \/ arm2u[i]==placeConFloor \/ arm1u[i]==placeAonFloor \/ arm2u[i]==placeAonFloor \/ arm1u[i]==placeBonFloor \/ arm2u[i]==placeBonFloor)->(floorabove[i]==nothing /\ floorabove[i+1]!=nothing));
constraint forall(i in STAGES)(floorabove[i]!=floor);

% pick A transition times
float : t1 = 1.0;
float : t2 = 2.0;
float : t3 = 3.0;
float : t4 = 4.0;
% pick B transition times
float : t5 = 1.3;
float : t6 = 2.3;
float : t7 = 3.3;
float : t8 = 4.3;
% pick C transition times
float : t9 = 1.6;
float : t10 = 2.6;
float : t11 = 3.6;
float : t12 = 4.6;

float : thome = 5.0;

% HARDCODED Automaton enum types
% Note: There is an explicit enum for each location and control variable
%       because you cannot mix enums (create unions of enums)

% HARDCODED transition constraints for Robot 1
constraint forall(i in STAGES)(not Eno1[101,i]); % state changing
constraint forall(i in STAGES)(not Eno1[103,i]); % state changing
constraint forall(i in STAGES)(not Eno1[104,i]); % state changing
constraint forall(i in STAGES)(not Eno1[105,i]); % state changing
constraint forall(i in STAGES)(not Eno1[106,i]); % state changing
constraint forall(i in STAGES)(not Eno1[110,i]); % state changing
constraint forall(i in STAGES)(not Eno1[111,i]); % state changing
constraint forall(i in STAGES)(not Eno1[112,i]); % state changing
constraint forall(i in STAGES)(not Eno1[113,i]); % state changing
constraint forall(i in STAGES)(not Eno1[114,i]); % state changing
constraint forall(i in STAGES)(not Eno1[115,i]); % state changing
constraint forall(i in STAGES)(not Eno1[116,i]); % state changing
constraint forall(i in STAGES)(not Eno1[118,i]); % state changing
constraint forall(i in STAGES)(not Eno1[119,i]); % state changing
constraint forall(i in STAGES)(not Eno1[120,i]); % state changing
constraint forall(i in STAGES)(not Eno1[121,i]); % state changing
constraint forall(i in STAGES)(not Eno1[125,i]); % state changing
constraint forall(i in STAGES)(not Eno1[126,i]); % state changing
constraint forall(i in STAGES)(not Eno1[127,i]); % state changing
constraint forall(i in STAGES)(not Eno1[128,i]); % state changing
constraint forall(i in STAGES)(not Eno1[129,i]); % state changing
constraint forall(i in STAGES)(not Eno1[130,i]); % state changing
constraint forall(i in STAGES)(not Eno1[131,i]); % state changing
constraint forall(i in STAGES)(not Eno1[133,i]); % state changing
constraint forall(i in STAGES)(not Eno1[134,i]); % state changing
constraint forall(i in STAGES)(not Eno1[135,i]); % state changing
constraint forall(i in STAGES)(not Eno1[136,i]); % state changing
constraint forall(i in STAGES)(not Eno1[140,i]); % state changing
constraint forall(i in STAGES)(not Eno1[141,i]); % state changing
constraint forall(i in STAGES)(not Eno1[142,i]); % state changing
constraint forall(i in STAGES)(not Eno1[143,i]); % state changing
constraint forall(i in STAGES)(not Eno1[144,i]); % state changing
constraint forall(i in STAGES)(not Eno1[145,i]); % state changing
constraint forall(i in STAGES)(not Eno1[147,i]); % state changing

% set of int : TRANSITIONS_arm_idle = {102,107,108,109, 117,122,123,124, 132,137,138,139, 146,148};
% constraint forall(i in STAGES)(Eno1[102,i] -> arm1l[i]==pickingA /\ openIdlingClock(c, cl, cu, e, co, arm1, i)); % idling
constraint forall(i in STAGES)(Eno1[107,i] -> arm1l[i]==placingAonFloor /\ openIdlingClock(c, cl, cu, e, co, arm1, i)); % idling
constraint forall(i in STAGES)(Eno1[108,i] -> arm1l[i]==placingAonB /\ openIdlingClock(c, cl, cu, e, co, arm1, i)); % idling
constraint forall(i in STAGES)(Eno1[109,i] -> arm1l[i]==placingAonC /\ openIdlingClock(c, cl, cu, e, co, arm1, i)); % idling
constraint forall(i in STAGES)(Eno1[117,i] -> arm1l[i]==pickingB /\ openIdlingClock(c, cl, cu, e, co, arm1, i)); % idling
constraint forall(i in STAGES)(Eno1[122,i] -> arm1l[i]==placingBonFloor /\ openIdlingClock(c, cl, cu, e, co, arm1, i)); % idling
constraint forall(i in STAGES)(Eno1[123,i] -> arm1l[i]==placingBonA /\ openIdlingClock(c, cl, cu, e, co, arm1, i)); % idling
constraint forall(i in STAGES)(Eno1[124,i] -> arm1l[i]==placingBonC /\ openIdlingClock(c, cl, cu, e, co, arm1, i)); % idling
constraint forall(i in STAGES)(Eno1[132,i] -> arm1l[i]==pickingC /\ openIdlingClock(c, cl, cu, e, co, arm1, i)); % idling
constraint forall(i in STAGES)(Eno1[137,i] -> arm1l[i]==placingConFloor /\ openIdlingClock(c, cl, cu, e, co, arm1, i)); % idling
constraint forall(i in STAGES)(Eno1[138,i] -> arm1l[i]==placingConA /\ openIdlingClock(c, cl, cu, e, co, arm1, i)); % idling
constraint forall(i in STAGES)(Eno1[139,i] -> arm1l[i]==placingConB /\ openIdlingClock(c, cl, cu, e, co, arm1, i)); % idling
constraint forall(i in STAGES)(Eno1[146,i] -> arm1l[i]==goingHome /\ openIdlingClock(c, cl, cu, e, co, arm1, i)); % idling
constraint forall(i in STAGES)(Eno1[148,i] -> arm1l[i]==home /\ openIdlingClock(c, cl, cu, e, co, arm1, i)); % idling

%% set of int : TRANSITIONS_armc_reset = {101,103,104,105,106,110,111,112,113,114,115, 116,118,119,120,121,125,126,127,128,129,130, 131,133,134,135,136,140,141,142,143,144,145, 147};
%% enum ArmU = {doNothing, pickA, placeAonFloor, placeAonB, placeAonC, pickB, placeBonFloor, placeBonA, placeBonC, pickC, placeConFloor, placeConA, placeConB};
%% STATE CHANGING
% Pick A
% 101,103,104,105,106,110,111,112,113,114,115
constraint forall(i in STAGESm1)(Ene1[101,i] -> 
  arm1l[i]==home /\ arm1l[i+1]==pickingA /\ 
  arm1u[i]==pickA /\ blockAabove[i]==nothing /\
  closeChangeClock(c, cl, cu, e, co, arm1, i) /\ 
  cvs(e, co, arm1, i) /\ cps(co, cl, cu, arm1, i)); % state changing
constraint forall(i in STAGESm1)(Ene1[103,i] -> 
  arm1l[i]==pickingA /\ arm1l[i+1]==pickedA /\ blockAabove[i+1]==gripper /\ blockAbelow[i+1]==gripper /\
  c[arm1,i]==t1 /\ arm1u[i]==doNothing /\
  closeChangeClock(c, cl, cu, e, co, arm1, i) /\ 
  cvs(e, co, arm1, i) /\ cps(co, cl, cu, arm1, i)); % state changing
constraint forall(i in STAGESm1)(Ene1[104,i] -> 
  arm1l[i]==pickedA /\ arm1l[i+1]==placingAonFloor /\ 
  arm1u[i]==placeAonFloor /\ floorabove[i]==nothing /\ 
  closeChangeClock(c, cl, cu, e, co, arm1, i) /\ 
  cvs(e, co, arm1, i) /\ cps(co, cl, cu, arm1, i)); % state changing
constraint forall(i in STAGESm1)(Ene1[105,i] -> 
  arm1l[i]==pickedA /\ arm1l[i+1]==placingAonB /\ 
  arm1u[i]==placeAonB /\ blockBabove[i]==nothing /\ 
  closeChangeClock(c, cl, cu, e, co, arm1, i) /\ 
  cvs(e, co, arm1, i) /\ cps(co, cl, cu, arm1, i)); % state changing
constraint forall(i in STAGESm1)(Ene1[106,i] -> 
  arm1l[i]==pickedA /\ arm1l[i+1]==placingAonC /\ 
  arm1u[i]==placeAonC /\ blockCabove[i]==nothing /\ 
  closeChangeClock(c, cl, cu, e, co, arm1, i) /\ 
  cvs(e, co, arm1, i) /\ cps(co, cl, cu, arm1, i)); % state changing
constraint forall(i in STAGESm1)(Ene1[110,i] -> 
  arm1l[i]==placingAonFloor /\ arm1l[i+1]==placedAonFloor /\ 
  floorabove[i+1]==blockA /\ blockAbelow[i+1]==floor /\ blockAabove[i+1]==nothing /\ arm1u[i]==doNothing /\
  c[arm1,i]==t2 /\ closeChangeClock(c, cl, cu, e, co, arm1, i) /\ 
  cvs(e, co, arm1, i) /\ cps(co, cl, cu, arm1, i)); % state changing
constraint forall(i in STAGESm1)(Ene1[111,i] -> 
  arm1l[i]==placingAonB /\ arm1l[i+1]==placedAonB /\ 
  blockBabove[i+1]==blockA /\ blockAbelow[i+1]==blockB /\ blockAabove[i+1]==nothing /\
  c[arm1,i]==t3 /\ closeChangeClock(c, cl, cu, e, co, arm1, i) /\ 
  cvs(e, co, arm1, i) /\ cps(co, cl, cu, arm1, i)); % state changing
constraint forall(i in STAGESm1)(Ene1[112,i] -> 
  arm1l[i]==placingAonC /\ arm1l[i+1]==placedAonC /\ 
  blockCabove[i+1]==blockA /\ blockAbelow[i+1]==blockC /\ blockAabove[i+1]==nothing /\
  c[arm1,i]==t4 /\ closeChangeClock(c, cl, cu, e, co, arm1, i) /\ 
  cvs(e, co, arm1, i) /\ cps(co, cl, cu, arm1, i)); % state changing
constraint forall(i in STAGESm1)(Ene1[113,i] -> 
  arm1l[i]==placedAonFloor /\ arm1l[i+1]==goingHome /\ 
  closeChangeClock(c, cl, cu, e, co, arm1, i) /\ 
  cvs(e, co, arm1, i) /\ cps(co, cl, cu, arm1, i)); % state changing
constraint forall(i in STAGESm1)(Ene1[114,i] -> 
  arm1l[i]==placedAonB /\ arm1l[i+1]==goingHome /\ 
  closeChangeClock(c, cl, cu, e, co, arm1, i) /\ 
  cvs(e, co, arm1, i) /\ cps(co, cl, cu, arm1, i)); % state changing
constraint forall(i in STAGESm1)(Ene1[115,i] -> 
  arm1l[i]==placedAonC /\ arm1l[i+1]==goingHome /\ 
  closeChangeClock(c, cl, cu, e, co, arm1, i) /\ 
  cvs(e, co, arm1, i) /\ cps(co, cl, cu, arm1, i)); % state changing

% Pick B
% 116,118,119,120,121,125,126,127,128,129,130
constraint forall(i in STAGESm1)(Ene1[116,i] -> 
  arm1l[i]==home /\ arm1l[i+1]==pickingB /\ 
  arm1u[i]==pickB /\ blockBabove[i]==nothing /\
  closeChangeClock(c, cl, cu, e, co, arm1, i) /\ 
  cvs(e, co, arm1, i) /\ cps(co, cl, cu, arm1, i)); % state changing
constraint forall(i in STAGESm1)(Ene1[118,i] -> 
  arm1l[i]==pickingB /\ arm1l[i+1]==pickedB /\ blockBabove[i+1]==gripper /\ blockBbelow[i+1]==gripper /\
  c[arm1,i]==t5 /\
  closeChangeClock(c, cl, cu, e, co, arm1, i) /\ 
  cvs(e, co, arm1, i) /\ cps(co, cl, cu, arm1, i)); % state changing
constraint forall(i in STAGESm1)(Ene1[119,i] -> 
  arm1l[i]==pickedB /\ arm1l[i+1]==placingBonFloor /\ 
  arm1u[i]==placeBonFloor /\ floorabove[i]==nothing /\
  closeChangeClock(c, cl, cu, e, co, arm1, i) /\ 
  cvs(e, co, arm1, i) /\ cps(co, cl, cu, arm1, i)); % state changing
constraint forall(i in STAGESm1)(Ene1[120,i] -> 
  arm1l[i]==pickedB /\ arm1l[i+1]==placingBonA /\ 
  arm1u[i]==placeBonA /\ blockAabove[i]==nothing /\
  closeChangeClock(c, cl, cu, e, co, arm1, i) /\ 
  cvs(e, co, arm1, i) /\ cps(co, cl, cu, arm1, i)); % state changing
constraint forall(i in STAGESm1)(Ene1[121,i] -> 
  arm1l[i]==pickedB /\ arm1l[i+1]==placingBonC /\ 
  arm1u[i]==placeBonC /\ blockCabove[i]==nothing /\
  closeChangeClock(c, cl, cu, e, co, arm1, i) /\ 
  cvs(e, co, arm1, i) /\ cps(co, cl, cu, arm1, i)); % state changing
constraint forall(i in STAGESm1)(Ene1[125,i] -> 
  arm1l[i]==placingBonFloor /\ arm1l[i+1]==placedBonFloor /\ 
  floorabove[i+1]==blockB /\ blockBbelow[i+1]==floor /\ blockBabove[i+1]==nothing /\
  c[arm1,i]==t6 /\ closeChangeClock(c, cl, cu, e, co, arm1, i) /\ 
  cvs(e, co, arm1, i) /\ cps(co, cl, cu, arm1, i)); % state changing
constraint forall(i in STAGESm1)(Ene1[126,i] -> 
  arm1l[i]==placingBonA /\ arm1l[i+1]==placedBonA /\ 
  blockAabove[i+1]==blockB /\ blockBbelow[i+1]==blockA /\ blockBabove[i+1]==nothing /\
  c[arm1,i]==t7 /\ closeChangeClock(c, cl, cu, e, co, arm1, i) /\ 
  cvs(e, co, arm1, i) /\ cps(co, cl, cu, arm1, i)); % state changing
constraint forall(i in STAGESm1)(Ene1[127,i] -> 
  arm1l[i]==placingBonC /\ arm1l[i+1]==placedBonC /\ 
  blockCabove[i+1]==blockB /\ blockBbelow[i+1]==blockC /\ blockBabove[i+1]==nothing /\
  c[arm1,i]==t8 /\ closeChangeClock(c, cl, cu, e, co, arm1, i) /\ 
  cvs(e, co, arm1, i) /\ cps(co, cl, cu, arm1, i)); % state changing
constraint forall(i in STAGESm1)(Ene1[128,i] -> 
  arm1l[i]==placedBonFloor /\ arm1l[i+1]==goingHome /\ 
  closeChangeClock(c, cl, cu, e, co, arm1, i) /\ 
  cvs(e, co, arm1, i) /\ cps(co, cl, cu, arm1, i)); % state changing
constraint forall(i in STAGESm1)(Ene1[129,i] -> 
  arm1l[i]==placedBonA /\ arm1l[i+1]==goingHome /\ 
  closeChangeClock(c, cl, cu, e, co, arm1, i) /\ 
  cvs(e, co, arm1, i) /\ cps(co, cl, cu, arm1, i)); % state changing
constraint forall(i in STAGESm1)(Ene1[130,i] -> 
  arm1l[i]==placedBonC /\ arm1l[i+1]==goingHome /\ 
  closeChangeClock(c, cl, cu, e, co, arm1, i) /\ 
  cvs(e, co, arm1, i) /\ cps(co, cl, cu, arm1, i)); % state changing


% Pick C
% 131,133,134,135,136,140,141,142,143,144,145
constraint forall(i in STAGESm1)(Ene1[131,i] -> 
  arm1l[i]==home /\ arm1l[i+1]==pickingC /\ 
  arm1u[i]==pickC /\ blockCabove[i]==nothing /\
  closeChangeClock(c, cl, cu, e, co, arm1, i) /\ 
  cvs(e, co, arm1, i) /\ cps(co, cl, cu, arm1, i)); % state changing
constraint forall(i in STAGESm1)(Ene1[133,i] -> 
  arm1l[i]==pickingC /\ arm1l[i+1]==pickedC /\ % blockCabove[i+1]==gripper /\ blockCbelow[i+1]==gripper /\
  c[arm1,i]==t9 /\
  closeChangeClock(c, cl, cu, e, co, arm1, i) /\ 
  cvs(e, co, arm1, i) /\ cps(co, cl, cu, arm1, i)); % state changing
constraint forall(i in STAGESm1)(Ene1[134,i] -> 
  arm1l[i]==pickedC /\ arm1l[i+1]==placingConFloor /\ 
  arm1u[i]==placeConFloor /\ floorabove[i]==nothing /\
  closeChangeClock(c, cl, cu, e, co, arm1, i) /\ 
  cvs(e, co, arm1, i) /\ cps(co, cl, cu, arm1, i)); % state changing
constraint forall(i in STAGESm1)(Ene1[135,i] -> 
  arm1l[i]==pickedC /\ arm1l[i+1]==placingConA /\ 
  arm1u[i]==placeConA /\ blockAabove[i]==nothing /\
  closeChangeClock(c, cl, cu, e, co, arm1, i) /\ 
  cvs(e, co, arm1, i) /\ cps(co, cl, cu, arm1, i)); % state changing
constraint forall(i in STAGESm1)(Ene1[136,i] -> 
  arm1l[i]==pickedC /\ arm1l[i+1]==placingConB /\ 
  arm1u[i]==placeConB /\ blockBabove[i]==nothing /\
  closeChangeClock(c, cl, cu, e, co, arm1, i) /\ 
  cvs(e, co, arm1, i) /\ cps(co, cl, cu, arm1, i)); % state changing
constraint forall(i in STAGESm1)(Ene1[140,i] -> 
  arm1l[i]==placingConFloor /\ arm1l[i+1]==placedConFloor /\ 
  floorabove[i+1]==blockC /\ blockCbelow[i+1]==floor /\ blockCabove[i+1]==nothing /\
  c[arm1,i]==t10 /\ closeChangeClock(c, cl, cu, e, co, arm1, i) /\ 
  cvs(e, co, arm1, i) /\ cps(co, cl, cu, arm1, i)); % state changing
constraint forall(i in STAGESm1)(Ene1[141,i] -> 
  arm1l[i]==placingConA /\ arm1l[i+1]==placedConA /\ 
  blockAabove[i+1]==blockC /\ blockCbelow[i+1]==blockA /\ blockCabove[i+1]==nothing /\
  c[arm1,i]==t11 /\ closeChangeClock(c, cl, cu, e, co, arm1, i) /\ 
  cvs(e, co, arm1, i) /\ cps(co, cl, cu, arm1, i)); % state changing
constraint forall(i in STAGESm1)(Ene1[142,i] -> 
  arm1l[i]==placingConB /\ arm1l[i+1]==placedConB /\ 
  blockBabove[i+1]==blockC /\ blockCbelow[i+1]==blockC /\ blockCabove[i+1]==nothing /\
  c[arm1,i]==t12 /\ closeChangeClock(c, cl, cu, e, co, arm1, i) /\ 
  cvs(e, co, arm1, i) /\ cps(co, cl, cu, arm1, i)); % state changing
constraint forall(i in STAGESm1)(Ene1[143,i] -> 
  arm1l[i]==placedConFloor /\ arm1l[i+1]==goingHome /\ 
  closeChangeClock(c, cl, cu, e, co, arm1, i) /\ 
  cvs(e, co, arm1, i) /\ cps(co, cl, cu, arm1, i)); % state changing
constraint forall(i in STAGESm1)(Ene1[144,i] -> 
  arm1l[i]==placedConA /\ arm1l[i+1]==goingHome /\ 
  closeChangeClock(c, cl, cu, e, co, arm1, i) /\ 
  cvs(e, co, arm1, i) /\ cps(co, cl, cu, arm1, i)); % state changing
constraint forall(i in STAGESm1)(Ene1[145,i] -> 
  arm1l[i]==placedConB /\ arm1l[i+1]==goingHome /\ 
  closeChangeClock(c, cl, cu, e, co, arm1, i) /\ 
  cvs(e, co, arm1, i) /\ cps(co, cl, cu, arm1, i)); % state changing

% Go Home
constraint forall(i in STAGESm1)(Ene1[147,i] -> 
  arm1l[i]==goingHome /\ arm1l[i+1]==home /\ 
  c[arm1,i]==thome /\
  closeChangeClock(c, cl, cu, e, co, arm1, i) /\ 
  cvs(e, co, arm1, i) /\ cps(co, cl, cu, arm1, i)); % state changing

% set of int : TRANSITIONS_arm_idle = {102,107,108,109, 117,122,123,124, 132,137,138,139, 146,148};
%% IDLING
constraint forall(i in STAGESm1)(Ene1[102,i] ->
  arm1l[i]==pickingA /\ arm1l[i+1]==pickingA /\ arm1u[i]==doNothing /\
  closeIdlingClock(c, cl, cu, e, co, arm1, i) /\ 
  cps(co, cl, cu, arm1, i)); % idling
constraint forall(i in STAGESm1)(Ene1[107,i] ->
  arm1l[i]==placingAonFloor /\ arm1l[i+1]==placingAonFloor /\ arm1u[i]==doNothing /\
  closeIdlingClock(c, cl, cu, e, co, arm1, i) /\ 
  cps(co, cl, cu, arm1, i)); % idling
constraint forall(i in STAGESm1)(Ene1[108,i] ->
  arm1l[i]==placingAonB /\ arm1l[i+1]==placingAonB /\ arm1u[i]==doNothing /\
  closeIdlingClock(c, cl, cu, e, co, arm1, i) /\ 
  cps(co, cl, cu, arm1, i)); % idling
constraint forall(i in STAGESm1)(Ene1[109,i] ->
  arm1l[i]==placingAonC /\ arm1l[i+1]==placingAonC /\ arm1u[i]==doNothing /\
  closeIdlingClock(c, cl, cu, e, co, arm1, i) /\ 
  cps(co, cl, cu, arm1, i)); % idling
constraint forall(i in STAGESm1)(Ene1[117,i] ->
  arm1l[i]==pickingB /\ arm1l[i+1]==pickingB /\ arm1u[i]==doNothing /\
  closeIdlingClock(c, cl, cu, e, co, arm1, i) /\ 
  cps(co, cl, cu, arm1, i)); % idling
constraint forall(i in STAGESm1)(Ene1[122,i] ->
  arm1l[i]==placingBonFloor /\ arm1l[i+1]==placingBonFloor /\ arm1u[i]==doNothing /\
  closeIdlingClock(c, cl, cu, e, co, arm1, i) /\ 
  cps(co, cl, cu, arm1, i)); % idling
constraint forall(i in STAGESm1)(Ene1[123,i] ->
  arm1l[i]==placingBonA /\ arm1l[i+1]==placingBonA /\ arm1u[i]==doNothing /\
  closeIdlingClock(c, cl, cu, e, co, arm1, i) /\ 
  cps(co, cl, cu, arm1, i)); % idling
constraint forall(i in STAGESm1)(Ene1[124,i] ->
  arm1l[i]==placingBonC /\ arm1l[i+1]==placingBonC /\ arm1u[i]==doNothing /\
  closeIdlingClock(c, cl, cu, e, co, arm1, i) /\ 
  cps(co, cl, cu, arm1, i)); % idling
constraint forall(i in STAGESm1)(Ene1[132,i] ->
  arm1l[i]==pickingC /\ arm1l[i+1]==pickingC /\ arm1u[i]==doNothing /\
  closeIdlingClock(c, cl, cu, e, co, arm1, i) /\ 
  cps(co, cl, cu, arm1, i)); % idling
constraint forall(i in STAGESm1)(Ene1[137,i] ->
  arm1l[i]==placingConFloor /\ arm1l[i+1]==placingConFloor /\ arm1u[i]==doNothing /\
  closeIdlingClock(c, cl, cu, e, co, arm1, i) /\ 
  cps(co, cl, cu, arm1, i)); % idling
constraint forall(i in STAGESm1)(Ene1[138,i] ->
  arm1l[i]==placingConA /\ arm1l[i+1]==placingConA /\ arm1u[i]==doNothing /\
  closeIdlingClock(c, cl, cu, e, co, arm1, i) /\ 
  cps(co, cl, cu, arm1, i)); % idling
constraint forall(i in STAGESm1)(Ene1[139,i] ->
  arm1l[i]==placingConB /\ arm1l[i+1]==placingConB /\ arm1u[i]==doNothing /\
  closeIdlingClock(c, cl, cu, e, co, arm1, i) /\ 
  cps(co, cl, cu, arm1, i)); % idling
constraint forall(i in STAGESm1)(Ene1[146,i] ->
  arm1l[i]==goingHome /\ arm1l[i+1]==goingHome /\ arm1u[i]==doNothing /\
  closeIdlingClock(c, cl, cu, e, co, arm1, i) /\ 
  cps(co, cl, cu, arm1, i)); % idling
constraint forall(i in STAGESm1)(Ene1[148,i] ->
  arm1l[i]==home /\ arm1l[i+1]==home /\
  closeIdlingClock(c, cl, cu, e, co, arm1, i) /\ arm1u[i]==doNothing /\
  cps(co, cl, cu, arm1, i)); % idling

%%%%%%% ARM 2 %%%%%% 
constraint forall(i in STAGES)(not Eno2[101,i]); % state changing
constraint forall(i in STAGES)(not Eno2[103,i]); % state changing
constraint forall(i in STAGES)(not Eno2[104,i]); % state changing
constraint forall(i in STAGES)(not Eno2[105,i]); % state changing
constraint forall(i in STAGES)(not Eno2[106,i]); % state changing
constraint forall(i in STAGES)(not Eno2[110,i]); % state changing
constraint forall(i in STAGES)(not Eno2[111,i]); % state changing
constraint forall(i in STAGES)(not Eno2[112,i]); % state changing
constraint forall(i in STAGES)(not Eno2[113,i]); % state changing
constraint forall(i in STAGES)(not Eno2[114,i]); % state changing
constraint forall(i in STAGES)(not Eno2[115,i]); % state changing
constraint forall(i in STAGES)(not Eno2[116,i]); % state changing
constraint forall(i in STAGES)(not Eno2[118,i]); % state changing
constraint forall(i in STAGES)(not Eno2[119,i]); % state changing
constraint forall(i in STAGES)(not Eno2[120,i]); % state changing
constraint forall(i in STAGES)(not Eno2[121,i]); % state changing
constraint forall(i in STAGES)(not Eno2[125,i]); % state changing
constraint forall(i in STAGES)(not Eno2[126,i]); % state changing
constraint forall(i in STAGES)(not Eno2[127,i]); % state changing
constraint forall(i in STAGES)(not Eno2[128,i]); % state changing
constraint forall(i in STAGES)(not Eno2[129,i]); % state changing
constraint forall(i in STAGES)(not Eno2[130,i]); % state changing
constraint forall(i in STAGES)(not Eno2[131,i]); % state changing
constraint forall(i in STAGES)(not Eno2[133,i]); % state changing
constraint forall(i in STAGES)(not Eno2[134,i]); % state changing
constraint forall(i in STAGES)(not Eno2[135,i]); % state changing
constraint forall(i in STAGES)(not Eno2[136,i]); % state changing
constraint forall(i in STAGES)(not Eno2[140,i]); % state changing
constraint forall(i in STAGES)(not Eno2[141,i]); % state changing
constraint forall(i in STAGES)(not Eno2[142,i]); % state changing
constraint forall(i in STAGES)(not Eno2[143,i]); % state changing
constraint forall(i in STAGES)(not Eno2[144,i]); % state changing
constraint forall(i in STAGES)(not Eno2[145,i]); % state changing
constraint forall(i in STAGES)(not Eno2[147,i]); % state changing

% % set of int : TRANSITIONS_arm_idle = {102,107,108,109, 117,122,123,124, 132,137,138,139, 146,148};
constraint forall(i in STAGES)(Eno2[102,i] -> arm2l[i]==pickingA /\ openIdlingClock(c, cl, cu, e, co, arm2, i)); % idling
constraint forall(i in STAGES)(Eno2[107,i] -> arm2l[i]==placingAonFloor /\ openIdlingClock(c, cl, cu, e, co, arm2, i)); % idling
constraint forall(i in STAGES)(Eno2[108,i] -> arm2l[i]==placingAonB /\ openIdlingClock(c, cl, cu, e, co, arm2, i)); % idling
constraint forall(i in STAGES)(Eno2[109,i] -> arm2l[i]==placingAonC /\ openIdlingClock(c, cl, cu, e, co, arm2, i)); % idling
constraint forall(i in STAGES)(Eno2[117,i] -> arm2l[i]==pickingB /\ openIdlingClock(c, cl, cu, e, co, arm2, i)); % idling
constraint forall(i in STAGES)(Eno2[122,i] -> arm2l[i]==placingBonFloor /\ openIdlingClock(c, cl, cu, e, co, arm2, i)); % idling
constraint forall(i in STAGES)(Eno2[123,i] -> arm2l[i]==placingBonA /\ openIdlingClock(c, cl, cu, e, co, arm2, i)); % idling
constraint forall(i in STAGES)(Eno2[124,i] -> arm2l[i]==placingBonC /\ openIdlingClock(c, cl, cu, e, co, arm2, i)); % idling
constraint forall(i in STAGES)(Eno2[132,i] -> arm2l[i]==pickingC /\ openIdlingClock(c, cl, cu, e, co, arm2, i)); % idling
constraint forall(i in STAGES)(Eno2[137,i] -> arm2l[i]==placingConFloor /\ openIdlingClock(c, cl, cu, e, co, arm2, i)); % idling
constraint forall(i in STAGES)(Eno2[138,i] -> arm2l[i]==placingConA /\ openIdlingClock(c, cl, cu, e, co, arm2, i)); % idling
constraint forall(i in STAGES)(Eno2[139,i] -> arm2l[i]==placingConB /\ openIdlingClock(c, cl, cu, e, co, arm2, i)); % idling
constraint forall(i in STAGES)(Eno2[146,i] -> arm2l[i]==goingHome /\ openIdlingClock(c, cl, cu, e, co, arm2, i)); % idling
constraint forall(i in STAGES)(Eno2[148,i] -> arm2l[i]==home /\ openIdlingClock(c, cl, cu, e, co, arm2, i)); % idling

% %% set of int : TRANSITIONS_armc_reset = {101,103,104,105,106,110,111,112,113,114,115, 116,118,119,120,121,125,126,127,128,129,130, 131,133,134,135,136,140,141,142,143,144,145, 147};
% %% enum ArmU = {doNothing, pickA, placeAonFloor, placeAonB, placeAonC, pickB, placeBonFloor, placeBonA, placeBonC, pickC, placeConFloor, placeConA, placeConB};
% %% STATE CHANGING
% % Pick A
% % 101,103,104,105,106,110,111,112,113,114,115
constraint forall(i in STAGESm1)(Ene2[101,i] -> 
  arm2l[i]==home /\ arm2l[i+1]==pickingA /\ 
  arm2u[i]==pickA /\ blockAabove[i]==nothing /\
  closeChangeClock(c, cl, cu, e, co, arm2, i) /\ 
  cvs(e, co, arm2, i) /\ cps(co, cl, cu, arm2, i)); % state changing
constraint forall(i in STAGESm1)(Ene2[103,i] -> 
  arm2l[i]==pickingA /\ arm2l[i+1]==pickedA /\ blockAabove[i+1]==gripper /\ blockAbelow[i+1]==gripper /\
  c[arm2,i]==t1 /\ arm2u[i]==doNothing /\
  closeChangeClock(c, cl, cu, e, co, arm2, i) /\ 
  cvs(e, co, arm2, i) /\ cps(co, cl, cu, arm2, i)); % state changing
constraint forall(i in STAGESm1)(Ene2[104,i] -> 
  arm2l[i]==pickedA /\ arm2l[i+1]==placingAonFloor /\ 
  arm2u[i]==placeAonFloor /\ floorabove[i]==nothing /\ 
  closeChangeClock(c, cl, cu, e, co, arm2, i) /\ 
  cvs(e, co, arm2, i) /\ cps(co, cl, cu, arm2, i)); % state changing
constraint forall(i in STAGESm1)(Ene2[105,i] -> 
  arm2l[i]==pickedA /\ arm2l[i+1]==placingAonB /\ 
  arm2u[i]==placeAonB /\ blockBabove[i]==nothing /\ 
  closeChangeClock(c, cl, cu, e, co, arm2, i) /\ 
  cvs(e, co, arm2, i) /\ cps(co, cl, cu, arm2, i)); % state changing
constraint forall(i in STAGESm1)(Ene2[106,i] -> 
  arm2l[i]==pickedA /\ arm2l[i+1]==placingAonC /\ 
  arm2u[i]==placeAonC /\ blockCabove[i]==nothing /\ 
  closeChangeClock(c, cl, cu, e, co, arm2, i) /\ 
  cvs(e, co, arm2, i) /\ cps(co, cl, cu, arm2, i)); % state changing
constraint forall(i in STAGESm1)(Ene2[110,i] -> 
  arm2l[i]==placingAonFloor /\ arm2l[i+1]==placedAonFloor /\ 
  floorabove[i+1]==blockA /\ blockAbelow[i+1]==floor /\ blockAabove[i+1]==nothing /\
  c[arm2,i]==t2 /\ closeChangeClock(c, cl, cu, e, co, arm2, i) /\ 
  cvs(e, co, arm2, i) /\ cps(co, cl, cu, arm2, i)); % state changing
constraint forall(i in STAGESm1)(Ene2[111,i] -> 
  arm2l[i]==placingAonB /\ arm2l[i+1]==placedAonB /\ 
  blockBabove[i+1]==blockA /\ blockAbelow[i+1]==blockB /\ blockAabove[i+1]==nothing /\
  c[arm2,i]==t3 /\ closeChangeClock(c, cl, cu, e, co, arm2, i) /\ 
  cvs(e, co, arm2, i) /\ cps(co, cl, cu, arm2, i)); % state changing
constraint forall(i in STAGESm1)(Ene2[112,i] -> 
  arm2l[i]==placingAonC /\ arm2l[i+1]==placedAonC /\ 
  blockCabove[i+1]==blockA /\ blockAbelow[i+1]==blockC /\ blockAabove[i+1]==nothing /\
  c[arm2,i]==t4 /\ closeChangeClock(c, cl, cu, e, co, arm2, i) /\ 
  cvs(e, co, arm2, i) /\ cps(co, cl, cu, arm2, i)); % state changing
constraint forall(i in STAGESm1)(Ene2[113,i] -> 
  arm2l[i]==placedAonFloor /\ arm2l[i+1]==goingHome /\ 
  closeChangeClock(c, cl, cu, e, co, arm2, i) /\ 
  cvs(e, co, arm2, i) /\ cps(co, cl, cu, arm2, i)); % state changing
constraint forall(i in STAGESm1)(Ene2[114,i] -> 
  arm2l[i]==placedAonB /\ arm2l[i+1]==goingHome /\ 
  closeChangeClock(c, cl, cu, e, co, arm2, i) /\ 
  cvs(e, co, arm2, i) /\ cps(co, cl, cu, arm2, i)); % state changing
constraint forall(i in STAGESm1)(Ene2[115,i] -> 
  arm2l[i]==placedAonC /\ arm2l[i+1]==goingHome /\ 
  closeChangeClock(c, cl, cu, e, co, arm2, i) /\ 
  cvs(e, co, arm2, i) /\ cps(co, cl, cu, arm2, i)); % state changing

% % Pick B
% % 116,118,119,120,121,125,126,127,128,129,130
constraint forall(i in STAGESm1)(Ene2[116,i] -> 
  arm2l[i]==home /\ arm2l[i+1]==pickingB /\ 
  arm2u[i]==pickB /\ blockBabove[i]==nothing /\
  closeChangeClock(c, cl, cu, e, co, arm2, i) /\ 
  cvs(e, co, arm2, i) /\ cps(co, cl, cu, arm2, i)); % state changing
constraint forall(i in STAGESm1)(Ene2[118,i] -> 
  arm2l[i]==pickingB /\ arm2l[i+1]==pickedB /\ blockBabove[i+1]==gripper /\ blockBbelow[i+1]==gripper /\
  c[arm2,i]==t5 /\
  closeChangeClock(c, cl, cu, e, co, arm2, i) /\ 
  cvs(e, co, arm2, i) /\ cps(co, cl, cu, arm2, i)); % state changing
constraint forall(i in STAGESm1)(Ene2[119,i] -> 
  arm2l[i]==pickedB /\ arm2l[i+1]==placingBonFloor /\ 
  arm2u[i]==placeBonFloor /\ floorabove[i]==nothing /\
  closeChangeClock(c, cl, cu, e, co, arm2, i) /\ 
  cvs(e, co, arm2, i) /\ cps(co, cl, cu, arm2, i)); % state changing
constraint forall(i in STAGESm1)(Ene2[120,i] -> 
  arm2l[i]==pickedB /\ arm2l[i+1]==placingBonA /\ 
  arm2u[i]==placeBonA /\ blockAabove[i]==nothing /\
  closeChangeClock(c, cl, cu, e, co, arm2, i) /\ 
  cvs(e, co, arm2, i) /\ cps(co, cl, cu, arm2, i)); % state changing
constraint forall(i in STAGESm1)(Ene2[121,i] -> 
  arm2l[i]==pickedB /\ arm2l[i+1]==placingBonC /\ 
  arm2u[i]==placeBonC /\ blockCabove[i]==nothing /\
  closeChangeClock(c, cl, cu, e, co, arm2, i) /\ 
  cvs(e, co, arm2, i) /\ cps(co, cl, cu, arm2, i)); % state changing
constraint forall(i in STAGESm1)(Ene2[125,i] -> 
  arm2l[i]==placingBonFloor /\ arm2l[i+1]==placedBonFloor /\ 
  floorabove[i+1]==blockB /\ blockBbelow[i+1]==floor /\ blockBabove[i+1]==nothing /\
  c[arm2,i]==t6 /\ closeChangeClock(c, cl, cu, e, co, arm2, i) /\ 
  cvs(e, co, arm2, i) /\ cps(co, cl, cu, arm2, i)); % state changing
constraint forall(i in STAGESm1)(Ene2[126,i] -> 
  arm2l[i]==placingBonA /\ arm2l[i+1]==placedBonA /\ 
  blockAabove[i+1]==blockB /\ blockBbelow[i+1]==blockA /\ blockBabove[i+1]==nothing /\
  c[arm2,i]==t7 /\ closeChangeClock(c, cl, cu, e, co, arm2, i) /\ 
  cvs(e, co, arm2, i) /\ cps(co, cl, cu, arm2, i)); % state changing
constraint forall(i in STAGESm1)(Ene2[127,i] -> 
  arm2l[i]==placingBonC /\ arm2l[i+1]==placedBonC /\ 
  blockCabove[i+1]==blockB /\ blockBbelow[i+1]==blockC /\ blockBabove[i+1]==nothing /\
  c[arm2,i]==t8 /\ closeChangeClock(c, cl, cu, e, co, arm2, i) /\ 
  cvs(e, co, arm2, i) /\ cps(co, cl, cu, arm2, i)); % state changing
constraint forall(i in STAGESm1)(Ene2[128,i] -> 
  arm2l[i]==placedBonFloor /\ arm2l[i+1]==goingHome /\ 
  closeChangeClock(c, cl, cu, e, co, arm2, i) /\ 
  cvs(e, co, arm2, i) /\ cps(co, cl, cu, arm2, i)); % state changing
constraint forall(i in STAGESm1)(Ene2[129,i] -> 
  arm2l[i]==placedBonA /\ arm2l[i+1]==goingHome /\ 
  closeChangeClock(c, cl, cu, e, co, arm2, i) /\ 
  cvs(e, co, arm2, i) /\ cps(co, cl, cu, arm2, i)); % state changing
constraint forall(i in STAGESm1)(Ene2[130,i] -> 
  arm2l[i]==placedBonC /\ arm2l[i+1]==goingHome /\ 
  closeChangeClock(c, cl, cu, e, co, arm2, i) /\ 
  cvs(e, co, arm2, i) /\ cps(co, cl, cu, arm2, i)); % state changing


% % Pick C
% % 131,133,134,135,136,140,141,142,143,144,145
constraint forall(i in STAGESm1)(Ene2[131,i] -> 
  arm2l[i]==home /\ arm2l[i+1]==pickingC /\ 
  arm2u[i]==pickC /\ blockCabove[i]==nothing /\
  closeChangeClock(c, cl, cu, e, co, arm2, i) /\ 
  cvs(e, co, arm2, i) /\ cps(co, cl, cu, arm2, i)); % state changing
constraint forall(i in STAGESm1)(Ene2[133,i] -> 
  arm2l[i]==pickingC /\ arm2l[i+1]==pickedC /\ % blockCabove[i+1]==gripper /\ blockCbelow[i+1]==gripper /\
  c[arm2,i]==t9 /\
  closeChangeClock(c, cl, cu, e, co, arm2, i) /\ 
  cvs(e, co, arm2, i) /\ cps(co, cl, cu, arm2, i)); % state changing
constraint forall(i in STAGESm1)(Ene2[134,i] -> 
  arm2l[i]==pickedC /\ arm2l[i+1]==placingConFloor /\ 
  arm2u[i]==placeConFloor /\ floorabove[i]==nothing /\
  closeChangeClock(c, cl, cu, e, co, arm2, i) /\ 
  cvs(e, co, arm2, i) /\ cps(co, cl, cu, arm2, i)); % state changing
constraint forall(i in STAGESm1)(Ene2[135,i] -> 
  arm2l[i]==pickedC /\ arm2l[i+1]==placingConA /\ 
  arm2u[i]==placeConA /\ blockAabove[i]==nothing /\
  closeChangeClock(c, cl, cu, e, co, arm2, i) /\ 
  cvs(e, co, arm2, i) /\ cps(co, cl, cu, arm2, i)); % state changing
constraint forall(i in STAGESm1)(Ene2[136,i] -> 
  arm2l[i]==pickedC /\ arm2l[i+1]==placingConB /\ 
  arm2u[i]==placeConB /\ blockBabove[i]==nothing /\
  closeChangeClock(c, cl, cu, e, co, arm2, i) /\ 
  cvs(e, co, arm2, i) /\ cps(co, cl, cu, arm2, i)); % state changing
constraint forall(i in STAGESm1)(Ene2[140,i] -> 
  arm2l[i]==placingConFloor /\ arm2l[i+1]==placedConFloor /\ 
  floorabove[i+1]==blockC /\ blockCbelow[i+1]==floor /\ blockCabove[i+1]==nothing /\
  c[arm2,i]==t10 /\ closeChangeClock(c, cl, cu, e, co, arm2, i) /\ 
  cvs(e, co, arm2, i) /\ cps(co, cl, cu, arm2, i)); % state changing
constraint forall(i in STAGESm1)(Ene2[141,i] -> 
  arm2l[i]==placingConA /\ arm2l[i+1]==placedConA /\ 
  blockAabove[i+1]==blockC /\ blockCbelow[i+1]==blockA /\ blockCabove[i+1]==nothing /\
  c[arm2,i]==t11 /\ closeChangeClock(c, cl, cu, e, co, arm2, i) /\ 
  cvs(e, co, arm2, i) /\ cps(co, cl, cu, arm2, i)); % state changing
constraint forall(i in STAGESm1)(Ene2[142,i] -> 
  arm2l[i]==placingConB /\ arm2l[i+1]==placedConB /\ 
  blockBabove[i+1]==blockC /\ blockCbelow[i+1]==blockC /\ blockCabove[i+1]==nothing /\
  c[arm2,i]==t12 /\ closeChangeClock(c, cl, cu, e, co, arm2, i) /\ 
  cvs(e, co, arm2, i) /\ cps(co, cl, cu, arm2, i)); % state changing
constraint forall(i in STAGESm1)(Ene2[143,i] -> 
  arm2l[i]==placedConFloor /\ arm2l[i+1]==goingHome /\ 
  closeChangeClock(c, cl, cu, e, co, arm2, i) /\ 
  cvs(e, co, arm2, i) /\ cps(co, cl, cu, arm2, i)); % state changing
constraint forall(i in STAGESm1)(Ene2[144,i] -> 
  arm2l[i]==placedConA /\ arm2l[i+1]==goingHome /\ 
  closeChangeClock(c, cl, cu, e, co, arm2, i) /\ 
  cvs(e, co, arm2, i) /\ cps(co, cl, cu, arm2, i)); % state changing
constraint forall(i in STAGESm1)(Ene2[145,i] -> 
  arm2l[i]==placedConB /\ arm2l[i+1]==goingHome /\ 
  closeChangeClock(c, cl, cu, e, co, arm2, i) /\ 
  cvs(e, co, arm2, i) /\ cps(co, cl, cu, arm2, i)); % state changing

% % Go Home
constraint forall(i in STAGESm1)(Ene2[147,i] -> 
  arm2l[i]==goingHome /\ arm2l[i+1]==home /\ 
  c[arm2,i]==thome /\
  closeChangeClock(c, cl, cu, e, co, arm2, i) /\ 
  cvs(e, co, arm2, i) /\ cps(co, cl, cu, arm2, i)); % state changing

% % set of int : TRANSITIONS_arm_idle = {102,107,108,109, 117,122,123,124, 132,137,138,139, 146,148};
% %% IDLING
% constraint forall(i in STAGESm1)(Ene2[102,i] ->
%   arm2l[i]==pickingA /\ arm2l[i+1]==pickingA /\ arm2u[i]==doNothing /\
%   closeIdlingClock(c, cl, cu, e, co, arm2, i) /\ 
%   cps(co, cl, cu, arm2, i)); % idling
constraint forall(i in STAGESm1)(Ene2[107,i] ->
  arm2l[i]==placingAonFloor /\ arm2l[i+1]==placingAonFloor /\ arm2u[i]==doNothing /\
  closeIdlingClock(c, cl, cu, e, co, arm2, i) /\ 
  cps(co, cl, cu, arm2, i)); % idling
constraint forall(i in STAGESm1)(Ene2[108,i] ->
  arm2l[i]==placingAonB /\ arm2l[i+1]==placingAonB /\ arm2u[i]==doNothing /\
  closeIdlingClock(c, cl, cu, e, co, arm2, i) /\ 
  cps(co, cl, cu, arm2, i)); % idling
constraint forall(i in STAGESm1)(Ene2[109,i] ->
  arm2l[i]==placingAonC /\ arm2l[i+1]==placingAonC /\ arm2u[i]==doNothing /\
  closeIdlingClock(c, cl, cu, e, co, arm2, i) /\ 
  cps(co, cl, cu, arm2, i)); % idling
constraint forall(i in STAGESm1)(Ene2[117,i] ->
  arm2l[i]==pickingB /\ arm2l[i+1]==pickingB /\ arm2u[i]==doNothing /\
  closeIdlingClock(c, cl, cu, e, co, arm2, i) /\ 
  cps(co, cl, cu, arm2, i)); % idling
constraint forall(i in STAGESm1)(Ene2[122,i] ->
  arm2l[i]==placingBonFloor /\ arm2l[i+1]==placingBonFloor /\ arm2u[i]==doNothing /\
  closeIdlingClock(c, cl, cu, e, co, arm2, i) /\ 
  cps(co, cl, cu, arm2, i)); % idling
constraint forall(i in STAGESm1)(Ene2[123,i] ->
  arm2l[i]==placingBonA /\ arm2l[i+1]==placingBonA /\ arm2u[i]==doNothing /\
  closeIdlingClock(c, cl, cu, e, co, arm2, i) /\ 
  cps(co, cl, cu, arm2, i)); % idling
constraint forall(i in STAGESm1)(Ene2[124,i] ->
  arm2l[i]==placingBonC /\ arm2l[i+1]==placingBonC /\ arm2u[i]==doNothing /\
  closeIdlingClock(c, cl, cu, e, co, arm2, i) /\ 
  cps(co, cl, cu, arm2, i)); % idling
constraint forall(i in STAGESm1)(Ene2[132,i] ->
  arm2l[i]==pickingC /\ arm2l[i+1]==pickingC /\ arm2u[i]==doNothing /\
  closeIdlingClock(c, cl, cu, e, co, arm2, i) /\ 
  cps(co, cl, cu, arm2, i)); % idling
constraint forall(i in STAGESm1)(Ene2[137,i] ->
  arm2l[i]==placingConFloor /\ arm2l[i+1]==placingConFloor /\ arm2u[i]==doNothing /\
  closeIdlingClock(c, cl, cu, e, co, arm2, i) /\ 
  cps(co, cl, cu, arm2, i)); % idling
constraint forall(i in STAGESm1)(Ene2[138,i] ->
  arm2l[i]==placingConA /\ arm2l[i+1]==placingConA /\ arm2u[i]==doNothing /\
  closeIdlingClock(c, cl, cu, e, co, arm2, i) /\ 
  cps(co, cl, cu, arm2, i)); % idling
constraint forall(i in STAGESm1)(Ene2[139,i] ->
  arm2l[i]==placingConB /\ arm2l[i+1]==placingConB /\ arm2u[i]==doNothing /\
  closeIdlingClock(c, cl, cu, e, co, arm2, i) /\
  cps(co, cl, cu, arm2, i)); % idling
constraint forall(i in STAGESm1)(Ene2[146,i] ->
  arm2l[i]==goingHome /\ arm2l[i+1]==goingHome /\ arm2u[i]==doNothing /\
  closeIdlingClock(c, cl, cu, e, co, arm2, i) /\ 
  cps(co, cl, cu, arm2, i)); % idling
constraint forall(i in STAGESm1)(Ene2[148,i] ->
  arm2l[i]==home /\ arm2l[i+1]==home /\ arm2u[i]==doNothing /\
  closeIdlingClock(c, cl, cu, e, co, arm2, i) /\ 
  cps(co, cl, cu, arm2, i)); % idling

%%%%%%% ENCODE COST

% var float: totalCost = sum(i in STAGES)(sum(t in (TRANSITIONS_comp_idle union TRANSITIONS_conn_idle union TRANSITIONS_proj_idle))(Eno[t,i] * 1 * floor(e[i+1]-e[i])) + sum(t in TRANSITIONS_state_changing)(Ene[t,i])); % throws error - MLTP Cost

% var float: totalCost = sum(i in STAGES)(sum(t in TRANSITIONS_state_changing)(1 * Ene[t,i])); % TOP cost

var float: totalCost = e[h];

solve minimize totalCost;

% output ["Total Cost: ", show(totalCost)];

% solve satisfy;