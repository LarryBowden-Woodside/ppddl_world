% Use this editor as a MiniZinc scratch book
% ADJUSTABLE Parameter for float upper limit

float : Fupper = 25000;
% ADJUSTABLE Parameter for horizon
int : h = 15; 
% stage numbering
set of int : STAGES = 0..h-1;
set of int : STAGESm1 = 0..h-2; % m1 = minus 1
set of int : STAGESp1 = 0..h;   % p1 = plus 1pyya

% HARDCODED Parameter for number of automata
enum Automata = {robot1, robot2};
set of Automata : AUTOMATA = {robot1, robot2};

% HARDCODED Parameter for number of transitions
int : tr = 137;
% HARDCODED transition numbering
set of int : TRANSITIONS = 101..tr;

set of int : TRANSITIONS_robot_idle = {101,103,105,107,110,112,114,116,118,120,123,126,128,130,132,134,136};
set of int : TRANSITIONS_robotc_reset = {102,104,106,108,109,111,113,115,117,137,119,121,122,124,125,127,129,131,133,135};

set of int : TRANSITIONS_state_changing = {102,104,106,108,109,111,113,115,117,137,119,121,122,124,125,127,129,131,133,135};

% HARDCODED Automaton enum types
% Note: There is an explicit enum for each location and control variable
%       because you cannot mix enums (create unions of enums)
enum RobotL = {outside, goingToDoor1, atDoor1, door1Opening, insideRoom1, goingToDoor2, atDoor2, openingDoor2, insideDoor2, goingDoor2Person1, goingDoor2Person2, rescuedPerson1, rescuedPerson2, goingToDoor3, atDoor3, goingDoor3Person1, goingDoor3Person2};
enum RobotU = {doNothing, goToDoor1, openDoor1, goToDoor2, openDoor2, goToDoor2Person1, goToDoor2Person2, goToDoor3, goToDoor3Person1, goToDoor3Person2};

enum DoorL = {closed, opening, open};

% location vars for all stages
array[STAGES] of var RobotL : robot1l;
array[STAGES] of var RobotL : robot2l;

array[STAGES] of var DoorL : door1l;
array[STAGES] of var DoorL : door2l;
array[STAGES] of var DoorL : door3l;

% command vars for all stages
array[STAGES] of var RobotU : robot1u;
array[STAGES] of var RobotU : robot2u;

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

var float: clockWhenPerson1Rescued;
var float: clockWhenPerson2Rescued;

constraint clockWhenPerson1Rescued >=0 /\ clockWhenPerson1Rescued<=Fupper;
constraint clockWhenPerson2Rescued >=0 /\ clockWhenPerson2Rescued<=Fupper;

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

% %%% Starting state constraints
% % % if e1=e2=e0
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

% % %%%%% Parameter constraints
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
constraint forall(i in STAGESm1)((forall([(not Ene1[t, i]) | t in TRANSITIONS_robotc_reset])) -> (co[robot1,i]==co[robot1,i+1]));
constraint forall(i in STAGESm1)((forall([(not Ene2[t, i]) | t in TRANSITIONS_robotc_reset])) -> (co[robot2,i]==co[robot2,i+1]));

% Constraints that Ensure Deterministic Execution
% Robot 1
constraint forall(i in STAGES)(sum([Eno1[t, i] | t in TRANSITIONS_robot_idle]) = 1);
constraint forall(i in STAGES)(sum([Ene1[t, i] | t in (TRANSITIONS_robot_idle union TRANSITIONS_robotc_reset)]) = 1);

% Robot 2
constraint forall(i in STAGES)(sum([Eno2[t, i] | t in TRANSITIONS_robot_idle]) = 1);
constraint forall(i in STAGES)(sum([Ene2[t, i] | t in (TRANSITIONS_robot_idle union TRANSITIONS_robotc_reset)]) = 1);

% Constraints That Ensure Concise Runs
constraint forall(i in STAGESm1)((exists([Ene1[t,i] | t in TRANSITIONS_state_changing]) \/ exists([Ene2[t,i] | t in TRANSITIONS_state_changing])) xor endStateAcceptAutomatonTraj[i]==accepted);

% Initial State Encoding
constraint robot1l[0]==outside;
constraint robot2l[0]==outside;
constraint door1l[0]==closed;
constraint door2l[0]==closed;
constraint door3l[0]==open;
% end state accepting
constraint endStateAcceptAutomatonTraj[0]==waiting;

% Goal State Encoding
% constraint compl[h-1]==compOn;
% constraint connl[h-1]==connected;
% constraint projl[h-1]==projOn;
constraint exists(i in STAGES)(endStateAcceptAutomatonTraj[i]==accepted);

%%%%%%% END STATE ACCEPTING AUTOMATON
predicate maintenanceConstraint(int: i) = true;
predicate goalConstraint(int : i) = (robot1l[i+1]==rescuedPerson1 /\ robot2l[i+1]==rescuedPerson2) \/ (robot1l[i+1]==rescuedPerson2 /\ robot2l[i+1]==rescuedPerson1); % /\ epAcceptAutomatonTraj[i+1]=epAccepted); % /\ robot2l[i+1]==rescuedPerson2 /\ epAcceptAutomatonTraj[i+1]=epAccepted);
% predicate goalConstraint(int : i) = robot1l[i+1]==rescuedPerson1; %  /\ temporalAcceptConstraint_2_Traj[i+1]==tempAccepted;

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

predicate epAcceptAcceptingConstraint(int : i) = robot2l[i]==atDoor2;
predicate epAcceptStateConstraint(int : i) = true;

% % Upper and lower bounds on epAcceptClockParameter
float : epAcceptLowerBound=1;
float : epAcceptUpperBound=1;

constraint epAcceptClockParameter >= epAcceptLowerBound /\ epAcceptClockParameter <= epAcceptUpperBound;

