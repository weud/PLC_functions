FUNCTION_BLOCK D_MOT2D_S7400
{S7_m_c := 'true';S7_alarm_ui := '0'; S7_tasklist := 'OB100'}

TITLE = 'Standard 2 Way Motor Control'
//
// Dal Elektrik ve Otomasyon A.S. ©2009
//

//: "VERSION & CHANGE LOG"

AUTHOR  : DEO
NAME    : D_MOT2D
VERSION : '00.06'
FAMILY  : DL_S7400
KNOW_HOW_PROTECT

(*
    Change Log
    Date                Owner   Mj.Mn   Comment
    12:17 08.06.2009    ET     00.00   Project started.
    09:08 19.06.2009    EE      00.01   Arranged acording to S7300.
    14:56 26.06.2009    YKU     00.02   Interface names modified.
    15:11 29.06.2009    YKU     01.00   Main algorithm changed.
    18:19 29.06.2009    YKU     01.01   First compiled source.
    14:01 11.08.2009    EE      00.05   for F_STOP, AND NOT L_STOP added.
    14:00 17.02.2011    IK      00.06   Adjusted for S7 400 CPU.
*)

//|

//: "INTERFACE DEFINITIONS"

    CONST
        ON          := TRUE;
        OFF         := FALSE;
        _HORN       :=  1;
        _START      :=  2;
        _STOP       :=  3;
        _TRP_START  :=  4;
        _TRP_STOP   :=  5;
        _FDBCK1     :=  6;
        _FDBCK2     :=  7;
        _SPEED      :=  8;
        _PULSE      :=  9;
        _BELT       := 10;
        _LEVEL      := 11;
        MAX_ODT     := 11; // Maximum count of Software On-Delay Timers
    END_CONST

    VAR_INPUT
        M_READY         : BOOL; // MCC Ready
        M_FDBCK1        : BOOL; // MCC Feedback  running
        M_FDBCK2        : BOOL; // MCC Feedback  running
        L_LOCAL         : BOOL; // Local Box Local Position
        L_REMOTE        : BOOL; // Local Box Remote Position
        L_START1        : BOOL; // Local Box Local Start
        L_START2        : BOOL; // Local Box Local Start
        L_STOP          : BOOL; // Local Box Local Stop

        C_SPRDC         : BOOL; // Sporadic ON/OFF
        C_STRT1         : BOOL; // Start Condition
        C_STRTA1        : BOOL; // Start Condition (Auto Mode Only)
        C_STRT2         : BOOL; // Start Condition
        C_STRTA2        : BOOL; // Start Condition (Auto Mode Only)
        C_STOPA         : BOOL; // Stop Condition (Auto Mode Only)

        I_OPERA1        : BOOL; // Operation Interlok (Auto Mode Only)
        I_OPERA2        : BOOL; // Operation Interlok (Auto Mode Only)
        I_PROT          : BOOL; // Protection Interlock
        I_PROTA         : BOOL; // Protection Interlock (Auto Mode Only)

        G_START1        : BOOL; // Group Start Command
        G_START2        : BOOL; // Group Start Command
        G_STOP          : BOOL; // Group Stop Command
        G_QSTOP         : BOOL; // Group Quick Stop Command
        G_AUTO          : BOOL; // Group in Auto Mode
        G_SINGLE        : BOOL; // Group in Single Mode
        G_LOCAL         : BOOL; // Group in Local Mode
        G_SIM           : BOOL; // Group Simulation Mode
        G_ACK           : BOOL; // Group wise Acknowledge

        S_QSTOP         : BOOL; // Quick Stop
        S_SPEED         : BOOL; // Rotation Dedector Signal

        P_ENABLE        : BOOL; // Device enabled(1) / disabled(0)
        P_NO_LOC        : BOOL; // Local Control Box not Used
        P_IS_PLS        : BOOL; // Rotation Dedector Pulse Enable
        P_SIM           : BOOL; // Simulation Mode On

        T_START         : REAL := 5;  // Start Delay Time
        T_STOP          : REAL := 10; // Stop Delay Time
        T_FB_ON         : REAL := 3;  // Feedback Ramp Up Delay Time
        T_FB_OFF        : REAL := 3;  // Feedback Ramp Down Delay Time
        T_FB_FLT        : REAL := 1;  // Feedback Filter Time
        T_SPEED         : REAL := 10; // Rotation Dedector Delay Time
        T_PULSE         : REAL := 5;  // Rotation Dedector Pulse Time
        T_HORN          : REAL := 7;  // Horn Time

        OS_CMND { S7_m_c := 'true'}: WORD;
        CMND AT OS_CMND : STRUCT // First Status Bits for OS
            SINGLE_START1  : BOOL; // Start Command From OS in Single Mode
            SINGLE_START2  : BOOL; // Start Command From OS in Single Mode
            SINGLE_STOP    : BOOL; // Stop Command From OS in Single Mode
            ACKNOWLEDGE    : BOOL; // Device Acknowledgement
            MAINTENANCE_OP : BOOL; // Maintenance Mode ON(1)/OFF(0)
        END_STRUCT;

        OS_USTAT {S7_m_c := 'true'}: WORD; // User Status Bits for OS

        MSG_LOCK    {S7_visible:='false'; S7_dynamic:='true'; S7_m_c:='true'}
                    : BOOL := 0;    // Enable 1=Messages locked
        MSG_EVID_1  {S7_visible  := 'false';S7_link := 'false'; S7_param := 'false';S7_server := 'alarm_archiv';S7_a_type := 'alarm_8p'}:DWORD ;
        MSG_EVID_2  {S7_visible  := 'false';S7_link := 'false'; S7_param := 'false';S7_server := 'alarm_archiv';S7_a_type := 'alarm_8p'}:DWORD ;

        S_T         {S7_visible := 'false'; S7_link := 'false'; S7_sampletime:='true'}
                    : REAL := 0.1;  // Sample time value
        RUNUPCYC    {S7_visible:='false'; S7_link:='false'}
                    : INT  := 3;    // Number of Run Up Cycles
    END_VAR

    VAR_OUTPUT
        Q_ACTIVE        : BOOL; // Device Active
        Q_FDBCK1        : BOOL; // Device Running
        Q_FDBCK2        : BOOL; // Device Running
        Q_FAULT         : BOOL; // Device Fault
        Q_RUN1          : BOOL; // Run Command
        Q_RUN2          : BOOL; // Run Command
        Q_HORN          : BOOL; // Horn
        Q_SIM           : BOOL; // Simulation On
        Q_LOCALMODE     : BOOL; // Motor Local Mode
        OS_VISU { S7_m_c := 'true'} : INT; // Visualization for OS
    (*
        0:  Disabled                    :Dark  Grey
        1:  Stopped Without Fault       :Light Grey Colour
        2:  Fault not Acknowledged      :Flashing Red
        3:  Acknowledged Fault          :Red
        4:  Running in Auto D1          :Green
        5:  Running in Auto D2          :Green
        6:  Local Mode Ready            :Yellow
        7:  Local Mode Running D1       :Flashing Yellow
        8:  Local Mode Running D2       :Flashing Yellow
        9:  Single Mode Ready           :Blue
        10: Single Mode Running D1      :Flashing Blue
        11: Single Mode Running D2      :Flashing Blue
        12: Maintenance Mode            :Orange
        13: Maintenance Mode Running D1 :Flashing Orange
        14: Maintenance Mode Running D2 :Flashing Orange
    *)
        OS_STAT1 {S7_m_c := 'true'}  : DWORD; // First Status Bits for OS
        OS_STAT2 {S7_m_c := 'true'}  : DWORD; // Second Status Bits for OS
        OS_FLAGS {S7_m_c := 'true'}  : DWORD; // Alarm Status Bits for OS

    END_VAR

    VAR_TEMP
        T_INT       : INT;
        TOP_SI      : STRUCT
                    EV_CLASS    : BYTE;
                    EV_NUM      : BYTE;
                    PRIORITY    : BYTE;
                    NUM         : BYTE;
                    TYP2_3      : BYTE;
                    TYP1        : BYTE;
                    ZI1         : WORD;
                    ZI2_3       : DWORD;
                END_STRUCT;
        START_UP_SI : STRUCT
                    EV_CLASS    : BYTE;
                    EV_NUM      : BYTE;
                    PRIORITY    : BYTE;
                    NUM         : BYTE;
                    TYP2_3      : BYTE;
                    TYP1        : BYTE;
                    ZI1         : WORD;
                    ZI2_3       : DWORD;
                END_STRUCT;
        ERR         : INT;
    END_VAR

    VAR
        SIGNALS     : DWORD;
        ALARMS      : DWORD;
        _W          : WORD;
        _B AT _W    : STRUCT
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

        TIMERS      : ARRAY[1..MAX_ODT] OF STRUCT      // ODT holders
                        IN : BOOL;
                        TV : REAL;
                        Q  : BOOL;
                        ET : REAL;
                      END_STRUCT;
        RUNUPCNT    : INT := 0;                     // Counter for RUNUPCYC editing

        F_FDBCK1    : BOOL;
        F_FDBCK2    : BOOL;
        E_FDBCK1    : BOOL;
        E_FDBCK2    : BOOL;
        E_SPEED     : BOOL;
        F_START1    : BOOL;
        F_START2    : BOOL;
        F_STOP      : BOOL;
        F_RUN1      : BOOL;
        F_RUN2      : BOOL;
        F_OSST1     : BOOL;
        F_OSST2     : BOOL;
        F_OSSTP     : BOOL;
        LOCAL_MODES : BOOL;
        ALARM8P_1 : ALARM_8P;
        ALARM8P_2 : ALARM_8P; 
    END_VAR

