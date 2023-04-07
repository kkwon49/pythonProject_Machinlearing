//
// Academic License - for use in teaching, academic research, and meeting
// course requirements at degree granting institutions only.  Not for
// government, commercial, or other organizational use.
// File: rearrange_5c.h
//
// MATLAB Coder version            : 3.3
// C/C++ source code generated on  : 14-Sep-2018 10:16:29
//
#ifndef REARRANGE_5C_H
#define REARRANGE_5C_H

// Include Files
#include <stddef.h>
#include <stdlib.h>
#include "rtwtypes.h"
#include "rearrange_5c_types.h"

// Function Declarations
extern void maximize_probs(const float X[10000], double max_prob[10000]);
extern void maximize_probs_float(const float X[10000], float max_prob[10000]);
extern void rearrange_5c(const float input_array[10000], float rearranged[10000]);
extern void rearrange_2c(const float input_array[4000], float rearranged[4000]);
extern void get_class_distribution(const float input_array[4000], double
*b_index, float scores[2]);

extern void get_class_distribution_c5(const float input_array[10000], double *b_index, float scores[5]);
extern void rearrange_5c_initialize();
extern void rearrange_5c_terminate();

#endif

//
// File trailer for rearrange_5c.h
//
// [EOF]
//
