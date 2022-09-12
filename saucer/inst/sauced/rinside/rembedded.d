/*
 *  R : A Computer Language for Statistical Data Analysis
 *  Copyright (C) 2006-2016  The R Core Team.
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

/* A header for use with alternative front-ends. Not formally part of
 * the API so subject to change without notice. */

module sauced.rinside.rembedded;

import sauced.r2d;

extern (C):

int Rf_initEmbeddedR (int argc, char** argv);
void Rf_endEmbeddedR (int fatal);

/* From here on down can be helpful in writing tailored startup and
   termination code */

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

/* REMBEDDED_H_ */
