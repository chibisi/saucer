module sauced.r2d;

import core.stdc.config;
import core.stdc.stddef;
import core.stdc.stdarg;

extern (C):

@nogc:

alias _Float128 = void*;
alias size_t = c_ulong;
alias wchar_t = int;

enum idtype_t
{
    P_ALL = 0,
    P_PID = 1,
    P_PGID = 2
}

struct div_t
{
    int quot;
    int rem;
}

struct ldiv_t
{
    c_long quot;
    c_long rem;
}

struct lldiv_t
{
    long quot;
    long rem;
}

size_t __ctype_get_mb_cur_max ();
double atof (const(char)* __nptr);
int atoi (const(char)* __nptr);
c_long atol (const(char)* __nptr);
long atoll (const(char)* __nptr);
double strtod (const(char)* __nptr, char** __endptr);
float strtof (const(char)* __nptr, char** __endptr);
real strtold (const(char)* __nptr, char** __endptr);
c_long strtol (const(char)* __nptr, char** __endptr, int __base);
c_ulong strtoul (const(char)* __nptr, char** __endptr, int __base);

long strtoq (const(char)* __nptr, char** __endptr, int __base);

ulong strtouq (const(char)* __nptr, char** __endptr, int __base);

long strtoll (const(char)* __nptr, char** __endptr, int __base);

ulong strtoull (const(char)* __nptr, char** __endptr, int __base);
char* l64a (c_long __n);
c_long a64l (const(char)* __s);

alias __u_char = ubyte;
alias __u_short = ushort;
alias __u_int = uint;
alias __u_long = c_ulong;
alias __int8_t = byte;
alias __uint8_t = ubyte;
alias __int16_t = short;
alias __uint16_t = ushort;
alias __int32_t = int;
alias __uint32_t = uint;
alias __int64_t = c_long;
alias __uint64_t = c_ulong;
alias __int_least8_t = byte;
alias __uint_least8_t = ubyte;
alias __int_least16_t = short;
alias __uint_least16_t = ushort;
alias __int_least32_t = int;
alias __uint_least32_t = uint;
alias __int_least64_t = c_long;
alias __uint_least64_t = c_ulong;
alias __quad_t = c_long;
alias __u_quad_t = c_ulong;
alias __intmax_t = c_long;
alias __uintmax_t = c_ulong;
alias __dev_t = c_ulong;
alias __uid_t = uint;
alias __gid_t = uint;
alias __ino_t = c_ulong;
alias __ino64_t = c_ulong;
alias __mode_t = uint;
alias __nlink_t = c_ulong;
alias __off_t = c_long;
alias __off64_t = c_long;
alias __pid_t = int;

struct __fsid_t
{
    int[2] __val;
}

alias __clock_t = c_long;
alias __rlim_t = c_ulong;
alias __rlim64_t = c_ulong;
alias __id_t = uint;
alias __time_t = c_long;
alias __useconds_t = uint;
alias __suseconds_t = c_long;
alias __daddr_t = int;
alias __key_t = int;
alias __clockid_t = int;
alias __timer_t = void*;
alias __blksize_t = c_long;
alias __blkcnt_t = c_long;
alias __blkcnt64_t = c_long;
alias __fsblkcnt_t = c_ulong;
alias __fsblkcnt64_t = c_ulong;
alias __fsfilcnt_t = c_ulong;
alias __fsfilcnt64_t = c_ulong;
alias __fsword_t = c_long;
alias __ssize_t = c_long;
alias __syscall_slong_t = c_long;
alias __syscall_ulong_t = c_ulong;
alias __loff_t = c_long;
alias __caddr_t = char*;
alias __intptr_t = c_long;
alias __socklen_t = uint;
alias __sig_atomic_t = int;
alias u_char = ubyte;
alias u_short = ushort;
alias u_int = uint;
alias u_long = c_ulong;
alias quad_t = c_long;
alias u_quad_t = c_ulong;
alias fsid_t = __fsid_t;
alias loff_t = c_long;
alias ino_t = c_ulong;
alias dev_t = c_ulong;
alias gid_t = uint;
alias mode_t = uint;
alias nlink_t = c_ulong;
alias uid_t = uint;
alias off_t = c_long;
alias pid_t = int;
alias id_t = uint;
alias ssize_t = c_long;
alias daddr_t = int;
alias caddr_t = char*;
alias key_t = int;
alias clock_t = c_long;
alias clockid_t = int;
alias time_t = c_long;
alias timer_t = void*;
alias ulong_ = c_ulong;
alias u_int8_t = ubyte;
alias u_int16_t = ushort;
alias u_int32_t = uint;
alias u_int64_t = c_ulong;
alias register_t = c_long;
__uint16_t __bswap_16 (__uint16_t __bsx);
__uint32_t __bswap_32 (__uint32_t __bsx);
__uint64_t __bswap_64 (__uint64_t __bsx);
__uint16_t __uint16_identity (__uint16_t __x);
__uint32_t __uint32_identity (__uint32_t __x);
__uint64_t __uint64_identity (__uint64_t __x);

struct __sigset_t
{
    c_ulong[16] __val;
}

alias sigset_t = __sigset_t;

struct timeval
{
    __time_t tv_sec;
    __suseconds_t tv_usec;
}

struct timespec
{
    __time_t tv_sec;
    __syscall_slong_t tv_nsec;
}

alias suseconds_t = c_long;
alias __fd_mask = c_long;

struct fd_set
{
    __fd_mask[16] __fds_bits;
}

alias fd_mask = c_long;

int select (
    int __nfds,
    fd_set* __readfds,
    fd_set* __writefds,
    fd_set* __exceptfds,
    timeval* __timeout);
int pselect (
    int __nfds,
    fd_set* __readfds,
    fd_set* __writefds,
    fd_set* __exceptfds,
    const(timespec)* __timeout,
    const(__sigset_t)* __sigmask);

alias blksize_t = c_long;
alias blkcnt_t = c_long;
alias fsblkcnt_t = c_ulong;
alias fsfilcnt_t = c_ulong;

struct __pthread_internal_list
{
    __pthread_internal_list* __prev;
    __pthread_internal_list* __next;
}

alias __pthread_list_t = __pthread_internal_list;

struct __pthread_internal_slist
{
    __pthread_internal_slist* __next;
}

alias __pthread_slist_t = __pthread_internal_slist;

struct __pthread_mutex_s
{
    int __lock;
    uint __count;
    int __owner;
    uint __nusers;
    int __kind;
    short __spins;
    short __elision;
    __pthread_list_t __list;
}

struct __pthread_rwlock_arch_t
{
    uint __readers;
    uint __writers;
    uint __wrphase_futex;
    uint __writers_futex;
    uint __pad3;
    uint __pad4;
    int __cur_writer;
    int __shared;
    byte __rwelision;
    ubyte[7] __pad1;
    c_ulong __pad2;
    uint __flags;
}

struct __pthread_cond_s
{
    union
    {
        ulong __wseq;

        struct _Anonymous_0
        {
            uint __low;
            uint __high;
        }

        _Anonymous_0 __wseq32;
    }

    union
    {
        ulong __g1_start;

        struct _Anonymous_1
        {
            uint __low;
            uint __high;
        }

        _Anonymous_1 __g1_start32;
    }

    uint[2] __g_refs;
    uint[2] __g_size;
    uint __g1_orig_size;
    uint __wrefs;
    uint[2] __g_signals;
}

alias pthread_t = c_ulong;

union pthread_mutexattr_t
{
    char[4] __size;
    int __align;
}

union pthread_condattr_t
{
    char[4] __size;
    int __align;
}

alias pthread_key_t = uint;
alias pthread_once_t = int;

union pthread_attr_t
{
    char[56] __size;
    c_long __align;
}

union pthread_mutex_t
{
    __pthread_mutex_s __data;
    char[40] __size;
    c_long __align;
}

union pthread_cond_t
{
    __pthread_cond_s __data;
    char[48] __size;
    long __align;
}

union pthread_rwlock_t
{
    __pthread_rwlock_arch_t __data;
    char[56] __size;
    c_long __align;
}

union pthread_rwlockattr_t
{
    char[8] __size;
    c_long __align;
}

alias pthread_spinlock_t = int;

union pthread_barrier_t
{
    char[32] __size;
    c_long __align;
}

union pthread_barrierattr_t
{
    char[4] __size;
    int __align;
}

c_long random ();
void srandom (uint __seed);
char* initstate (uint __seed, char* __statebuf, size_t __statelen);
char* setstate (char* __statebuf);

struct random_data
{
    int* fptr;
    int* rptr;
    int* state;
    int rand_type;
    int rand_deg;
    int rand_sep;
    int* end_ptr;
}

int random_r (random_data* __buf, int* __result);
int srandom_r (uint __seed, random_data* __buf);
int initstate_r (
    uint __seed,
    char* __statebuf,
    size_t __statelen,
    random_data* __buf);
int setstate_r (char* __statebuf, random_data* __buf);
int rand ();
void srand (uint __seed);
int rand_r (uint* __seed);
double drand48 ();
double erand48 (ref ushort[3] __xsubi);
c_long lrand48 ();
c_long nrand48 (ref ushort[3] __xsubi);
c_long mrand48 ();
c_long jrand48 (ref ushort[3] __xsubi);
void srand48 (c_long __seedval);
ushort* seed48 (ref ushort[3] __seed16v);
void lcong48 (ref ushort[7] __param);

struct drand48_data
{
    ushort[3] __x;
    ushort[3] __old_x;
    ushort __c;
    ushort __init;
    ulong __a;
}

int drand48_r (drand48_data* __buffer, double* __result);
int erand48_r (ref ushort[3] __xsubi, drand48_data* __buffer, double* __result);
int lrand48_r (drand48_data* __buffer, c_long* __result);
int nrand48_r (ref ushort[3] __xsubi, drand48_data* __buffer, c_long* __result);
int mrand48_r (drand48_data* __buffer, c_long* __result);
int jrand48_r (ref ushort[3] __xsubi, drand48_data* __buffer, c_long* __result);
int srand48_r (c_long __seedval, drand48_data* __buffer);
int seed48_r (ref ushort[3] __seed16v, drand48_data* __buffer);
int lcong48_r (ref ushort[7] __param, drand48_data* __buffer);
void* malloc (size_t __size);
void* calloc (size_t __nmemb, size_t __size);
void* realloc (void* __ptr, size_t __size);
void* reallocarray (void* __ptr, size_t __nmemb, size_t __size);
void free (void* __ptr);

void* alloca (size_t __size);

void* valloc (size_t __size);
int posix_memalign (void** __memptr, size_t __alignment, size_t __size);
void* aligned_alloc (size_t __alignment, size_t __size);
void abort ();
int atexit (void function () __func);
int at_quick_exit (void function () __func);
int on_exit (void function (int __status, void* __arg) __func, void* __arg);
void exit (int __status);
void quick_exit (int __status);
void _Exit (int __status);
char* getenv (const(char)* __name);
int putenv (char* __string);
int setenv (const(char)* __name, const(char)* __value, int __replace);
int unsetenv (const(char)* __name);
int clearenv ();
char* mktemp (char* __template);
int mkstemp (char* __template);
int mkstemps (char* __template, int __suffixlen);
char* mkdtemp (char* __template);
int system (const(char)* __command);
char* realpath (const(char)* __name, char* __resolved);
alias __compar_fn_t = int function (const(void)*, const(void)*);
void* bsearch (
    const(void)* __key,
    const(void)* __base,
    size_t __nmemb,
    size_t __size,
    __compar_fn_t __compar);