//|

//: "INITIAL PARAMETERS"
    ERR := RD_SINFO (TOP_SI := TOP_SI, START_UP_SI := START_UP_SI);
    IF TOP_SI.NUM = 100 THEN
        //: "ADD CODE HERE FOR WORKING IN START-UP OB."

            //: "CLEAR ALL TIMERS"
                FOR T_INT:= 1 TO MAX_ODT DO
                    TIMERS[T_INT].Q  := FALSE;
                    TIMERS[T_INT].ET := 0;
                END_FOR;
            //|

        //|
        RUNUPCNT := RUNUPCYC;
    ELSIF RUNUPCNT > 0 THEN
        RUNUPCNT := RUNUPCNT -1;
        //: "ADD CODE HERE WORKING FOR A FEW (RUNUPCYCLE) CYCLES AFTER START-UP"

        //|
    END_IF;

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

    //: "MAINTENANCE MODE"
        IF NOT P_ENABLE THEN
            IF CMND.MAINTENANCE_OP THEN
                G_AUTO    := FALSE;
                G_SINGLE  := FALSE;
                G_LOCAL   := TRUE;
            END_IF;
        ELSE
            CMND.MAINTENANCE_OP := FALSE;
        END_IF;
    //|

    //: "FAULT CONDITIONS"

        _D := DW#16#0;

        // Control Center Not Ready
        _B32.B00  := NOT M_READY;

        // Local Box Position Fault
        _B32.B01  := ( G_AUTO OR G_SINGLE ) AND ( L_LOCAL OR NOT L_REMOTE ) AND NOT P_NO_LOC;

        // Local Stop in Automatic Mode
        _B32.B02  := ( G_AUTO OR G_SINGLE ) AND NOT L_STOP AND NOT P_NO_LOC;

        // Unexpected Start d1
        TIMERS[_FDBCK1].TV := T_FB_FLT;
        TIMERS[_FDBCK1].IN := NOT M_FDBCK1;
        F_FDBCK1 := NOT TIMERS[_FDBCK1].Q;
        _B32.B03   := NOT Q_RUN1 AND NOT E_FDBCK1 AND F_FDBCK1;

        // Unexpected Start d2
        TIMERS[_FDBCK2].TV := T_FB_FLT;
        TIMERS[_FDBCK2].IN := NOT M_FDBCK2;
        F_FDBCK2 := NOT TIMERS[_FDBCK2].Q;
        _B32.B04   := NOT Q_RUN2 AND NOT E_FDBCK2 AND F_FDBCK2;

        // Unexpected Stop d1
        _B32.B05  := Q_RUN1 AND E_FDBCK1 AND NOT F_FDBCK1;
        E_FDBCK1 := F_FDBCK1;

        // Unexpected Stop d2
        _B32.B06  := Q_RUN2 AND E_FDBCK2 AND NOT F_FDBCK2;
        E_FDBCK2 := F_FDBCK2;

        // Trip Start d1
        TIMERS[_TRP_START].TV := T_FB_ON;
        TIMERS[_TRP_START].IN := (Q_RUN1 AND NOT F_FDBCK1) OR (Q_RUN2 AND NOT F_FDBCK2);
        _B32.B07 := TIMERS[_TRP_START].Q AND Q_RUN1;

        // Trip Start d2
        _B32.B08 := TIMERS[_TRP_START].Q AND Q_RUN2;

        // Trip Stop d1
        TIMERS[_TRP_STOP].TV := T_FB_OFF;
        TIMERS[_TRP_STOP].IN := ( NOT Q_RUN1 AND F_FDBCK1 ) OR ( NOT Q_RUN2 AND F_FDBCK2 );
        _B32.B09 := TIMERS[_TRP_STOP].Q AND F_FDBCK1;

        // Trip Stop d2
        _B32.B10 := TIMERS[_TRP_STOP].Q AND F_FDBCK2;

        // Rotation Dedector
        TIMERS[_SPEED].TV := T_SPEED;
        TIMERS[_PULSE].TV := T_PULSE;
        TIMERS[_SPEED].IN := (G_AUTO OR G_SINGLE) AND (F_FDBCK1 OR F_FDBCK2);
        TIMERS[_PULSE].IN := TIMERS[_SPEED].Q AND NOT (S_SPEED XOR E_SPEED);
        E_SPEED := S_SPEED AND P_IS_PLS;
        _B32.B11 := TIMERS[_PULSE].Q;

        // Quick Stop
        _B32.B12 := NOT S_QSTOP;
        
        // Protection Interlock Missing
        _B32.B13 := NOT I_PROT OR (( G_AUTO OR G_SINGLE ) AND NOT I_PROTA );

        SIGNALS := _D;
        IF G_ACK OR CMND.ACKNOWLEDGE THEN
            OS_FLAGS   := SIGNALS;
        ELSIF OS_FLAGS = DW#16#0 THEN
            OS_FLAGS   := SIGNALS;
        END_IF;

        IF MSG_LOCK OR NOT P_ENABLE THEN
            ALARMS  := DW#16#0;
        ELSE
            ALARMS  := SIGNALS;
        END_IF;

        Q_FAULT := OS_FLAGS <> DW#16#0;
    //|

    //: "SINGLE START-STOP OS HELPER"
         IF NOT CMND.SINGLE_START1 AND NOT F_START1 THEN
            F_OSST1:=FALSE;
         END_IF;
         IF NOT CMND.SINGLE_START2 AND NOT F_START2 THEN
            F_OSST2:=FALSE;
         END_IF;
        
        IF CMND.SINGLE_START1 THEN
            CMND.SINGLE_START2  := FALSE;
            CMND.SINGLE_STOP    := FALSE;
            F_OSST1 := TRUE;
        ELSIF CMND.SINGLE_START2 THEN
            CMND.SINGLE_START1  := FALSE;
            CMND.SINGLE_STOP    := FALSE;
            F_OSST2 := TRUE;
        ELSIF CMND.SINGLE_STOP THEN
            CMND.SINGLE_START1  := FALSE;
            CMND.SINGLE_START2  := FALSE;
            F_OSSTP := TRUE;
        END_IF;

        IF F_OSST1 AND (Q_FAULT OR F_RUN1 OR Q_FDBCK1) THEN F_OSST1 := FALSE; END_IF;
        IF F_OSST2 AND (Q_FAULT OR F_RUN2 OR Q_FDBCK2) THEN F_OSST2 := FALSE; END_IF;
        IF F_OSSTP AND NOT (F_START1 OR F_START2) THEN F_OSSTP := FALSE; END_IF;
    //|

    //: "START-STOP ALGORITHM"
        LOCAL_MODES := ( G_LOCAL OR ( NOT P_ENABLE AND CMND.MAINTENANCE_OP ));  // Local or Maintenance mode activated.

        F_STOP :=
            ( C_STOPA OR LOCAL_MODES ) AND
            (( G_AUTO AND ( L_REMOTE OR P_NO_LOC ) AND G_STOP ) OR
            ( G_SINGLE AND ( L_REMOTE OR P_NO_LOC ) AND F_OSSTP ) OR
            ( LOCAL_MODES AND (( NOT P_NO_LOC AND L_LOCAL AND NOT L_STOP ) OR ( P_NO_LOC AND F_OSSTP ))));

        F_START1 :=
            (( C_STRT1 AND ( C_STRTA1 OR LOCAL_MODES )) OR F_RUN1 ) AND         // Start Conditions
            ( I_OPERA1 OR LOCAL_MODES ) AND                                     // Operation Interlocks
            (( G_AUTO AND ( L_REMOTE OR P_NO_LOC ) AND G_START1 ) OR            // Start Command in Auto Mode
            ( G_SINGLE AND ( L_REMOTE OR P_NO_LOC ) AND F_OSST1 ) OR // Start Command in Single Mode
            ( LOCAL_MODES AND (( NOT P_NO_LOC AND L_LOCAL AND L_START1 ) OR ( P_NO_LOC AND F_OSST1 ))) OR F_RUN1 ) AND // Start Command in Local Modes
            NOT Q_FAULT AND NOT G_QSTOP AND NOT F_START2 AND NOT F_STOP;        // Stop Command and Faults

        F_START2 :=
            (( C_STRT2 AND ( C_STRTA2 OR LOCAL_MODES )) OR F_RUN2 ) AND         // Start Conditions
            ( I_OPERA2 OR LOCAL_MODES ) AND                                     // Operation Interlocks
            (( G_AUTO AND ( L_REMOTE OR P_NO_LOC ) AND G_START2 ) OR            // Start Command in Auto Mode
            ( G_SINGLE AND ( L_REMOTE OR P_NO_LOC ) AND F_OSST2 ) OR // Start Command in Single Mode
            (LOCAL_MODES AND (( NOT P_NO_LOC AND L_LOCAL AND L_START2 ) OR ( P_NO_LOC AND F_OSST2 ))) OR F_RUN2 ) AND // Start Command in Local Modes
            NOT Q_FAULT AND NOT G_QSTOP AND NOT F_START1 AND NOT F_STOP;        // Stop Command and Faults

        IF F_START1 OR F_START2 THEN                                            // START DEVICE
            IF NOT TIMERS[_START].IN THEN
                TIMERS[_START].IN := TRUE;
                IF G_SINGLE OR (LOCAL_MODES AND P_NO_LOC) THEN                  // Remote start by manualy
                    TIMERS[_START].TV := T_HORN;
                    TIMERS[_STOP].TV  := 0;
                    Q_HORN := TRUE;
                ELSIF G_AUTO THEN                                               // Automatic start from group
                    TIMERS[_START].TV := T_START;
                    TIMERS[_STOP].TV  := T_STOP;
                ELSE                                                            // Local start at side
                    TIMERS[_START].TV := 0;
                    TIMERS[_STOP].TV  := 0;
                END_IF;
            ELSIF TIMERS[_START].Q THEN                                         // Wait for start-up or horn time.
                F_RUN1 := F_START1;
                F_RUN2 := F_START2;
                Q_HORN := FALSE;
            END_IF;
        ELSE                                                                    // STOP DEVICE
            TIMERS[_START].IN := FALSE;
            TIMERS[_STOP].IN  := F_RUN1 OR F_RUN2;
            IF NOT G_AUTO OR Q_FAULT OR G_QSTOP OR (G_AUTO AND (( Q_RUN1 AND NOT I_OPERA1 ) OR ( Q_RUN2 AND NOT I_OPERA2 ))) THEN
                F_RUN1 := FALSE;
                F_RUN2 := FALSE;
            ELSIF TIMERS[_STOP].Q THEN
                F_RUN1 := FALSE;
                F_RUN2 := FALSE;
            END_IF;
            Q_HORN := FALSE;
        END_IF;

        Q_SIM       := G_SIM OR P_SIM;
        Q_RUN1      := F_RUN1 AND (LOCAL_MODES OR C_SPRDC );
        Q_RUN2      := F_RUN2 AND (LOCAL_MODES OR C_SPRDC );
        Q_ACTIVE    := (G_AUTO OR G_SINGLE) AND (F_RUN1 OR F_RUN2);
        Q_FDBCK1    := Q_ACTIVE AND F_FDBCK1;
        Q_FDBCK2    := Q_ACTIVE AND F_FDBCK2;
   
        Q_LOCALMODE := G_LOCAL AND NOT (G_AUTO OR G_SINGLE);

    //|

    //: "OS_STATUS"
        _D          := DW#16#0;
        _B32.B00    := M_READY;        // Control Center Ready
        _B32.B01    := M_FDBCK1;       // Device Running
        _B32.B02    := M_FDBCK2;       // Device Running
        _B32.B03    := L_LOCAL;        // Local Box Local Position
        _B32.B04    := L_REMOTE;       // Local Box Remote Position
        _B32.B05    := L_START1;       // Local Box Local Start
        _B32.B06    := L_START2;       // Local Box Local Start
        _B32.B07    := L_STOP;         // Local Box Local Stop
        _B32.B08    := C_SPRDC;        // Sporadic ON/OFF Command
        _B32.B09    := C_STRT1;        // Start Condition
        _B32.B10    := C_STRTA1;       // Start Condition (Auto Mode Only)
        _B32.B11    := C_STRT2;        // Start Condition
        _B32.B12    := C_STRTA2;       // Start Condition (Auto Mode Only)
        _B32.B13    := C_STOPA;        // Stop Condition
        _B32.B14    := I_OPERA1;       // Operation Interlok (Auto Mode Only)
        _B32.B15    := I_OPERA2;       // Operation Interlok (Auto Mode Only)
        _B32.B16    := I_PROT;         // Protection Interlock
        _B32.B17    := I_PROTA;        // Protection Interlock (Auto Mode Only)
        _B32.B18    := G_START1;       // Group Start Command
        _B32.B19    := G_START2;       // Group Start Command
        _B32.B20    := G_STOP;         // Group Stop Command
        _B32.B21    := G_QSTOP;        // Group Quick Stop Command
        _B32.B22    := G_AUTO;         // Automatic Mode
        _B32.B23    := G_SINGLE;       // Single Mode
        _B32.B24    := G_LOCAL;        // Local Mode
        _B32.B25    := G_SIM;          // Group Simulation Mode
        _B32.B26    := P_ENABLE;       // Device Disabled
        _B32.B27    := P_NO_LOC;       // Local Control Box not Used
        _B32.B28    := P_IS_PLS;       // Rotation Dedector Pulse Enable
        _B32.B29    := P_SIM;          // Simulation Mode On
        _B32.B30    := NOT P_ENABLE AND CMND.MAINTENANCE_OP;  // Maintenance Mode
        _B32.B31    := S_SPEED;         // Speed Monitor
        OS_STAT1    := _D;

        _D          := DW#16#0;
        _B32.B00    := Q_ACTIVE;       // Device Active
        _B32.B01    := Q_FDBCK1;       // Device Running
        _B32.B02    := Q_FDBCK2;       // Device Running
        _B32.B03    := Q_FAULT;        // Device Fault
        _B32.B04    := Q_RUN1;         // Run Command
        _B32.B05    := Q_RUN2;         // Run Command
        _B32.B06    := Q_HORN;         // Horn
        _B32.B07    := Q_SIM;          // Simulation On
        OS_STAT2    := _D;
    //|

    //: "OS_VISU"
        OS_VISU := 1;

        IF G_LOCAL THEN OS_VISU := 6; END_IF;
        IF G_LOCAL AND Q_RUN1 AND NOT TIMERS[3].Q THEN OS_VISU := 7; END_IF;
        IF G_LOCAL AND Q_RUN2 AND NOT TIMERS[3].Q THEN OS_VISU := 8; END_IF;

        IF G_SINGLE THEN OS_VISU := 9; END_IF;
        IF G_SINGLE AND Q_RUN1 AND NOT TIMERS[3].Q THEN OS_VISU := 10; END_IF;
        IF G_SINGLE AND Q_RUN2 AND NOT TIMERS[3].Q THEN OS_VISU := 11; END_IF;

        IF G_AUTO AND Q_RUN1 AND NOT TIMERS[3].Q THEN OS_VISU := 4; END_IF;
        IF G_AUTO AND Q_RUN2 AND NOT TIMERS[3].Q THEN OS_VISU := 5; END_IF;

        IF NOT P_ENABLE THEN OS_VISU := 0; END_IF;

        IF (NOT P_ENABLE OR G_LOCAL) AND CMND.MAINTENANCE_OP THEN OS_VISU := 12; END_IF;
        IF (NOT P_ENABLE OR G_LOCAL) AND CMND.MAINTENANCE_OP AND Q_RUN1 AND M_FDBCK1 THEN OS_VISU := 13; END_IF;
        IF (NOT P_ENABLE OR G_LOCAL) AND CMND.MAINTENANCE_OP AND Q_RUN2 AND M_FDBCK2 THEN OS_VISU := 14; END_IF;

        IF Q_FAULT THEN OS_VISU := 3; END_IF;
        IF OS_FLAGS <> SIGNALS THEN OS_VISU := 2; END_IF;
    //|

