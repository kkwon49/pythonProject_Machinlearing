/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 * File: _coder_tf_csm_welch_w128_api.h
 *
 * MATLAB Coder version            : 3.3
 * C/C++ source code generated on  : 27-Mar-2018 16:29:53
 */

#ifndef _CODER_TF_CSM_WELCH_W128_API_H
#define _CODER_TF_CSM_WELCH_W128_API_H

/* Include Files */
#include "tmwtypes.h"
#include "mex.h"
#include "emlrt.h"
#include <stddef.h>
#include <stdlib.h>
#include "_coder_tf_csm_welch_w128_api.h"

/* Variable Declarations */
extern emlrtCTX emlrtRootTLSGlobal;
extern emlrtContext emlrtContextGlobal;

/* Function Declarations */
extern void tf_csm_welch_w128(real_T X[256], real32_T Y[192]);
extern void tf_csm_welch_w128_api(const mxArray *prhs[1], const mxArray *plhs[1]);
extern void tf_csm_welch_w128_atexit(void);
extern void tf_csm_welch_w128_initialize(void);
extern void tf_csm_welch_w128_terminate(void);
extern void tf_csm_welch_w128_xil_terminate(void);

#endif

/*
 * File trailer for _coder_tf_csm_welch_w128_api.h
 *
 * [EOF]
 */