void qsort (
    void* __base,
    size_t __nmemb,
    size_t __size,
    __compar_fn_t __compar);
int abs (int __x);
c_long labs (c_long __x);
long llabs (long __x);
div_t div (int __numer, int __denom);
ldiv_t ldiv (c_long __numer, c_long __denom);
lldiv_t lldiv (long __numer, long __denom);
char* ecvt (double __value, int __ndigit, int* __decpt, int* __sign);
char* fcvt (double __value, int __ndigit, int* __decpt, int* __sign);
char* gcvt (double __value, int __ndigit, char* __buf);
char* qecvt (real __value, int __ndigit, int* __decpt, int* __sign);
char* qfcvt (real __value, int __ndigit, int* __decpt, int* __sign);
char* qgcvt (real __value, int __ndigit, char* __buf);
int ecvt_r (
    double __value,
    int __ndigit,
    int* __decpt,
    int* __sign,
    char* __buf,
    size_t __len);
int fcvt_r (
    double __value,
    int __ndigit,
    int* __decpt,
    int* __sign,
    char* __buf,
    size_t __len);
int qecvt_r (
    real __value,
    int __ndigit,
    int* __decpt,
    int* __sign,
    char* __buf,
    size_t __len);
int qfcvt_r (
    real __value,
    int __ndigit,
    int* __decpt,
    int* __sign,
    char* __buf,
    size_t __len);
int mblen (const(char)* __s, size_t __n);
int mbtowc (wchar_t* __pwc, const(char)* __s, size_t __n);
int wctomb (char* __s, wchar_t __wchar);
size_t mbstowcs (wchar_t* __pwcs, const(char)* __s, size_t __n);
size_t wcstombs (char* __s, const(wchar_t)* __pwcs, size_t __n);
int rpmatch (const(char)* __response);
int getsubopt (char** __optionp, char** __tokens, char** __valuep);
int getloadavg (double* __loadavg, int __nelem);

alias __gnuc_va_list = __va_list_tag[1];

struct __mbstate_t
{
    int __count;

    union _Anonymous_2
    {
        uint __wch;
        char[4] __wchb;
    }

    _Anonymous_2 __value;
}

struct _G_fpos_t
{
    __off_t __pos;
    __mbstate_t __state;
}

alias __fpos_t = _G_fpos_t;

struct _G_fpos64_t
{
    __off64_t __pos;
    __mbstate_t __state;
}

alias __fpos64_t = _G_fpos64_t;

alias __FILE = _IO_FILE;

alias FILE = _IO_FILE;

struct _IO_marker;
struct _IO_codecvt;
struct _IO_wide_data;
alias _IO_lock_t = void;

struct _IO_FILE
{
    int _flags;
    char* _IO_read_ptr;
    char* _IO_read_end;
    char* _IO_read_base;
    char* _IO_write_base;
    char* _IO_write_ptr;
    char* _IO_write_end;
    char* _IO_buf_base;
    char* _IO_buf_end;
    char* _IO_save_base;
    char* _IO_backup_base;
    char* _IO_save_end;
    _IO_marker* _markers;
    _IO_FILE* _chain;
    int _fileno;
    int _flags2;
    __off_t _old_offset;
    ushort _cur_column;
    byte _vtable_offset;
    char[1] _shortbuf;
    _IO_lock_t* _lock;
    __off64_t _offset;
    _IO_codecvt* _codecvt;
    _IO_wide_data* _wide_data;
    _IO_FILE* _freeres_list;
    void* _freeres_buf;
    size_t __pad5;
    int _mode;
    char[20] _unused2;
}

alias va_list = __va_list_tag[1];
alias fpos_t = _G_fpos_t;
extern __gshared FILE* stdin;
extern __gshared FILE* stdout;
extern __gshared FILE* stderr;
int remove (const(char)* __filename);
int rename (const(char)* __old, const(char)* __new);
int renameat (int __oldfd, const(char)* __old, int __newfd, const(char)* __new);
FILE* tmpfile ();
char* tmpnam (char* __s);
char* tmpnam_r (char* __s);
char* tempnam (const(char)* __dir, const(char)* __pfx);
int fclose (FILE* __stream);
int fflush (FILE* __stream);
int fflush_unlocked (FILE* __stream);
FILE* fopen (const(char)* __filename, const(char)* __modes);
FILE* freopen (const(char)* __filename, const(char)* __modes, FILE* __stream);
FILE* fdopen (int __fd, const(char)* __modes);
FILE* fmemopen (void* __s, size_t __len, const(char)* __modes);
FILE* open_memstream (char** __bufloc, size_t* __sizeloc);
void setbuf (FILE* __stream, char* __buf);
int setvbuf (FILE* __stream, char* __buf, int __modes, size_t __n);
void setbuffer (FILE* __stream, char* __buf, size_t __size);
void setlinebuf (FILE* __stream);
int fprintf (FILE* __stream, const(char)* __format, ...);
int printf (const(char)* __format, ...);
int sprintf (char* __s, const(char)* __format, ...);
int vfprintf (FILE* __s, const(char)* __format, __gnuc_va_list __arg);
int vprintf (const(char)* __format, __gnuc_va_list __arg);
int vsprintf (char* __s, const(char)* __format, __gnuc_va_list __arg);
int snprintf (char* __s, size_t __maxlen, const(char)* __format, ...);
int vsnprintf (
    char* __s,
    size_t __maxlen,
    const(char)* __format,
    __gnuc_va_list __arg);
int vdprintf (int __fd, const(char)* __fmt, __gnuc_va_list __arg);
int dprintf (int __fd, const(char)* __fmt, ...);
int fscanf (FILE* __stream, const(char)* __format, ...);
int scanf (const(char)* __format, ...);
int sscanf (const(char)* __s, const(char)* __format, ...);
int fscanf (FILE* __stream, const(char)* __format, ...);
int scanf (const(char)* __format, ...);
int sscanf (const(char)* __s, const(char)* __format, ...);
int vfscanf (FILE* __s, const(char)* __format, __gnuc_va_list __arg);
int vscanf (const(char)* __format, __gnuc_va_list __arg);
int vsscanf (const(char)* __s, const(char)* __format, __gnuc_va_list __arg);
int vfscanf (FILE* __s, const(char)* __format, __gnuc_va_list __arg);
int vscanf (const(char)* __format, __gnuc_va_list __arg);
int vsscanf (const(char)* __s, const(char)* __format, __gnuc_va_list __arg);
int fgetc (FILE* __stream);
int getc (FILE* __stream);
int getchar ();
int getc_unlocked (FILE* __stream);
int getchar_unlocked ();
int fgetc_unlocked (FILE* __stream);
int fputc (int __c, FILE* __stream);
int putc (int __c, FILE* __stream);
int putchar (int __c);
int fputc_unlocked (int __c, FILE* __stream);
int putc_unlocked (int __c, FILE* __stream);
int putchar_unlocked (int __c);
int getw (FILE* __stream);
int putw (int __w, FILE* __stream);
char* fgets (char* __s, int __n, FILE* __stream);

__ssize_t __getdelim (
    char** __lineptr,
    size_t* __n,
    int __delimiter,
    FILE* __stream);
__ssize_t getdelim (
    char** __lineptr,
    size_t* __n,
    int __delimiter,
    FILE* __stream);
__ssize_t getline (char** __lineptr, size_t* __n, FILE* __stream);
int fputs (const(char)* __s, FILE* __stream);
int puts (const(char)* __s);
int ungetc (int __c, FILE* __stream);
c_ulong fread (void* __ptr, size_t __size, size_t __n, FILE* __stream);
c_ulong fwrite (const(void)* __ptr, size_t __size, size_t __n, FILE* __s);
size_t fread_unlocked (void* __ptr, size_t __size, size_t __n, FILE* __stream);
size_t fwrite_unlocked (
    const(void)* __ptr,
    size_t __size,
    size_t __n,
    FILE* __stream);
int fseek (FILE* __stream, c_long __off, int __whence);
c_long ftell (FILE* __stream);
void rewind (FILE* __stream);
int fseeko (FILE* __stream, __off_t __off, int __whence);
__off_t ftello (FILE* __stream);
int fgetpos (FILE* __stream, fpos_t* __pos);
int fsetpos (FILE* __stream, const(fpos_t)* __pos);
void clearerr (FILE* __stream);
int feof (FILE* __stream);
int ferror (FILE* __stream);
void clearerr_unlocked (FILE* __stream);
int feof_unlocked (FILE* __stream);
int ferror_unlocked (FILE* __stream);
void perror (const(char)* __s);
extern __gshared int sys_nerr;
extern __gshared const(char*)[] sys_errlist;
int fileno (FILE* __stream);
int fileno_unlocked (FILE* __stream);
FILE* popen (const(char)* __command, const(char)* __modes);
int pclose (FILE* __stream);
char* ctermid (char* __s);
void flockfile (FILE* __stream);
int ftrylockfile (FILE* __stream);
void funlockfile (FILE* __stream);
int __uflow (FILE*);
int __overflow (FILE*, int);

