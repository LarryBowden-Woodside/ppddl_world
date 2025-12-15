float : Fupper = 25000;
int : h = 10;

set of int : STAGES = 0..9;
set of int : STAGESm1 = 0..8;
set of int : STAGESp1 = 0..10;

enum Automata = {comp, conn, proj};

set of Automata : AUTOMATA = {comp, conn, proj};

int : tr = 27;

set of int : TRANSITIONS = 1..27;

set of int : TRANSITIONS_comp_idle ={5, 6, 7, 8};
set of int : TRANSITIONS_conn_idle ={11, 12};
set of int : TRANSITIONS_proj_idle ={21, 22, 23, 24, 25, 26};

set of int : TRANSITIONS_comp_reset ={1, 2, 3, 4};
set of int : TRANSITIONS_conn_reset ={9, 10};
set of int : TRANSITIONS_proj_reset ={13, 14, 15, 16, 17, 18, 19, 20, 27};

set of int : TRANSITIONS_state_changing = {1, 2, 3, 4, 9, 10, 13, 14, 15, 16, 17, 18, 19, 20, 27};

enum compL ={compOn, compShutdown, compOff, compBooting};
enum connL ={connected, disconnected};
enum projL ={projWaiting, projConfirm, projOn, projCoolDown, projWarmUp, projOff};

enum compU ={compTurnOn, compTurnOff};
enum connU ={connect, disconnect};
enum projU ={projTurnOn, projTurnOff};

array[STAGES] of var compL : compl;
array[STAGES] of var connL : connl;
array[STAGES] of var projL : projl;

array[STAGES] of var compU : compu;
array[STAGES] of var connU : connu;
array[STAGES] of var projU : proju;

set of int : endStateAcceptAutomatonTr = {28, 29, 30, 31, 32};
enum endStateAcceptAutomatonL = {waiting, accepted, failed};

set of int : epAcceptAutomatonTr = {33, 34, 35, 36, 37, 38, 39};
enum epAcceptAutomatonL = {epWaiting, epActive, epAccepted, epFailed};

set of int : temporalAcceptAutomatonTr = {41, 42, 43, 44, 45, 46};
enum tempAcceptAutomatonL = {tempWaiting, tempActive, tempAccepted, tempFailed};

array[STAGES] of var endStateAcceptAutomatonL : endStateAcceptAutomatonTraj;
array[endStateAcceptAutomatonTr, STAGES] of var bool: endStateAcceptAutomatonTrTraj;
var int: stageWhenAccepted;

array[STAGES] of var epAcceptAutomatonL : epAcceptAutomatonTraj_ProjectorOnDuration;
array[epAcceptAutomatonTr, STAGES] of var bool: epAcceptAutomatonTrTraj_ProjectorOnDuration;
var int : epAcceptStartEvent_ProjectorOnDuration;
var int : epAcceptEndEvent_ProjectorOnDuration;
var float : epAcceptClockWhenStart_ProjectorOnDuration;
var float : epAcceptClockWhenEnd_ProjectorOnDuration;
var float : epAcceptClockParameter_ProjectorOnDuration;
constraint epAcceptStartEvent_ProjectorOnDuration >=0 /\ epAcceptStartEvent_ProjectorOnDuration <= h;
constraint epAcceptEndEvent_ProjectorOnDuration >=0 /\ epAcceptEndEvent_ProjectorOnDuration <= h;
constraint epAcceptClockWhenStart_ProjectorOnDuration >= 0 /\ epAcceptClockWhenStart_ProjectorOnDuration <= Fupper;
constraint epAcceptClockWhenEnd_ProjectorOnDuration >= 0 /\ epAcceptClockWhenEnd_ProjectorOnDuration <= Fupper;
constraint epAcceptClockParameter_ProjectorOnDuration >= 0 /\ epAcceptClockParameter_ProjectorOnDuration <= Fupper;

