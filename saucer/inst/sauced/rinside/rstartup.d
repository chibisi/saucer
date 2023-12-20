module sauced.rinside.rstartup;

import sauced.r2d;
import core.stdc.stddef;

extern (C):

/* for size_t */
alias R_SIZE_T = size_t;

/* Startup Actions */
enum SA_TYPE
{
    SA_NORESTORE = 0,
    SA_RESTORE = 1,
    SA_DEFAULT = 2,
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
}

alias Rstart = structRstart*;

void R_DefParams (Rstart);
void R_SetParams (Rstart);
void R_SetWin32 (Rstart);
void R_SizeFromEnv (Rstart);
void R_common_command_line (int*, char**, Rstart);

void R_set_command_line_arguments (int argc, char** argv);