alias float_t = float;
alias double_t = double;
int __fpclassify (double __value);
int __signbit (double __value);
int __isinf (double __value);
int __finite (double __value);
int __isnan (double __value);
int __iseqsig (double __x, double __y);
int __issignaling (double __value);
double acos (double __x);
double __acos (double __x);
double asin (double __x);
double __asin (double __x);
double atan (double __x);
double __atan (double __x);
double atan2 (double __y, double __x);
double __atan2 (double __y, double __x);
double cos (double __x);
double __cos (double __x);
double sin (double __x);
double __sin (double __x);
double tan (double __x);
double __tan (double __x);
double cosh (double __x);
double __cosh (double __x);
double sinh (double __x);
double __sinh (double __x);
double tanh (double __x);
double __tanh (double __x);
double acosh (double __x);
double __acosh (double __x);
double asinh (double __x);
double __asinh (double __x);
double atanh (double __x);
double __atanh (double __x);
double exp (double __x);
double __exp (double __x);
double frexp (double __x, int* __exponent);
double __frexp (double __x, int* __exponent);
double ldexp (double __x, int __exponent);
double __ldexp (double __x, int __exponent);
double log (double __x);
double __log (double __x);
double log10 (double __x);
double __log10 (double __x);
double modf (double __x, double* __iptr);
double __modf (double __x, double* __iptr);
double exp10 (double __x);
double __exp10 (double __x);
double expm1 (double __x);
double __expm1 (double __x);
double log1p (double __x);
double __log1p (double __x);
double logb (double __x);
double __logb (double __x);
double exp2 (double __x);
double __exp2 (double __x);
double log2 (double __x);
double __log2 (double __x);
double pow (double __x, double __y);
double __pow (double __x, double __y);
double sqrt (double __x);
double __sqrt (double __x);
double hypot (double __x, double __y);
double __hypot (double __x, double __y);
double cbrt (double __x);
double __cbrt (double __x);
double ceil (double __x);
double __ceil (double __x);
double fabs (double __x);
double __fabs (double __x);
double floor (double __x);
double __floor (double __x);
double fmod (double __x, double __y);
double __fmod (double __x, double __y);
int isinf (double __value);
int finite (double __value);
double drem (double __x, double __y);
double __drem (double __x, double __y);
double significand (double __x);
double __significand (double __x);
double copysign (double __x, double __y);
double __copysign (double __x, double __y);
double nan (const(char)* __tagb);
double __nan (const(char)* __tagb);
int isnan (double __value);
double j0 (double);
double __j0 (double);
double j1 (double);
double __j1 (double);
double jn (int, double);
double __jn (int, double);
double y0 (double);
double __y0 (double);
double y1 (double);
double __y1 (double);
double yn (int, double);
double __yn (int, double);
double erf (double);
double __erf (double);
double erfc (double);
double __erfc (double);
double lgamma (double);
double __lgamma (double);
double tgamma (double);
double __tgamma (double);
double gamma (double);
double __gamma (double);
double lgamma_r (double, int* __signgamp);
double __lgamma_r (double, int* __signgamp);
double rint (double __x);
double __rint (double __x);
double nextafter (double __x, double __y);
double __nextafter (double __x, double __y);
double nexttoward (double __x, real __y);
double __nexttoward (double __x, real __y);
double remainder (double __x, double __y);
double __remainder (double __x, double __y);
double scalbn (double __x, int __n);
double __scalbn (double __x, int __n);
int ilogb (double __x);
int __ilogb (double __x);
double scalbln (double __x, c_long __n);
double __scalbln (double __x, c_long __n);
double nearbyint (double __x);
double __nearbyint (double __x);
double round (double __x);
double __round (double __x);
double trunc (double __x);
double __trunc (double __x);
double remquo (double __x, double __y, int* __quo);
double __remquo (double __x, double __y, int* __quo);
c_long lrint (double __x);
c_long __lrint (double __x);

long llrint (double __x);
long __llrint (double __x);
c_long lround (double __x);
c_long __lround (double __x);

long llround (double __x);
long __llround (double __x);
double fdim (double __x, double __y);
double __fdim (double __x, double __y);
double fmax (double __x, double __y);
double __fmax (double __x, double __y);
double fmin (double __x, double __y);
double __fmin (double __x, double __y);
double fma (double __x, double __y, double __z);
double __fma (double __x, double __y, double __z);
double scalb (double __x, double __n);
double __scalb (double __x, double __n);
int __fpclassifyf (float __value);
int __signbitf (float __value);
int __isinff (float __value);
int __finitef (float __value);
int __isnanf (float __value);
int __iseqsigf (float __x, float __y);
int __issignalingf (float __value);
float acosf (float __x);
float __acosf (float __x);
float asinf (float __x);
float __asinf (float __x);
float atanf (float __x);
float __atanf (float __x);
float atan2f (float __y, float __x);
float __atan2f (float __y, float __x);
float cosf (float __x);
float __cosf (float __x);
float sinf (float __x);
float __sinf (float __x);
float tanf (float __x);
float __tanf (float __x);
float coshf (float __x);
float __coshf (float __x);
float sinhf (float __x);
float __sinhf (float __x);
float tanhf (float __x);
float __tanhf (float __x);
float acoshf (float __x);
float __acoshf (float __x);
float asinhf (float __x);
float __asinhf (float __x);
float atanhf (float __x);
float __atanhf (float __x);
float expf (float __x);
float __expf (float __x);
float frexpf (float __x, int* __exponent);
float __frexpf (float __x, int* __exponent);
float ldexpf (float __x, int __exponent);
float __ldexpf (float __x, int __exponent);
float logf (float __x);
float __logf (float __x);
float log10f (float __x);
float __log10f (float __x);
float modff (float __x, float* __iptr);
float __modff (float __x, float* __iptr);
float exp10f (float __x);
float __exp10f (float __x);
float expm1f (float __x);
float __expm1f (float __x);
float log1pf (float __x);
float __log1pf (float __x);
float logbf (float __x);
float __logbf (float __x);
float exp2f (float __x);
float __exp2f (float __x);
float log2f (float __x);
float __log2f (float __x);
float powf (float __x, float __y);
float __powf (float __x, float __y);
float sqrtf (float __x);
float __sqrtf (float __x);
float hypotf (float __x, float __y);
float __hypotf (float __x, float __y);
float cbrtf (float __x);
float __cbrtf (float __x);
float ceilf (float __x);
float __ceilf (float __x);
float fabsf (float __x);
float __fabsf (float __x);
float floorf (float __x);
float __floorf (float __x);
float fmodf (float __x, float __y);
float __fmodf (float __x, float __y);
int isinff (float __value);
int finitef (float __value);
float dremf (float __x, float __y);
float __dremf (float __x, float __y);
float significandf (float __x);
float __significandf (float __x);
float copysignf (float __x, float __y);
float __copysignf (float __x, float __y);
float nanf (const(char)* __tagb);
float __nanf (const(char)* __tagb);
int isnanf (float __value);
float j0f (float);
float __j0f (float);
float j1f (float);
float __j1f (float);
float jnf (int, float);
float __jnf (int, float);
float y0f (float);
float __y0f (float);
float y1f (float);
float __y1f (float);
float ynf (int, float);
float __ynf (int, float);
float erff (float);
float __erff (float);
float erfcf (float);
float __erfcf (float);
float lgammaf (float);
float __lgammaf (float);
float tgammaf (float);
float __tgammaf (float);
float gammaf (float);
float __gammaf (float);
float lgammaf_r (float, int* __signgamp);
float __lgammaf_r (float, int* __signgamp);
float rintf (float __x);
float __rintf (float __x);
float nextafterf (float __x, float __y);
float __nextafterf (float __x, float __y);
float nexttowardf (float __x, real __y);
float __nexttowardf (float __x, real __y);
float remainderf (float __x, float __y);
float __remainderf (float __x, float __y);
float scalbnf (float __x, int __n);
float __scalbnf (float __x, int __n);
int ilogbf (float __x);
int __ilogbf (float __x);
float scalblnf (float __x, c_long __n);
float __scalblnf (float __x, c_long __n);
float nearbyintf (float __x);
float __nearbyintf (float __x);
float roundf (float __x);
float __roundf (float __x);
float truncf (float __x);
float __truncf (float __x);
float remquof (float __x, float __y, int* __quo);
float __remquof (float __x, float __y, int* __quo);
c_long lrintf (float __x);
c_long __lrintf (float __x);

long llrintf (float __x);
long __llrintf (float __x);
c_long lroundf (float __x);
c_long __lroundf (float __x);

long llroundf (float __x);
long __llroundf (float __x);
float fdimf (float __x, float __y);
float __fdimf (float __x, float __y);
float fmaxf (float __x, float __y);
float __fmaxf (float __x, float __y);
float fminf (float __x, float __y);
float __fminf (float __x, float __y);
float fmaf (float __x, float __y, float __z);
float __fmaf (float __x, float __y, float __z);
float scalbf (float __x, float __n);
float __scalbf (float __x, float __n);
int __fpclassifyl (real __value);
int __signbitl (real __value);
int __isinfl (real __value);
int __finitel (real __value);
int __isnanl (real __value);
int __iseqsigl (real __x, real __y);
int __issignalingl (real __value);
real acosl (real __x);
real __acosl (real __x);
real asinl (real __x);
real __asinl (real __x);
real atanl (real __x);
real __atanl (real __x);
real atan2l (real __y, real __x);
real __atan2l (real __y, real __x);
real cosl (real __x);
real __cosl (real __x);
real sinl (real __x);
real __sinl (real __x);
real tanl (real __x);
real __tanl (real __x);
real coshl (real __x);
real __coshl (real __x);
real sinhl (real __x);
real __sinhl (real __x);
real tanhl (real __x);
real __tanhl (real __x);
real acoshl (real __x);
real __acoshl (real __x);
real asinhl (real __x);
real __asinhl (real __x);
real atanhl (real __x);
real __atanhl (real __x);
real expl (real __x);
real __expl (real __x);
real frexpl (real __x, int* __exponent);
real __frexpl (real __x, int* __exponent);
real ldexpl (real __x, int __exponent);
real __ldexpl (real __x, int __exponent);
real logl (real __x);
real __logl (real __x);
real log10l (real __x);
real __log10l (real __x);
real modfl (real __x, real* __iptr);
real __modfl (real __x, real* __iptr);
real exp10l (real __x);
real __exp10l (real __x);
real expm1l (real __x);
real __expm1l (real __x);
real log1pl (real __x);
real __log1pl (real __x);
real logbl (real __x);
real __logbl (real __x);
real exp2l (real __x);
real __exp2l (real __x);
real log2l (real __x);
real __log2l (real __x);
real powl (real __x, real __y);
real __powl (real __x, real __y);
real sqrtl (real __x);
real __sqrtl (real __x);
real hypotl (real __x, real __y);
real __hypotl (real __x, real __y);
real cbrtl (real __x);
real __cbrtl (real __x);
real ceill (real __x);
real __ceill (real __x);
real fabsl (real __x);
real __fabsl (real __x);
real floorl (real __x);
real __floorl (real __x);
real fmodl (real __x, real __y);
real __fmodl (real __x, real __y);
int isinfl (real __value);
int finitel (real __value);
real dreml (real __x, real __y);
real __dreml (real __x, real __y);
real significandl (real __x);
real __significandl (real __x);
real copysignl (real __x, real __y);
real __copysignl (real __x, real __y);
real nanl (const(char)* __tagb);
real __nanl (const(char)* __tagb);
int isnanl (real __value);
real j0l (real);
real __j0l (real);
real j1l (real);
real __j1l (real);
real jnl (int, real);
real __jnl (int, real);
real y0l (real);
real __y0l (real);
real y1l (real);
real __y1l (real);
real ynl (int, real);
real __ynl (int, real);
real erfl (real);
real __erfl (real);
real erfcl (real);
real __erfcl (real);
real lgammal (real);
real __lgammal (real);
real tgammal (real);
real __tgammal (real);
real gammal (real);
real __gammal (real);
real lgammal_r (real, int* __signgamp);
real __lgammal_r (real, int* __signgamp);
real rintl (real __x);
real __rintl (real __x);
real nextafterl (real __x, real __y);
real __nextafterl (real __x, real __y);
real nexttowardl (real __x, real __y);
real __nexttowardl (real __x, real __y);
real remainderl (real __x, real __y);
real __remainderl (real __x, real __y);
real scalbnl (real __x, int __n);
real __scalbnl (real __x, int __n);
int ilogbl (real __x);
int __ilogbl (real __x);
real scalblnl (real __x, c_long __n);
real __scalblnl (real __x, c_long __n);
real nearbyintl (real __x);
real __nearbyintl (real __x);
real roundl (real __x);
real __roundl (real __x);
real truncl (real __x);
real __truncl (real __x);
real remquol (real __x, real __y, int* __quo);
real __remquol (real __x, real __y, int* __quo);
c_long lrintl (real __x);
c_long __lrintl (real __x);