array[STAGES] of var epAcceptAutomatonL : epAcceptAutomatonTraj_ComputerOnDuration;
array[epAcceptAutomatonTr, STAGES] of var bool: epAcceptAutomatonTrTraj_ComputerOnDuration;
var int : epAcceptStartEvent_ComputerOnDuration;
var int : epAcceptEndEvent_ComputerOnDuration;
var float : epAcceptClockWhenStart_ComputerOnDuration;
var float : epAcceptClockWhenEnd_ComputerOnDuration;
var float : epAcceptClockParameter_ComputerOnDuration;
constraint epAcceptStartEvent_ComputerOnDuration >=0 /\ epAcceptStartEvent_ComputerOnDuration <= h;
constraint epAcceptEndEvent_ComputerOnDuration >=0 /\ epAcceptEndEvent_ComputerOnDuration <= h;
constraint epAcceptClockWhenStart_ComputerOnDuration >= 0 /\ epAcceptClockWhenStart_ComputerOnDuration <= Fupper;
constraint epAcceptClockWhenEnd_ComputerOnDuration >= 0 /\ epAcceptClockWhenEnd_ComputerOnDuration <= Fupper;
constraint epAcceptClockParameter_ComputerOnDuration >= 0 /\ epAcceptClockParameter_ComputerOnDuration <= Fupper;

