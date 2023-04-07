//
// Academic License - for use in teaching, academic research, and meeting
// course requirements at degree granting institutions only.  Not for
// government, commercial, or other organizational use.
// File: get_hr_rr_emxutil.h
//
// MATLAB Coder version            : 3.3
// C/C++ source code generated on  : 02-Dec-2018 18:36:01
//
#ifndef GET_HR_RR_EMXUTIL_H
#define GET_HR_RR_EMXUTIL_H

// Include Files
#include <stddef.h>
#include <stdlib.h>
#include <string.h>
#include "rt_nonfinite.h"
#include "rtwtypes.h"
#include "get_hr_rr_types.h"

// Function Declarations
extern void emxEnsureCapacity(emxArray__common *emxArray, int oldNumel, unsigned
  int elementSize);
extern void emxFree_real_T(emxArray_real_T **pEmxArray);
extern void emxInit_real_T(emxArray_real_T **pEmxArray, int b_numDimensions);
extern void emxInit_real_T1(emxArray_real_T **pEmxArray, int b_numDimensions);

#endif

//
// File trailer for get_hr_rr_emxutil.h
//
// [EOF]
//