% Parameter constraints
constraint (epAcceptClockWhenEnd - epAcceptClockWhenStart)==epAcceptClockParameter;

% initial state of the episode accepting automaton
constraint (robot2l[0]==atDoor2)->(epAcceptAutomatonTraj[0]==epActive);
constraint (robot2l[0]!=atDoor2)->(epAcceptAutomatonTraj[0]==epWaiting);

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

% predicate temporalAcceptConstraint_2_acceptingEvent1(int : i) = (robot1l[i]==rescuedPerson1 \/ robot2l[i]==rescuedPerson1);
% predicate temporalAcceptConstraint_2_acceptingEvent2(int : i) = (robot1l[i]==rescuedPerson2 \/ robot2l[i]==rescuedPerson2);

% float : temporalAcceptConstraint_2_lowerBound=0;
% float : temporalAcceptConstraint_2_upperBound=Fupper;

% % % Upper and Lower bounds on the clock parameter
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
%   temporalAcceptConstraint_2_event2Clock < temporalAcceptConstraint_2_event1Clock /\ temporalAcceptConstraint_2_event1==i+1 /\ temporalAcceptConstraint_2_acceptingEvent1(i);

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


%% Constrain the transitions for the doors so that we can only move from closed to opening, or opening to open, and idle in a given state.
constraint forall(i in STAGESm1)((door1l[i]==closed /\ door1l[i+1]==opening) \/ (door1l[i]==opening /\ door1l[i+1]==open) \/ (door1l[i]==open /\ door1l[i+1]==open) \/ (door1l[i]==closed /\ door1l[i+1]==closed) \/ (door1l[i]==opening /\ door1l[i+1]==opening));
constraint forall(i in STAGESm1)((door2l[i]==closed /\ door2l[i+1]==opening) \/ (door2l[i]==opening /\ door2l[i+1]==open) \/ (door2l[i]==open /\ door2l[i+1]==open) \/ (door2l[i]==closed /\ door2l[i+1]==closed) \/ (door2l[i]==opening /\ door2l[i+1]==opening));
constraint forall(i in STAGESm1)((door3l[i]==closed /\ door3l[i+1]==opening) \/ (door3l[i]==opening /\ door3l[i+1]==open) \/ (door3l[i]==open /\ door3l[i+1]==open) \/ (door3l[i]==closed /\ door3l[i+1]==closed) \/ (door3l[i]==opening /\ door3l[i+1]==opening));

constraint forall(i in STAGESm1)((door1l[i]==closed /\ door1l[i+1]==opening) -> ((robot1u[i]==openDoor1 /\ robot1l[i]==atDoor1) \/ (robot2u[i]==openDoor1 /\ robot2l[i]==atDoor1)));
constraint forall(i in STAGESm1)((door2l[i]==closed /\ door2l[i+1]==opening) -> ((robot1u[i]==openDoor2 /\ robot1l[i]==atDoor2) \/ (robot2u[i]==openDoor2 /\ robot2l[i]==atDoor2)));

float : t1 = 1.0;
float : t2 = 2.0;
float : t3 = 3.0;
float : t4 = 4.0;
float : t5 = 5.0;
float : t6 = 6.0;
float : t7 = 7.0;
float : t8 = 8.0;
float : t9 = 9.0;

% HARDCODED transition constraints for Robot 1
constraint forall(i in STAGES)(not Eno1[102,i]); % state changing
constraint forall(i in STAGES)(not Eno1[104,i]); % state changing
constraint forall(i in STAGES)(not Eno1[106,i]); % state changing
constraint forall(i in STAGES)(not Eno1[108,i]); % state changing
constraint forall(i in STAGES)(not Eno1[109,i]); % state changing
constraint forall(i in STAGES)(not Eno1[111,i]); % state changing
constraint forall(i in STAGES)(not Eno1[113,i]); % state changing
constraint forall(i in STAGES)(not Eno1[115,i]); % state changing
constraint forall(i in STAGES)(not Eno1[117,i]); % state changing
constraint forall(i in STAGES)(not Eno1[137,i]); % state changing
constraint forall(i in STAGES)(not Eno1[119,i]); % state changing
constraint forall(i in STAGES)(not Eno1[121,i]); % state changing
constraint forall(i in STAGES)(not Eno1[122,i]); % state changing
constraint forall(i in STAGES)(not Eno1[124,i]); % state changing
constraint forall(i in STAGES)(not Eno1[125,i]); % state changing
constraint forall(i in STAGES)(not Eno1[127,i]); % state changing
constraint forall(i in STAGES)(not Eno1[129,i]); % state changing
constraint forall(i in STAGES)(not Eno1[131,i]); % state changing
constraint forall(i in STAGES)(not Eno1[133,i]); % state changing
constraint forall(i in STAGES)(not Eno1[135,i]); % state changing

