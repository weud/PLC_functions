FUNCTION_BLOCK D_MOT1D_S74
{S7_m_c := 'true';S7_alarm_ui := '0'; S7_tasklist := 'OB100'}

TITLE = 'Standart Motor Control'
//
// Dal Elektrik ve Otomasyon A.S. ©2007
//

//: "VERSION & CHANGE LOG"

AUTHOR  : DEO
NAME    : D_MOT1D
VERSION : '00.07'
FAMILY  : DL_S7400
KNOW_HOW_PROTECT

(*
    Change Log
    Date                Owner   Mj.Mn   Comment

    12:17 08.06.2009    ET     00.00   Project started
    09:08 19.06.2009    EE      00.01   Arrenged Acording to S7300
    11:35 26.06.2009    ET     00.02   Block is tested, Group Start,Group Stop,Visulisiation To OS,Maintenance Mode,Simulation Mode
    14:56 26.06.2009    ACAN    00.03   Interface names modified.
    14:04 01.07.2009    BO      00.04   Block is modified.
    14:01 11.08.2009    EE      00.05   for F_STOP, AND NOT L_STOP added.
    11:15 23.09.2009    EE      00.06   OS_VISUOS arranged.(for visuos 4,6,8, timers[6] is used. before it was timers[3])
    17:31 16.02.2011    ET      00.07   Rearranged according to S7400
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
        _FDBCK      :=  6;
        _SPEED1     :=  7;
        _SPEED2     :=  8;  
        _TBELT      :=  9;
        _TLEVEL     := 10;
        _PULSE1     := 11;
        _PULSE2     := 12;
         MAX_ODT    := 12; // Maximum count of Software On-Delay Timers
    END_CONST

    VAR_INPUT
        M_READY         : BOOL; // MCC Ready
        M_FDBCK         : BOOL; // MCC Feedback  running

        
        L_LOCAL         : BOOL; // Local Box Local Position
        L_REMOTE        : BOOL; // Local Box Remote Position
        L_START         : BOOL; // Local Box Local Start
        L_STOP          : BOOL; // Local Box Local Stop

        C_SPRDC         : BOOL; // Sporadic ON/OFF
        C_STRT          : BOOL; // Start Condition
        C_STRTA         : BOOL; // Start Condition (Auto Mode Only)
        C_STOPA         : BOOL; // Stop Condition (Auto Mode Only)

        I_OPERA         : BOOL; // Operation Interlok (Auto Mode Only)
        I_PROT          : BOOL; // Protection Interlock
        I_PROTA         : BOOL; // Protection Interlock (Auto Mode Only)

        G_START         : BOOL; // Group Start Command
        G_STOP          : BOOL; // Group Stop Command
        G_QSTOP         : BOOL; // Group Quick Stop Command
        G_AUTO          : BOOL; // Group in Auto Mode
        G_SINGLE        : BOOL; // Group in Single Mode
        G_LOCAL         : BOOL; // Group in Local Mode
        G_SIM           : BOOL; // Group Simulation Mode
        G_ACK           : BOOL; // Group wise Acknowledge

        S_QSTOP         : BOOL; // Quick Stop
        S_SPEED1        : BOOL; // Rotation Dedector Signal 1
        S_SPEED2        : BOOL; // Rotation Dedector Signal 2
        S_BELT          : BOOL;// Belt Drift Signal
        S_LEVEL         : BOOL;// Level Signal
        S_ROPE          : BOOL;// Rope Switch
        
        P_ENABLE        : BOOL; // Device enabled(1) / disabled(0)
        P_NO_LOC        : BOOL; // Local Control Box not Used
        P_IS_PLS1       : BOOL; // Rotation Dedector Pulse Enable 1
        P_IS_PLS2       : BOOL; // Rotation Dedector Pulse Enable 2       
        P_SIM           : BOOL; // Simulation Mode On

        T_START         : REAL := 5;  // Start Delay Time
        T_STOP          : REAL := 10; // Stop Delay Time
        T_FB_ON         : REAL := 3;  // Feedback Ramp Up Delay Time
        T_FB_OFF        : REAL := 3;  // Feedback Ramp Down Delay Time
        T_FB_FLT        : REAL := 1;  // Feedback Filter Time
        T_SPEED1        : REAL := 10; // Rotation Dedector Delay Time 1
        T_SPEED2        : REAL := 10; // Rotation Dedector Delay Time 2
        T_PULSE1        : REAL := 5;  // Rotation Dedector Pulse Time 1
        T_PULSE2        : REAL := 5;  // Rotation Dedector Pulse Time 2
        T_BELT          : REAL := 3;  // Belt Drift Time
        T_LEVEL         : REAL := 3;  // Level Switch Time 
        T_HORN          : REAL := 7;  // Horn Time

        OS_CMND { S7_m_c := 'true'}: WORD;
        CMND AT OS_CMND : STRUCT // First Status Bits for OS
            SINGLE_START   : BOOL; // Start Command From OS in Single Mode
            SINGLE_STOP    : BOOL; // Stop Command From OS in Single Mode
            ACKNOWLEDGE    : BOOL; // Device Acknowledgement
            MAINTENANCE_OP : BOOL; // Maintenance Mode ON(1)/OFF(0)
        END_STRUCT;

        OS_USTAT {S7_m_c := 'true'}: WORD; // User Status Bits for OS

        MSG_LOCK    {S7_visible:='false'; S7_dynamic:='true'; S7_m_c:='true'}
                    : BOOL := 0;    // Enable 1=Messages locked
        
        S_T         {S7_visible := 'false'; S7_link := 'false'; S7_sampletime:='true'}
                    : REAL := 0.1;  // Sample time value
        RUNUPCYC    {S7_visible:='false'; S7_link:='false'}
                    : INT  := 3;    // Number of Run Up Cycles
                    
        
        MSG_EVID_1  {S7_visible  := 'false';S7_link := 'false'; S7_param := 'false';S7_server := 'alarm_archiv';S7_a_type := 'alarm_8p'}:DWORD ;
        MSG_EVID_2  {S7_visible  := 'false';S7_link := 'false'; S7_param := 'false';S7_server := 'alarm_archiv';S7_a_type := 'alarm_8p'}:DWORD ;
        
    END_VAR

    VAR_OUTPUT
        Q_ACTIVE        : BOOL; // Device Active
        Q_FDBCK         : BOOL; // Device Running
        Q_FAULT         : BOOL; // Device Fault
        Q_RUN           : BOOL; // Run Command
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

        F_FDBCK     : BOOL;
        E_FDBCK     : BOOL;
        E_SPEED1    : BOOL;
        E_SPEED2    : BOOL;
        F_START     : BOOL;
        F_STOP      : BOOL;
        F_RUN      : BOOL;
        F_OSST1     : BOOL;
        F_OSST2     : BOOL;
        F_OSSTP     : BOOL;
        LOCAL_MODES  :BOOL;
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

        // Unexpected Start
        TIMERS[_FDBCK].TV := T_FB_FLT;
        TIMERS[_FDBCK].IN := NOT M_FDBCK;
        F_FDBCK    := NOT TIMERS[_FDBCK].Q;
        _B32.B03   := NOT Q_RUN AND NOT E_FDBCK AND F_FDBCK;
       
        // Unexpected Stop
        _B32.B04  := Q_RUN AND E_FDBCK AND NOT F_FDBCK;
        E_FDBCK   := F_FDBCK;

        // Trip Start
        TIMERS[_TRP_START].TV := T_FB_ON;
        TIMERS[_TRP_START].IN := (Q_RUN AND NOT F_FDBCK);
        _B32.B05 := TIMERS[_TRP_START].Q AND Q_RUN;

        // Trip Stop 
        TIMERS[_TRP_STOP].TV := T_FB_OFF;
        TIMERS[_TRP_STOP].IN := ( NOT Q_RUN AND F_FDBCK );
        _B32.B06 := TIMERS[_TRP_STOP].Q AND F_FDBCK;

        // Rotation Dedector 1
        TIMERS[_SPEED1].TV := T_SPEED1;
        TIMERS[_PULSE1].TV := T_PULSE1;
        TIMERS[_SPEED1].IN := (G_AUTO OR G_SINGLE) AND F_FDBCK ;
        TIMERS[_PULSE1].IN := TIMERS[_SPEED1].Q AND NOT (S_SPEED1 XOR E_SPEED1);
        E_SPEED1 := S_SPEED1 AND P_IS_PLS1;
        _B32.B07 := TIMERS[_PULSE1].Q;

        // Quick Stop
        _B32.B08 := NOT S_QSTOP;
        
        // Protection Interlock Missing
        _B32.B09 := NOT I_PROT OR (( G_AUTO OR G_SINGLE ) AND NOT I_PROTA );
        
      
        
                // Rotation Dedector 2
        TIMERS[_SPEED2].TV := T_SPEED2;
        TIMERS[_PULSE2].TV := T_PULSE2;
        TIMERS[_SPEED2].IN := (G_AUTO OR G_SINGLE) AND F_FDBCK;
        TIMERS[_PULSE2].IN := TIMERS[_SPEED2].Q AND NOT (S_SPEED2 XOR E_SPEED2);
        E_SPEED2 := S_SPEED2 AND P_IS_PLS2;
        _B32.B10 := TIMERS[_PULSE2].Q;
        
          // Rope Switch
        _B32.B11 := NOT S_ROPE;
        
        // Belt Drift 
        TIMERS[_TBELT].TV := _TBELT;
        TIMERS[_TBELT].IN := (G_AUTO OR G_SINGLE) AND NOT S_BELT;
        _B32.B12 := TIMERS[_TBELT].Q;
        
         // Level Switch 
        TIMERS[_TLEVEL].TV := _TLEVEL;
        TIMERS[_TLEVEL].IN := (G_AUTO OR G_SINGLE) AND NOT S_LEVEL;
        _B32.B13 := TIMERS[_TLEVEL].Q;
        

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
    
      IF NOT CMND.SINGLE_START AND NOT F_START  THEN  /////////// EKLENDI
            F_OSST1 := FALSE;
        END_IF;
    
    
    
        IF  CMND.SINGLE_START  THEN
            CMND.SINGLE_STOP    := FALSE;
            F_OSST1 := TRUE;
        ELSIF    CMND.SINGLE_STOP THEN
            CMND.SINGLE_START   := FALSE;
            F_OSSTP := TRUE;
        END_IF;

        IF F_OSST1 AND (Q_FAULT OR F_RUN OR Q_FDBCK ) THEN F_OSST1 := FALSE; END_IF;
        IF F_OSSTP AND NOT F_START THEN F_OSSTP := FALSE; END_IF;
    //|

    //: "START-STOP ALGORITHM"
        LOCAL_MODES := ( G_LOCAL OR ( NOT P_ENABLE AND CMND.MAINTENANCE_OP ));  // Local or Maintenance mode activated.

        F_STOP :=
            ( C_STOPA OR LOCAL_MODES ) AND
            (( G_AUTO AND ( L_REMOTE OR P_NO_LOC ) AND G_STOP ) OR
            ( G_SINGLE AND ( L_REMOTE OR P_NO_LOC ) AND CMND.SINGLE_STOP ) OR
            ( LOCAL_MODES AND (( NOT P_NO_LOC AND L_LOCAL AND NOT L_STOP ) OR ( P_NO_LOC AND CMND.SINGLE_STOP ))));

        F_START :=
            (( C_STRT AND ( C_STRTA OR LOCAL_MODES )) OR F_RUN ) AND         // Start Conditions
            ( I_OPERA OR LOCAL_MODES ) AND                                     // Operation Interlocks
            (( G_AUTO AND ( L_REMOTE OR P_NO_LOC ) AND G_START ) OR            // Start Command in Auto Mode
            ( G_SINGLE AND ( L_REMOTE OR P_NO_LOC ) AND F_OSST1 ) OR // Start Command in Single Mode
            ( LOCAL_MODES AND (( NOT P_NO_LOC AND L_LOCAL AND L_START ) OR ( P_NO_LOC AND F_OSST1 ))) OR F_RUN ) AND // Start Command in Local Modes
            NOT Q_FAULT AND NOT G_QSTOP AND NOT F_STOP;        // Stop Command and Faults


        IF F_START  THEN                                            // START DEVICE
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
                F_RUN  := F_START;
                Q_HORN := FALSE;
            END_IF;
        ELSE                                                                    // STOP DEVICE
            TIMERS[_START].IN := FALSE;
            TIMERS[_STOP].IN  := F_RUN;
            IF NOT G_AUTO OR Q_FAULT OR G_QSTOP OR (G_AUTO AND ( Q_RUN AND NOT I_OPERA )) THEN
                F_RUN  := FALSE;
            ELSIF TIMERS[_STOP].Q THEN
                F_RUN  := FALSE;
            END_IF;
            Q_HORN := FALSE;
        END_IF;

        Q_SIM       := G_SIM OR P_SIM;
        Q_RUN       := F_RUN  AND (LOCAL_MODES OR C_SPRDC );
        Q_ACTIVE    := (G_AUTO OR G_SINGLE) AND F_RUN;
        Q_FDBCK     := Q_ACTIVE AND F_FDBCK;
        Q_LOCALMODE := G_LOCAL AND NOT (G_AUTO OR G_SINGLE);


    //|

    //: "OS_STATUS"
        _D          := DW#16#0;
        _B32.B00    := M_READY;        // Control Center Ready
        _B32.B01    := M_FDBCK;       // Device Running
        _B32.B02    := L_LOCAL;        // Local Box Local Position
        _B32.B03    := L_REMOTE;       // Local Box Remote Position
        _B32.B04    := L_START;       // Local Box Local Start
        _B32.B05    := L_STOP;         // Local Box Local Stop
        _B32.B06    := C_SPRDC;        // Sporadic ON/OFF Command
        _B32.B07    := C_STRT;        // Start Condition
        _B32.B08    := C_STRTA;       // Start Condition (Auto Mode Only)
        _B32.B09    := C_STOPA;        // Stop Condition
        _B32.B10    := I_OPERA;       // Operation Interlok (Auto Mode Only)
        _B32.B11    := I_PROT;         // Protection Interlock
        _B32.B12    := I_PROTA;        // Protection Interlock (Auto Mode Only)
        _B32.B13    := G_START;       // Group Start Command
        _B32.B14    := G_STOP;         // Group Stop Command
        _B32.B15    := G_QSTOP;        // Group Quick Stop Command
        _B32.B16    := G_AUTO;         // Automatic Mode
        _B32.B17    := G_SINGLE;       // Single Mode
        _B32.B18    := G_LOCAL;        // Local Mode
        _B32.B19    := G_SIM;          // Group Simulation Mode
        _B32.B20    := P_ENABLE;       // Device Disabled
        _B32.B21    := P_NO_LOC;       // Local Control Box not Used
        _B32.B22    := P_IS_PLS1;       // Rotation Dedector Pulse Enable
        _B32.B23    := P_SIM;          // Simulation Mode On
        _B32.B24    := NOT P_ENABLE AND CMND.MAINTENANCE_OP; // Maintenance Mode
        _B32.B25    := S_SPEED1;        // Speed Monitor 1 
        _B32.B26    := S_SPEED2;       // Speed Monitor 2 
        _B32.B27    := P_IS_PLS2;      // Rotation Dedector Pulse Enable 2   
        _B32.B28    := S_BELT;         // Belt Drift Switch
        _B32.B29    := S_ROPE;         // Rope Switch
        _B32.B30    := S_LEVEL;        // Level Switch
        OS_STAT1    := _D;

        _D          := DW#16#0;
        _B32.B00    := Q_ACTIVE;       // Device Active
        _B32.B01    := Q_FDBCK;       // Device Running
        _B32.B02    := Q_FAULT;        // Device Fault
        _B32.B03    := Q_RUN;         // Run Command
        _B32.B04    := Q_HORN;         // Horn
        _B32.B05    := Q_SIM;          // Simulation On
        OS_STAT2    := _D;
    //|

    //: "OS_VISU"
        OS_VISU := 1;

        IF G_LOCAL THEN OS_VISU := 5; END_IF;
        IF G_LOCAL AND Q_RUN AND NOT TIMERS[6].Q THEN OS_VISU := 6; END_IF;

        IF G_SINGLE THEN OS_VISU := 7; END_IF;
        IF G_SINGLE AND Q_RUN AND NOT TIMERS[6].Q THEN OS_VISU := 8; END_IF;

        IF G_AUTO AND Q_RUN AND NOT TIMERS[6].Q THEN OS_VISU := 4; END_IF;

        IF NOT P_ENABLE THEN OS_VISU := 0; END_IF;

        IF (NOT P_ENABLE OR G_LOCAL) AND CMND.MAINTENANCE_OP THEN OS_VISU := 9; END_IF;
        IF (NOT P_ENABLE OR G_LOCAL) AND CMND.MAINTENANCE_OP AND Q_RUN AND M_FDBCK THEN OS_VISU := 10; END_IF;

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