long llrintl (real __x);
long __llrintl (real __x);
c_long lroundl (real __x);
c_long __lroundl (real __x);

long llroundl (real __x);
long __llroundl (real __x);
real fdiml (real __x, real __y);
real __fdiml (real __x, real __y);
real fmaxl (real __x, real __y);
real __fmaxl (real __x, real __y);
real fminl (real __x, real __y);
real __fminl (real __x, real __y);
real fmal (real __x, real __y, real __z);
real __fmal (real __x, real __y, real __z);
real scalbl (real __x, real __n);
real __scalbl (real __x, real __n);
int __fpclassifyf128 (_Float128 __value);
int __signbitf128 (_Float128 __value);
int __isinff128 (_Float128 __value);
int __finitef128 (_Float128 __value);
int __isnanf128 (_Float128 __value);
int __iseqsigf128 (_Float128 __x, _Float128 __y);
int __issignalingf128 (_Float128 __value);
extern __gshared int signgam;

enum
{
    FP_NAN = 0,
    FP_INFINITE = 1,
    FP_ZERO = 2,
    FP_SUBNORMAL = 3,
    FP_NORMAL = 4
}

extern __gshared double R_NaN;
extern __gshared double R_PosInf;
extern __gshared double R_NegInf;
extern __gshared double R_NaReal;
extern __gshared int R_NaInt;
int R_IsNA (double);
int R_IsNaN (double);
int R_finite (double);

enum Rboolean
{
    FALSE = 0,
    TRUE = 1
}

struct Rcomplex
{
    double r;
    double i;
}

void Rf_error (const(char)*, ...);
void UNIMPLEMENTED (const(char)*);
void WrongArgCount (const(char)*);
void Rf_warning (const(char)*, ...);
void R_ShowMessage (const(char)* s);
alias ptrdiff_t = c_long;

struct max_align_t
{
    long __max_align_ll;
    real __max_align_ld;
}

void* vmaxget ();
void vmaxset (const(void)*);
void R_gc ();
int R_gc_running ();
char* R_alloc (size_t, int);
real* R_allocLD (size_t nelem);
char* S_alloc (c_long, int);
char* S_realloc (char*, c_long, c_long, int);
void* R_malloc_gc (size_t);
void* R_calloc_gc (size_t, size_t);
void* R_realloc_gc (void*, size_t);
void Rprintf (const(char)*, ...);
void REprintf (const(char)*, ...);
void Rvprintf (const(char)*, va_list);
void REvprintf (const(char)*, va_list);

enum RNGtype
{
    WICHMANN_HILL = 0,
    MARSAGLIA_MULTICARRY = 1,
    SUPER_DUPER = 2,
    MERSENNE_TWISTER = 3,
    KNUTH_TAOCP = 4,
    USER_UNIF = 5,
    KNUTH_TAOCP2 = 6,
    LECUYER_CMRG = 7
}

enum N01type
{
    BUGGY_KINDERMAN_RAMAGE = 0,
    AHRENS_DIETER = 1,
    BOX_MULLER = 2,
    USER_NORM = 3,
    INVERSION = 4,
    KINDERMAN_RAMAGE = 5
}

enum Sampletype
{
    ROUNDING = 0,
    REJECTION = 1
}

Sampletype R_sample_kind ();
void GetRNGstate ();
void PutRNGstate ();
double unif_rand ();
double R_unif_index (double);
double norm_rand ();
double exp_rand ();
alias Int32 = uint;
double* user_unif_rand ();
void user_unif_init (Int32);
int* user_unif_nseed ();
int* user_unif_seedloc ();
double* user_norm_rand ();
void R_isort (int*, int);
void R_rsort (double*, int);
void R_csort (Rcomplex*, int);
void rsort_with_index (double*, int*, int);
void Rf_revsort (double*, int*, int);
void Rf_iPsort (int*, int, int);
void Rf_rPsort (double*, int, int);
void Rf_cPsort (Rcomplex*, int, int);
void R_qsort (double* v, size_t i, size_t j);
void R_qsort_I (double* v, int* II, int i, int j);
void R_qsort_int (int* iv, size_t i, size_t j);
void R_qsort_int_I (int* iv, int* II, int i, int j);
const(char)* R_ExpandFileName (const(char)*);
void Rf_setIVector (int*, int, int);
void Rf_setRVector (double*, int, double);
Rboolean Rf_StringFalse (const(char)*);
Rboolean Rf_StringTrue (const(char)*);
Rboolean Rf_isBlankString (const(char)*);
double R_atof (const(char)* str);
double R_strtod (const(char)* c, char** end);
char* R_tmpnam (const(char)* prefix, const(char)* tempdir);
char* R_tmpnam2 (const(char)* prefix, const(char)* tempdir, const(char)* fileext);
void R_free_tmpnam (char* name);
void R_CheckUserInterrupt ();
void R_CheckStack ();
void R_CheckStack2 (size_t);
int findInterval (
    double* xt,
    int n,
    double x,
    Rboolean rightmost_closed,
    Rboolean all_inside,
    int ilo,
    int* mflag);
int findInterval2 (
    double* xt,
    int n,
    double x,
    Rboolean rightmost_closed,
    Rboolean all_inside,
    Rboolean left_open,
    int ilo,
    int* mflag);
void find_interv_vec (
    double* xt,
    int* n,
    double* x,
    int* nx,
    int* rightmost_closed,
    int* all_inside,
    int* indx);
void R_max_col (double* matrix, int* nr, int* nc, int* maxes, int* ties_meth);

void* memcpy (void* __dest, const(void)* __src, size_t __n);
void* memmove (void* __dest, const(void)* __src, size_t __n);
void* memccpy (void* __dest, const(void)* __src, int __c, size_t __n);
void* memset (void* __s, int __c, size_t __n);
int memcmp (const(void)* __s1, const(void)* __s2, size_t __n);
void* memchr (const(void)* __s, int __c, size_t __n);
char* strcpy (char* __dest, const(char)* __src);
char* strncpy (char* __dest, const(char)* __src, size_t __n);
char* strcat (char* __dest, const(char)* __src);
char* strncat (char* __dest, const(char)* __src, size_t __n);
int strcmp (const(char)* __s1, const(char)* __s2);
int strncmp (const(char)* __s1, const(char)* __s2, size_t __n);
int strcoll (const(char)* __s1, const(char)* __s2);
c_ulong strxfrm (char* __dest, const(char)* __src, size_t __n);

struct __locale_struct
{
    struct __locale_data;
    __locale_data*[13] __locales;
    const(ushort)* __ctype_b;
    const(int)* __ctype_tolower;
    const(int)* __ctype_toupper;
    const(char)*[13] __names;
}

alias __locale_t = __locale_struct*;
alias locale_t = __locale_struct*;
int strcoll_l (const(char)* __s1, const(char)* __s2, locale_t __l);
size_t strxfrm_l (char* __dest, const(char)* __src, size_t __n, locale_t __l);
char* strdup (const(char)* __s);
char* strndup (const(char)* __string, size_t __n);
char* strchr (const(char)* __s, int __c);
char* strrchr (const(char)* __s, int __c);
c_ulong strcspn (const(char)* __s, const(char)* __reject);
c_ulong strspn (const(char)* __s, const(char)* __accept);
char* strpbrk (const(char)* __s, const(char)* __accept);
char* strstr (const(char)* __haystack, const(char)* __needle);
char* strtok (char* __s, const(char)* __delim);
char* __strtok_r (char* __s, const(char)* __delim, char** __save_ptr);
char* strtok_r (char* __s, const(char)* __delim, char** __save_ptr);
c_ulong strlen (const(char)* __s);
size_t strnlen (const(char)* __string, size_t __maxlen);
char* strerror (int __errnum);
int strerror_r (int __errnum, char* __buf, size_t __buflen);
char* strerror_l (int __errnum, locale_t __l);

int bcmp (const(void)* __s1, const(void)* __s2, size_t __n);
void bcopy (const(void)* __src, void* __dest, size_t __n);
void bzero (void* __s, size_t __n);
char* index (const(char)* __s, int __c);
char* rindex (const(char)* __s, int __c);
int ffs (int __i);
int ffsl (c_long __l);
int ffsll (long __ll);
int strcasecmp (const(char)* __s1, const(char)* __s2);
int strncasecmp (const(char)* __s1, const(char)* __s2, size_t __n);
int strcasecmp_l (const(char)* __s1, const(char)* __s2, locale_t __loc);
int strncasecmp_l (
    const(char)* __s1,
    const(char)* __s2,
    size_t __n,
    locale_t __loc);

void explicit_bzero (void* __s, size_t __n);
char* strsep (char** __stringp, const(char)* __delim);
char* strsignal (int __sig);
char* __stpcpy (char* __dest, const(char)* __src);
char* stpcpy (char* __dest, const(char)* __src);
char* __stpncpy (char* __dest, const(char)* __src, size_t __n);
char* stpncpy (char* __dest, const(char)* __src, size_t __n);

void* R_chk_calloc (size_t, size_t);
void* R_chk_realloc (void*, size_t);
void R_chk_free (void*);
void call_R (char*, c_long, void**, char**, c_long*, char**, c_long, char**);
alias Sfloat = double;
alias Sint = int;
void R_FlushConsole ();
void R_ProcessEvents ();
alias DL_FUNC = void* function();
alias R_NativePrimitiveArgType = uint;

struct R_CMethodDef
{
    const(char)* name;
    DL_FUNC fun;
    int numArgs;
    R_NativePrimitiveArgType* types;
}

alias R_FortranMethodDef = R_CMethodDef;

struct R_CallMethodDef
{
    const(char)* name;
    DL_FUNC fun;
    int numArgs;
}

alias R_ExternalMethodDef = R_CallMethodDef;
struct _DllInfo;
alias DllInfo = _DllInfo;
int R_registerRoutines (
    DllInfo* info,
    const R_CMethodDef* croutines,
    const R_CallMethodDef* callRoutines,
    const R_FortranMethodDef* fortranRoutines,
    const R_ExternalMethodDef* externalRoutines);
Rboolean R_useDynamicSymbols (DllInfo* info, Rboolean value);
Rboolean R_forceSymbols (DllInfo* info, Rboolean value);
DllInfo* R_getDllInfo (const(char)* name);
DllInfo* R_getEmbeddingDllInfo ();
struct Rf_RegisteredNativeSymbol;
alias R_RegisteredNativeSymbol = Rf_RegisteredNativeSymbol;

enum NativeSymbolType
{
    R_ANY_SYM = 0,
    R_C_SYM = 1,
    R_CALL_SYM = 2,
    R_FORTRAN_SYM = 3,
    R_EXTERNAL_SYM = 4
}

DL_FUNC R_FindSymbol (
    const(char)*,
    const(char)*,
    R_RegisteredNativeSymbol* symbol);
void R_RegisterCCallable (const(char)* package_, const(char)* name, DL_FUNC fptr);
DL_FUNC R_GetCCallable (const(char)* package_, const(char)* name);
alias Rbyte = ubyte;
alias R_len_t = int;
alias R_xlen_t = c_long;

