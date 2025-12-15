% ADJUSTABLE Parameter for float upper limit
float : Fupper;
% ADJUSTABLE Parameter for horizon
int : h;
% stage numbering
set of int : STAGES = 0..h-1;
set of int : STAGESm1 = 0..h-2; % m1 = minus 1
set of int : STAGESp1 = 0..h;   % p1 = plus 1

% HARDCODED Parameter for number of transitions
int : tr = 27;
% HARDCODED transition numbering
set of int : TRANSITIONS = 0..tr;
set of int : TRANSITIONS_compc_reset = {1,2,3,4};
set of int : TRANSITIONS_connc_reset = {9,10};
set of int : TRANSITIONS_projc_reset = {13,14,15,16,17,18,19,20,27};
set of int : TRANSITIONS_state_changing = {0,1,2,3,8,9,12,13,14,15,16,17,18,19,20};

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
constraint forall(i in STAGESp1)(e[i]>=0 /\ e[i]<=Fupper); % Bound the variable to be positive integer

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
constraint forall(a in AUTOMATA, i in STAGES)(c[a,i]>=0 /\ c[a,i]<=Fupper); % Bound the variable to be positive integer

% clock offsets for all stages
array[AUTOMATA, STAGESp1] of var float : co; 
constraint forall(a in AUTOMATA, i in STAGESp1)(co[a,i]>=0 /\ co[a,i]<=Fupper); % Bound the variable to be positive integer

% clock parameters for all stages
array[AUTOMATA, STAGES] of var float : cl;
array[AUTOMATA, STAGES] of var float : cu;
constraint forall(a in AUTOMATA, i in STAGES)(cl[a,i]>=0 /\ cl[a,i]<=Fupper); % Bound the variable to be positive integer
constraint forall(a in AUTOMATA, i in STAGES)(cu[a,i]>=0 /\ cu[a,i]<=Fupper); % Bound the variable to be positive integer

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
          inOffsetRangeWithEq(e[i],e[i+1],co[a,i],l[a,i],u[a,i]);

% end event of a stage, idling transition, clock constraint
predicate closeIdlingClock(array[Automata,int] of var float: c, 
                      array[Automata,int] of var float: l, 
                      array[Automata,int] of var float: u,
                      array[int] of var float: e,
                      array[Automata,int] of var float: co, 
                      Automata: a, int: i) = 
          lessThanUpper(e[i+1],e[i+1],co[a,i],u[a,i]);

% end event of a stage, state changing transition, clock constraint
predicate closeChangeClock(array[Automata,int] of var float: c, 
                      array[Automata,int] of var float: l,
                      array[Automata,int] of var float: u,
                      array[int] of var float: e,
                      array[Automata,int] of var float: co, 
                      Automata: a, int: i) = 
          inOffsetRangeWithEq(e[i+1],e[i+1],co[a,i],l[a,i],u[a,i]);

% "cvs" stands for clock variable reset
predicate cvs(array[int] of var float: e,
              array[Automata,int] of var float: co, 
              Automata: a,  int: i) = (co[a,i+1] == e[i+1]);

% "cps" stands for clock parameter reset
predicate cps(array[Automata,int] of var float: co,
              array[Automata,int] of var float: l,
              array[Automata,int] of var float: u,
              Automata: a,  int: i) = inRangeWithEq(co[a,i+1], l[a,i], u[a,i]);

% clock constraints
constraint forall(a in AUTOMATA, i in STAGES)(c[a,i]>=0);
constraint forall(a in AUTOMATA, i in STAGES)(co[a,i]>=0);
constraint forall(a in AUTOMATA, i in STAGES)(cu[a,i]>=cl[a,i]);


% HARDCODED transition constraints for COMPUTER
constraint forall(i in STAGES)(not Eno[0,i]); % state changing
constraint forall(i in STAGES)(not Eno[1,i]); % state changing
constraint forall(i in STAGES)(not Eno[2,i]); % state changing
constraint forall(i in STAGES)(not Eno[3,i]); % state changing
constraint forall(i in STAGES)(Eno[4,i] -> compl[i]==compOn /\ openIdlingClock(c, cl, cu, e, co, comp, i)); % idling
constraint forall(i in STAGES)(Eno[5,i] -> compl[i]==compShutdown /\ openIdlingClock(c, cl, cu, e, co, comp, i)); % idling
constraint forall(i in STAGES)(Eno[6,i] -> compl[i]==compOff /\ openIdlingClock(c, cl, cu, e, co, comp, i)); % idling
constraint forall(i in STAGES)(Eno[7,i] -> compl[i]==compBooting /\ openIdlingClock(c, cl, cu, e, co, comp, i)); % idling

