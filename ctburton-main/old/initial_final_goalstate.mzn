% Use this editor as a MiniZinc scratch book
% ADJUSTABLE Parameter for float upper limit
float : Fupper = 100;
% ADJUSTABLE Parameter for horizon
int : h = 5; 
% stage numbering
set of int : STAGES = 0..h-1;
set of int : STAGESm1 = 0..h-2; % m1 = minus 1
set of int : STAGESp1 = 0..h;   % p1 = plus 1

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

% HARDCODED Parameter for number of automata
enum Automata = {comp, conn, proj};
set of Automata : AUTOMATA = {comp, conn, proj};

% HARDCODED Automaton enum types
% Note: There is an explicit enum for each location and control variable
%       because you cannot mix enums (create unions of enums)
enum CompL = {compOn, compShutdown, compOff, compBooting};
enum ConnL = {connected, disconnected};
enum ProjL = {projWaiting, projConfirm, projOn, projCoolDown, projWarmUp, projOff};
enum CompU = {compTurnOn, compTurnOff};
enum ConnU = {connect, disconnect};
enum ProjU = {projTurnOn, projTurnOff};

% events for all stages: forall 0<i<h, ei < ei+1
array[STAGESp1] of var float : e; 
constraint forall(i in STAGES)(e[i] < e[i+1]);
constraint forall(i in STAGESp1)(e[i]>=0 /\ e[i]<=Fupper); % Bound the variable to be positive

% location vars for all stages
array[STAGES] of var CompL : compl;
array[STAGES] of var ConnL : connl;
array[STAGES] of var ProjL : projl;

% command vars for all stages
array[STAGES] of var CompU : compu;
array[STAGES] of var ConnU : connu;
array[STAGES] of var ProjU : proju;

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
  projl[i]==projOn /\ projl[i+1]==projOn /\
  closeIdlingClock(c, cl, cu, e, co, proj, i) /\ 
  cps(co, cl, cu, proj, i)); % idling
  
constraint forall(i in STAGESm1)(Ene[24,i] -> 
  projl[i]==projConfirm /\ projl[i]=projConfirm /\
  closeIdlingClock(c, cl, cu, e, co, proj, i) /\ 
  cps(co, cl, cu, proj, i)); % idling
  
constraint forall(i in STAGESm1)(Ene[25,i] -> 
  projl[i]==projCoolDown /\ projl[i]==projCoolDown /\
  closeIdlingClock(c, cl, cu, e, co, proj, i) /\ 
  cps(co, cl, cu, proj, i)); % idling
  
constraint forall(i in STAGESm1)(Ene[26,i] -> 
  projl[i]==projWaiting /\ projl[i]==projWaiting /\
  closeIdlingClock(c, cl, cu, e, co, proj, i) /\ 
  cps(co, cl, cu, proj, i)); % idling

% Making clock variables and parameters persist % these seem a little problematic
constraint forall(i in STAGESm1)((forall([(not Ene[t, i]) | t in TRANSITIONS_compc_reset])) -> (co[comp,i]==co[comp,i+1]));
constraint forall(i in STAGESm1)((forall([(not Ene[t, i]) | t in TRANSITIONS_connc_reset])) -> (co[conn,i]==co[conn,i+1]));
constraint forall(i in STAGESm1)((forall([(not Ene[t, i]) | t in TRANSITIONS_projc_reset])) -> (co[proj,i]==co[proj,i+1]));

% constraint forall(i in STAGESm1, t in TRANSITIONS_compc_reset)(not Ene[t,i] -> co[comp,i]==co[comp,i+1]); % OLD
% constraint forall(i in STAGESm1, t in TRANSITIONS_connc_reset)(not Ene[t,i] -> co[conn,i]==co[conn, i+1]); % OLD
% constraint forall(i in STAGESm1, t in TRANSITIONS_projc_reset)(not Ene[t,i] -> co[proj,i]==co[proj,i+1]); % OLD

% Initial State Encoding
% TODO
constraint compl[0]==compOff;
constraint connl[0]==disconnected;
constraint projl[0]==projOff;

% Goal State Encoding
% TODO
% constraint compl[h-1]==compShutdown;
constraint compl[h-1]==compOn;
constraint connl[h-1]==connected;
constraint projl[h-1]==projOn;

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
constraint forall(i in STAGESm1)(exists([Ene[t,i] | t in TRANSITIONS_state_changing]));
% constraint exists(i in STAGESm1, t in TRANSITIONS_state_changing)(Ene[t,i]); % OLD

% var float: totalCost = sum(i in STAGES)(sum(t in (TRANSITIONS_comp_idle union TRANSITIONS_conn_idle union TRANSITIONS_proj_idle))(Eno[t,i] * 1 * floor(e[i+1]-e[i])) + sum(t in TRANSITIONS_state_changing)(Ene[t,i])); % throws error - MLTP Cost

% var float: totalCost = sum(i in STAGES)(sum(t in TRANSITIONS_state_changing)(1 * Ene[t,i])); % TOP cost

var float: totalCost = e[h];

solve minimize totalCost;

% output ["Total Cost: ", show(totalCost)];

% solve satisfy;