constraint forall(i in STAGES)(Eno1[101,i] -> robot1l[i]==outside /\ openIdlingClock(c, cl, cu, e, co, robot1, i)); % idling
constraint forall(i in STAGES)(Eno1[103,i] -> robot1l[i]==goingToDoor1 /\ openIdlingClock(c, cl, cu, e, co, robot1, i)); % idling
constraint forall(i in STAGES)(Eno1[105,i] -> robot1l[i]==atDoor1 /\ openIdlingClock(c, cl, cu, e, co, robot1, i)); % idling
constraint forall(i in STAGES)(Eno1[107,i] -> robot1l[i]==door1Opening /\ openIdlingClock(c, cl, cu, e, co, robot1, i)); % idling
constraint forall(i in STAGES)(Eno1[110,i] -> robot1l[i]==insideRoom1 /\ openIdlingClock(c, cl, cu, e, co, robot1, i)); % idling
constraint forall(i in STAGES)(Eno1[112,i] -> robot1l[i]==goingToDoor2 /\ openIdlingClock(c, cl, cu, e, co, robot1, i)); % idling
constraint forall(i in STAGES)(Eno1[114,i] -> robot1l[i]==atDoor2 /\ openIdlingClock(c, cl, cu, e, co, robot1, i)); % idling
constraint forall(i in STAGES)(Eno1[116,i] -> robot1l[i]==openingDoor2 /\ openIdlingClock(c, cl, cu, e, co, robot1, i)); % idling
constraint forall(i in STAGES)(Eno1[118,i] -> robot1l[i]==insideDoor2 /\ openIdlingClock(c, cl, cu, e, co, robot1, i)); % idling
constraint forall(i in STAGES)(Eno1[120,i] -> robot1l[i]==goingDoor2Person1 /\ openIdlingClock(c, cl, cu, e, co, robot1, i)); % idling
constraint forall(i in STAGES)(Eno1[123,i] -> robot1l[i]==goingDoor2Person2 /\ openIdlingClock(c, cl, cu, e, co, robot1, i)); % idling
constraint forall(i in STAGES)(Eno1[126,i] -> robot1l[i]==rescuedPerson1 /\ openIdlingClock(c, cl, cu, e, co, robot1, i)); % idling
constraint forall(i in STAGES)(Eno1[128,i] -> robot1l[i]==rescuedPerson2 /\ openIdlingClock(c, cl, cu, e, co, robot1, i)); % idling
constraint forall(i in STAGES)(Eno1[130,i] -> robot1l[i]==goingToDoor3 /\ openIdlingClock(c, cl, cu, e, co, robot1, i)); % idling
constraint forall(i in STAGES)(Eno1[132,i] -> robot1l[i]==atDoor3 /\ openIdlingClock(c, cl, cu, e, co, robot1, i)); % idling
constraint forall(i in STAGES)(Eno1[134,i] -> robot1l[i]==goingDoor3Person1 /\ openIdlingClock(c, cl, cu, e, co, robot1, i)); % idling
constraint forall(i in STAGES)(Eno1[136,i] -> robot1l[i]==goingDoor3Person2 /\ openIdlingClock(c, cl, cu, e, co, robot1, i)); % idling


%% STATE CHANGING
constraint forall(i in STAGESm1)(Ene1[102,i] -> 
  robot1l[i]==outside /\ robot1l[i+1]==goingToDoor1 /\ 
  robot1u[i]==goToDoor1 /\ 
  closeChangeClock(c, cl, cu, e, co, robot1, i) /\ 
  cvs(e, co, robot1, i) /\ cps(co, cl, cu, robot1, i)); % state changing
constraint forall(i in STAGESm1)(Ene1[104,i] -> 
  robot1l[i]==goingToDoor1 /\ robot1l[i+1]==atDoor1 /\ 
  c[robot1,i]==t1 /\
  closeChangeClock(c, cl, cu, e, co, robot1, i) /\ 
  cvs(e, co, robot1, i) /\ cps(co, cl, cu, robot1, i)); % state changing
constraint forall(i in STAGESm1)(Ene1[106,i] -> 
  robot1l[i]==atDoor1 /\ robot1l[i+1]==door1Opening /\ 
  c[robot1,i]==t1 /\ door1l[i]==closed /\ door1l[i+1]==opening /\
  closeChangeClock(c, cl, cu, e, co, robot1, i) /\ 
  cvs(e, co, robot1, i) /\ cps(co, cl, cu, robot1, i)); % state changing
constraint forall(i in STAGESm1)(Ene1[108,i] -> 
  robot1l[i]==door1Opening /\ robot1l[i+1]==insideRoom1 /\ 
  c[robot1,i]==t2 /\ door1l[i]==opening /\ door1l[i+1]==open /\
  closeChangeClock(c, cl, cu, e, co, robot1, i) /\ 
  cvs(e, co, robot1, i) /\ cps(co, cl, cu, robot1, i)); % state changing
constraint forall(i in STAGESm1)(Ene1[109,i] -> 
  robot1l[i]==atDoor1 /\ robot1l[i+1]==insideRoom1 /\ 
  door1l[i]==open /\
  closeChangeClock(c, cl, cu, e, co, robot1, i) /\ 
  cvs(e, co, robot1, i) /\ cps(co, cl, cu, robot1, i)); % state changing
constraint forall(i in STAGESm1)(Ene1[111,i] -> 
  robot1l[i]==insideRoom1 /\ robot1l[i+1]==goingToDoor2 /\ 
  robot1u[i]==goToDoor2 /\
  closeChangeClock(c, cl, cu, e, co, robot1, i) /\ 
  cvs(e, co, robot1, i) /\ cps(co, cl, cu, robot1, i)); % state changing
constraint forall(i in STAGESm1)(Ene1[113,i] -> 
  robot1l[i]==goingToDoor2 /\ robot1l[i+1]==atDoor2 /\ 
  c[robot1,i]==t3 /\
  closeChangeClock(c, cl, cu, e, co, robot1, i) /\ 
  cvs(e, co, robot1, i) /\ cps(co, cl, cu, robot1, i)); % state changing
constraint forall(i in STAGESm1)(Ene1[115,i] -> 
  robot1l[i]==atDoor2 /\ robot1l[i+1]==openingDoor2 /\ 
  robot1u[i]==openDoor2  /\ door2l[i]==closed /\ door2l[i+1]==opening /\
  closeChangeClock(c, cl, cu, e, co, robot1, i) /\ 
  cvs(e, co, robot1, i) /\ cps(co, cl, cu, robot1, i)); % state changing
constraint forall(i in STAGESm1)(Ene1[117,i] -> 
  robot1l[i]==openingDoor2 /\ robot1l[i+1]==insideDoor2 /\ 
  door2l[i]==opening /\ door2l[i]==open /\ c[robot1,i]==t7 /\
  closeChangeClock(c, cl, cu, e, co, robot1, i) /\ 
  cvs(e, co, robot1, i) /\ cps(co, cl, cu, robot1, i)); % state changing
