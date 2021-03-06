FUNCTION_BLOCK D_DMP_S7400
{S7_m_c := 'true';S7_alarm_ui := '0'; S7_tasklist := 'OB100'}

TITLE = 'Standard 2 Way Damper Control'
//
// Dal Elektrik ve Otomasyon A.S. �2009
//

//: "VERSION & CHANGE LOG"

AUTHOR  : DEO
NAME    : D_DMP
VERSION : '00.06'
FAMILY  : DL_S7400
KNOW_HOW_PROTECT

(*
    Change Log
    Date                Owner   Mj.Mn   Comment
    12:17 08.06.2009    ERS     00.00   Project started. (DS73_M2D)
    09:08 19.06.2009    EE      00.01   Arranged acording to S7300. (DS73_M2D)
    14:56 26.06.2009    YKU     00.02   Interface names modified. (DS73_M2D)
    15:11 29.06.2009    YKU     01.00   Main algorithm changed. (DS73_M2D)
    18:19 29.06.2009    YKU     01.01   First compiled source. (DS73_M2D)
    14:13 01.07.2009    YKU     00.01   DS73_V2D created
    17:02 03.07.2009    BO      00.03   OS_VISU changed
    14:01 11.08.2009    EE      00.05   for F_STOP, AND NOT L_STOP added.
    14:10 17.02.2011    IK      00.06   Adjusted for S7 400 CPU.
*)

//|

