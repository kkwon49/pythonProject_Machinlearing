//
// Academic License - for use in teaching, academic research, and meeting
// course requirements at degree granting institutions only.  Not for
// government, commercial, or other organizational use.
// File: eegcfilt.h
//
// MATLAB Coder version            : 3.1
// C/C++ source code generated on  : 03-Apr-2017 14:33:13
//
#ifndef EEGCFILT_H
#define EEGCFILT_H

// Include Files
#include <stddef.h>
#include <stdlib.h>
#include <string.h>
#include "rtwtypes.h"
#include "eegcfilt_types.h"

// Function Declarations
extern void eegcfilt(const emxArray_real_T *X, emxArray_real_T *Y);
extern void eegcfilt_initialize();
extern void eegcfilt_terminate();
extern emxArray_real_T *emxCreateND_real_T(int numDimensions, int *size);
extern emxArray_real_T *emxCreateWrapperND_real_T(double *data, int
  numDimensions, int *size);
extern emxArray_real_T *emxCreateWrapper_real_T(double *data, int rows, int cols);
extern emxArray_real_T *emxCreate_real_T(int rows, int cols);
extern void emxDestroyArray_real_T(emxArray_real_T *emxArray);
extern void emxInitArray_real_T(emxArray_real_T **pEmxArray, int numDimensions);

#endif

//
// File trailer for eegcfilt.h
//
// [EOF]
//