constraint forall(i in STAGESm1)(Ene1[137,i] -> 
  robot1l[i]==atDoor2 /\ robot1l[i+1]==insideDoor2 /\ 
  door2l[i]==open /\
  closeChangeClock(c, cl, cu, e, co, robot1, i) /\ 
  cvs(e, co, robot1, i) /\ cps(co, cl, cu, robot1, i)); % state changing
constraint forall(i in STAGESm1)(Ene1[119,i] -> 
  robot1l[i]==insideDoor2 /\ robot1l[i+1]==goingDoor2Person1 /\ 
  robot1u[i]==goToDoor2Person1 /\
  closeChangeClock(c, cl, cu, e, co, robot1, i) /\ 
  cvs(e, co, robot1, i) /\ cps(co, cl, cu, robot1, i)); % state changing
constraint forall(i in STAGESm1)(Ene1[121,i] -> 
  robot1l[i]==goingDoor2Person1 /\ robot1l[i+1]==rescuedPerson1 /\ 
  c[robot1,i]==t8 /\
  closeChangeClock(c, cl, cu, e, co, robot1, i) /\ 
  cvs(e, co, robot1, i) /\ cps(co, cl, cu, robot1, i)); % state changing
constraint forall(i in STAGESm1)(Ene1[122,i] -> 
  robot1l[i]==insideDoor2 /\ robot1l[i+1]==goingDoor2Person2 /\ 
  robot1u[i]==goToDoor2Person2 /\
  closeChangeClock(c, cl, cu, e, co, robot1, i) /\ 
  cvs(e, co, robot1, i) /\ cps(co, cl, cu, robot1, i)); % state changing
constraint forall(i in STAGESm1)(Ene1[124,i] -> 
  robot1l[i]==goingDoor2Person2 /\ robot1l[i+1]==rescuedPerson2 /\ 
  c[robot1,i]==t9 /\
  closeChangeClock(c, cl, cu, e, co, robot1, i) /\ 
  cvs(e, co, robot1, i) /\ cps(co, cl, cu, robot1, i)); % state changing
constraint forall(i in STAGESm1)(Ene1[125,i] -> 
  robot1l[i]==insideRoom1 /\ robot1l[i+1]==goingToDoor3 /\ 
  robot1u[i]==goToDoor3 /\
  closeChangeClock(c, cl, cu, e, co, robot1, i) /\ 
  cvs(e, co, robot1, i) /\ cps(co, cl, cu, robot1, i)); % state changing
constraint forall(i in STAGESm1)(Ene1[127,i] -> 
  robot1l[i]==goingToDoor3 /\ robot1l[i+1]==atDoor3 /\ 
  c[robot1,i]==t4 /\
  closeChangeClock(c, cl, cu, e, co, robot1, i) /\ 
  cvs(e, co, robot1, i) /\ cps(co, cl, cu, robot1, i)); % state changing
constraint forall(i in STAGESm1)(Ene1[129,i] -> 
  robot1l[i]==atDoor3 /\ robot1l[i+1]==goingDoor3Person1 /\ 
  robot1u[i]==goToDoor3Person1 /\
  closeChangeClock(c, cl, cu, e, co, robot1, i) /\ 
  cvs(e, co, robot1, i) /\ cps(co, cl, cu, robot1, i)); % state changing
constraint forall(i in STAGESm1)(Ene1[131,i] -> 
  robot1l[i]==goingDoor3Person1 /\ robot1l[i+1]==rescuedPerson1 /\ 
  c[robot1,i]==t5 /\
  closeChangeClock(c, cl, cu, e, co, robot1, i) /\ 
  cvs(e, co, robot1, i) /\ cps(co, cl, cu, robot1, i)); % state changing
constraint forall(i in STAGESm1)(Ene1[133,i] -> 
  robot1l[i]==atDoor3 /\ robot1l[i+1]==goingDoor3Person2 /\ 
  robot1u[i]==goToDoor3Person2 /\
  closeChangeClock(c, cl, cu, e, co, robot1, i) /\ 
  cvs(e, co, robot1, i) /\ cps(co, cl, cu, robot1, i)); % state changing
constraint forall(i in STAGESm1)(Ene1[135,i] -> 
  robot1l[i]==goingDoor3Person2 /\ robot1l[i+1]==rescuedPerson2 /\ 
  c[robot1,i]==t6 /\
  closeChangeClock(c, cl, cu, e, co, robot1, i) /\ 
  cvs(e, co, robot1, i) /\ cps(co, cl, cu, robot1, i)); % state changing

%% IDLING
constraint forall(i in STAGESm1)(Ene1[101,i] ->
  robot1l[i]==outside /\ robot1l[i+1]==outside /\ robot1u[i]==doNothing /\
  closeIdlingClock(c, cl, cu, e, co, robot1, i) /\ 
  cps(co, cl, cu, robot1, i)); % idling
constraint forall(i in STAGESm1)(Ene1[103,i] ->
  robot1l[i]==goingToDoor1 /\ robot1l[i+1]==goingToDoor1 /\
  closeIdlingClock(c, cl, cu, e, co, robot1, i) /\ 
  cps(co, cl, cu, robot1, i)); % idling
constraint forall(i in STAGESm1)(Ene1[105,i] ->
  robot1l[i]==atDoor1 /\ robot1l[i+1]==atDoor1 /\ robot1u[i]==doNothing /\
  closeIdlingClock(c, cl, cu, e, co, robot1, i) /\ 
  cps(co, cl, cu, robot1, i)); % idling
constraint forall(i in STAGESm1)(Ene1[107,i] ->
  robot1l[i]==door1Opening /\ robot1l[i+1]==door1Opening /\
  closeIdlingClock(c, cl, cu, e, co, robot1, i) /\ 
  cps(co, cl, cu, robot1, i)); % idling
