FUNCTION_BLOCK D_MEASS7400
{S7_m_c := 'true';S7_alarm_ui := '0'; S7_tasklist := 'OB100'}


TITLE = 'Analog Value Measurement Center'
//
// Dal Elektrik ve Otomasyon A.S. ©2009
//

//: "VERSION & CHANGE LOG"

AUTHOR  : DEO
NAME    : D_MEAS
VERSION : '00.06'
FAMILY  : DL_S7400
KNOW_HOW_PROTECT

(*
    Change Log
    Date                Owner   Mj.Mn   Comment
    16:46 30.06.2009    YKU     00.00   Project started
    13:38 01.07.2009    YKU     00.01   First Compiled Source...
    14:30 27.07.2009    EE      00.02   IN_VALUE Changed From REAL to WORD
    09:10 18.02.2011    IK      01.06   Adjusted for S7 400 CPU.

*)

//|

//: "INTERFACE DEFINITIONS"

CONST
    ON      :=  TRUE;
    OFF     :=  FALSE;
    _AH     := 1;
    _WH     := 2;
    _WL     := 3;
    _AL     := 4;
    MAX_ODT := 4; // Maximum count of Software On-Delay Timers
END_CONST

VAR_INPUT
    AH_ENABL    : BOOL; // Alarm high enable
    AH_LIMIT    : REAL; // Alarm high limit value
    AH_DELAY    : REAL; // Alarm high delay time

    WH_ENABL    : BOOL; // Warning high enable
    WH_LIMIT    : REAL; // Warning high limit value
    WH_DELAY    : REAL; // Warning high delay time

    WL_ENABL    : BOOL; // Warning low enable
    WL_LIMIT    : REAL; // Warning low limit value
    WL_DELAY    : REAL; // Warning low delay time

    AL_ENABL    : BOOL; // Alarm low enable
    AL_LIMIT    : REAL; // Alarm low limit value
    AL_DELAY    : REAL; // Alarm low delay time

    HH_SWTCH    : REAL; // Alarm high switch value
    HI_SWTCH    : REAL; // Warning high switch value
    LO_SWTCH    : REAL; // Warning low switch value
    LL_SWTCH    : REAL; // Alarm low switch value

    IN_VALUE    : WORD; // Input value
    IN_MAX      : REAL := 27648.0; // Maximum input value
    IN_MIN      : REAL :=     0.0; // Minimum input value
    MV_MAX      : REAL :=   100.0; // Maximum manupulated value
    MV_MIN      : REAL :=     0.0; // Minimum manupulated value
    MV_FILTT    : REAL :=     0.5; // Manupulated value Filter time
    MV_CROPE    : BOOL :=    TRUE; // Manupulated value Crop Enable

    MSG_LOCK    {S7_visible:='false'; S7_dynamic:='true'; S7_m_c:='true'}
                : BOOL := 0;    // Enable 1=Messages locked
    MSG_EVID1  {S7_visible  := 'false';S7_link := 'false'; S7_param := 'false';S7_server := 'alarm_archiv';S7_a_type := 'alarm_8p'}:DWORD ;

    S_T         {S7_visible := 'false'; S7_link := 'false'; S7_sampletime:='true'}
                : REAL := 0.1;  // Sample time value
END_VAR

VAR_OUTPUT

    MV_VALUE    {S7_m_c:='true'} : REAL; // Manupulated Value
    AH_ACTIV    : BOOL; // Alarm high active
    WH_ACTIV    : BOOL; // Warning high active
    WL_ACTIV    : BOOL; // Warning low active
    AL_ACTIV    : BOOL; // Alarm low active
    HH_ACTIV    : BOOL; // Alarm high switch value
    HI_ACTIV    : BOOL; // Warning high switch value
    LO_ACTIV    : BOOL; // Warning low switch value
    LL_ACTIV    : BOOL; // Alarm low switch value

    OS_VISU     {S7_m_c:='true'} : INT; // Status

END_VAR

VAR_IN_OUT
END_VAR

VAR_TEMP
    T_INT       : INT;
    ERR         : INT;
    SC_VALUE    : REAL; // Scaled value
END_VAR

VAR
    ALARMS      : ARRAY[1..4] OF BOOL;           // Alarm holders
    TIMERS      : ARRAY[1..MAX_ODT] OF STRUCT    // ODT holders
                    IN : BOOL;
                    TV : REAL;
                    Q  : BOOL;
                    ET : REAL;
                END_STRUCT;
    _IN : REAL;