// END OF MAIN CODE AREA
END_IF;
//|

//: "ALARM ENGINE"
    IF RUNUPCNT = 0 THEN
        _D := ALARMS;
            ALARM8P_1(EN_R := TRUE // IN: BOOL
               ,SIG_1 := _B32.B00 // IN: BOOL
               ,SIG_2 := _B32.B01 // IN: BOOL
               ,SIG_3 := _B32.B02 // IN: BOOL
               ,SIG_4 := _B32.B03 // IN: BOOL
               ,SIG_5 := _B32.B04 // IN: BOOL
               ,SIG_6 := _B32.B05 // IN: BOOL
               ,SIG_7 := _B32.B06 // IN: BOOL
               ,SIG_8 := _B32.B07 // IN: BOOL
               ,ID    := 16#EEEE // IN: WORD
               ,EV_ID := MSG_EVID_1 // IN: DWORD
               ,SEVERITY := 16#0001 // IN: WORD
               );   
        
        ALARM8P_2(EN_R := TRUE // IN: BOOL
               ,SIG_1 := _B32.B08 // IN: BOOL
               ,SIG_2 := _B32.B09 // IN: BOOL
               ,SIG_3 := _B32.B10 // IN: BOOL
               ,SIG_4 := _B32.B11 // IN: BOOL
               ,SIG_5 := _B32.B12 // IN: BOOL
               ,SIG_6 := _B32.B13 // IN: BOOL
               ,SIG_7 :=  FALSE// IN: BOOL
               ,SIG_8 :=  FALSE// IN: BOOL
               ,ID    := 16#EEEE // IN: WORD
               ,EV_ID := MSG_EVID_2 // IN: DWORD
               ,SEVERITY := 16#0001 // IN: WORD
               );   
    END_IF;

//|

END_FUNCTION_BLOCK