constraint forall(i in STAGES)(Ene[0,i] -> 
  compl[i]==compOn /\ compl[i]==compShutdown /\ 
  compu[i]==compTurnOff /\ 
  closeChangeClock(c, cl, cu, e, co, comp, i) /\ 
  cvs(e, co, comp, i) /\ cps(co, cl, cu, comp, i)); % state changing
constraint forall(i in STAGES)(Ene[1,i] -> 
  compl[i]==compShutdown /\ compl[i]==compOff /\ 
  c[comp,i]==30 /\
  closeChangeClock(c, cl, cu, e, co, comp, i) /\ 
  cvs(e, co, comp, i) /\ cps(co, cl, cu, comp, i)); % state changing
constraint forall(i in STAGES)(Ene[2,i] ->
  compl[i]==compOff /\ compl[i]==compBooting /\ 
  compu[i]==compTurnOn /\ 
  closeChangeClock(c, cl, cu, e, co, comp, i) /\ 
  cvs(e, co, comp, i) /\ cps(co, cl, cu, comp, i)); % state changing
constraint forall(i in STAGES)(Ene[3,i] ->
  compl[i]==compBooting /\ compl[i]==compOn /\ 
  c[comp,i]==15 /\
  closeChangeClock(c, cl, cu, e, co, comp, i) /\ 
  cvs(e, co, comp, i) /\ cps(co, cl, cu, comp, i)); % state changing
constraint forall(i in STAGES)(Ene[4,i] ->
  compl[i]==compOn /\ 
  closeIdlingClock(c, cl, cu, e, co, comp, i) /\ 
  cvs(e, co, comp, i) /\ cps(co, cl, cu, comp, i)); % idling
constraint forall(i in STAGES)(Ene[5,i] ->
  compl[i]==compShutdown /\ 
  closeIdlingClock(c, cl, cu, e, co, comp, i) /\ 
  cvs(e, co, comp, i) /\ cps(co, cl, cu, comp, i)); % idling
constraint forall(i in STAGES)(Ene[6,i] ->
  compl[i]==compOff /\ 
  closeIdlingClock(c, cl, cu, e, co, comp, i) /\ 
  cvs(e, co, comp, i) /\ cps(co, cl, cu, comp, i)); % idling
constraint forall(i in STAGES)(Ene[7,i] ->
  compl[i]==compBooting /\ 
  closeIdlingClock(c, cl, cu, e, co, comp, i) /\ 
  cvs(e, co, comp, i) /\ cps(co, cl, cu, comp, i)); % idling

% HARDCODED transition constraints for CONNECTION
constraint forall(i in STAGES)(not Eno[8,i]); % state changing
constraint forall(i in STAGES)(not Eno[9,i]); % state changing
constraint forall(i in STAGES)(Eno[10,i] -> connl[i]==connected /\ openIdlingClock(c, cl, cu, e, co, conn, i)); % idling
constraint forall(i in STAGES)(Eno[11,i] -> connl[i]==disconnected /\ openIdlingClock(c, cl, cu, e, co, conn, i)); % idling

constraint forall(i in STAGES)(Ene[8,i] -> 
  connl[i]==connected /\ connl[i]==disconnected /\
  connu[i]==disconnect /\
  closeChangeClock(c, cl, cu, e, co, conn, i) /\ 
  cvs(e, co, conn, i) /\ cps(co, cl, cu, conn, i)); % state changing
constraint forall(i in STAGES)(Ene[9,i] ->
  connl[i]==disconnected /\ connl[i]==connected /\ 
  connu[i]==connect /\
  closeChangeClock(c, cl, cu, e, co, conn, i) /\ 
  cvs(e, co, conn, i) /\ cps(co, cl, cu, conn, i)); % state changing
constraint forall(i in STAGES)(Ene[10,i] -> 
  connl[i]==connected /\ 
  closeIdlingClock(c, cl, cu, e, co, conn, i) /\ 
  cvs(e, co, conn, i) /\ cps(co, cl, cu, conn, i)); % idling
