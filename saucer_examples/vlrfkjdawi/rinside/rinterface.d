/*
 *  R : A Computer Language for Statistical Data Analysis
 *  Copyright (C) 1995, 1996  Robert Gentleman and Ross Ihaka
 *  Copyright (C) 1998--2017  The R Core Team.
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, a copy is available at
 *  https://www.R-project.org/Licenses/
 */

module sauced.rinside.rinterface;

import sauced.r2d;
import rinside.rstartup: SA_TYPE;
import core.stdc.config;
import core.stdc.stdio;

extern (C):

/* This header file is to provide hooks for alternative front-ends,
   e.g. GUIs such as GNOME and Cocoa.  It is only used on Unix-alikes.
   All entries here should be documented in doc/manual/R-exts.texi.

   It should not be included by package sources unless they are
   providing such a front-end.

   If CSTACK_DEFNS is defined, also define HAVE_UINTPTR_T (if true)
   before including this, perhaps by including Rconfig.h from C code
   (for C++ you need to test the C++ compiler in use).
*/

/* we do not support DO_NOT_USE_CXX_HEADERS in this file */

/* from Defn.h */
/* this duplication will be removed in due course */

extern __gshared Rboolean R_Interactive; /* TRUE during interactive use*/
extern __gshared Rboolean R_NoEcho; /* do not echo R code */

void R_RestoreGlobalEnv ();
void R_RestoreGlobalEnvFromFile (const(char)*, Rboolean);
void R_SaveGlobalEnv ();
void R_SaveGlobalEnvToFile (const(char)*);
void R_FlushConsole ();
void R_ClearerrConsole ();
void R_Suicide (const(char)*);
char* R_HomeDir ();
extern __gshared int R_DirtyImage; /* Current image dirty */
extern __gshared char* R_GUIType;
void R_setupHistory ();
extern __gshared char* R_HistoryFile; /* Name of the history file */
extern __gshared int R_HistorySize; /* Size of the history file */
extern __gshared int R_RestoreHistory; /* restore the history file? */
extern __gshared char* R_Home; /* Root of the R tree */

alias jump_to_toplevel = Rf_jump_to_toplevel;
alias mainloop = Rf_mainloop;
alias onintr = Rf_onintr;
alias onintrNoResume = Rf_onintrNoResume;

void Rf_jump_to_toplevel ();
void Rf_mainloop ();
void Rf_onintr ();
void Rf_onintrNoResume ();

extern __gshared void* R_GlobalContext; /* Need opaque pointer type for export */

void process_site_Renviron ();
void process_system_Renviron ();
void process_user_Renviron ();

extern __gshared sauced.r2d.FILE* R_Consolefile;
extern __gshared sauced.r2d.FILE* R_Outputfile;

/* in ../unix/sys-unix.c */
void R_setStartTime ();
void fpu_setup (Rboolean);

/* in ../unix/system.c */
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

// added in 3.0.0
extern __gshared int function (int, const(char*)*, const(char*)*, const(char)*) ptr_R_EditFiles;
// naming follows earlier versions in R.app
extern __gshared SEXP function (SEXP, SEXP, SEXP, SEXP) ptr_do_selectlist;
extern __gshared SEXP function (SEXP, SEXP, SEXP, SEXP) ptr_do_dataentry;
extern __gshared SEXP function (SEXP, SEXP, SEXP, SEXP) ptr_do_dataviewer;
extern __gshared void function () ptr_R_ProcessEvents;

/* These two are not used by R itself, but are used by the tcltk package */
extern __gshared int function () R_timeout_handler;
extern __gshared c_long R_timeout_val;



extern __gshared int R_SignalHandlers;