constraint forall(i in STAGESm1)(Ene1[110,i] ->
  robot1l[i]==insideRoom1 /\ robot1l[i+1]==insideRoom1 /\ robot1u[i]==doNothing /\
  closeIdlingClock(c, cl, cu, e, co, robot1, i) /\ 
  cps(co, cl, cu, robot1, i)); % idling
constraint forall(i in STAGESm1)(Ene1[112,i] ->
  robot1l[i]==goingToDoor2 /\ robot1l[i+1]==goingToDoor2 /\
  closeIdlingClock(c, cl, cu, e, co, robot1, i) /\ 
  cps(co, cl, cu, robot1, i)); % idling
constraint forall(i in STAGESm1)(Ene1[114,i] ->
  robot1l[i]==atDoor2 /\ robot1l[i+1]==atDoor2 /\ robot1u[i]==doNothing /\
  closeIdlingClock(c, cl, cu, e, co, robot1, i) /\ 
  cps(co, cl, cu, robot1, i)); % idling
constraint forall(i in STAGESm1)(Ene1[116,i] ->
  robot1l[i]==openingDoor2 /\ robot1l[i+1]==openingDoor2 /\
  closeIdlingClock(c, cl, cu, e, co, robot1, i) /\ 
  cps(co, cl, cu, robot1, i)); % idling
constraint forall(i in STAGESm1)(Ene1[118,i] ->
  robot1l[i]==insideDoor2 /\ robot1l[i+1]==insideDoor2 /\ robot1u[i]==doNothing /\
  closeIdlingClock(c, cl, cu, e, co, robot1, i) /\ 
  cps(co, cl, cu, robot1, i)); % idling
constraint forall(i in STAGESm1)(Ene1[120,i] ->
  robot1l[i]==goingDoor2Person1 /\ robot1l[i+1]==goingDoor2Person1 /\
  closeIdlingClock(c, cl, cu, e, co, robot1, i) /\ 
  cps(co, cl, cu, robot1, i)); % idling
constraint forall(i in STAGESm1)(Ene1[123,i] ->
  robot1l[i]==goingDoor2Person2 /\ robot1l[i+1]==goingDoor2Person2 /\
  closeIdlingClock(c, cl, cu, e, co, robot1, i) /\ 
  cps(co, cl, cu, robot1, i)); % idling
constraint forall(i in STAGESm1)(Ene1[126,i] ->
  robot1l[i]==rescuedPerson1 /\ robot1l[i+1]==rescuedPerson1 /\
  closeIdlingClock(c, cl, cu, e, co, robot1, i) /\ 
  cps(co, cl, cu, robot1, i)); % idling
constraint forall(i in STAGESm1)(Ene1[128,i] ->
  robot1l[i]==rescuedPerson2 /\ robot1l[i+1]==rescuedPerson2 /\
  closeIdlingClock(c, cl, cu, e, co, robot1, i) /\ 
  cps(co, cl, cu, robot1, i)); % idling
constraint forall(i in STAGESm1)(Ene1[130,i] ->
  robot1l[i]==goingToDoor3 /\ robot1l[i+1]==goingToDoor3 /\
  closeIdlingClock(c, cl, cu, e, co, robot1, i) /\ 
  cps(co, cl, cu, robot1, i)); % idling
constraint forall(i in STAGESm1)(Ene1[132,i] ->
  robot1l[i]==atDoor3 /\ robot1l[i+1]==atDoor3 /\ robot1u[i]==doNothing /\
  closeIdlingClock(c, cl, cu, e, co, robot1, i) /\ 
  cps(co, cl, cu, robot1, i)); % idling
constraint forall(i in STAGESm1)(Ene1[134,i] ->
  robot1l[i]==goingDoor3Person1 /\ robot1l[i+1]==goingDoor3Person1 /\
  closeIdlingClock(c, cl, cu, e, co, robot1, i) /\ 
  cps(co, cl, cu, robot1, i)); % idling
constraint forall(i in STAGESm1)(Ene1[136,i] ->
  robot1l[i]==goingDoor3Person2 /\ robot1l[i+1]==goingDoor3Person2 /\
  closeIdlingClock(c, cl, cu, e, co, robot1, i) /\ 
  cps(co, cl, cu, robot1, i)); % idling
  
  
%%%%%%% ROBOT 2 %%%%%% 
  
% HARDCODED transition constraints for Robot 2
constraint forall(i in STAGES)(not Eno2[102,i]); % state changing
constraint forall(i in STAGES)(not Eno2[104,i]); % state changing
constraint forall(i in STAGES)(not Eno2[106,i]); % state changing
constraint forall(i in STAGES)(not Eno2[108,i]); % state changing
constraint forall(i in STAGES)(not Eno2[109,i]); % state changing
constraint forall(i in STAGES)(not Eno2[111,i]); % state changing
constraint forall(i in STAGES)(not Eno2[113,i]); % state changing
constraint forall(i in STAGES)(not Eno2[115,i]); % state changing
constraint forall(i in STAGES)(not Eno2[117,i]); % state changing
constraint forall(i in STAGES)(not Eno2[137,i]); % state changing
constraint forall(i in STAGES)(not Eno2[119,i]); % state changing
constraint forall(i in STAGES)(not Eno2[121,i]); % state changing
constraint forall(i in STAGES)(not Eno2[122,i]); % state changing
constraint forall(i in STAGES)(not Eno2[124,i]); % state changing
constraint forall(i in STAGES)(not Eno2[125,i]); % state changing
constraint forall(i in STAGES)(not Eno2[127,i]); % state changing
constraint forall(i in STAGES)(not Eno2[129,i]); % state changing
constraint forall(i in STAGES)(not Eno2[131,i]); % state changing
constraint forall(i in STAGES)(not Eno2[133,i]); % state changing
constraint forall(i in STAGES)(not Eno2[135,i]); % state changing

