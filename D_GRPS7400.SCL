FUNCTION_BLOCK D_GRPS7400
{S7_m_c := 'true';S7_alarm_ui := '0'; S7_tasklist := 'OB100'}

TITLE = 'Standart Group Control'
//
// Standart Group Control For Maguin/
//

//: "VERSION & CHANGE LOG"

AUTHOR  : DEO
NAME    : D_GRP
VERSION : '00.06'
FAMILY  : DL_S7400
 KNOW_HOW_PROTECT

(*
    Change Log
    Date                Owner   Mj.Mn   Comment
    12:17 08.06.2009    ERS     00.00   Project started
    09:40 18.06.2009    YKU     00.01   Interface changed
    09:08 19.06.2009    EE      00.02   Arranged Acording to S7300
    13:26 26.06.2009    ERS     00.03   Block Tested,Start Stop Functions,Modes
    13:18 01.07.2009    YKU     00.04   Block name changed.
    09:54 09.09.2009    EE      00.05   Start condition added.
    09:30 16.02.2011    EE      00.06   Adjusted for S7 400 CPU.
    

*)  

//|

//: "INTERFACE DEFINITIONS"

CONST
    ON      := TRUE;
    OFF     := FALSE;
    _HORN   := 1;
    _GSPRV  := 2;
    MAX_ODT := 2; // Maximum count of Software On-Delay Timers
END_CONST

VAR_INPUT
    GCON            : BOOL;         // Group Completely On
    GCOFF           : BOOL;         // Group Completely Off
    GFAULT          : BOOL;         // Group has a Faulty Device
    GQSTOP          : BOOL;         // Group Quick Stop
    GSIMEN          : BOOL;         // Group Simulation Enable

    C_STRT          : BOOL;         // Start Condition
    C_STOP          : BOOL;         // Stop Condition

    GR_SSEN         : BOOL;         // External Start Stop Enable
    GR_STRT         : BOOL;         // Group Start Command
    GR_STOP         : BOOL;         // Group Stop Command
    GR_QSTP         : BOOL;         // Group Quick Stop Command

    TM_GSPRV        : REAL := 300;  // Group Supervision Time
    TM_HORN         : REAL := 10;   // Horn Time

    OS_CMND         {S7_m_c := 'true'} : WORD;
    CMND AT OS_CMND : STRUCT // First Status Bits for OS
        GR_STRT     : BOOL;  // Group Start Command From OS
        GR_STOP     : BOOL;  // Group Stop Command From OS
        GR_LOCM     : BOOL;  // Group Local Mode From OS
        GR_SNGM     : BOOL;  // Group Single Mode From OS
        GR_AUTM     : BOOL;  // Group Auto Mode From OS
        GR_ACK      : BOOL;  // Group wise Acknowledge From OS
        GR_QSTOP     : BOOL;  // Group wise Quick Stop From OS
        GR_HORN     : BOOL;  // Group Horn
    END_STRUCT;

    MSG_LOCK        {S7_visible:='false'; S7_dynamic:='true'; S7_m_c:='true'}
                    : BOOL;         // Enable 1=Messages locked
    MSG_EVID1  {S7_visible  := 'false';S7_link := 'false'; S7_param := 'false';S7_server := 'alarm_archiv';S7_a_type := 'alarm_8p'}:DWORD ;


    S_T             {S7_visible := 'false'; S7_link := 'false'; S7_sampletime:='true'}
                    : REAL := 0.1;  // Sample time value
                    
    RUNUPCYC        {S7_visible:='false'; S7_link:='false'}
                    : INT := 3;     // Number of Run Up Cycles
END_VAR

VAR_OUTPUT
    Q_GACT          : BOOL; // Group Active
    Q_GCON          : BOOL; // Group Completely On
    Q_GCOFF         : BOOL; // Group Completely Off
    Q_STRT          : BOOL; // Group Start Command
    Q_STOP          : BOOL; // Group Stop Command
    Q_QSTP          : BOOL; // Group Quick Stop Command
    Q_AUTM          : BOOL; // Group in Automode
    Q_SNGM          : BOOL; // Group in Single Mode
    Q_LOCM          : BOOL; // Group in Local Mode
    Q_SIMM          : BOOL; // Simulation Mode
    Q_ACK           : BOOL; // Group wise Acknowledge
    Q_FAULT         : BOOL; // Group has a Faulty Device
    Q_HORN          : BOOL; // Horn

    OS_VISU         {S7_m_c := 'true'} : INT; // Visualization for OS
    (*
        0 : Group Completely Off
        1 : Horning   
        2 : Shutdown
        3 : Startup
        4 : Startup timeout
        5 : Group Completely ON
        6 : Does Not Run Completely Anymore
    *)
    OS_STAT            {S7_m_c := 'true'} : DWORD; // First Status Bits for OS
    
END_VAR

VAR_IN_OUT
END_VAR