array[STAGES] of var tempAcceptAutomatonL : temporalAcceptConstraint_Traj_ShutdownWithin600;
array[temporalAcceptAutomatonTr, STAGES] of var bool : temporalAcceptConstraint_TrTraj_ShutdownWithin600;
var int : temporalAcceptConstraint_event1_ShutdownWithin600;
var int : temporalAcceptConstraint_event2_ShutdownWithin600;
var float : temporalAcceptConstraint_event1Clock_ShutdownWithin600;
var float : temporalAcceptConstraint_event2Clock_ShutdownWithin600;
var float : temporalAcceptConstraint_ClockWhenActivated_ShutdownWithin600;
var float : temporalAcceptConstraint_ClockWhenAccepted_ShutdownWithin600;
var float : temporalAcceptConstraint_ClockParameter_ShutdownWithin600;
constraint temporalAcceptConstraint_event1_ShutdownWithin600>=0 /\ temporalAcceptConstraint_event1_ShutdownWithin600<=h;
constraint temporalAcceptConstraint_event2_ShutdownWithin600>=0 /\ temporalAcceptConstraint_event2_ShutdownWithin600<=h;
constraint temporalAcceptConstraint_event1Clock_ShutdownWithin600>=0 /\ temporalAcceptConstraint_event1Clock_ShutdownWithin600<=Fupper;
constraint temporalAcceptConstraint_event2Clock_ShutdownWithin600>=0 /\ temporalAcceptConstraint_event2Clock_ShutdownWithin600<=Fupper;
constraint temporalAcceptConstraint_ClockWhenActivated_ShutdownWithin600>=0 /\ temporalAcceptConstraint_ClockWhenActivated_ShutdownWithin600<=Fupper;
constraint temporalAcceptConstraint_ClockWhenAccepted_ShutdownWithin600>=0 /\ temporalAcceptConstraint_ClockWhenAccepted_ShutdownWithin600<=Fupper;
constraint temporalAcceptConstraint_ClockParameter_ShutdownWithin600>=-Fupper /\ temporalAcceptConstraint_ClockParameter_ShutdownWithin600<=Fupper;
constraint temporalAcceptConstraint_ClockParameter_ShutdownWithin600 >= temporalAcceptConstraint_lowerBound_ShutdownWithin600 /\ temporalAcceptConstraint_ClockParameter_ShutdownWithin600 <= temporalAcceptConstraint_upperBound_ShutdownWithin600;
predicate startingConstraint1_ShutdownWithin600() = temporalAcceptConstraint_event1_ShutdownWithin600==temporalAcceptConstraint_event2_ShutdownWithin600 /\ temporalAcceptConstraint_event2_ShutdownWithin600==0;
constraint (startingConstraint1_ShutdownWithin600())->(temporalAcceptConstraint_Traj_ShutdownWithin600[0]==tempAccepted /\ temporalAcceptConstraint_ClockWhenActivated_ShutdownWithin600==e[0] /\ temporalAcceptConstraint_ClockWhenAccepted_ShutdownWithin600==e[0] /\ temporalAcceptConstraint_event1Clock_ShutdownWithin600==e[0] /\ temporalAcceptConstraint_event2Clock_ShutdownWithin600==e[0] /\ temporalAcceptConstraint_acceptingEvent1_ShutdownWithin600(0) /\ temporalAcceptConstraint_acceptingEvent2_ShutdownWithin600(0));
predicate startingConstraint2_ShutdownWithin600() = temporalAcceptConstraint_event1_ShutdownWithin600==0 /\ 0!=temporalAcceptConstraint_event2_ShutdownWithin600;
constraint (startingConstraint2_ShutdownWithin600())->(temporalAcceptConstraint_Traj_ShutdownWithin600[0]==tempActive /\ temporalAcceptConstraint_event1Clock_ShutdownWithin600==e[0] /\ temporalAcceptConstraint_ClockWhenActivated_ShutdownWithin600==e[0] /\ temporalAcceptConstraint_acceptingEvent1_ShutdownWithin600(0));
predicate startingConstraint3_ShutdownWithin600() =  temporalAcceptConstraint_event2_ShutdownWithin600==0 /\ 0!=temporalAcceptConstraint_event1_ShutdownWithin600;
constraint (startingConstraint3_ShutdownWithin600())->(temporalAcceptConstraint_Traj_ShutdownWithin600[0]==tempActive /\ temporalAcceptConstraint_event2Clock_ShutdownWithin600==e[0] /\ temporalAcceptConstraint_ClockWhenActivated_ShutdownWithin600==e[0] /\ temporalAcceptConstraint_acceptingEvent2_ShutdownWithin600(0));
constraint (not (startingConstraint1_ShutdownWithin600() \/ startingConstraint2_ShutdownWithin600() \/ startingConstraint3_ShutdownWithin600()))->(temporalAcceptConstraint_Traj_ShutdownWithin600[0]==tempWaiting);
constraint abs(temporalAcceptConstraint_event2Clock_ShutdownWithin600 - temporalAcceptConstraint_event1Clock_ShutdownWithin600)==temporalAcceptConstraint_ClockParameter_ShutdownWithin600;
constraint temporalAcceptConstraint_ClockWhenAccepted_ShutdownWithin600 - temporalAcceptConstraint_ClockWhenActivated_ShutdownWithin600 == temporalAcceptConstraint_ClockParameter_ShutdownWithin600;

array[STAGESp1] of var float : e;
constraint forall(i in STAGES)(e[i] < e[i+1]);
constraint forall(i in STAGESp1)(e[i]>=0 /\ e[i]<=Fupper);

array[AUTOMATA, STAGES] of var float : c;
constraint forall(a in AUTOMATA, i in STAGES)(c[a,i]>=0 /\ c[a,i]<=Fupper);

array[AUTOMATA, STAGESp1] of var float : co;
constraint forall(a in AUTOMATA, i in STAGESp1)(co[a,i]>=0 /\ co[a,i]<=Fupper);

constraint forall(a in AUTOMATA, i in STAGESm1)(c[a,i] = e[i+1] - co[a,i]);

array[AUTOMATA, STAGES] of var float : cl;
array[AUTOMATA, STAGES] of var float : cu;
constraint forall(a in AUTOMATA, i in STAGES)(cl[a,i]>=0 /\ cl[a,i]<=Fupper);
constraint forall(a in AUTOMATA, i in STAGES)(cu[a,i]>=0 /\ cu[a,i]<=Fupper);
constraint forall(a in AUTOMATA, i in STAGES)(cu[a,i]>=(cl[a,i]));

