/*
 *  R : A Computer Language for Statistical Data Analysis
 *  Copyright (C) 1999-2020  The R Core Team
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

/*
  C functions to be called from alternative front-ends.

  Part of the API for such front-ends but not for packages.
*/

module sauced.rinside.rstartup;

import sauced.r2d;
import core.stdc.stddef;

extern (C):

/* for size_t */
alias R_SIZE_T = size_t;

/* TRUE/FALSE */

/* Return value here is expected to be 1 for Yes, -1 for No and 0 for Cancel:
   symbolic constants in graphapp.h */

/* Startup Actions */
enum SA_TYPE
{
    SA_NORESTORE = 0, /* = 0 */
    SA_RESTORE = 1,
    SA_DEFAULT = 2, /* was === SA_RESTORE */
    SA_NOSAVE = 3,
    SA_SAVE = 4,
    SA_SAVEASK = 5,
    SA_SUICIDE = 6
}

struct structRstart
{
    Rboolean R_Quiet;
    Rboolean R_NoEcho;
    Rboolean R_Interactive;
    Rboolean R_Verbose;
    Rboolean LoadSiteFile;
    Rboolean LoadInitFile;
    Rboolean DebugInitFile;
    SA_TYPE RestoreAction;
    SA_TYPE SaveAction;
    size_t vsize;
    size_t nsize;
    size_t max_vsize;
    size_t max_nsize;
    size_t ppsize;
    int NoRenviron;

    /* R_HOME */
    /* HOME  */

    /* used only if WriteConsole is NULL */

    /* R may embed UTF-8 sections into strings otherwise in current native
    	   encoding, escaped by UTF8in and UTF8out (rgui_UTF8.h). The setting
    	   currently has no effect in Rgui (always enabled) and in Rterm (never
    	   enabled).
    	*/
}

alias Rstart = structRstart*;

void R_DefParams (Rstart);
void R_SetParams (Rstart);
void R_SetWin32 (Rstart);
void R_SizeFromEnv (Rstart);
void R_common_command_line (int*, char**, Rstart);

void R_set_command_line_arguments (int argc, char** argv);