enum SEXPTYPE
{
    NILSXP = 0,
    SYMSXP = 1,
    LISTSXP = 2,
    CLOSXP = 3,
    ENVSXP = 4,
    PROMSXP = 5,
    LANGSXP = 6,
    SPECIALSXP = 7,
    BUILTINSXP = 8,
    CHARSXP = 9,
    LGLSXP = 10,
    INTSXP = 13,
    REALSXP = 14,
    CPLXSXP = 15,
    STRSXP = 16,
    DOTSXP = 17,
    ANYSXP = 18,
    VECSXP = 19,
    EXPRSXP = 20,
    BCODESXP = 21,
    EXTPTRSXP = 22,
    WEAKREFSXP = 23,
    RAWSXP = 24,
    S4SXP = 25,
    NEWSXP = 30,
    FREESXP = 31,
    FUNSXP = 99
}

struct SEXPREC;
alias SEXP = SEXPREC*;
const(char)* R_CHAR (SEXP x);
Rboolean Rf_isNull (SEXP s);
Rboolean Rf_isSymbol (SEXP s);
Rboolean Rf_isLogical (SEXP s);
Rboolean Rf_isReal (SEXP s);
Rboolean Rf_isComplex (SEXP s);
Rboolean Rf_isExpression (SEXP s);
Rboolean Rf_isEnvironment (SEXP s);
Rboolean Rf_isString (SEXP s);
Rboolean Rf_isObject (SEXP s);

enum
{
    SORTED_DECR_NA_1ST = -2,
    SORTED_DECR = -1,
    UNKNOWN_SORTEDNESS = -0x7fffffff - 1,
    SORTED_INCR = 1,
    SORTED_INCR_NA_1ST = 2,
    KNOWN_UNSORTED = 0
}

SEXP ATTRIB (SEXP x);
int OBJECT (SEXP x);
int MARK (SEXP x);
int TYPEOF (SEXP x);
int NAMED (SEXP x);
int REFCNT (SEXP x);
int TRACKREFS (SEXP x);
void SET_OBJECT (SEXP x, int v);
void SET_TYPEOF (SEXP x, int v);
void SET_NAMED (SEXP x, int v);
void SET_ATTRIB (SEXP x, SEXP v);
void DUPLICATE_ATTRIB (SEXP to, SEXP from);
void SHALLOW_DUPLICATE_ATTRIB (SEXP to, SEXP from);
void ENSURE_NAMEDMAX (SEXP x);
void ENSURE_NAMED (SEXP x);
void SETTER_CLEAR_NAMED (SEXP x);
void RAISE_NAMED (SEXP x, int n);
void DECREMENT_REFCNT (SEXP x);
void INCREMENT_REFCNT (SEXP x);
void DISABLE_REFCNT (SEXP x);
void ENABLE_REFCNT (SEXP x);
void MARK_NOT_MUTABLE (SEXP x);
int ASSIGNMENT_PENDING (SEXP x);
void SET_ASSIGNMENT_PENDING (SEXP x, int v);
int IS_ASSIGNMENT_CALL (SEXP x);
void MARK_ASSIGNMENT_CALL (SEXP x);
int IS_S4_OBJECT (SEXP x);
void SET_S4_OBJECT (SEXP x);
void UNSET_S4_OBJECT (SEXP x);
int NOJIT (SEXP x);
int MAYBEJIT (SEXP x);
void SET_NOJIT (SEXP x);
void SET_MAYBEJIT (SEXP x);
void UNSET_MAYBEJIT (SEXP x);
int IS_GROWABLE (SEXP x);
void SET_GROWABLE_BIT (SEXP x);
int LENGTH (SEXP x);
R_xlen_t XLENGTH (SEXP x);
R_xlen_t TRUELENGTH (SEXP x);
void SETLENGTH (SEXP x, R_xlen_t v);
void SET_TRUELENGTH (SEXP x, R_xlen_t v);
int IS_LONG_VEC (SEXP x);
int LEVELS (SEXP x);
int SETLEVELS (SEXP x, int v);
int* LOGICAL (SEXP x);
int* INTEGER (SEXP x);
Rbyte* RAW (SEXP x);
double* REAL (SEXP x);
Rcomplex* COMPLEX (SEXP x);
const(int)* LOGICAL_RO (SEXP x);
const(int)* INTEGER_RO (SEXP x);
const(Rbyte)* RAW_RO (SEXP x);
const(double)* REAL_RO (SEXP x);
const(Rcomplex)* COMPLEX_RO (SEXP x);
SEXP VECTOR_ELT (SEXP x, R_xlen_t i);
void SET_STRING_ELT (SEXP x, R_xlen_t i, SEXP v);
SEXP SET_VECTOR_ELT (SEXP x, R_xlen_t i, SEXP v);
SEXP* STRING_PTR (SEXP x);
const(SEXP)* STRING_PTR_RO (SEXP x);
SEXP* VECTOR_PTR (SEXP x);
void* STDVEC_DATAPTR (SEXP x);
int IS_SCALAR (SEXP x, int type);
int ALTREP (SEXP x);
SEXP ALTREP_DUPLICATE_EX (SEXP x, Rboolean deep);
SEXP ALTREP_COERCE (SEXP x, int type);
Rboolean ALTREP_INSPECT (SEXP, int, int, int, void function (SEXP, int, int, int));
SEXP ALTREP_SERIALIZED_CLASS (SEXP);
SEXP ALTREP_SERIALIZED_STATE (SEXP);
SEXP ALTREP_UNSERIALIZE_EX (SEXP, SEXP, SEXP, int, int);
R_xlen_t ALTREP_LENGTH (SEXP x);
R_xlen_t ALTREP_TRUELENGTH (SEXP x);
void* ALTVEC_DATAPTR (SEXP x);
const(void)* ALTVEC_DATAPTR_RO (SEXP x);
const(void)* ALTVEC_DATAPTR_OR_NULL (SEXP x);
SEXP ALTVEC_EXTRACT_SUBSET (SEXP x, SEXP indx, SEXP call);
int ALTINTEGER_ELT (SEXP x, R_xlen_t i);
void ALTINTEGER_SET_ELT (SEXP x, R_xlen_t i, int v);
int ALTLOGICAL_ELT (SEXP x, R_xlen_t i);
void ALTLOGICAL_SET_ELT (SEXP x, R_xlen_t i, int v);
double ALTREAL_ELT (SEXP x, R_xlen_t i);
void ALTREAL_SET_ELT (SEXP x, R_xlen_t i, double v);
SEXP ALTSTRING_ELT (SEXP, R_xlen_t);
void ALTSTRING_SET_ELT (SEXP, R_xlen_t, SEXP);
Rcomplex ALTCOMPLEX_ELT (SEXP x, R_xlen_t i);
void ALTCOMPLEX_SET_ELT (SEXP x, R_xlen_t i, Rcomplex v);
Rbyte ALTRAW_ELT (SEXP x, R_xlen_t i);
void ALTRAW_SET_ELT (SEXP x, R_xlen_t i, Rbyte v);
R_xlen_t INTEGER_GET_REGION (SEXP sx, R_xlen_t i, R_xlen_t n, int* buf);
R_xlen_t REAL_GET_REGION (SEXP sx, R_xlen_t i, R_xlen_t n, double* buf);
R_xlen_t LOGICAL_GET_REGION (SEXP sx, R_xlen_t i, R_xlen_t n, int* buf);
R_xlen_t COMPLEX_GET_REGION (SEXP sx, R_xlen_t i, R_xlen_t n, Rcomplex* buf);
R_xlen_t RAW_GET_REGION (SEXP sx, R_xlen_t i, R_xlen_t n, Rbyte* buf);
int INTEGER_IS_SORTED (SEXP x);
int INTEGER_NO_NA (SEXP x);
int REAL_IS_SORTED (SEXP x);
int REAL_NO_NA (SEXP x);
int LOGICAL_IS_SORTED (SEXP x);
int LOGICAL_NO_NA (SEXP x);
int STRING_IS_SORTED (SEXP x);
int STRING_NO_NA (SEXP x);
SEXP ALTINTEGER_SUM (SEXP x, Rboolean narm);
SEXP ALTINTEGER_MIN (SEXP x, Rboolean narm);
SEXP ALTINTEGER_MAX (SEXP x, Rboolean narm);
SEXP INTEGER_MATCH (SEXP, SEXP, int, SEXP, SEXP, Rboolean);
SEXP INTEGER_IS_NA (SEXP x);
SEXP ALTREAL_SUM (SEXP x, Rboolean narm);
SEXP ALTREAL_MIN (SEXP x, Rboolean narm);
SEXP ALTREAL_MAX (SEXP x, Rboolean narm);
SEXP REAL_MATCH (SEXP, SEXP, int, SEXP, SEXP, Rboolean);
SEXP REAL_IS_NA (SEXP x);
SEXP ALTLOGICAL_SUM (SEXP x, Rboolean narm);
SEXP R_compact_intrange (R_xlen_t n1, R_xlen_t n2);
SEXP R_deferred_coerceToString (SEXP v, SEXP info);
SEXP R_virtrep_vec (SEXP, SEXP);
SEXP R_tryWrap (SEXP);
SEXP R_tryUnwrap (SEXP);
R_len_t R_BadLongVector (SEXP, const(char)*, int);
int BNDCELL_TAG (SEXP e);
void SET_BNDCELL_TAG (SEXP e, int v);
double BNDCELL_DVAL (SEXP cell);
int BNDCELL_IVAL (SEXP cell);
int BNDCELL_LVAL (SEXP cell);
void SET_BNDCELL_DVAL (SEXP cell, double v);
void SET_BNDCELL_IVAL (SEXP cell, int v);
void SET_BNDCELL_LVAL (SEXP cell, int v);
void INIT_BNDCELL (SEXP cell, int type);
void SET_BNDCELL (SEXP cell, SEXP val);
SEXP TAG (SEXP e);
SEXP CAR0 (SEXP e);
SEXP CDR (SEXP e);
SEXP CAAR (SEXP e);
SEXP CDAR (SEXP e);
SEXP CADR (SEXP e);
SEXP CDDR (SEXP e);
SEXP CDDDR (SEXP e);
SEXP CADDR (SEXP e);
SEXP CADDDR (SEXP e);
SEXP CAD4R (SEXP e);
int MISSING (SEXP x);
void SET_MISSING (SEXP x, int v);
void SET_TAG (SEXP x, SEXP y);
SEXP SETCAR (SEXP x, SEXP y);
SEXP SETCDR (SEXP x, SEXP y);
SEXP SETCADR (SEXP x, SEXP y);
SEXP SETCADDR (SEXP x, SEXP y);
SEXP SETCADDDR (SEXP x, SEXP y);
SEXP SETCAD4R (SEXP e, SEXP y);
void* EXTPTR_PTR (SEXP);
SEXP CONS_NR (SEXP a, SEXP b);
SEXP FORMALS (SEXP x);
SEXP BODY (SEXP x);
SEXP CLOENV (SEXP x);
int RDEBUG (SEXP x);
int RSTEP (SEXP x);
int RTRACE (SEXP x);
void SET_RDEBUG (SEXP x, int v);
void SET_RSTEP (SEXP x, int v);
void SET_RTRACE (SEXP x, int v);
void SET_FORMALS (SEXP x, SEXP v);
void SET_BODY (SEXP x, SEXP v);
void SET_CLOENV (SEXP x, SEXP v);
SEXP PRINTNAME (SEXP x);
SEXP SYMVALUE (SEXP x);
SEXP INTERNAL (SEXP x);
int DDVAL (SEXP x);
void SET_DDVAL (SEXP x, int v);
void SET_PRINTNAME (SEXP x, SEXP v);
void SET_SYMVALUE (SEXP x, SEXP v);
void SET_INTERNAL (SEXP x, SEXP v);
SEXP FRAME (SEXP x);
SEXP ENCLOS (SEXP x);
SEXP HASHTAB (SEXP x);
int ENVFLAGS (SEXP x);
void SET_ENVFLAGS (SEXP x, int v);
void SET_FRAME (SEXP x, SEXP v);
void SET_ENCLOS (SEXP x, SEXP v);
void SET_HASHTAB (SEXP x, SEXP v);
SEXP PRCODE (SEXP x);
SEXP PRENV (SEXP x);
SEXP PRVALUE (SEXP x);
int PRSEEN (SEXP x);
void SET_PRSEEN (SEXP x, int v);
void SET_PRENV (SEXP x, SEXP v);
void SET_PRVALUE (SEXP x, SEXP v);
void SET_PRCODE (SEXP x, SEXP v);
void SET_PRSEEN (SEXP x, int v);
int HASHASH (SEXP x);
int HASHVALUE (SEXP x);
void SET_HASHASH (SEXP x, int v);
void SET_HASHVALUE (SEXP x, int v);
alias PROTECT_INDEX = int;
extern __gshared SEXP R_GlobalEnv;
extern __gshared SEXP R_EmptyEnv;
extern __gshared SEXP R_BaseEnv;
extern __gshared SEXP R_BaseNamespace;
extern __gshared SEXP R_NamespaceRegistry;
extern __gshared SEXP R_Srcref;
extern __gshared SEXP R_NilValue;
extern __gshared SEXP R_UnboundValue;
extern __gshared SEXP R_MissingArg;
extern __gshared SEXP R_InBCInterpreter;
extern __gshared SEXP R_CurrentExpression;
extern __gshared SEXP R_RestartToken;
extern __gshared SEXP R_AsCharacterSymbol;
extern __gshared SEXP R_baseSymbol;
extern __gshared SEXP R_BaseSymbol;
extern __gshared SEXP R_BraceSymbol;
extern __gshared SEXP R_Bracket2Symbol;
extern __gshared SEXP R_BracketSymbol;
extern __gshared SEXP R_ClassSymbol;
extern __gshared SEXP R_DeviceSymbol;
extern __gshared SEXP R_DimNamesSymbol;
extern __gshared SEXP R_DimSymbol;
extern __gshared SEXP R_DollarSymbol;
extern __gshared SEXP R_DotsSymbol;
extern __gshared SEXP R_DoubleColonSymbol;
extern __gshared SEXP R_DropSymbol;
extern __gshared SEXP R_EvalSymbol;
extern __gshared SEXP R_FunctionSymbol;
extern __gshared SEXP R_LastvalueSymbol;
extern __gshared SEXP R_LevelsSymbol;
extern __gshared SEXP R_ModeSymbol;
extern __gshared SEXP R_NaRmSymbol;
extern __gshared SEXP R_NameSymbol;
extern __gshared SEXP R_NamesSymbol;
extern __gshared SEXP R_NamespaceEnvSymbol;
extern __gshared SEXP R_PackageSymbol;
extern __gshared SEXP R_PreviousSymbol;
extern __gshared SEXP R_QuoteSymbol;
extern __gshared SEXP R_RowNamesSymbol;
extern __gshared SEXP R_SeedsSymbol;
extern __gshared SEXP R_SortListSymbol;
extern __gshared SEXP R_SourceSymbol;
extern __gshared SEXP R_SpecSymbol;
extern __gshared SEXP R_TripleColonSymbol;
extern __gshared SEXP R_TspSymbol;
extern __gshared SEXP R_dot_defined;
extern __gshared SEXP R_dot_Method;
extern __gshared SEXP R_dot_packageName;
extern __gshared SEXP R_dot_target;
extern __gshared SEXP R_dot_Generic;
extern __gshared SEXP R_NaString;
extern __gshared SEXP R_BlankString;
extern __gshared SEXP R_BlankScalarString;
SEXP R_GetCurrentSrcref (int);
SEXP R_GetSrcFilename (SEXP);
SEXP Rf_asChar (SEXP);
SEXP Rf_coerceVector (SEXP, SEXPTYPE);
SEXP Rf_PairToVectorList (SEXP x);
SEXP Rf_VectorToPairList (SEXP x);
SEXP Rf_asCharacterFactor (SEXP x);
int Rf_asLogical (SEXP x);
int Rf_asLogical2 (SEXP x, int checking, SEXP call, SEXP rho);
int Rf_asInteger (SEXP x);
double Rf_asReal (SEXP x);
Rcomplex Rf_asComplex (SEXP x);
struct R_allocator;
alias R_allocator_t = R_allocator;