array[TRANSITIONS, STAGES] of var bool: Eno;
array[TRANSITIONS, STAGES] of var bool: Ene;

constraint forall(i in STAGESm1)((forall([(not Ene[t, i]) | t in TRANSITIONS_comp_reset])) -> (co[comp,i]==co[comp,i+1]));
constraint forall(i in STAGESm1)((forall([(not Ene[t, i]) | t in TRANSITIONS_conn_reset])) -> (co[conn,i]==co[conn,i+1]));
constraint forall(i in STAGESm1)((forall([(not Ene[t, i]) | t in TRANSITIONS_proj_reset])) -> (co[proj,i]==co[proj,i+1]));

constraint forall(i in STAGES)(sum([Eno[t, i] | t in TRANSITIONS_comp_idle]) = 1);
constraint forall(i in STAGES)(sum([Ene[t, i] | t in (TRANSITIONS_comp_idle union TRANSITIONS_comp_reset)]) = 1);

constraint forall(i in STAGES)(sum([Eno[t, i] | t in TRANSITIONS_conn_idle]) = 1);
constraint forall(i in STAGES)(sum([Ene[t, i] | t in (TRANSITIONS_conn_idle union TRANSITIONS_conn_reset)]) = 1);

constraint forall(i in STAGES)(sum([Eno[t, i] | t in TRANSITIONS_proj_idle]) = 1);
constraint forall(i in STAGES)(sum([Ene[t, i] | t in (TRANSITIONS_proj_idle union TRANSITIONS_proj_reset)]) = 1);

constraint forall(i in STAGESm1)(exists([Ene[t,i] | t in TRANSITIONS_state_changing]) xor endStateAcceptAutomatonTraj[i]==accepted);

constraint compl[0]==compOff;
constraint connl[0]==disconnected;
constraint projl[0]==projOff;
constraint endStateAcceptAutomatonTraj[0]==waiting;

constraint exists(i in STAGES)(endStateAcceptAutomatonTraj[i]==accepted);

predicate maintenanceConstraint(int : i) = true;
predicate goalConstraint(int : i) = compl[i+1]==compOff /\ connl[i+1]==disconnected /\ projl[i+1]==projOff /\ epAcceptAutomatonTraj_ProjectorOnDuration[i+1]==epAccepted /\ epAcceptAutomatonTraj_ComputerOnDuration[i+1]==epAccepted /\ temporalAcceptConstraint_Traj_ShutdownWithin600[i+1]==tempAccepted;
constraint forall(i in STAGESm1)(endStateAcceptAutomatonTrTraj[28,i] -> endStateAcceptAutomatonTraj[i]==waiting /\ endStateAcceptAutomatonTraj[i+1]==waiting /\ maintenanceConstraint(i) /\ (not goalConstraint(i)));
constraint forall(i in STAGESm1)(endStateAcceptAutomatonTrTraj[29,i] -> endStateAcceptAutomatonTraj[i]==waiting /\ endStateAcceptAutomatonTraj[i+1]==accepted /\ stageWhenAccepted==i+1 /\ goalConstraint(i));
constraint forall(i in STAGESm1)(endStateAcceptAutomatonTrTraj[30,i] -> endStateAcceptAutomatonTraj[i]==waiting /\ endStateAcceptAutomatonTraj[i+1]==failed /\ (not maintenanceConstraint(i)) /\ (not goalConstraint(i)));
constraint forall(i in STAGESm1)(endStateAcceptAutomatonTrTraj[31,i] -> endStateAcceptAutomatonTraj[i]==accepted /\ endStateAcceptAutomatonTraj[i+1]==accepted);
constraint forall(i in STAGESm1)(endStateAcceptAutomatonTrTraj[32,i] -> endStateAcceptAutomatonTraj[i]==failed /\ endStateAcceptAutomatonTraj[i+1]==failed);
constraint forall(i in STAGES)(sum(t in endStateAcceptAutomatonTr)(endStateAcceptAutomatonTrTraj[t, i]) == 1);