constraint forall(i in STAGES)(Eno2[101,i] -> robot2l[i]==outside /\ openIdlingClock(c, cl, cu, e, co, robot2, i)); % idling
constraint forall(i in STAGES)(Eno2[103,i] -> robot2l[i]==goingToDoor1 /\ openIdlingClock(c, cl, cu, e, co, robot2, i)); % idling
constraint forall(i in STAGES)(Eno2[105,i] -> robot2l[i]==atDoor1 /\ openIdlingClock(c, cl, cu, e, co, robot2, i)); % idling
constraint forall(i in STAGES)(Eno2[107,i] -> robot2l[i]==door1Opening /\ openIdlingClock(c, cl, cu, e, co, robot2, i)); % idling
constraint forall(i in STAGES)(Eno2[110,i] -> robot2l[i]==insideRoom1 /\ openIdlingClock(c, cl, cu, e, co, robot2, i)); % idling
constraint forall(i in STAGES)(Eno2[112,i] -> robot2l[i]==goingToDoor2 /\ openIdlingClock(c, cl, cu, e, co, robot2, i)); % idling
constraint forall(i in STAGES)(Eno2[114,i] -> robot2l[i]==atDoor2 /\ openIdlingClock(c, cl, cu, e, co, robot2, i)); % idling
constraint forall(i in STAGES)(Eno2[116,i] -> robot2l[i]==openingDoor2 /\ openIdlingClock(c, cl, cu, e, co, robot2, i)); % idling
constraint forall(i in STAGES)(Eno2[118,i] -> robot2l[i]==insideDoor2 /\ openIdlingClock(c, cl, cu, e, co, robot2, i)); % idling
constraint forall(i in STAGES)(Eno2[120,i] -> robot2l[i]==goingDoor2Person1 /\ openIdlingClock(c, cl, cu, e, co, robot2, i)); % idling
constraint forall(i in STAGES)(Eno2[123,i] -> robot2l[i]==goingDoor2Person2 /\ openIdlingClock(c, cl, cu, e, co, robot2, i)); % idling
constraint forall(i in STAGES)(Eno2[126,i] -> robot2l[i]==rescuedPerson1 /\ openIdlingClock(c, cl, cu, e, co, robot2, i)); % idling
constraint forall(i in STAGES)(Eno2[128,i] -> robot2l[i]==rescuedPerson2 /\ openIdlingClock(c, cl, cu, e, co, robot2, i)); % idling
constraint forall(i in STAGES)(Eno2[130,i] -> robot2l[i]==goingToDoor3 /\ openIdlingClock(c, cl, cu, e, co, robot2, i)); % idling
constraint forall(i in STAGES)(Eno2[132,i] -> robot2l[i]==atDoor3 /\ openIdlingClock(c, cl, cu, e, co, robot2, i)); % idling
constraint forall(i in STAGES)(Eno2[134,i] -> robot2l[i]==goingDoor3Person1 /\ openIdlingClock(c, cl, cu, e, co, robot2, i)); % idling
constraint forall(i in STAGES)(Eno2[136,i] -> robot2l[i]==goingDoor3Person2 /\ openIdlingClock(c, cl, cu, e, co, robot2, i)); % idling


%% STATE CHANGING
constraint forall(i in STAGESm1)(Ene2[102,i] -> 
  robot2l[i]==outside /\ robot2l[i+1]==goingToDoor1 /\ 
  robot2u[i]==goToDoor1 /\ 
  closeChangeClock(c, cl, cu, e, co, robot2, i) /\ 
  cvs(e, co, robot2, i) /\ cps(co, cl, cu, robot2, i)); % state changing
constraint forall(i in STAGESm1)(Ene2[104,i] -> 
  robot2l[i]==goingToDoor1 /\ robot2l[i+1]==atDoor1 /\ 
  c[robot2,i]==t1 /\
  closeChangeClock(c, cl, cu, e, co, robot2, i) /\ 
  cvs(e, co, robot2, i) /\ cps(co, cl, cu, robot2, i)); % state changing
constraint forall(i in STAGESm1)(Ene2[106,i] -> 
  robot2l[i]==atDoor1 /\ robot2l[i+1]==door1Opening /\ 
  c[robot2,i]==t1 /\ door1l[i]==closed /\ door1l[i+1]==opening /\
  closeChangeClock(c, cl, cu, e, co, robot2, i) /\ 
  cvs(e, co, robot2, i) /\ cps(co, cl, cu, robot2, i)); % state changing
constraint forall(i in STAGESm1)(Ene2[108,i] -> 
  robot2l[i]==door1Opening /\ robot2l[i+1]==insideRoom1 /\ 
  c[robot2,i]==t2 /\ door1l[i]==opening /\ door1l[i+1]==open /\
  closeChangeClock(c, cl, cu, e, co, robot2, i) /\ 
  cvs(e, co, robot2, i) /\ cps(co, cl, cu, robot2, i)); % state changing
constraint forall(i in STAGESm1)(Ene2[109,i] -> 
  robot2l[i]==atDoor1 /\ robot2l[i+1]==insideRoom1 /\ 
  door1l[i]==open /\
  closeChangeClock(c, cl, cu, e, co, robot2, i) /\ 
  cvs(e, co, robot2, i) /\ cps(co, cl, cu, robot2, i)); % state changing
constraint forall(i in STAGESm1)(Ene2[111,i] -> 
  robot2l[i]==insideRoom1 /\ robot2l[i+1]==goingToDoor2 /\ 
  robot2u[i]==goToDoor2 /\
  closeChangeClock(c, cl, cu, e, co, robot2, i) /\ 
  cvs(e, co, robot2, i) /\ cps(co, cl, cu, robot2, i)); % state changing
constraint forall(i in STAGESm1)(Ene2[113,i] -> 
  robot2l[i]==goingToDoor2 /\ robot2l[i+1]==atDoor2 /\ 
  c[robot2,i]==t3 /\
  closeChangeClock(c, cl, cu, e, co, robot2, i) /\ 
  cvs(e, co, robot2, i) /\ cps(co, cl, cu, robot2, i)); % state changing