VAR_TEMP
    T_INT       : INT;
    ERR         : INT;
END_VAR

VAR
    ALARMS      : ARRAY[1..2] OF BOOL;           // Alarm holders
    TIMERS      : ARRAY[1..MAX_ODT] OF STRUCT    // ODT holders
        IN : BOOL;
        TV : REAL;
        Q  : BOOL;
        ET : REAL;
    END_STRUCT;
    _D          : DWORD;
    _B32 AT _D  : STRUCT
        B00     : BOOL;
        B01     : BOOL;
        B02     : BOOL;
        B03     : BOOL;
        B04     : BOOL;
        B05     : BOOL;
        B06     : BOOL;
        B07     : BOOL;
        B08     : BOOL;
        B09     : BOOL;
        B10     : BOOL;
        B11     : BOOL;
        B12     : BOOL;
        B13     : BOOL;
        B14     : BOOL;
        B15     : BOOL;
        B16     : BOOL;
        B17     : BOOL;
        B18     : BOOL;
        B19     : BOOL;
        B20     : BOOL;
        B21     : BOOL;
        B22     : BOOL;
        B23     : BOOL;
        B24     : BOOL;
        B25     : BOOL;
        B26     : BOOL;
        B27     : BOOL;
        B28     : BOOL;
        B29     : BOOL;
        B30     : BOOL;
        B31     : BOOL;
    END_STRUCT;
    MG_STRT : BOOL;
    MO_STRT : BOOL;
    RUNUPCNT    : INT;                     // Counter for RUNUPCYC editing
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
IF (RUNUPCNT = 0) THEN
    // START MAIN CODE AREA
    
    CASE OS_VISU OF
        0 : // Group Completely Off
            Q_STRT  := FALSE;
            Q_STOP  := FALSE;
            Q_GACT   := FALSE;
            Q_GCON  := FALSE;
            Q_GCOFF := TRUE;
            TIMERS[_HORN].IN := OFF;
            TIMERS[_GSPRV].IN := OFF;
            IF ( GR_SSEN AND GR_STRT AND C_STRT ) OR ( NOT GR_SSEN AND (CMND.GR_STRT AND NOT MO_STRT)AND C_STRT ) THEN 
                OS_VISU     := 1;
            END_IF;
        1 : // Horning
            Q_STRT  := FALSE;
            Q_STOP  := FALSE;
            Q_GACT   := FALSE;
            Q_GCON  := FALSE;
            Q_GCOFF := FALSE;
            TIMERS[_HORN].TV := TM_HORN;
            TIMERS[_HORN].IN := ON;
            IF TIMERS[_HORN].Q THEN 
                OS_VISU     := 3;
            END_IF;       
            IF GFAULT THEN OS_VISU := 4; END_IF;
            IF ( GR_SSEN AND GR_STOP AND C_STOP ) OR ( NOT GR_SSEN AND CMND.GR_STOP ) THEN 
                OS_VISU     := 2;
            END_IF;
        2 : // Shutdown
            Q_STRT  := FALSE;
            Q_STOP  := TRUE;
            Q_GACT   := TRUE;
            Q_GCON  := FALSE;
            Q_GCOFF := FALSE;
            TIMERS[_HORN].IN := OFF;
            TIMERS[_GSPRV].IN := OFF;
            IF GCOFF THEN OS_VISU := 0; END_IF;
            IF ( GR_SSEN AND GR_STRT AND C_STRT ) OR ( NOT GR_SSEN AND (CMND.GR_STRT AND NOT MO_STRT) AND C_STRT) THEN 
                OS_VISU     := 1;
            END_IF;
        3 : // Startup
            Q_STRT  := NOT GFAULT;
            Q_STOP  := FALSE;
            Q_GACT   := TRUE;
            Q_GCON  := FALSE;
            Q_GCOFF := FALSE;
            TIMERS[_GSPRV].TV := TM_GSPRV;
            TIMERS[_GSPRV].IN := ON;
            IF GFAULT OR TIMERS[_GSPRV].Q THEN OS_VISU := 4; END_IF;
            IF GCON   THEN OS_VISU := 5; END_IF;
            IF ( GR_SSEN AND GR_STOP AND C_STOP ) OR ( NOT GR_SSEN AND CMND.GR_STOP ) THEN 
                OS_VISU     := 2;
            END_IF;
        4 : // Startup timeout
            Q_STRT  := FALSE;
            Q_STOP  := FALSE;
            Q_GACT   := TRUE;
            Q_GCON  := FALSE;
            Q_GCOFF := FALSE;
            TIMERS[_HORN].IN := OFF;
            TIMERS[_GSPRV].IN := OFF;
            IF ( GR_SSEN AND GR_STRT AND C_STRT ) OR ( NOT GR_SSEN AND (CMND.GR_STRT AND NOT MO_STRT) AND C_STRT ) THEN 
                OS_VISU     := 1;
            END_IF;
            IF ( GR_SSEN AND GR_STOP AND C_STOP ) OR ( NOT GR_SSEN AND CMND.GR_STOP ) THEN 
                OS_VISU     := 2;
            END_IF;
        5 : // Group Completely ON
            Q_STRT  := FALSE;
            Q_STOP  := FALSE;
            Q_GACT   := TRUE;
            Q_GCON  := TRUE;
            Q_GCOFF := FALSE;
            TIMERS[_HORN].IN := OFF;
            TIMERS[_GSPRV].IN := OFF;
            IF NOT GCON THEN OS_VISU := 6; END_IF;
            IF ( GR_SSEN AND GR_STOP AND C_STOP ) OR ( NOT GR_SSEN AND CMND.GR_STOP ) THEN 
                OS_VISU     := 2;
            END_IF;
        6 : // Does Not Run Completely Anymore
            Q_STRT  := FALSE;
            Q_STOP  := FALSE;
            Q_GACT   := TRUE;
            Q_GCON  := FALSE;
            Q_GCOFF := FALSE;
            TIMERS[_HORN].IN := OFF;
            TIMERS[_GSPRV].IN := OFF;
            IF ( GR_SSEN AND GR_STRT AND C_STRT ) OR ( NOT GR_SSEN AND (CMND.GR_STRT AND NOT MO_STRT)AND C_STRT ) THEN 
                OS_VISU     := 1;
            END_IF;
            IF ( GR_SSEN AND GR_STOP AND C_STOP ) OR ( NOT GR_SSEN AND CMND.GR_STOP ) THEN 
                OS_VISU     := 2;
            END_IF;
    ELSE
        OS_VISU := 0;
    END_CASE;

    IF CMND.GR_SNGM AND GCON THEN OS_VISU :=5; END_IF;
    MG_STRT := GR_STRT;
    MO_STRT := CMND.GR_STRT;    

    IF (GR_QSTP OR CMND.GR_QSTOP OR GQSTOP) THEN
        OS_VISU := 2;
        Q_QSTP := TRUE;
    ELSE
        Q_QSTP := FALSE;
    END_IF;
    
    ALARMS[1] := GR_QSTP OR CMND.GR_QSTOP OR GQSTOP ;    
    IF OS_VISU = 4 THEN
    ALARMS[2] := TRUE ;
    END_IF;
    
    Q_AUTM      := CMND.GR_AUTM;
    Q_SNGM      := CMND.GR_SNGM;
    Q_LOCM      := CMND.GR_LOCM;
    Q_SIMM      := GSIMEN;
    Q_ACK       := CMND.GR_ACK;
    Q_FAULT     := GFAULT;
    Q_HORN      := CMND.GR_HORN OR (TIMERS[_HORN].IN <> TIMERS[_HORN].Q);

    //: "STATUS WORD"
        _D := DW#16#0;
        _B32.B00    := Q_GACT;
        _B32.B01    := Q_GCON;
        _B32.B02    := Q_GCOFF;
        _B32.B03    := Q_STRT;
        _B32.B04    := Q_STOP;
        _B32.B05    := Q_QSTP;
        _B32.B06    := Q_AUTM;
        _B32.B07    := Q_SNGM;
        _B32.B08    := Q_LOCM;
        _B32.B09    := Q_SIMM;
        _B32.B10    := Q_FAULT;
        _B32.B11    := Q_HORN;
        _B32.B12    := C_STRT;
        _B32.B13    := C_STOP; 
        _B32.B14    := GR_SSEN;
        _B32.B15    := GR_STRT;
        _B32.B16    := GR_STOP;
        _B32.B17    := GR_QSTP;             
        OS_STAT     := _D;
    //|
    
    // END OF MAIN CODE AREA
END_IF;
//|

//: "ALARM ENGINE"
    IF RUNUPCNT = 0 THEN
        IF MSG_LOCK THEN
            ALARMS[1] := FALSE;
            ALARMS[2] := FALSE;
        END_IF;

            ALARM8P(EN_R := TRUE // IN: BOOL
               ,SIG_1 :=  ALARMS[1] // IN: BOOL
               ,SIG_2 :=  ALARMS[2] // IN: BOOL
               ,SIG_3 :=  FALSE // IN: BOOL
               ,SIG_4 :=  FALSE // IN: BOOL
               ,SIG_5 :=  FALSE // IN: BOOL
               ,SIG_6 :=  FALSE // IN: BOOL
               ,SIG_7 :=  FALSE // IN: BOOL
               ,SIG_8 :=  FALSE // IN: BOOL
               ,ID    := 16#EEEE // IN: WORD
               ,EV_ID := MSG_EVID1 // IN: DWORD
               ,SEVERITY := 16#0001 // IN: WORD
               );   
                            
    END_IF;
//|

END_FUNCTION_BLOCK