predicate epAcceptAcceptingConstraint_ProjectorOnDuration(int : i) = projl[i]==projOn;
predicate epAcceptStateConstraint_ProjectorOnDuration(int : i) = projl[i]==projOn;
float : epAcceptLowerBound_ProjectorOnDuration=200;
float : epAcceptUpperBound_ProjectorOnDuration=200;
constraint epAcceptClockParameter_ProjectorOnDuration >= epAcceptLowerBound_ProjectorOnDuration /\ epAcceptClockParameter_ProjectorOnDuration <= epAcceptUpperBound_ProjectorOnDuration;
constraint (epAcceptClockWhenEnd_ProjectorOnDuration - epAcceptClockWhenStart_ProjectorOnDuration)==epAcceptClockParameter_ProjectorOnDuration;
constraint (projl[0]==projOn)->(epAcceptAutomatonTraj_ProjectorOnDuration[0]==epActive);
constraint ((not (projl[0]==projOn)))->(epAcceptAutomatonTraj_ProjectorOnDuration[0]==epWaiting);
constraint forall(i in STAGESm1)(epAcceptAutomatonTrTraj_ProjectorOnDuration[33,i] -> epAcceptAutomatonTraj_ProjectorOnDuration[i]==epWaiting /\ epAcceptAutomatonTraj_ProjectorOnDuration[i+1]==epWaiting /\ not epAcceptAcceptingConstraint_ProjectorOnDuration(i));
constraint forall(i in STAGESm1)(epAcceptAutomatonTrTraj_ProjectorOnDuration[34,i] -> epAcceptAutomatonTraj_ProjectorOnDuration[i]==epAccepted /\ epAcceptAutomatonTraj_ProjectorOnDuration[i+1]==epAccepted);
constraint forall(i in STAGESm1)(epAcceptAutomatonTrTraj_ProjectorOnDuration[35,i] -> epAcceptAutomatonTraj_ProjectorOnDuration[i]==epFailed /\ epAcceptAutomatonTraj_ProjectorOnDuration[i+1]==epFailed);
constraint forall(i in STAGESm1)(epAcceptAutomatonTrTraj_ProjectorOnDuration[36,i] -> epAcceptAutomatonTraj_ProjectorOnDuration[i]==epWaiting /\ epAcceptAutomatonTraj_ProjectorOnDuration[i+1]==epActive /\ epAcceptAcceptingConstraint_ProjectorOnDuration(i) /\ epAcceptStartEvent_ProjectorOnDuration==(i+1) /\ epAcceptClockWhenStart_ProjectorOnDuration==e[i+1]);
constraint forall(i in STAGESm1)(epAcceptAutomatonTrTraj_ProjectorOnDuration[37,i] -> epAcceptAutomatonTraj_ProjectorOnDuration[i]==epActive /\ epAcceptAutomatonTraj_ProjectorOnDuration[i+1]==epActive /\ epAcceptStateConstraint_ProjectorOnDuration(i) /\ (e[i+1] - epAcceptClockWhenStart_ProjectorOnDuration < epAcceptClockParameter_ProjectorOnDuration));
constraint forall(i in STAGESm1)(epAcceptAutomatonTrTraj_ProjectorOnDuration[38,i] -> epAcceptAutomatonTraj_ProjectorOnDuration[i]==epActive /\ epAcceptAutomatonTraj_ProjectorOnDuration[i+1]==epAccepted /\ epAcceptStateConstraint_ProjectorOnDuration(i) /\ (e[i+1] - epAcceptClockWhenStart_ProjectorOnDuration >= epAcceptClockParameter_ProjectorOnDuration) /\ epAcceptEndEvent_ProjectorOnDuration==(i+1) /\ epAcceptClockWhenEnd_ProjectorOnDuration==e[i+1]) ;
constraint forall(i in STAGESm1)(epAcceptAutomatonTrTraj_ProjectorOnDuration[39,i] -> epAcceptAutomatonTraj_ProjectorOnDuration[i]==epActive /\ epAcceptAutomatonTraj_ProjectorOnDuration[i+1]==epFailed /\ not epAcceptStateConstraint_ProjectorOnDuration(i));
constraint forall(i in STAGES)(sum(t in epAcceptAutomatonTr)(epAcceptAutomatonTrTraj_ProjectorOnDuration[t, i]) == 1);