//: "INTERFACE DEFINITIONS"

    CONST
        ON          := TRUE;
        OFF         := FALSE;
        _HORN       :=  1;
        _START      :=  2;
        _STOP       :=  3;
        _TCLOSE     :=  4;
        _TOPEN      :=  5;
        _UCLOSE     :=  6;
        _UOPEN      :=  7;
        _TSCLOSE    :=  8;
        _TSOPEN      :=  9;
        MAX_ODT     := 11; // Maximum count of Software On-Delay Timers
    END_CONST

    VAR_INPUT
        M_READY         : BOOL; // MCC Ready

        S_CLOSE         : BOOL; // Closed Limit Switch Signal
        S_OPEN          : BOOL; // Opened Limit Switch Signal
        S_TCLOSE        : BOOL; // Closed Torque Switch Signal
        S_TOPEN         : BOOL; // Opened Torque Switch Signal

        L_LOCAL         : BOOL; // Local Box Local Position
        L_REMOTE        : BOOL; // Local Box Remote Position
        L_STARTC        : BOOL; // Local Box Local Start
        L_STARTO        : BOOL; // Local Box Local Start
        L_STOP          : BOOL; // Local Box Local Stop

        C_SPRDC         : BOOL; // Sporadic ON/OFF

        C_STRTC         : BOOL; // Start Condition
        C_STRTAC        : BOOL; // Start Condition (Auto Mode Only)
        C_STRTO         : BOOL; // Start Condition
        C_STRTAO        : BOOL; // Start Condition (Auto Mode Only)
        C_STOPA         : BOOL; // Stop Condition (Auto Mode Only)

        I_OPERAC        : BOOL; // Operation Interlok (Auto Mode Only)
        I_OPERAO        : BOOL; // Operation Interlok (Auto Mode Only)
        I_PROT          : BOOL; // Protection Interlock
        I_PROTA         : BOOL; // Protection Interlock (Auto Mode Only)

        G_STARTC        : BOOL; // Group Start Command
        G_STARTO        : BOOL; // Group Start Command
        G_STOP          : BOOL; // Group Stop Command
        G_AUTO          : BOOL; // Group in Auto Mode
        G_SINGLE        : BOOL; // Group in Single Mode
        G_LOCAL         : BOOL; // Group in Local Mode
        G_SIM           : BOOL; // Group Simulation Mode
        G_ACK           : BOOL; // Group wise Acknowledge
        G_QSTOP         : BOOL; // Group stop
        P_ENABLE        : BOOL; // Device enabled(1) / disabled(0)
        P_NO_LOC        : BOOL; // Local Control Box not Used
        P_SIM           : BOOL; // Simulation Mode On


        T_START         : REAL := 5;  // Start Delay Time
        T_STOP          : REAL := 10; // Stop Delay Time
        T_OP_MON        : REAL := 3;  // Feedback Ramp Up Delay Time
        T_CL_MON        : REAL := 3;  // Feedback Ramp Down Delay Time
        T_FB_FLT        : REAL := 1;  // Feedback Filter Time
        T_HORN          : REAL := 7;  // Horn Time

        OS_CMND { S7_m_c := 'true'}: WORD;
        CMND AT OS_CMND : STRUCT // First Status Bits for OS
            SINGLE_STARTC  : BOOL; // Start Command From OS in Single Mode
            SINGLE_STARTO  : BOOL; // Start Command From OS in Single Mode
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
        Q_CLOSED        : BOOL; // Device Running
        Q_OPENED        : BOOL; // Device Running
        Q_FAULT         : BOOL; // Device Fault
        Q_CLOSE         : BOOL; // Run Command
        Q_OPEN          : BOOL; // Run Command
        Q_HORN          : BOOL; // Horn
        Q_SIM           : BOOL; // Simulation On

        OS_VISU { S7_m_c := 'true'} : INT; // Visualization for OS
    (*
        0:  Disabled                    :Dark  Grey
        1:  No limit no fault           :Light Grey Colour
        2:  Fault not Acknowledged      :Flashing Red
        3:  Acknowledged Fault          :Red
        4:  Limit switch 1 in auto mode :Green
        5:  Limit switch 2 in auto mode :Green
        6:  Moving to D1 in auto mode   :Flashing green
        7:  Moving to D2 in auto mode   :Flashing green
        8:  Limit switch 1 in lokal mode:yellow
        9: Limit switch 2 in lokal mode:yellow
        10: Moving to D1 in lokal mode  :Flashing yellow
        11: Moving to D2 in lokal mode :Flashing yellow
        12: No limit in local mode     :Yellow
        13: Limit switch 1 in single mode:blue
        14: Limit switch 2 in single mode:blue
        15: Moving to D1 in single mode  :Flashing blue
        16: Moving to D1 in single mode  :Flashing blue
        17: No limit in single mode      :Blue
        18: Limit switch 1 in maintenance mode :orange
        19: Limit switch 2 in maintenance mode :orange
        20: Moving to D1 in maintenance mode :flashing orange
        21: Moving to D2 in maintenance mode :flashing orange
        22: No limit in maintenance mode     : Orange
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

        F_CLOSE     : BOOL;
        F_OPEN      : BOOL;
        E_CLOSE     : BOOL;
        E_OPEN      : BOOL;
        E_SPEED     : BOOL;
        F_STARTC    : BOOL;
        F_STARTO    : BOOL;
        F_STOP      : BOOL;
        F_RUNC      : BOOL;
        F_RUNO      : BOOL;
        E_SINGLE_STARTC     : BOOL;
        E_SINGLE_STARTO     : BOOL;
        E_SINGLE_STOP     : BOOL;
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

        // Unexpected Close
        TIMERS[_UCLOSE].TV := T_FB_FLT;
        TIMERS[_UCLOSE].IN := NOT S_CLOSE;

        _B32.B03   := NOT Q_CLOSE AND NOT E_CLOSE AND F_CLOSE;
         F_CLOSE := NOT TIMERS[_UCLOSE].Q;

        // Unexpected Open
        TIMERS[_UOPEN].TV := T_FB_FLT;
        TIMERS[_UOPEN].IN := NOT S_OPEN;

        _B32.B04   := NOT Q_OPEN AND NOT E_OPEN AND F_OPEN;
         F_OPEN := NOT TIMERS[_UOPEN].Q;
        // Close missing
        _B32.B05  := NOT Q_OPEN AND E_CLOSE AND NOT F_CLOSE;
        E_CLOSE := F_CLOSE;

        // Open missing
        _B32.B06  := NOT Q_CLOSE AND E_OPEN AND NOT F_OPEN;
        E_OPEN := F_OPEN;

        // Position fault
        _B32.B07  := F_CLOSE AND F_OPEN;





        // Close monitoring time

        TIMERS[_TCLOSE].TV := T_CL_MON;
        TIMERS[_TCLOSE].IN := (Q_CLOSE AND NOT F_CLOSE);
        _B32.B08 := TIMERS[_TCLOSE].Q;




         // Open monitoring time
        TIMERS[_TOPEN].TV := T_OP_MON;
        TIMERS[_TOPEN].IN := (Q_OPEN AND NOT F_OPEN );
        _B32.B09 := TIMERS[_TOPEN].Q;

        // Torque Close Switch
        TIMERS[_TSCLOSE].TV := T_FB_FLT;
        TIMERS[_TSCLOSE].IN := NOT S_TCLOSE;
        _B32.B10  := TIMERS[_TSCLOSE].Q;

        // Torque Open Switch
        TIMERS[_TSOPEN].TV := T_FB_FLT;
        TIMERS[_TSOPEN].IN := NOT S_TOPEN;
        _B32.B11  := TIMERS[_TSOPEN].Q;

        // Protection Interlock Missing
        _B32.B12 := NOT I_PROT OR (( G_AUTO OR G_SINGLE ) AND NOT I_PROTA );

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
        IF NOT CMND.SINGLE_STARTC AND NOT F_STARTC  THEN  /////////// EKLENDI
            E_SINGLE_STARTC := FALSE;
        END_IF;

        IF NOT CMND.SINGLE_STARTO AND NOT F_STARTO  THEN  /////////// EKLENDI
            E_SINGLE_STARTO := FALSE;
        END_IF;


        IF CMND.SINGLE_STARTC  THEN
            CMND.SINGLE_STARTO  := FALSE;
              E_SINGLE_STOP    := FALSE;
              E_SINGLE_STARTC  := TRUE;

        ELSIF CMND.SINGLE_STARTO  THEN
            CMND.SINGLE_STARTC  := FALSE;
               E_SINGLE_STOP    := FALSE;
               E_SINGLE_STARTO  := TRUE;
        ELSIF CMND.SINGLE_STOP  THEN
            E_SINGLE_STARTC  := FALSE;
            E_SINGLE_STARTO  := FALSE;
            F_RUNC           := FALSE;
            F_RUNO           := FALSE;
        END_IF;

        IF  E_SINGLE_STARTC AND (Q_FAULT OR F_RUNC) THEN  E_SINGLE_STARTC := FALSE; END_IF;
        IF  E_SINGLE_STARTO AND (Q_FAULT OR F_RUNO) THEN  E_SINGLE_STARTO := FALSE; END_IF;
        IF CMND.SINGLE_STOP AND NOT (F_STARTC OR F_STARTO) THEN CMND.SINGLE_STOP := FALSE; END_IF;
    //|

    //: "START-STOP ALGORITHM"
        LOCAL_MODES := ( G_LOCAL OR ( NOT P_ENABLE AND CMND.MAINTENANCE_OP ));  // Local or Maintenance mode activated.

        F_STOP :=
            ( C_STOPA OR LOCAL_MODES ) AND
            (( G_AUTO AND ( L_REMOTE OR P_NO_LOC ) AND G_STOP ) OR
            ( G_SINGLE AND ( L_REMOTE OR P_NO_LOC ) AND  E_SINGLE_STOP ) OR
            ( LOCAL_MODES AND (( NOT P_NO_LOC AND L_LOCAL AND NOT L_STOP ) OR ( P_NO_LOC AND  E_SINGLE_STOP ))));

        F_STARTC :=
            (( C_STRTC AND ( C_STRTAC OR LOCAL_MODES )) OR F_RUNC ) AND         // Start Conditions
            ( I_OPERAC OR LOCAL_MODES ) AND                                     // Operation Interlocks
            (( G_AUTO AND ( L_REMOTE OR P_NO_LOC ) AND G_STARTC ) OR            // Start Command in Auto Mode
            ( G_SINGLE AND ( L_REMOTE OR P_NO_LOC ) AND E_SINGLE_STARTC ) OR // Start Command in Single Mode
            ( LOCAL_MODES AND (( NOT P_NO_LOC AND L_LOCAL AND L_STARTC ) OR ( P_NO_LOC AND E_SINGLE_STARTC ))) OR F_RUNC ) AND // Start Command in Local Modes
            NOT Q_FAULT AND NOT G_QSTOP AND NOT F_STARTO AND NOT S_CLOSE AND NOT F_STOP;        // Stop Command and Faults

        F_STARTO :=
            (( C_STRTO AND ( C_STRTAO OR LOCAL_MODES )) OR F_RUNO ) AND         // Start Conditions
            ( I_OPERAO OR LOCAL_MODES ) AND                                     // Operation Interlocks
            (( G_AUTO AND ( L_REMOTE OR P_NO_LOC ) AND G_STARTO ) OR            // Start Command in Auto Mode
            ( G_SINGLE AND ( L_REMOTE OR P_NO_LOC ) AND  E_SINGLE_STARTO  ) OR // Start Command in Single Mode
            (LOCAL_MODES AND (( NOT P_NO_LOC AND L_LOCAL AND L_STARTO ) OR ( P_NO_LOC AND  E_SINGLE_STARTO  ))) OR F_RUNO ) AND // Start Command in Local Modes
            NOT Q_FAULT AND NOT G_QSTOP AND NOT F_STARTC AND NOT S_OPEN AND NOT F_STOP;        // Stop Command and Faults

        IF F_STARTC OR F_STARTO THEN                                            // START DEVICE
            IF NOT TIMERS[_START].IN THEN
                TIMERS[_START].IN := TRUE;
                IF G_SINGLE OR (LOCAL_MODES AND P_NO_LOC) THEN                  // Remote start by manualy
                    TIMERS[_START].TV := T_HORN;
                    Q_HORN := TRUE;
                ELSIF G_AUTO THEN                                               // Automatic start from group
                    TIMERS[_START].TV := T_START;
                ELSE                                                            // Local start at side
                    TIMERS[_START].TV := 0;
                END_IF;
            ELSIF TIMERS[_START].Q THEN                                         // Wait for start-up or horn time.
                F_RUNC := F_STARTC;
                F_RUNO := F_STARTO;
                Q_HORN := FALSE;
            END_IF;
        ELSE                                                                    // STOP DEVICE
            TIMERS[_START].IN := FALSE;
            F_RUNC := FALSE;
            F_RUNO := FALSE;
            Q_HORN := FALSE;
        END_IF;

        Q_SIM       := G_SIM OR P_SIM;
        Q_CLOSE     := F_RUNC;
        Q_OPEN      := F_RUNO;
        Q_ACTIVE    := NOT Q_FAULT;
        Q_CLOSED    := F_CLOSE;
        Q_OPENED    := F_OPEN;

    //|

    //: "OS_STATUS"
        _D          := DW#16#0;
        _B32.B00    := M_READY;        // Control Center Ready
        _B32.B01    := S_CLOSE;       // Device Running
        _B32.B02    := S_OPEN;       // Device Running
        _B32.B03    := L_LOCAL;        // Local Box Local Position
        _B32.B04    := L_REMOTE;       // Local Box Remote Position
        _B32.B05    := L_STARTC;       // Local Box Local Start
        _B32.B06    := L_STARTO;       // Local Box Local Start
        _B32.B07    := L_STOP;         // Local Box Local Stop
        _B32.B08    := C_SPRDC;        // Sporadic ON/OFF Command
        _B32.B09    := C_STRTC;        // Start Condition
        _B32.B10    := C_STRTAC;       // Start Condition (Auto Mode Only)
        _B32.B11    := C_STRTO;        // Start Condition
        _B32.B12    := C_STRTAO;       // Start Condition (Auto Mode Only)
        _B32.B13    := C_STOPA;        // Stop Condition
        _B32.B14    := I_OPERAC;       // Operation Interlok (Auto Mode Only)
        _B32.B15    := I_OPERAO;       // Operation Interlok (Auto Mode Only)
        _B32.B16    := I_PROT;         // Protection Interlock
        _B32.B17    := I_PROTA;        // Protection Interlock (Auto Mode Only)
        _B32.B18    := G_STARTC;       // Group Start Command
        _B32.B19    := G_STARTO;       // Group Start Command
        _B32.B20    := G_STOP;         // Group Stop Command
        _B32.B21    := G_QSTOP;        // Group Quick Stop Command
        _B32.B22    := G_AUTO;         // Automatic Mode
        _B32.B23    := G_SINGLE;       // Single Mode
        _B32.B24    := G_LOCAL;        // Local Mode
        _B32.B25    := G_SIM;          // Group Simulation Mode
        _B32.B26    := P_ENABLE;       // Device Disabled
        _B32.B27    := P_NO_LOC;       // Local Control Box not Used
        _B32.B29    := P_SIM;          // Simulation Mode On
        _B32.B30    := NOT P_ENABLE AND CMND.MAINTENANCE_OP; // Maintenance Mode
        OS_STAT1    := _D;

        _D          := DW#16#0;
        _B32.B00    := Q_ACTIVE;       // Device Active
        _B32.B01    := Q_CLOSED;       // Device Running
        _B32.B02    := Q_OPENED;       // Device Running
        _B32.B03    := Q_FAULT;        // Device Fault
        _B32.B04    := Q_CLOSE;         // Run Command
        _B32.B05    := Q_OPEN;         // Run Command
        _B32.B06    := Q_HORN;         // Horn
        _B32.B07    := Q_SIM;          // Simulation On
        OS_STAT2    := _D;
    //|

    //: "OS_VISU"
        OS_VISU := 1;

        IF G_LOCAL AND NOT Q_CLOSED AND NOT Q_OPENED THEN OS_VISU := 12; END_IF;
        IF G_LOCAL AND Q_CLOSED AND S_CLOSE THEN OS_VISU := 8; END_IF;
        IF G_LOCAL AND Q_OPENED AND S_OPEN THEN OS_VISU := 9; END_IF;
        IF G_LOCAL AND Q_CLOSE AND NOT S_CLOSE THEN OS_VISU := 10; END_IF;
        IF G_LOCAL AND Q_OPEN AND NOT S_OPEN THEN OS_VISU := 11; END_IF;


        IF G_SINGLE AND NOT Q_CLOSED AND NOT Q_OPENED THEN OS_VISU := 17; END_IF;
        IF G_SINGLE AND Q_CLOSED AND S_CLOSE THEN OS_VISU := 13; END_IF;
        IF G_SINGLE AND Q_OPENED AND S_OPEN THEN OS_VISU := 14; END_IF;
        IF G_SINGLE AND Q_CLOSE AND NOT S_CLOSE THEN OS_VISU := 15; END_IF;
        IF G_SINGLE AND Q_OPEN AND NOT S_OPEN THEN OS_VISU := 16; END_IF;


        IF G_AUTO AND Q_CLOSED AND S_CLOSE THEN OS_VISU := 4; END_IF;
        IF G_AUTO AND Q_OPENED AND S_OPEN THEN OS_VISU := 5; END_IF;
        IF G_AUTO AND Q_CLOSE AND NOT S_CLOSE  THEN OS_VISU :=6; END_IF;
        IF G_AUTO AND Q_OPEN AND NOT S_OPEN  THEN OS_VISU :=7; END_IF;

        IF NOT P_ENABLE THEN OS_VISU := 0; END_IF;

        IF (NOT P_ENABLE OR G_LOCAL) AND CMND.MAINTENANCE_OP AND NOT Q_CLOSED AND NOT Q_OPENED THEN OS_VISU := 22; END_IF;
        IF (NOT P_ENABLE OR G_LOCAL) AND CMND.MAINTENANCE_OP AND Q_CLOSED AND S_CLOSE THEN OS_VISU := 18; END_IF;
        IF (NOT P_ENABLE OR G_LOCAL) AND CMND.MAINTENANCE_OP AND Q_OPENED AND S_OPEN THEN OS_VISU := 19; END_IF;
        IF (NOT P_ENABLE OR G_LOCAL) AND CMND.MAINTENANCE_OP AND Q_CLOSE AND NOT S_CLOSE THEN OS_VISU := 20; END_IF;
        IF (NOT P_ENABLE OR G_LOCAL) AND CMND.MAINTENANCE_OP AND Q_OPEN AND NOT S_OPEN THEN OS_VISU := 21; END_IF;

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
               ,SIG_6 :=  FALSE // IN: BOOL
               ,SIG_7 :=  FALSE// IN: BOOL
               ,SIG_8 :=  FALSE// IN: BOOL
               ,ID    := 16#EEEE // IN: WORD
               ,EV_ID := MSG_EVID_2 // IN: DWORD
               ,SEVERITY := 16#0001 // IN: WORD
               );
    END_IF;

//|

END_FUNCTION_BLOCK
