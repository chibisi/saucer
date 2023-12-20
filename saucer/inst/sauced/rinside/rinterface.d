module sauced.rinside.rinterface;

import sauced.r2d;
import rinside.rstartup: SA_TYPE;
import core.stdc.config;
import core.stdc.stdio;

extern (C):


extern __gshared Rboolean R_Interactive;
extern __gshared Rboolean R_NoEcho; 

void R_RestoreGlobalEnv ();
void R_RestoreGlobalEnvFromFile (const(char)*, Rboolean);
void R_SaveGlobalEnv ();
void R_SaveGlobalEnvToFile (const(char)*);
void R_FlushConsole ();
void R_ClearerrConsole ();
void R_Suicide (const(char)*);
char* R_HomeDir ();
extern __gshared int R_DirtyImage; 
extern __gshared char* R_GUIType;
void R_setupHistory ();
extern __gshared char* R_HistoryFile;
extern __gshared int R_HistorySize;
extern __gshared int R_RestoreHistory;
extern __gshared char* R_Home;

alias jump_to_toplevel = Rf_jump_to_toplevel;
alias mainloop = Rf_mainloop;
alias onintr = Rf_onintr;
alias onintrNoResume = Rf_onintrNoResume;

void Rf_jump_to_toplevel ();
void Rf_mainloop ();
void Rf_onintr ();
void Rf_onintrNoResume ();

extern __gshared void* R_GlobalContext;

void process_site_Renviron ();
void process_system_Renviron ();
void process_user_Renviron ();

extern __gshared sauced.r2d.FILE* R_Consolefile;
extern __gshared sauced.r2d.FILE* R_Outputfile;

void R_setStartTime ();
void fpu_setup (Rboolean);

extern __gshared int R_running_as_main_program;

extern __gshared void function (const(char)*) ptr_R_Suicide;
extern __gshared void function (const(char)*) ptr_R_ShowMessage;
extern __gshared int function (const(char)*, ubyte*, int, int) ptr_R_ReadConsole;
extern __gshared void function (const(char)*, int) ptr_R_WriteConsole;
extern __gshared void function (const(char)*, int, int) ptr_R_WriteConsoleEx;
extern __gshared void function () ptr_R_ResetConsole;
extern __gshared void function () ptr_R_FlushConsole;
extern __gshared void function () ptr_R_ClearerrConsole;
extern __gshared void function (int) ptr_R_Busy;
extern __gshared void function (SA_TYPE, int, int) ptr_R_CleanUp;
extern __gshared int function (int, const(char*)*, const(char*)*, const(char)*, Rboolean, const(char)*) ptr_R_ShowFiles;
extern __gshared int function (int, char*, int) ptr_R_ChooseFile;
extern __gshared int function (const(char)*) ptr_R_EditFile;
extern __gshared void function (SEXP, SEXP, SEXP, SEXP) ptr_R_loadhistory;
extern __gshared void function (SEXP, SEXP, SEXP, SEXP) ptr_R_savehistory;
extern __gshared void function (SEXP, SEXP, SEXP, SEXP) ptr_R_addhistory;


extern __gshared int function (int, const(char*)*, const(char*)*, const(char)*) ptr_R_EditFiles;

extern __gshared SEXP function (SEXP, SEXP, SEXP, SEXP) ptr_do_selectlist;
extern __gshared SEXP function (SEXP, SEXP, SEXP, SEXP) ptr_do_dataentry;
extern __gshared SEXP function (SEXP, SEXP, SEXP, SEXP) ptr_do_dataviewer;
extern __gshared void function () ptr_R_ProcessEvents;

extern __gshared int function () R_timeout_handler;
extern __gshared c_long R_timeout_val;



extern __gshared int R_SignalHandlers;