ALARM8P : ALARM_8P;
END_VAR

//|

//: "INTERNAL SOFTWARE ON-DELAY TIMERS"
FOR T_INT:= 1 TO MAX_ODT DO
  IF TIMERS[T_INT].IN THEN
    IF TIMERS[T_INT].ET >= TIMERS[T_INT].TV THEN
      TIMERS[T_INT].Q  := TRUE;
      TIMERS[T_INT].ET := TIMERS[T_INT].TV;
    ELSE
      TIMERS[T_INT].ET := TIMERS[T_INT].ET + S_T;
    END_IF;
  ELSE
    TIMERS[T_INT].Q  := FALSE;
    TIMERS[T_INT].ET := 0;
  END_IF;
END_FOR;
//|

//: "MAIN CODE AREA"
    // START MAIN CODE AREA
    _IN := DINT_TO_REAL(WORD_TO_INT(IN_VALUE));

    SC_VALUE := ((MV_MAX-MV_MIN)/(IN_MAX-IN_MIN)*(_IN-IN_MIN))+ MV_MIN;
    IF MV_CROPE AND (SC_VALUE > MV_MAX) THEN SC_VALUE := MV_MAX; END_IF;
    IF MV_CROPE AND (SC_VALUE < MV_MIN) THEN SC_VALUE := MV_MIN; END_IF;
    IF (MV_FILTT > S_T) THEN
        MV_VALUE := (SC_VALUE*(S_T/(MV_FILTT+S_T)))+(MV_VALUE*(MV_FILTT/(MV_FILTT+S_T)));
    ELSE
        MV_VALUE := SC_VALUE;
    END_IF;

    TIMERS[_AH].TV := AH_DELAY;
    TIMERS[_AH].IN := AH_ENABL AND (MV_VALUE >= AH_LIMIT);
    AH_ACTIV := TIMERS[_AH].Q;
    ALARMS[1] := AH_ACTIV;

    TIMERS[_WH].TV := WH_DELAY;
    TIMERS[_WH].IN := WH_ENABL AND (MV_VALUE >= WH_LIMIT);
    WH_ACTIV := TIMERS[_WH].Q;
    ALARMS[2] := WH_ACTIV;

    TIMERS[_WL].TV := WL_DELAY;
    TIMERS[_WL].IN := WL_ENABL AND (MV_VALUE <= WL_LIMIT);
    WL_ACTIV := TIMERS[_WL].Q;
    ALARMS[3] := WL_ACTIV;

    TIMERS[_AL].TV := AL_DELAY;
    TIMERS[_AL].IN := AL_ENABL AND (MV_VALUE <= AL_LIMIT);
    AL_ACTIV := TIMERS[_AL].Q;
    ALARMS[4] := AL_ACTIV;

    HH_ACTIV := (MV_VALUE >= HH_SWTCH);
    HI_ACTIV := (MV_VALUE >= HI_SWTCH);
    LO_ACTIV := (MV_VALUE <= LO_SWTCH);
    LL_ACTIV := (MV_VALUE <= LL_SWTCH);

    IF AH_ACTIV OR AL_ACTIV THEN
        OS_VISU := 2;
    ELSIF WH_ACTIV OR WL_ACTIV THEN
        OS_VISU := 1;
    ELSE
        OS_VISU := 0;
    END_IF;

    // END OF MAIN CODE AREA
//|

//: "ALARM ENGINE"
        IF MSG_LOCK THEN
            ALARMS[1] := FALSE;
            ALARMS[2] := FALSE;
            ALARMS[3] := FALSE;
            ALARMS[4] := FALSE;
        END_IF;
ALARM8P(EN_R := TRUE // IN: BOOL
               ,SIG_1 := ALARMS[1] // IN: BOOL
               ,SIG_2 := ALARMS[2] // IN: BOOL
               ,SIG_3 := ALARMS[3] // IN: BOOL
               ,SIG_4 := ALARMS[4] // IN: BOOL
               ,SIG_5 := FALSE     // IN: BOOL
               ,SIG_6 := FALSE     // IN: BOOL
               ,SIG_7 := FALSE     // IN: BOOL
               ,SIG_8 := FALSE     // IN: BOOL
               ,ID    := 16#EEEE   // IN: WORD
               ,EV_ID := MSG_EVID1 // IN: DWORD
               ,SEVERITY := 16#0001 // IN: WORD
               );   


//|

END_FUNCTION_BLOCK