constraint forall(i in STAGESm1)(Ene2[115,i] -> 
  robot2l[i]==atDoor2 /\ robot2l[i+1]==openingDoor2 /\ 
  robot2u[i]==openDoor2  /\ door2l[i]==closed /\ door2l[i+1]==opening /\
  closeChangeClock(c, cl, cu, e, co, robot2, i) /\ 
  cvs(e, co, robot2, i) /\ cps(co, cl, cu, robot2, i)); % state changing
constraint forall(i in STAGESm1)(Ene2[117,i] -> 
  robot2l[i]==openingDoor2 /\ robot2l[i+1]==insideDoor2 /\ 
  door2l[i]==opening /\ door2l[i]==open /\ c[robot2,i]==t7 /\
  closeChangeClock(c, cl, cu, e, co, robot2, i) /\ 
  cvs(e, co, robot2, i) /\ cps(co, cl, cu, robot2, i)); % state changing
constraint forall(i in STAGESm1)(Ene2[137,i] -> 
  robot2l[i]==atDoor2 /\ robot2l[i+1]==insideDoor2 /\ 
  door2l[i]==open /\
  closeChangeClock(c, cl, cu, e, co, robot2, i) /\ 
  cvs(e, co, robot2, i) /\ cps(co, cl, cu, robot2, i)); % state changing
constraint forall(i in STAGESm1)(Ene2[119,i] -> 
  robot2l[i]==insideDoor2 /\ robot2l[i+1]==goingDoor2Person1 /\ 
  robot2u[i]==goToDoor2Person1 /\
  closeChangeClock(c, cl, cu, e, co, robot2, i) /\ 
  cvs(e, co, robot2, i) /\ cps(co, cl, cu, robot2, i)); % state changing
constraint forall(i in STAGESm1)(Ene2[121,i] -> 
  robot2l[i]==goingDoor2Person1 /\ robot2l[i+1]==rescuedPerson1 /\ 
  c[robot2,i]==t8 /\
  closeChangeClock(c, cl, cu, e, co, robot2, i) /\ 
  cvs(e, co, robot2, i) /\ cps(co, cl, cu, robot2, i)); % state changing
constraint forall(i in STAGESm1)(Ene2[122,i] -> 
  robot2l[i]==insideDoor2 /\ robot2l[i+1]==goingDoor2Person2 /\ 
  robot2u[i]==goToDoor2Person2 /\
  closeChangeClock(c, cl, cu, e, co, robot2, i) /\ 
  cvs(e, co, robot2, i) /\ cps(co, cl, cu, robot2, i)); % state changing
constraint forall(i in STAGESm1)(Ene2[124,i] -> 
  robot2l[i]==goingDoor2Person2 /\ robot2l[i+1]==rescuedPerson2 /\ 
  c[robot2,i]==t9 /\
  closeChangeClock(c, cl, cu, e, co, robot2, i) /\ 
  cvs(e, co, robot2, i) /\ cps(co, cl, cu, robot2, i)); % state changing
constraint forall(i in STAGESm1)(Ene2[125,i] -> 
  robot2l[i]==insideRoom1 /\ robot2l[i+1]==goingToDoor3 /\ 
  robot2u[i]==goToDoor3 /\
  closeChangeClock(c, cl, cu, e, co, robot2, i) /\ 
  cvs(e, co, robot2, i) /\ cps(co, cl, cu, robot2, i)); % state changing
constraint forall(i in STAGESm1)(Ene2[127,i] -> 
  robot2l[i]==goingToDoor3 /\ robot2l[i+1]==atDoor3 /\ 
  c[robot2,i]==t4 /\
  closeChangeClock(c, cl, cu, e, co, robot2, i) /\ 
  cvs(e, co, robot2, i) /\ cps(co, cl, cu, robot2, i)); % state changing
constraint forall(i in STAGESm1)(Ene2[129,i] -> 
  robot2l[i]==atDoor3 /\ robot2l[i+1]==goingDoor3Person1 /\ 
  robot2u[i]==goToDoor3Person1 /\
  closeChangeClock(c, cl, cu, e, co, robot2, i) /\ 
  cvs(e, co, robot2, i) /\ cps(co, cl, cu, robot2, i)); % state changing
constraint forall(i in STAGESm1)(Ene2[131,i] -> 
  robot2l[i]==goingDoor3Person1 /\ robot2l[i+1]==rescuedPerson1 /\ 
  c[robot2,i]==t5 /\
  closeChangeClock(c, cl, cu, e, co, robot2, i) /\ 
  cvs(e, co, robot2, i) /\ cps(co, cl, cu, robot2, i)); % state changing
constraint forall(i in STAGESm1)(Ene2[133,i] -> 
  robot2l[i]==atDoor3 /\ robot2l[i+1]==goingDoor3Person2 /\ 
  robot2u[i]==goToDoor3Person2 /\
  closeChangeClock(c, cl, cu, e, co, robot2, i) /\ 
  cvs(e, co, robot2, i) /\ cps(co, cl, cu, robot2, i)); % state changing
constraint forall(i in STAGESm1)(Ene2[135,i] -> 
  robot2l[i]==goingDoor3Person2 /\ robot2l[i+1]==rescuedPerson2 /\ 
  c[robot2,i]==t6 /\
  closeChangeClock(c, cl, cu, e, co, robot2, i) /\ 
  cvs(e, co, robot2, i) /\ cps(co, cl, cu, robot2, i)); % state changing

%% IDLING
constraint forall(i in STAGESm1)(Ene2[101,i] ->
  robot2l[i]==outside /\ robot2l[i+1]==outside /\ robot2u[i]==doNothing /\
  closeIdlingClock(c, cl, cu, e, co, robot2, i) /\ 
  cps(co, cl, cu, robot2, i)); % idling
