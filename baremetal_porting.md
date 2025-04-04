# CoreMark

## Using CoreMark with microcontrollers / embedded processors

### Overview

CoreMark can be used with microcontrollers / embedded processor devices. Before you start porting CoreMark, please setup a project environment that provides:

- printf support
- timer support (e.g. base on a reference that has a constant clock frequency)

The CoreMark execution needs to execute for at least 10 seconds. Therefore when selecting a timer peripheral for timing measurement, you need to ensure that the timer can measure the whole duration of the coremark execution. For example, let's say you are using a Cortex-M based microcontroller and use the SysTick timer as timing reference. If the device is running at 100MHz and the SysTick is setup to run using the processor's clock, the longest time that the timer can count is 0.16777 second before it reaches zero. To measure the execution time, you could setup the SysTick timer to interrupt at a rate of 1KHz, and increment a counter variable inside the interrupt service routine. With this arrangement, there is some software overhead but the result should still be quite accurate.

You also need to estimate a minimum number of iterations before your start. The number of iterations can be set using a C preprocessing macro "ITERATIONS". For a processor with around 4 CoreMark/MHz and running at 100MHz, you need an iteration of at least 4 (CoreMark/MHz) x100 (MHz) x 10 (seconds) = 4000 iterations.

Incorrect timing reference is a common error, therefore, please test your timing measurement code. For example, by creating a small program that wait for 10 seconds and compare that to an external timing measurement tool (e.g. stopwatch).

Once that are ready, you can then port the CoreMark project. The following files are required:

