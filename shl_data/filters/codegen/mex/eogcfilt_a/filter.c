/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * filter.c
 *
 * Code generation for function 'filter'
 *
 */

/* Include files */
#include "rt_nonfinite.h"
#include "eogcfilt_a.h"
#include "filter.h"
#include "error.h"

/* Variable Definitions */
static emlrtRSInfo d_emlrtRSI = { 97, "filter",
  "C:\\Program Files\\MATLAB\\R2016a\\toolbox\\eml\\lib\\matlab\\datafun\\filter.m"
};

static emlrtRSInfo e_emlrtRSI = { 99, "filter",
  "C:\\Program Files\\MATLAB\\R2016a\\toolbox\\eml\\lib\\matlab\\datafun\\filter.m"
};

/* Function Definitions */
void filter(const emlrtStack *sp, real_T b[7], real_T a[7], const real_T x[1036],
            const real_T zi[6], real_T y[1036])
{
  real_T a1;
  int32_T k;
  real_T dbuffer[7];
  int32_T j;
  emlrtStack st;
  st.prev = sp;
  st.tls = sp->tls;
  a1 = a[0];
  if (!((!muDoubleScalarIsInf(a[0])) && (!muDoubleScalarIsNaN(a[0])))) {
    st.site = &d_emlrtRSI;
    error(&st);
  } else if (a[0] == 0.0) {
    st.site = &e_emlrtRSI;
    b_error(&st);
  } else {
    if (a[0] != 1.0) {
      for (k = 0; k < 7; k++) {
        b[k] /= a1;
      }

      for (k = 0; k < 6; k++) {
        a[k + 1] /= a1;
      }

      a[0] = 1.0;
    }
  }

  for (k = 0; k < 6; k++) {
    dbuffer[k + 1] = zi[k];
  }

  for (j = 0; j < 1036; j++) {
    for (k = 0; k < 6; k++) {
      dbuffer[k] = dbuffer[k + 1];
    }

    dbuffer[6] = 0.0;
    for (k = 0; k < 7; k++) {
      dbuffer[k] += x[j] * b[k];
    }

    for (k = 0; k < 6; k++) {
      dbuffer[k + 1] -= dbuffer[0] * a[k + 1];
    }

    y[j] = dbuffer[0];
  }
}

/* End of code generation (filter.c) */