enum warn_type
{
    iSILENT = 0,
    iWARN = 1,
    iERROR = 2
}

char* Rf_acopy_string (const(char)*);
void Rf_addMissingVarsToNewEnv (SEXP, SEXP);
SEXP Rf_alloc3DArray (SEXPTYPE, int, int, int);
SEXP Rf_allocArray (SEXPTYPE, SEXP);
SEXP Rf_allocFormalsList2 (SEXP sym1, SEXP sym2);
SEXP Rf_allocFormalsList3 (SEXP sym1, SEXP sym2, SEXP sym3);
SEXP Rf_allocFormalsList4 (SEXP sym1, SEXP sym2, SEXP sym3, SEXP sym4);
SEXP Rf_allocFormalsList5 (SEXP sym1, SEXP sym2, SEXP sym3, SEXP sym4, SEXP sym5);
SEXP Rf_allocFormalsList6 (SEXP sym1, SEXP sym2, SEXP sym3, SEXP sym4, SEXP sym5, SEXP sym6);
SEXP Rf_allocMatrix (SEXPTYPE, int, int);
SEXP Rf_allocList (int);
SEXP Rf_allocS4Object ();
SEXP Rf_allocSExp (SEXPTYPE);
SEXP Rf_allocVector3 (SEXPTYPE, R_xlen_t, R_allocator_t*);
R_xlen_t Rf_any_duplicated (SEXP x, Rboolean from_last);
R_xlen_t Rf_any_duplicated3 (SEXP x, SEXP incomp, Rboolean from_last);
SEXP Rf_applyClosure (SEXP, SEXP, SEXP, SEXP, SEXP);
SEXP Rf_arraySubscript (
    int,
    SEXP,
    SEXP,
    SEXP function (SEXP, SEXP),
    SEXP function (SEXP, int),
    SEXP);
SEXP Rf_classgets (SEXP, SEXP);
SEXP Rf_cons (SEXP, SEXP);
SEXP Rf_fixSubset3Args (SEXP, SEXP, SEXP, SEXP*);
void Rf_copyMatrix (SEXP, SEXP, Rboolean);
void Rf_copyListMatrix (SEXP, SEXP, Rboolean);
void Rf_copyMostAttrib (SEXP, SEXP);
void Rf_copyVector (SEXP, SEXP);
int Rf_countContexts (int, int);
SEXP Rf_CreateTag (SEXP);
void Rf_defineVar (SEXP, SEXP, SEXP);
SEXP Rf_dimgets (SEXP, SEXP);
SEXP Rf_dimnamesgets (SEXP, SEXP);
SEXP Rf_DropDims (SEXP);
SEXP Rf_duplicate (SEXP);
SEXP Rf_shallow_duplicate (SEXP);
SEXP R_duplicate_attr (SEXP);
SEXP R_shallow_duplicate_attr (SEXP);
SEXP Rf_lazy_duplicate (SEXP);
SEXP Rf_duplicated (SEXP, Rboolean);
Rboolean R_envHasNoSpecialSymbols (SEXP);
SEXP Rf_eval (SEXP, SEXP);
SEXP Rf_ExtractSubset (SEXP, SEXP, SEXP);
SEXP Rf_findFun (SEXP, SEXP);
SEXP Rf_findFun3 (SEXP, SEXP, SEXP);
void Rf_findFunctionForBody (SEXP);
SEXP Rf_findVar (SEXP, SEXP);
SEXP Rf_findVarInFrame (SEXP, SEXP);
SEXP Rf_findVarInFrame3 (SEXP, SEXP, Rboolean);
void R_removeVarFromFrame (SEXP, SEXP);
SEXP Rf_getAttrib (SEXP, SEXP);
SEXP Rf_GetArrayDimnames (SEXP);
SEXP Rf_GetColNames (SEXP);
void Rf_GetMatrixDimnames (SEXP, SEXP*, SEXP*, const(char*)*, const(char*)*);
SEXP Rf_GetOption (SEXP, SEXP);
SEXP Rf_GetOption1 (SEXP);
int Rf_FixupDigits (SEXP, warn_type);
int Rf_FixupWidth (SEXP, warn_type);
int Rf_GetOptionDigits ();
int Rf_GetOptionWidth ();
SEXP Rf_GetRowNames (SEXP);
void Rf_gsetVar (SEXP, SEXP, SEXP);
SEXP Rf_install (const(char)*);
SEXP Rf_installChar (SEXP);
SEXP Rf_installNoTrChar (SEXP);
SEXP Rf_installTrChar (SEXP);
SEXP Rf_installDDVAL (int i);
SEXP Rf_installS3Signature (const(char)*, const(char)*);
Rboolean Rf_isFree (SEXP);
Rboolean Rf_isOrdered (SEXP);
Rboolean Rf_isUnmodifiedSpecSym (SEXP sym, SEXP env);
Rboolean Rf_isUnordered (SEXP);
Rboolean Rf_isUnsorted (SEXP, Rboolean);
SEXP Rf_lengthgets (SEXP, R_len_t);
SEXP Rf_xlengthgets (SEXP, R_xlen_t);
SEXP R_lsInternal (SEXP, Rboolean);
SEXP R_lsInternal3 (SEXP, Rboolean, Rboolean);
SEXP Rf_match (SEXP, SEXP, int);
SEXP Rf_matchE (SEXP, SEXP, int, SEXP);
SEXP Rf_namesgets (SEXP, SEXP);
SEXP Rf_mkChar (const(char)*);
SEXP Rf_mkCharLen (const(char)*, int);
Rboolean Rf_NonNullStringMatch (SEXP, SEXP);
int Rf_ncols (SEXP);
int Rf_nrows (SEXP);
SEXP Rf_nthcdr (SEXP, int);

enum nchar_type
{
    Bytes = 0,
    Chars = 1,
    Width = 2
}

int R_nchar (
    SEXP string,
    nchar_type type_,
    Rboolean allowNA,
    Rboolean keepNA,
    const(char)* msg_name);
