/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 * File: _coder_eegcfilt_api.h
 *
 * MATLAB Coder version            : 3.1
 * C/C++ source code generated on  : 03-Apr-2017 14:33:13
 */

#ifndef _CODER_EEGCFILT_API_H
#define _CODER_EEGCFILT_API_H

/* Include Files */
#include "tmwtypes.h"
#include "mex.h"
#include "emlrt.h"
#include <stddef.h>
#include <stdlib.h>
#include "_coder_eegcfilt_api.h"

/* Type Definitions */
#ifndef struct_emxArray_real_T
#define struct_emxArray_real_T

struct emxArray_real_T
{
  real_T *data;
  int32_T *size;
  int32_T allocatedSize;
  int32_T numDimensions;
  boolean_T canFreeData;
};

#endif                                 /*struct_emxArray_real_T*/

#ifndef typedef_emxArray_real_T
#define typedef_emxArray_real_T

typedef struct emxArray_real_T emxArray_real_T;

#endif                                 /*typedef_emxArray_real_T*/

/* Variable Declarations */
extern emlrtCTX emlrtRootTLSGlobal;
extern emlrtContext emlrtContextGlobal;

/* Function Declarations */
extern void eegcfilt(emxArray_real_T *X, emxArray_real_T *Y);
extern void eegcfilt_api(const mxArray *prhs[1], const mxArray *plhs[1]);
extern void eegcfilt_atexit(void);
extern void eegcfilt_initialize(void);
extern void eegcfilt_terminate(void);
extern void eegcfilt_xil_terminate(void);

#endif

/*
 * File trailer for _coder_eegcfilt_api.h
 *
 * [EOF]
 */