constraint forall(i in STAGESm1)(Ene2[103,i] ->
  robot2l[i]==goingToDoor1 /\ robot2l[i+1]==goingToDoor1 /\
  closeIdlingClock(c, cl, cu, e, co, robot2, i) /\ 
  cps(co, cl, cu, robot2, i)); % idling
constraint forall(i in STAGESm1)(Ene2[105,i] ->
  robot2l[i]==atDoor1 /\ robot2l[i+1]==atDoor1 /\ robot2u[i]==doNothing /\
  closeIdlingClock(c, cl, cu, e, co, robot2, i) /\ 
  cps(co, cl, cu, robot2, i)); % idling
constraint forall(i in STAGESm1)(Ene2[107,i] ->
  robot2l[i]==door1Opening /\ robot2l[i+1]==door1Opening /\
  closeIdlingClock(c, cl, cu, e, co, robot2, i) /\ 
  cps(co, cl, cu, robot2, i)); % idling
constraint forall(i in STAGESm1)(Ene2[110,i] ->
  robot2l[i]==insideRoom1 /\ robot2l[i+1]==insideRoom1 /\ robot2u[i]==doNothing /\
  closeIdlingClock(c, cl, cu, e, co, robot2, i) /\ 
  cps(co, cl, cu, robot2, i)); % idling
constraint forall(i in STAGESm1)(Ene2[112,i] ->
  robot2l[i]==goingToDoor2 /\ robot2l[i+1]==goingToDoor2 /\
  closeIdlingClock(c, cl, cu, e, co, robot2, i) /\ 
  cps(co, cl, cu, robot2, i)); % idling
constraint forall(i in STAGESm1)(Ene2[114,i] ->
  robot2l[i]==atDoor2 /\ robot2l[i+1]==atDoor2 /\ robot2u[i]==doNothing /\
  closeIdlingClock(c, cl, cu, e, co, robot2, i) /\ 
  cps(co, cl, cu, robot2, i)); % idling
constraint forall(i in STAGESm1)(Ene2[116,i] ->
  robot2l[i]==openingDoor2 /\ robot2l[i+1]==openingDoor2 /\
  closeIdlingClock(c, cl, cu, e, co, robot2, i) /\ 
  cps(co, cl, cu, robot2, i)); % idling
constraint forall(i in STAGESm1)(Ene2[118,i] ->
  robot2l[i]==insideDoor2 /\ robot2l[i+1]==insideDoor2 /\ robot2u[i]==doNothing /\
  closeIdlingClock(c, cl, cu, e, co, robot2, i) /\ 
  cps(co, cl, cu, robot2, i)); % idling
constraint forall(i in STAGESm1)(Ene2[120,i] ->
  robot2l[i]==goingDoor2Person1 /\ robot2l[i+1]==goingDoor2Person1 /\
  closeIdlingClock(c, cl, cu, e, co, robot2, i) /\ 
  cps(co, cl, cu, robot2, i)); % idling
constraint forall(i in STAGESm1)(Ene2[123,i] ->
  robot2l[i]==goingDoor2Person2 /\ robot2l[i+1]==goingDoor2Person2 /\
  closeIdlingClock(c, cl, cu, e, co, robot2, i) /\ 
  cps(co, cl, cu, robot2, i)); % idling
constraint forall(i in STAGESm1)(Ene2[126,i] ->
  robot2l[i]==rescuedPerson1 /\ robot2l[i+1]==rescuedPerson1 /\
  closeIdlingClock(c, cl, cu, e, co, robot2, i) /\ 
  cps(co, cl, cu, robot2, i)); % idling
constraint forall(i in STAGESm1)(Ene2[128,i] ->
  robot2l[i]==rescuedPerson2 /\ robot2l[i+1]==rescuedPerson2 /\
  closeIdlingClock(c, cl, cu, e, co, robot2, i) /\ 
  cps(co, cl, cu, robot2, i)); % idling
constraint forall(i in STAGESm1)(Ene2[130,i] ->
  robot2l[i]==goingToDoor3 /\ robot2l[i+1]==goingToDoor3 /\
  closeIdlingClock(c, cl, cu, e, co, robot2, i) /\ 
  cps(co, cl, cu, robot2, i)); % idling
constraint forall(i in STAGESm1)(Ene2[132,i] ->
  robot2l[i]==atDoor3 /\ robot2l[i+1]==atDoor3 /\ robot2u[i]==doNothing /\
  closeIdlingClock(c, cl, cu, e, co, robot2, i) /\ 
  cps(co, cl, cu, robot2, i)); % idling
constraint forall(i in STAGESm1)(Ene2[134,i] ->
  robot2l[i]==goingDoor3Person1 /\ robot2l[i+1]==goingDoor3Person1 /\
  closeIdlingClock(c, cl, cu, e, co, robot2, i) /\ 
  cps(co, cl, cu, robot2, i)); % idling
constraint forall(i in STAGESm1)(Ene2[136,i] ->
  robot2l[i]==goingDoor3Person2 /\ robot2l[i+1]==goingDoor3Person2 /\
  closeIdlingClock(c, cl, cu, e, co, robot2, i) /\ 
  cps(co, cl, cu, robot2, i)); % idling
  
%%%%%%% ENCODE COST

% var float: totalCost = sum(i in STAGES)(sum(t in (TRANSITIONS_comp_idle union TRANSITIONS_conn_idle union TRANSITIONS_proj_idle))(Eno[t,i] * 1 * floor(e[i+1]-e[i])) + sum(t in TRANSITIONS_state_changing)(Ene[t,i])); % throws error - MLTP Cost

% var float: totalCost = sum(i in STAGES)(sum(t in TRANSITIONS_state_changing)(1 * Ene[t,i])); % TOP cost

var float: totalCost = e[h];

solve minimize totalCost;

% output ["Total Cost: ", show(totalCost)];

% solve satisfy;