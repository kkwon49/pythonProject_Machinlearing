/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 * File: _coder_tf_psd_rescale_w512_api.h
 *
 * MATLAB Coder version            : 3.3
 * C/C++ source code generated on  : 25-Feb-2018 09:04:49
 */

#ifndef _CODER_TF_PSD_RESCALE_W512_API_H
#define _CODER_TF_PSD_RESCALE_W512_API_H

/* Include Files */
#include "tmwtypes.h"
#include "mex.h"
#include "emlrt.h"
#include <stddef.h>
#include <stdlib.h>
#include "_coder_tf_psd_rescale_w512_api.h"

/* Variable Declarations */
extern emlrtCTX emlrtRootTLSGlobal;
extern emlrtContext emlrtContextGlobal;

/* Function Declarations */
extern void tf_psd_rescale_w512(real_T X[1024], real32_T Y[512]);
extern void tf_psd_rescale_w512_api(const mxArray *prhs[1], const mxArray *plhs
  [1]);
extern void tf_psd_rescale_w512_atexit(void);
extern void tf_psd_rescale_w512_initialize(void);
extern void tf_psd_rescale_w512_terminate(void);
extern void tf_psd_rescale_w512_xil_terminate(void);

#endif

/*
 * File trailer for _coder_tf_psd_rescale_w512_api.h
 *
 * [EOF]
 */