Rboolean Rf_pmatch (SEXP, SEXP, Rboolean);
Rboolean Rf_psmatch (const(char)*, const(char)*, Rboolean);
SEXP R_ParseEvalString (const(char)*, SEXP);
void Rf_PrintValue (SEXP);
void Rf_printwhere ();
void Rf_readS3VarsFromFrame (SEXP, SEXP*, SEXP*, SEXP*, SEXP*, SEXP*, SEXP*);
SEXP Rf_setAttrib (SEXP, SEXP, SEXP);
void Rf_setSVector (SEXP*, int, SEXP);
void Rf_setVar (SEXP, SEXP, SEXP);
SEXP Rf_stringSuffix (SEXP, int);
SEXPTYPE Rf_str2type (const(char)*);
Rboolean Rf_StringBlank (SEXP);
SEXP Rf_substitute (SEXP, SEXP);
SEXP Rf_topenv (SEXP, SEXP);
const(char)* Rf_translateChar (SEXP);
const(char)* Rf_translateChar0 (SEXP);
const(char)* Rf_translateCharUTF8 (SEXP);
const(char)* Rf_type2char (SEXPTYPE);
SEXP Rf_type2rstr (SEXPTYPE);
SEXP Rf_type2str (SEXPTYPE);
SEXP Rf_type2str_nowarn (SEXPTYPE);
void Rf_unprotect_ptr (SEXP);
void R_signal_protect_error ();
void R_signal_unprotect_error ();
void R_signal_reprotect_error (PROTECT_INDEX i);
SEXP R_tryEval (SEXP, SEXP, int*);
SEXP R_tryEvalSilent (SEXP, SEXP, int*);
SEXP R_GetCurrentEnv ();
const(char)* R_curErrorBuf ();
Rboolean Rf_isS4 (SEXP);
SEXP Rf_asS4 (SEXP, Rboolean, int);
SEXP Rf_S3Class (SEXP);
int Rf_isBasicClass (const(char)*);
Rboolean R_cycle_detected (SEXP s, SEXP child);

enum cetype_t
{
    CE_NATIVE = 0,
    CE_UTF8 = 1,
    CE_LATIN1 = 2,
    CE_BYTES = 3,
    CE_SYMBOL = 5,
    CE_ANY = 99
}

cetype_t Rf_getCharCE (SEXP);
SEXP Rf_mkCharCE (const(char)*, cetype_t);
SEXP Rf_mkCharLenCE (const(char)*, int, cetype_t);
const(char)* Rf_reEnc (const(char)* x, cetype_t ce_in, cetype_t ce_out, int subst);
SEXP R_forceAndCall (SEXP e, int n, SEXP rho);
SEXP R_MakeExternalPtr (void* p, SEXP tag, SEXP prot);
void* R_ExternalPtrAddr (SEXP s);
SEXP R_ExternalPtrTag (SEXP s);
SEXP R_ExternalPtrProtected (SEXP s);
void R_ClearExternalPtr (SEXP s);
void R_SetExternalPtrAddr (SEXP s, void* p);
void R_SetExternalPtrTag (SEXP s, SEXP tag);
void R_SetExternalPtrProtected (SEXP s, SEXP p);
SEXP R_MakeExternalPtrFn (DL_FUNC p, SEXP tag, SEXP prot);
DL_FUNC R_ExternalPtrAddrFn (SEXP s);
alias R_CFinalizer_t = void function (SEXP);
void R_RegisterFinalizer (SEXP s, SEXP fun);
void R_RegisterCFinalizer (SEXP s, R_CFinalizer_t fun);
void R_RegisterFinalizerEx (SEXP s, SEXP fun, Rboolean onexit);
void R_RegisterCFinalizerEx (SEXP s, R_CFinalizer_t fun, Rboolean onexit);
void R_RunPendingFinalizers ();
SEXP R_MakeWeakRef (SEXP key, SEXP val, SEXP fin, Rboolean onexit);
SEXP R_MakeWeakRefC (SEXP key, SEXP val, R_CFinalizer_t fin, Rboolean onexit);
SEXP R_WeakRefKey (SEXP w);
SEXP R_WeakRefValue (SEXP w);
void R_RunWeakRefFinalizer (SEXP w);
SEXP R_PromiseExpr (SEXP);
SEXP R_ClosureExpr (SEXP);
SEXP R_BytecodeExpr (SEXP e);
void R_initialize_bcode ();
SEXP R_bcEncode (SEXP);
SEXP R_bcDecode (SEXP);
void R_registerBC (SEXP, SEXP);
Rboolean R_checkConstants (Rboolean);
Rboolean R_BCVersionOK (SEXP);
void R_init_altrep ();
void R_reinit_altrep_classes (DllInfo*);
Rboolean R_ToplevelExec (void function (void*) fun, void* data);
SEXP R_ExecWithCleanup (
    SEXP function (void*) fun,
    void* data,
    void function (void*) cleanfun,
    void* cleandata);
SEXP R_tryCatch (
    SEXP function (void*),
    void*,
    SEXP,
    SEXP function (SEXP, void*),
    void*,
    void function (void*),
    void*);
SEXP R_tryCatchError (
    SEXP function (void*),
    void*,
    SEXP function (SEXP, void*),
    void*);
SEXP R_withCallingErrorHandler (
    SEXP function (void*),
    void*,
    SEXP function (SEXP, void*),
    void*);
SEXP R_MakeUnwindCont ();
void R_ContinueUnwind (SEXP cont);
SEXP R_UnwindProtect (
    SEXP function (void* data) fun,
    void* data,
    void function (void* data, Rboolean jump) cleanfun,
    void* cleandata,
    SEXP cont);
SEXP R_NewEnv (SEXP, int, int);
void R_RestoreHashCount (SEXP rho);
Rboolean R_IsPackageEnv (SEXP rho);
SEXP R_PackageEnvName (SEXP rho);
SEXP R_FindPackageEnv (SEXP info);
Rboolean R_IsNamespaceEnv (SEXP rho);
SEXP R_NamespaceEnvSpec (SEXP rho);
SEXP R_FindNamespace (SEXP info);
void R_LockEnvironment (SEXP env, Rboolean bindings);
Rboolean R_EnvironmentIsLocked (SEXP env);
void R_LockBinding (SEXP sym, SEXP env);
void R_unLockBinding (SEXP sym, SEXP env);
void R_MakeActiveBinding (SEXP sym, SEXP fun, SEXP env);
Rboolean R_BindingIsLocked (SEXP sym, SEXP env);
Rboolean R_BindingIsActive (SEXP sym, SEXP env);
SEXP R_ActiveBindingFunction (SEXP sym, SEXP env);
Rboolean R_HasFancyBindings (SEXP rho);
void Rf_errorcall (SEXP, const(char)*, ...);
void Rf_warningcall (SEXP, const(char)*, ...);
void Rf_warningcall_immediate (SEXP, const(char)*, ...);
void R_XDREncodeDouble (double d, void* buf);
double R_XDRDecodeDouble (void* buf);
void R_XDREncodeInteger (int i, void* buf);
int R_XDRDecodeInteger (void* buf);
alias R_pstream_data_t = void*;

enum R_pstream_format_t
{
    R_pstream_any_format = 0,
    R_pstream_ascii_format = 1,
    R_pstream_binary_format = 2,
    R_pstream_xdr_format = 3,
    R_pstream_asciihex_format = 4
}

alias R_outpstream_t = R_outpstream_st*;

struct R_outpstream_st
{
    R_pstream_data_t data;
    R_pstream_format_t type;
    int version_;
    void function (R_outpstream_t, int) OutChar;
    void function (R_outpstream_t, void*, int) OutBytes;
    SEXP function (SEXP, SEXP) OutPersistHookFunc;
    SEXP OutPersistHookData;
}

alias R_inpstream_t = R_inpstream_st*;

struct R_inpstream_st
{
    R_pstream_data_t data;
    R_pstream_format_t type;
    int function (R_inpstream_t) InChar;
    void function (R_inpstream_t, void*, int) InBytes;
    SEXP function (SEXP, SEXP) InPersistHookFunc;
    SEXP InPersistHookData;
    char[64] native_encoding;
    void* nat2nat_obj;
    void* nat2utf8_obj;
}

void R_InitInPStream (
    R_inpstream_t stream,
    R_pstream_data_t data,
    R_pstream_format_t type,
    int function (R_inpstream_t) inchar,
    void function (R_inpstream_t, void*, int) inbytes,
    SEXP function (SEXP, SEXP) phook,
    SEXP pdata);
void R_InitOutPStream (
    R_outpstream_t stream,
    R_pstream_data_t data,
    R_pstream_format_t type,
    int version_,
    void function (R_outpstream_t, int) outchar,
    void function (R_outpstream_t, void*, int) outbytes,
    SEXP function (SEXP, SEXP) phook,
    SEXP pdata);
void R_InitFileInPStream (
    R_inpstream_t stream,
    FILE* fp,
    R_pstream_format_t type,
    SEXP function (SEXP, SEXP) phook,
    SEXP pdata);
void R_InitFileOutPStream (
    R_outpstream_t stream,
    FILE* fp,
    R_pstream_format_t type,
    int version_,
    SEXP function (SEXP, SEXP) phook,
    SEXP pdata);