constraint forall(i in STAGES)(Ene[11,i] -> 
  connl[i]==disconnected /\ 
  closeIdlingClock(c, cl, cu, e, co, conn, i) /\ 
  cvs(e, co, conn, i) /\ cps(co, cl, cu, conn, i)); % idling

% HARDCODED transition constraints for PROJECTOR
constraint forall(i in STAGES)(not Eno[12,i]); % state changing
constraint forall(i in STAGES)(not Eno[13,i]); % state changing
constraint forall(i in STAGES)(not Eno[14,i]); % state changing
constraint forall(i in STAGES)(not Eno[15,i]); % state changing
constraint forall(i in STAGES)(not Eno[16,i]); % state changing
constraint forall(i in STAGES)(not Eno[17,i]); % state changing
constraint forall(i in STAGES)(not Eno[18,i]); % state changing
constraint forall(i in STAGES)(not Eno[19,i]); % state changing
constraint forall(i in STAGES)(not Eno[20,i]); % state changing
constraint forall(i in STAGES)(Eno[21,i] -> projl[i]==projOff /\ openIdlingClock(c, cl, cu, e, co, proj, i)); % idling
constraint forall(i in STAGES)(Eno[22,i] -> projl[i]==projWarmUp /\ openIdlingClock(c, cl, cu, e, co, proj, i)); % idling
constraint forall(i in STAGES)(Eno[23,i] -> projl[i]==projOn /\ openIdlingClock(c, cl, cu, e, co, proj, i)); % idling
constraint forall(i in STAGES)(Eno[24,i] -> projl[i]==projConfirm /\ openIdlingClock(c, cl, cu, e, co, proj, i)); % idling
constraint forall(i in STAGES)(Eno[25,i] -> projl[i]==projCoolDown /\ openIdlingClock(c, cl, cu, e, co, proj, i)); % idling
constraint forall(i in STAGES)(Eno[26,i] -> projl[i]==projWaiting /\ openIdlingClock(c, cl, cu, e, co, proj, i)); % idling

constraint forall(i in STAGES)(Ene[12,i] -> 
  projl[i]==projCoolDown /\ projl[i]==projOff /\ 
  c[proj,i]==60 /\
  closeChangeClock(c, cl, cu, e, co, proj, i) /\ 
  cvs(e, co, proj, i) /\ cps(co, cl, cu, proj, i)); % state changing
constraint forall(i in STAGES)(Ene[13,i] -> 
  projl[i]==projOff /\ projl[i]==projWarmUp /\ 
  proju[i]==projTurnOn /\
  closeChangeClock(c, cl, cu, e, co, proj, i) /\ 
  cvs(e, co, proj, i) /\ cps(co, cl, cu, proj, i)); % state changing
constraint forall(i in STAGES)(Ene[14,i] -> 
  projl[i]==projWarmUp /\ projl[i]==projOn /\ 
  c[proj,i] == 30 /\
  closeChangeClock(c, cl, cu, e, co, proj, i) /\ 
  cvs(e, co, proj, i) /\ cps(co, cl, cu, proj, i)); % state changing
constraint forall(i in STAGES)(Ene[15,i] -> 
  projl[i]==projOn /\ projl[i]==projConfirm /\ 
  proju[i]==projTurnOff /\
  closeChangeClock(c, cl, cu, e, co, proj, i) /\ 
  cvs(e, co, proj, i) /\ cps(co, cl, cu, proj, i)); % state changing
constraint forall(i in STAGES)(Ene[16,i] -> 
  projl[i]==projOn /\ projl[i]==projWaiting /\ 
  (compl[i]!=compOn \/ connl[i]!=connected) /\ proju[i]!=projTurnOff /\
  closeChangeClock(c, cl, cu, e, co, proj, i) /\ 
  cvs(e, co, proj, i) /\ cps(co, cl, cu, proj, i)); % state changing
constraint forall(i in STAGES)(Ene[17,i] -> 
  projl[i]==projConfirm /\ projl[i]==projCoolDown /\ 
  proju[i]==projTurnOff /\ inRange(c[proj,i],cl[proj,i],cu[proj,i]) /\
  closeChangeClock(c, cl, cu, e, co, proj, i) /\ 
  cvs(e, co, proj, i) /\ cps(co, cl, cu, proj, i)); % state changing