- Source files that are used without modifications
  - [coremark/core_main.c](https://github.com/eembc/coremark/blob/main/core_main.c)
  - [coremark/core_list_join.c](https://github.com/eembc/coremark/blob/main/core_list_join.c)
  - [coremark/core_matrix.c](https://github.com/eembc/coremark/blob/main/core_matrix.c)
  - [coremark/core_state.c](https://github.com/eembc/coremark/blob/main/core_state.c)
  - [coremark/core_util.c](https://github.com/eembc/coremark/blob/main/core_util.c)
  - [coremark/coremark.h](https://github.com/eembc/coremark/blob/main/coremark.h)
- Source files that need modifications
  - [coremark/barebones/core_portme.c](https://github.com/eembc/coremark/blob/main/barebones/core_portme.c)
  - [coremark/barebones/core_portme.h](https://github.com/eembc/coremark/blob/main/barebones/core_portme.h)


And of course you need to include the support files for timer and printf support.

In your project setup you also need to define pre-processing macros:

| Preprocessing macro | Description / value |
|---|---|
|ITERATIONS| Set to the number of iterations the CoreMark workload will execute for at least 10 seconds. |
|STANDALONE| Set to indicate Standalone environment |
|PERFORMANCE_RUN / VALIDATION_RUN | Set to 1 |

### Modifications of core_portme.h

Several C macros require update:

| Preprocessing macro | Value |
|---|---|
|HAS_FLOAT| 0 or 1 based on the processor/device|
|HAS_TIME_H| 0 |
|USE_CLOCK| 0 |
|HAS_STDIO| 1 |
|HAS_PRINTF| 1 |

The next section in the file is dependent on the C compiler that you are using. For example, the following code could be used for the Arm Compiler 5/6

```C
#ifndef COMPILER_VERSION
  #ifdef __GNUC__
    #define COMPILER_VERSION "GCC"__VERSION__
  #elif defined __ARMCC_VERSION
    /* Arm Compiler */
    #if (__ARMCC_VERSION > 6000000)
	   // ARM compiler 6
      #define COMPILER_VERSION "ARM compiler 6"
    #else
	   // ARM compiler 5
      #define _VERSION_STRING(x) #x
      #define _VER_STRING(x) "armcc "##_VERSION_STRING(x)
      #define COMPILER_VERSION _VER_STRING(__ARMCC_VERSION)
    #endif
  #elif defined __ICCARM__
    #define _VERSION_STRING(x) #x
    #define _VER_STRING(x) "ICC "##_VERSION_STRING(x)
    #define COMPILER_VERSION _VER_STRING(__VER__)
  #else
    #define COMPILER_VERSION "Please put compiler version here (e.g. gcc 4.1)"
  #endif
#endif

#ifndef COMPILER_FLAGS
  #ifdef  __ARMCC_VERSION
    #if (__ARMCC_VERSION > 6000000)
      /* ARM Compiler 6 */
      #if defined (__OPTIMIZE_SIZE__)&&(__OPTIMIZE_SIZE__==1U)
        #define COMPILER_FLAGS "-Oz"
      #else
        #define COMPILER_FLAGS "-O3"
      #endif
    #else
      /* ARM Compiler 5 */
      #ifdef __OPTIMISE_SPACE
        #define _OPTIMISE_LEVEL_STRING(x) #x
        #define _OPTIMISE_OPTION_STRING(x) "-Ospace -O"##_OPTIMISE_LEVEL_STRING(x)
        #define COMPILER_FLAGS _OPTIMISE_OPTION_STRING(__OPTIMISE_LEVEL)
      #elif __OPTIMISE_TIME
        #define _OPTIMISE_LEVEL_STRING(x) #x
        #define _OPTIMISE_OPTION_STRING(x) "-Otime -O"##_OPTIMISE_LEVEL_STRING(x)
        #define COMPILER_FLAGS _OPTIMISE_OPTION_STRING(__OPTIMISE_LEVEL)
      #else
        #define _OPTIMISE_LEVEL_STRING(x) #x
        #define _OPTIMISE_OPTION_STRING(x) "-O"##_OPTIMISE_LEVEL_STRING(x)
        #define COMPILER_FLAGS _OPTIMISE_OPTION_STRING(__OPTIMISE_LEVEL)
      #endif
    #endif
  #elif defined __ICCARM__
    #define COMPILER_FLAGS "-o3" /* "Please put compiler flags here (e.g. -o3)" */
  #else
    #define COMPILER_FLAGS "-o3" /* "Please put compiler flags here (e.g. -o3)" */
    //#define COMPILER_FLAGS \
    //FLAGS_STR /* "Please put compiler flags here (e.g. -o3)" */
  #endif
#endif
```
We also need to add the MEM_LOCATION_UNSPEC macro:

```C
#ifndef MEM_LOCATION
  #define MEM_LOCATION "STACK"
  #define MEM_LOCATION_UNSPEC 0
#endif
```
And finally, set MAIN_HAS_NOARGC:

```C
#ifndef MAIN_HAS_NOARGC
#define MAIN_HAS_NOARGC 1
#endif
```

### Modifications of core_portme.c

Note: The following codes are example. You can change the codes in other ways.

In this file, first you might need to declare external functions for printf, timer and cache support. For example, in my project I declared the following external functions:

```C
extern void timer_config(void); /* Initialize a timer peripheral */
extern void stdio_init(void);   /* Initialize printf support (e.g. UART) */
extern void cache_init(void);   /* Initialize processor's cache if available */
extern unsigned long get_100Hz_value(void); /* Read a timer value with 0.01 sec resolution */
```

Then I modified the barebones_clock() function as:

```C
CORETIMETYPE
barebones_clock()
{
/*#error \
    "You must implement a method to measure time in barebones_clock()! This function should return current time.\n"
    */
  return get_100Hz_value();  
}
```

In this example, the timer value increments at 100Hz. So I need to tell the score calculation code with the following settings:

```C
/* Define : TIMER_RES_DIVIDER
        Divider to trade off timer resolution and total time that can be
   measured.

        Use lower values to increase resolution, but make sure that overflow
   does not occur. If there are issues with the return value overflowing,
   increase this value.
        */
#define CLOCKS_PER_SEC             100
#define GETMYTIME(_t)              (*_t = barebones_clock())
#define MYTIMEDIFF(fin, ini)       ((fin) - (ini))
#define TIMER_RES_DIVIDER          1
#define SAMPLE_TIME_IMPLEMENTATION 1
#define EE_TICKS_PER_SEC           (CLOCKS_PER_SEC / TIMER_RES_DIVIDER)
```

Finally, the platform initialization code is updated as follow:

```C
/* Function : portable_init
        Target specific initialization code
        Test for some common mistakes.
*/
void
portable_init(core_portable *p, int *argc, char *argv[])
{

/* #error \
    "Call board initialization routines in portable init (if needed), in particular initialize UART!\n"

    (void)argc; // prevent unused warning
    (void)argv; // prevent unused warning
*/
    /* Hardware initialization */
    stdio_init();
    cache_init();
    timer_config();
    
    if (sizeof(ee_ptr_int) != sizeof(ee_u8 *))
    {
        ee_printf(
            "ERROR! Please define ee_ptr_int to a type that holds a "
            "pointer!\n");
    }
    if (sizeof(ee_u32) != 4)
    {
        ee_printf("ERROR! Please define ee_u32 to a 32b unsigned type!\n");
    }
    p->portable_id = 1;
}
```

## Additional considerations

Typically the CoreMark project fit within 32KB of ROM/flash and use less than 32KB of RAM. The stack and heap sizes inside the RAM is dependent on the processor architecture as well as the toolchain being used. For example, some toolchains could use more RAM for printf and floating-point library. In toolchains for Arm Cortex-M based microcontrollers, typically the CoreMark uses less than 4KB of stack and 4KB of heap space.