predicate epAcceptAcceptingConstraint_ComputerOnDuration(int : i) = compl[i]==compOn;
predicate epAcceptStateConstraint_ComputerOnDuration(int : i) = compl[i]==compOn;
float : epAcceptLowerBound_ComputerOnDuration=300;
float : epAcceptUpperBound_ComputerOnDuration=300;
constraint epAcceptClockParameter_ComputerOnDuration >= epAcceptLowerBound_ComputerOnDuration /\ epAcceptClockParameter_ComputerOnDuration <= epAcceptUpperBound_ComputerOnDuration;
constraint (epAcceptClockWhenEnd_ComputerOnDuration - epAcceptClockWhenStart_ComputerOnDuration)==epAcceptClockParameter_ComputerOnDuration;
constraint (compl[0]==compOn)->(epAcceptAutomatonTraj_ComputerOnDuration[0]==epActive);
constraint ((not (compl[0]==compOn)))->(epAcceptAutomatonTraj_ComputerOnDuration[0]==epWaiting);
constraint forall(i in STAGESm1)(epAcceptAutomatonTrTraj_ComputerOnDuration[33,i] -> epAcceptAutomatonTraj_ComputerOnDuration[i]==epWaiting /\ epAcceptAutomatonTraj_ComputerOnDuration[i+1]==epWaiting /\ not epAcceptAcceptingConstraint_ComputerOnDuration(i));
constraint forall(i in STAGESm1)(epAcceptAutomatonTrTraj_ComputerOnDuration[34,i] -> epAcceptAutomatonTraj_ComputerOnDuration[i]==epAccepted /\ epAcceptAutomatonTraj_ComputerOnDuration[i+1]==epAccepted);
constraint forall(i in STAGESm1)(epAcceptAutomatonTrTraj_ComputerOnDuration[35,i] -> epAcceptAutomatonTraj_ComputerOnDuration[i]==epFailed /\ epAcceptAutomatonTraj_ComputerOnDuration[i+1]==epFailed);
constraint forall(i in STAGESm1)(epAcceptAutomatonTrTraj_ComputerOnDuration[36,i] -> epAcceptAutomatonTraj_ComputerOnDuration[i]==epWaiting /\ epAcceptAutomatonTraj_ComputerOnDuration[i+1]==epActive /\ epAcceptAcceptingConstraint_ComputerOnDuration(i) /\ epAcceptStartEvent_ComputerOnDuration==(i+1) /\ epAcceptClockWhenStart_ComputerOnDuration==e[i+1]);
constraint forall(i in STAGESm1)(epAcceptAutomatonTrTraj_ComputerOnDuration[37,i] -> epAcceptAutomatonTraj_ComputerOnDuration[i]==epActive /\ epAcceptAutomatonTraj_ComputerOnDuration[i+1]==epActive /\ epAcceptStateConstraint_ComputerOnDuration(i) /\ (e[i+1] - epAcceptClockWhenStart_ComputerOnDuration < epAcceptClockParameter_ComputerOnDuration));
constraint forall(i in STAGESm1)(epAcceptAutomatonTrTraj_ComputerOnDuration[38,i] -> epAcceptAutomatonTraj_ComputerOnDuration[i]==epActive /\ epAcceptAutomatonTraj_ComputerOnDuration[i+1]==epAccepted /\ epAcceptStateConstraint_ComputerOnDuration(i) /\ (e[i+1] - epAcceptClockWhenStart_ComputerOnDuration >= epAcceptClockParameter_ComputerOnDuration) /\ epAcceptEndEvent_ComputerOnDuration==(i+1) /\ epAcceptClockWhenEnd_ComputerOnDuration==e[i+1]) ;
constraint forall(i in STAGESm1)(epAcceptAutomatonTrTraj_ComputerOnDuration[39,i] -> epAcceptAutomatonTraj_ComputerOnDuration[i]==epActive /\ epAcceptAutomatonTraj_ComputerOnDuration[i+1]==epFailed /\ not epAcceptStateConstraint_ComputerOnDuration(i));
constraint forall(i in STAGES)(sum(t in epAcceptAutomatonTr)(epAcceptAutomatonTrTraj_ComputerOnDuration[t, i]) == 1);

