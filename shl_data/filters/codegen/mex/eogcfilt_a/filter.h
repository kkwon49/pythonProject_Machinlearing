/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * filter.h
 *
 * Code generation for function 'filter'
 *
 */

#ifndef FILTER_H
#define FILTER_H

/* Include files */
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "mwmathutil.h"
#include "tmwtypes.h"
#include "mex.h"
#include "emlrt.h"
#include "covrt.h"
#include "rtwtypes.h"
#include "eogcfilt_a_types.h"

/* Function Declarations */
extern void filter(const emlrtStack *sp, real_T b[7], real_T a[7], const real_T
                   x[1036], const real_T zi[6], real_T y[1036]);

#endif

/* End of code generation (filter.h) */