void R_Serialize (SEXP s, R_outpstream_t ops);
SEXP R_Unserialize (R_inpstream_t ips);
SEXP R_SerializeInfo (R_inpstream_t ips);
SEXP R_do_slot (SEXP obj, SEXP name);
SEXP R_do_slot_assign (SEXP obj, SEXP name, SEXP value);
int R_has_slot (SEXP obj, SEXP name);
SEXP R_S4_extends (SEXP klass, SEXP useTable);
SEXP R_do_MAKE_CLASS (const(char)* what);
SEXP R_getClassDef (const(char)* what);
SEXP R_getClassDef_R (SEXP what);
Rboolean R_has_methods_attached ();
Rboolean R_isVirtualClass (SEXP class_def, SEXP env);
Rboolean R_extends (SEXP class1, SEXP class2, SEXP env);
SEXP R_do_new_object (SEXP class_def);
int R_check_class_and_super (SEXP x, const(char*)* valid, SEXP rho);
int R_check_class_etc (SEXP x, const(char*)* valid);
void R_PreserveObject (SEXP);
void R_ReleaseObject (SEXP);
SEXP R_NewPreciousMSet (int);
void R_PreserveInMSet (SEXP x, SEXP mset);
void R_ReleaseFromMSet (SEXP x, SEXP mset);
void R_ReleaseMSet (SEXP mset, int keepSize);
void R_dot_Last ();
void R_RunExitFinalizers ();
int R_system (const(char)*);
Rboolean R_compute_identical (SEXP, SEXP, int);
SEXP R_body_no_src (SEXP x);
void R_orderVector (int* indx, int n, SEXP arglist, Rboolean nalast, Rboolean decreasing);
void R_orderVector1 (int* indx, int n, SEXP x, Rboolean nalast, Rboolean decreasing);
SEXP Rf_allocVector (SEXPTYPE, R_xlen_t);
Rboolean Rf_conformable (SEXP, SEXP);
SEXP Rf_elt (SEXP, int);
Rboolean Rf_inherits (SEXP, const(char)*);
Rboolean Rf_isArray (SEXP);
Rboolean Rf_isFactor (SEXP);
Rboolean Rf_isFrame (SEXP);
Rboolean Rf_isFunction (SEXP);
Rboolean Rf_isInteger (SEXP);
Rboolean Rf_isLanguage (SEXP);
Rboolean Rf_isList (SEXP);
Rboolean Rf_isMatrix (SEXP);
Rboolean Rf_isNewList (SEXP);
Rboolean Rf_isNumber (SEXP);
Rboolean Rf_isNumeric (SEXP);
Rboolean Rf_isPairList (SEXP);
Rboolean Rf_isPrimitive (SEXP);
Rboolean Rf_isTs (SEXP);
Rboolean Rf_isUserBinop (SEXP);
Rboolean Rf_isValidString (SEXP);
Rboolean Rf_isValidStringF (SEXP);
Rboolean Rf_isVector (SEXP);
Rboolean Rf_isVectorAtomic (SEXP);
Rboolean Rf_isVectorList (SEXP);
Rboolean Rf_isVectorizable (SEXP);
SEXP Rf_lang1 (SEXP);
SEXP Rf_lang2 (SEXP, SEXP);
SEXP Rf_lang3 (SEXP, SEXP, SEXP);
SEXP Rf_lang4 (SEXP, SEXP, SEXP, SEXP);
SEXP Rf_lang5 (SEXP, SEXP, SEXP, SEXP, SEXP);
SEXP Rf_lang6 (SEXP, SEXP, SEXP, SEXP, SEXP, SEXP);
SEXP Rf_lastElt (SEXP);
SEXP Rf_lcons (SEXP, SEXP);
R_len_t Rf_length (SEXP);
SEXP Rf_list1 (SEXP);
SEXP Rf_list2 (SEXP, SEXP);
SEXP Rf_list3 (SEXP, SEXP, SEXP);
SEXP Rf_list4 (SEXP, SEXP, SEXP, SEXP);
SEXP Rf_list5 (SEXP, SEXP, SEXP, SEXP, SEXP);
SEXP Rf_list6 (SEXP, SEXP, SEXP, SEXP, SEXP, SEXP);
SEXP Rf_listAppend (SEXP, SEXP);
SEXP Rf_mkNamed (SEXPTYPE, const(char*)*);
SEXP Rf_mkString (const(char)*);
int Rf_nlevels (SEXP);
int Rf_stringPositionTr (SEXP, const(char)*);
SEXP Rf_ScalarComplex (Rcomplex);
SEXP Rf_ScalarInteger (int);
SEXP Rf_ScalarLogical (int);
SEXP Rf_ScalarRaw (Rbyte);
SEXP Rf_ScalarReal (double);
SEXP Rf_ScalarString (SEXP);
R_xlen_t Rf_xlength (SEXP);
R_xlen_t XLENGTH (SEXP x);
R_xlen_t XTRUELENGTH (SEXP x);
int LENGTH_EX (SEXP x, const(char)* file, int line);
R_xlen_t XLENGTH_EX (SEXP x);
SEXP Rf_protect (SEXP);
void Rf_unprotect (int);
void R_ProtectWithIndex (SEXP, PROTECT_INDEX*);
void R_Reprotect (SEXP, PROTECT_INDEX);
SEXP R_FixupRHS (SEXP x, SEXP y);
SEXP CAR (SEXP e);
void* DATAPTR (SEXP x);
const(void)* DATAPTR_RO (SEXP x);
const(void)* DATAPTR_OR_NULL (SEXP x);
const(int)* LOGICAL_OR_NULL (SEXP x);
const(int)* INTEGER_OR_NULL (SEXP x);
const(double)* REAL_OR_NULL (SEXP x);
const(Rcomplex)* COMPLEX_OR_NULL (SEXP x);
const(Rbyte)* RAW_OR_NULL (SEXP x);
void* STDVEC_DATAPTR (SEXP x);
int INTEGER_ELT (SEXP x, R_xlen_t i);
double REAL_ELT (SEXP x, R_xlen_t i);
int LOGICAL_ELT (SEXP x, R_xlen_t i);
Rcomplex COMPLEX_ELT (SEXP x, R_xlen_t i);
Rbyte RAW_ELT (SEXP x, R_xlen_t i);
SEXP STRING_ELT (SEXP x, R_xlen_t i);
double SCALAR_DVAL (SEXP x);
int SCALAR_LVAL (SEXP x);
int SCALAR_IVAL (SEXP x);
void SET_SCALAR_DVAL (SEXP x, double v);
void SET_SCALAR_LVAL (SEXP x, int v);
void SET_SCALAR_IVAL (SEXP x, int v);
void SET_SCALAR_CVAL (SEXP x, Rcomplex v);
void SET_SCALAR_BVAL (SEXP x, Rbyte v);
SEXP R_altrep_data1 (SEXP x);
SEXP R_altrep_data2 (SEXP x);
void R_set_altrep_data1 (SEXP x, SEXP v);
void R_set_altrep_data2 (SEXP x, SEXP v);
SEXP ALTREP_CLASS (SEXP x);
int* LOGICAL0 (SEXP x);
int* INTEGER0 (SEXP x);
double* REAL0 (SEXP x);
Rcomplex* COMPLEX0 (SEXP x);
Rbyte* RAW0 (SEXP x);
void SET_LOGICAL_ELT (SEXP x, R_xlen_t i, int v);
void SET_INTEGER_ELT (SEXP x, R_xlen_t i, int v);
void SET_REAL_ELT (SEXP x, R_xlen_t i, double v);
void SET_COMPLEX_ELT (SEXP x, R_xlen_t i, Rcomplex v);
void SET_RAW_ELT (SEXP x, R_xlen_t i, Rbyte v);
void R_BadValueInRCode (
    SEXP value,
    SEXP call,
    SEXP rho,
    const(char)* rawmsg,
    const(char)* errmsg,
    const(char)* warnmsg,
    const(char)* varname,
    Rboolean warnByDefault);
double R_pow (double x, double y);
double R_pow_di (double, int);
double norm_rand ();
double unif_rand ();
double R_unif_index (double);
double exp_rand ();
void set_seed (uint, uint);
void get_seed (uint*, uint*);
double dnorm4 (double, double, double, int);
double pnorm5 (double, double, double, int, int);
double qnorm5 (double, double, double, int, int);
double rnorm (double, double);
void pnorm_both (double, double*, double*, int, int);
double dunif (double, double, double, int);
double punif (double, double, double, int, int);
double qunif (double, double, double, int, int);
double runif (double, double);
double dgamma (double, double, double, int);
double pgamma (double, double, double, int, int);
double qgamma (double, double, double, int, int);
double rgamma (double, double);
double log1pmx (double);
double log1pexp (double);
double log1mexp (double);
double lgamma1p (double);
double logspace_add (double, double);
double logspace_sub (double, double);
double logspace_sum (const(double)*, int);
double dbeta (double, double, double, int);
double pbeta (double, double, double, int, int);
double qbeta (double, double, double, int, int);
double rbeta (double, double);
double dlnorm (double, double, double, int);
double plnorm (double, double, double, int, int);
double qlnorm (double, double, double, int, int);
double rlnorm (double, double);
double dchisq (double, double, int);
double pchisq (double, double, int, int);
double qchisq (double, double, int, int);
double rchisq (double);
double dnchisq (double, double, double, int);
double pnchisq (double, double, double, int, int);
double qnchisq (double, double, double, int, int);
double rnchisq (double, double);
double df (double, double, double, int);
double pf (double, double, double, int, int);
double qf (double, double, double, int, int);
double rf (double, double);
double dt (double, double, int);
double pt (double, double, int, int);
double qt (double, double, int, int);
double rt (double);
double dbinom_raw (double x, double n, double p, double q, int give_log);
double dbinom (double, double, double, int);
double pbinom (double, double, double, int, int);
double qbinom (double, double, double, int, int);
double rbinom (double, double);
void rmultinom (int, double*, int, int*);
double dcauchy (double, double, double, int);
double pcauchy (double, double, double, int, int);
double qcauchy (double, double, double, int, int);
double rcauchy (double, double);
double dexp (double, double, int);
double pexp (double, double, int, int);
double qexp (double, double, int, int);
double rexp (double);
double dgeom (double, double, int);
double pgeom (double, double, int, int);
double qgeom (double, double, int, int);
double rgeom (double);
double dhyper (double, double, double, double, int);
double phyper (double, double, double, double, int, int);
double qhyper (double, double, double, double, int, int);
double rhyper (double, double, double);
double dnbinom (double, double, double, int);
double pnbinom (double, double, double, int, int);
double qnbinom (double, double, double, int, int);
double rnbinom (double, double);
double dnbinom_mu (double, double, double, int);
double pnbinom_mu (double, double, double, int, int);
double qnbinom_mu (double, double, double, int, int);
double rnbinom_mu (double, double);
double dpois_raw (double, double, int);
double dpois (double, double, int);
double ppois (double, double, int, int);
double qpois (double, double, int, int);
double rpois (double);
double dweibull (double, double, double, int);
double pweibull (double, double, double, int, int);
double qweibull (double, double, double, int, int);
double rweibull (double, double);
double dlogis (double, double, double, int);
double plogis (double, double, double, int, int);
double qlogis (double, double, double, int, int);
double rlogis (double, double);
double dnbeta (double, double, double, double, int);
double pnbeta (double, double, double, double, int, int);
double qnbeta (double, double, double, double, int, int);
double rnbeta (double, double, double);
double dnf (double, double, double, double, int);
double pnf (double, double, double, double, int, int);
double qnf (double, double, double, double, int, int);
double dnt (double, double, double, int);
double pnt (double, double, double, int, int);
double qnt (double, double, double, int, int);
double ptukey (double, double, double, double, int, int);
double qtukey (double, double, double, double, int, int);
double dwilcox (double, double, double, int);
double pwilcox (double, double, double, int, int);
double qwilcox (double, double, double, int, int);
double rwilcox (double, double);
double dsignrank (double, double, int);
double psignrank (double, double, int, int);
double qsignrank (double, double, int, int);
double rsignrank (double);
double gammafn (double);
double lgammafn (double);
double lgammafn_sign (double, int*);
void dpsifn (double, int, int, int, double*, int*, int*);
double psigamma (double, double);
double digamma (double);
double trigamma (double);
double tetragamma (double);
double pentagamma (double);
double beta (double, double);
double lbeta (double, double);
double choose (double, double);
double lchoose (double, double);
double bessel_i (double, double, double);
double bessel_j (double, double);
double bessel_k (double, double, double);
double bessel_y (double, double);
double bessel_i_ex (double, double, double, double*);
double bessel_j_ex (double, double, double*);
double bessel_k_ex (double, double, double, double*);
double bessel_y_ex (double, double, double*);
int imax2 (int, int);
int imin2 (int, int);
double fmax2 (double, double);
double fmin2 (double, double);
double sign (double);
double fprec (double, double);
double fround (double, double);
double fsign (double, double);
double ftrunc (double);
double log1pmx (double);
double lgamma1p (double);
double cospi (double);
double sinpi (double);
double tanpi (double);
double logspace_add (double logx, double logy);
double logspace_sub (double logx, double logy);
int R_finite (double);
extern __gshared int N01_kind;
