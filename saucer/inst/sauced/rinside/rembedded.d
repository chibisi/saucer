module sauced.rinside.rembedded;

import sauced.r2d;

extern (C):

int Rf_initEmbeddedR (int argc, char** argv);
void Rf_endEmbeddedR (int fatal);

int Rf_initialize_R (int ac, char** av);
void setup_Rmainloop ();
void R_ReplDLLinit ();
int R_ReplDLLdo1 ();

void R_setStartTime ();
void R_RunExitFinalizers ();
void CleanEd ();
void Rf_KillAllDevices ();
extern __gshared int R_DirtyImage;
void R_CleanTempDir ();
extern __gshared char* R_TempDir;
void R_SaveGlobalEnv ();

void fpu_setup (Rboolean start);