predicate temporalAcceptConstraint_acceptingEvent1_ShutdownWithin600(int : i) = projl[i]==projOn /\ compl[i]==compOn;
predicate temporalAcceptConstraint_acceptingEvent2_ShutdownWithin600(int : i) = projl[i+1]==projOff /\ connl[i+1]==disconnected /\ compl[i+1]=compOff /\ temporalAcceptConstraint_Traj_ShutdownWithin600[i]==tempActive;
float : temporalAcceptConstraint_lowerBound_ShutdownWithin600=600;
float : temporalAcceptConstraint_upperBound_ShutdownWithin600=600;
constraint forall(i in STAGESm1)(temporalAcceptConstraint_TrTraj_ShutdownWithin600[41,i] -> temporalAcceptConstraint_Traj_ShutdownWithin600[i]==tempWaiting /\ temporalAcceptConstraint_Traj_ShutdownWithin600[i+1]==tempWaiting /\ not temporalAcceptConstraint_acceptingEvent1_ShutdownWithin600(i) /\ not temporalAcceptConstraint_acceptingEvent2_ShutdownWithin600(i));
constraint forall(i in STAGESm1)(temporalAcceptConstraint_TrTraj_ShutdownWithin600[42,i] -> temporalAcceptConstraint_Traj_ShutdownWithin600[i]==tempWaiting /\ temporalAcceptConstraint_Traj_ShutdownWithin600[i+1]==tempAccepted /\ temporalAcceptConstraint_acceptingEvent1_ShutdownWithin600(i) /\ temporalAcceptConstraint_acceptingEvent2_ShutdownWithin600(i) /\ temporalAcceptConstraint_event1_ShutdownWithin600==i+1 /\ temporalAcceptConstraint_event2_ShutdownWithin600==i+1 /\ temporalAcceptConstraint_event1Clock_ShutdownWithin600==e[i+1] /\ temporalAcceptConstraint_event2Clock_ShutdownWithin600==e[i+1]);
predicate e1BeforeE2_ShutdownWithin600(int: i) = temporalAcceptConstraint_Traj_ShutdownWithin600[i]==tempWaiting /\ temporalAcceptConstraint_Traj_ShutdownWithin600[i+1]==tempActive /\ temporalAcceptConstraint_acceptingEvent1_ShutdownWithin600(i) /\ not temporalAcceptConstraint_acceptingEvent2_ShutdownWithin600(i) /\ temporalAcceptConstraint_event1Clock_ShutdownWithin600==e[i+1] /\ temporalAcceptConstraint_event1_ShutdownWithin600==i+1 /\ temporalAcceptConstraint_ClockWhenActivated_ShutdownWithin600==e[i+1] /\ temporalAcceptConstraint_ClockParameter_ShutdownWithin600 <= temporalAcceptConstraint_upperBound_ShutdownWithin600 /\ temporalAcceptConstraint_event1Clock_ShutdownWithin600 <= temporalAcceptConstraint_event2Clock_ShutdownWithin600;
predicate e2BeforeE1_ShutdownWithin600(int: i) = temporalAcceptConstraint_Traj_ShutdownWithin600[i]==tempWaiting /\ temporalAcceptConstraint_Traj_ShutdownWithin600[i+1]==tempActive /\ not temporalAcceptConstraint_acceptingEvent1_ShutdownWithin600(i) /\ temporalAcceptConstraint_acceptingEvent2_ShutdownWithin600(i) /\ temporalAcceptConstraint_event2Clock_ShutdownWithin600==e[i+1] /\ temporalAcceptConstraint_event2_ShutdownWithin600==i+1 /\ temporalAcceptConstraint_event2Clock_ShutdownWithin600 <= temporalAcceptConstraint_event1Clock_ShutdownWithin600 /\ temporalAcceptConstraint_ClockWhenActivated_ShutdownWithin600==e[i+1] /\ temporalAcceptConstraint_ClockParameter_ShutdownWithin600<=(-1 * temporalAcceptConstraint_lowerBound_ShutdownWithin600);
constraint forall(i in STAGESm1)(temporalAcceptConstraint_TrTraj_ShutdownWithin600[43,i] -> (e1BeforeE2_ShutdownWithin600(i) \/ e2BeforeE1_ShutdownWithin600(i)));
constraint forall(i in STAGESm1)(temporalAcceptConstraint_TrTraj_ShutdownWithin600[44,i] -> temporalAcceptConstraint_Traj_ShutdownWithin600[i]==tempActive /\ temporalAcceptConstraint_Traj_ShutdownWithin600[i+1]==tempActive /\ e[i+1]-temporalAcceptConstraint_ClockWhenActivated_ShutdownWithin600 < temporalAcceptConstraint_ClockParameter_ShutdownWithin600);
predicate endsOnE2_ShutdownWithin600(int: i) = temporalAcceptConstraint_Traj_ShutdownWithin600[i]==tempActive /\ temporalAcceptConstraint_Traj_ShutdownWithin600[i+1]==tempAccepted /\ (e[i+1]-temporalAcceptConstraint_ClockWhenActivated_ShutdownWithin600) >= temporalAcceptConstraint_ClockParameter_ShutdownWithin600 /\ temporalAcceptConstraint_event1Clock_ShutdownWithin600 < temporalAcceptConstraint_event2Clock_ShutdownWithin600 /\ temporalAcceptConstraint_event2_ShutdownWithin600==i+1 /\ temporalAcceptConstraint_acceptingEvent2_ShutdownWithin600(i);
predicate endsOnE1_ShutdownWithin600(int: i) = temporalAcceptConstraint_Traj_ShutdownWithin600[i]==tempActive /\ temporalAcceptConstraint_Traj_ShutdownWithin600[i+1]==tempAccepted /\ (e[i+1]-temporalAcceptConstraint_ClockWhenActivated_ShutdownWithin600) >= temporalAcceptConstraint_ClockParameter_ShutdownWithin600 /\ temporalAcceptConstraint_event2Clock_ShutdownWithin600 < temporalAcceptConstraint_event1Clock_ShutdownWithin600 /\ temporalAcceptConstraint_event1_ShutdownWithin600==i+1 /\ temporalAcceptConstraint_acceptingEvent1_ShutdownWithin600(i);
constraint forall(i in STAGESm1)(temporalAcceptConstraint_TrTraj_ShutdownWithin600[45,i] -> (endsOnE2_ShutdownWithin600(i) \/ endsOnE1_ShutdownWithin600(i)));
constraint forall(i in STAGESm1)(temporalAcceptConstraint_TrTraj_ShutdownWithin600[46,i] -> (temporalAcceptConstraint_Traj_ShutdownWithin600[i]==tempAccepted /\ temporalAcceptConstraint_Traj_ShutdownWithin600[i+1]==tempAccepted));
constraint forall(i in STAGES)(sum(t in temporalAcceptAutomatonTr)(temporalAcceptConstraint_TrTraj_ShutdownWithin600[t, i]) == 1);


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
    
    
var float: totalCost = e[h];

solve minimize totalCost;