constraint forall(i in STAGES)(Ene[18,i] -> 
  projl[i]==projWaiting /\ projl[i]==projCoolDown /\ 
  (compl[i]!=compOn \/ connl[i]!=connected) /\ c[proj,i]==60 /\
  closeChangeClock(c, cl, cu, e, co, proj, i) /\ 
  cvs(e, co, proj, i) /\ cps(co, cl, cu, proj, i)); % state changing
constraint forall(i in STAGES)(Ene[19,i] -> 
  projl[i]==projWaiting /\ projl[i]==projOn /\ 
  compl[i]==compOn /\ connl[i]==connected /\
  closeChangeClock(c, cl, cu, e, co, proj, i) /\ 
  cvs(e, co, proj, i) /\ cps(co, cl, cu, proj, i)); % state changing
constraint forall(i in STAGES)(Ene[20,i] -> 
  projl[i]==projConfirm /\ projl[i]==projOn /\ 
  proju[i]!=projTurnOff /\ c[proj,i]==5 /\
  closeChangeClock(c, cl, cu, e, co, proj, i) /\ 
  cvs(e, co, proj, i) /\ cps(co, cl, cu, proj, i)); % state changing
constraint forall(i in STAGES)(Ene[21,i] -> 
  projl[i]==projOff /\ 
  closeIdlingClock(c, cl, cu, e, co, proj, i) /\ 
  cvs(e, co, proj, i) /\ cps(co, cl, cu, proj, i)); % idling
constraint forall(i in STAGES)(Ene[22,i] -> 
  projl[i]==projWarmUp /\ 
  closeIdlingClock(c, cl, cu, e, co, proj, i) /\ 
  cvs(e, co, proj, i) /\ cps(co, cl, cu, proj, i)); % idling
constraint forall(i in STAGES)(Ene[23,i] -> 
  projl[i]==projOn /\ 
  closeIdlingClock(c, cl, cu, e, co, proj, i) /\ 
  cvs(e, co, proj, i) /\ cps(co, cl, cu, proj, i)); % idling
constraint forall(i in STAGES)(Ene[24,i] -> 
  projl[i]==projConfirm /\ 
  closeIdlingClock(c, cl, cu, e, co, proj, i) /\ 
  cvs(e, co, proj, i) /\ cps(co, cl, cu, proj, i)); % idling
constraint forall(i in STAGES)(Ene[25,i] -> 
  projl[i]==projCoolDown /\ 
  closeIdlingClock(c, cl, cu, e, co, proj, i) /\ 
  cvs(e, co, proj, i) /\ cps(co, cl, cu, proj, i)); % idling
constraint forall(i in STAGES)(Ene[26,i] -> 
  projl[i]==projWaiting /\ 
  closeIdlingClock(c, cl, cu, e, co, proj, i) /\ 
  cvs(e, co, proj, i) /\ cps(co, cl, cu, proj, i)); % idling

% Making clock variables and parameters persist
% TODO: Make softcoded
constraint forall(i in STAGES, t in TRANSITIONS_compc_reset)(not Ene[t,i] -> co[comp,i]==co[comp,i+1]);
constraint forall(i in STAGES, t in TRANSITIONS_connc_reset)(not Ene[t,i] -> co[conn,i]==co[conn, i+1]);
constraint forall(i in STAGES, t in TRANSITIONS_projc_reset)(not Ene[t,i] -> co[proj,i]==co[proj,i+1]);

% Initial State Encoding
% TODO
constraint compl[0]==compOff;
constraint connl[0]==disconnected;
constraint projl[0]==projOff;

% Goal State Encoding
% TODO
constraint compl[h-1]==compOn;
constraint connl[h-1]==connected;
constraint projl[h-1]==projOn;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% NOTE: Adding the following constrains results in an unsatisfiable problem
%% There could be an error in any of the constraints or predicates,
%% before or after this point.


% Constraints that Ensure Deterministic Execution
% TODO


% Constraints That Ensure Concise Runs
% TODO: Check translation of Brian's encoding

% constraint exists(i in STAGESm1, t in TRANSITIONS_state_changing)(Ene[t,i]);



solve satisfy;

