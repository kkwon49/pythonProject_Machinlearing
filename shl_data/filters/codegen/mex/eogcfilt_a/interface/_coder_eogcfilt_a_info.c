/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * _coder_eogcfilt_a_info.c
 *
 * Code generation for function '_coder_eogcfilt_a_info'
 *
 */

/* Include files */
#include "rt_nonfinite.h"
#include "eogcfilt_a.h"
#include "_coder_eogcfilt_a_info.h"
#include "eogcfilt_a_data.h"

/* Function Definitions */
mxArray *emlrtMexFcnProperties(void)
{
  mxArray *xResult;
  mxArray *xEntryPoints;
  const char * fldNames[4] = { "Name", "NumberOfInputs", "NumberOfOutputs",
    "ConstantInputs" };

  mxArray *xInputs;
  const char * b_fldNames[4] = { "Version", "ResolvedFunctions", "EntryPoints",
    "CoverageInfo" };

  xEntryPoints = emlrtCreateStructMatrix(1, 1, 4, fldNames);
  xInputs = emlrtCreateLogicalMatrix(1, 1);
  emlrtSetField(xEntryPoints, 0, "Name", mxCreateString("eogcfilt_a"));
  emlrtSetField(xEntryPoints, 0, "NumberOfInputs", mxCreateDoubleScalar(1.0));
  emlrtSetField(xEntryPoints, 0, "NumberOfOutputs", mxCreateDoubleScalar(1.0));
  emlrtSetField(xEntryPoints, 0, "ConstantInputs", xInputs);
  xResult = emlrtCreateStructMatrix(1, 1, 4, b_fldNames);
  emlrtSetField(xResult, 0, "Version", mxCreateString("9.0.0.341360 (R2016a)"));
  emlrtSetField(xResult, 0, "ResolvedFunctions", (mxArray *)
                emlrtMexFcnResolvedFunctionsInfo());
  emlrtSetField(xResult, 0, "EntryPoints", xEntryPoints);
  emlrtSetField(xResult, 0, "CoverageInfo", covrtSerializeInstanceData
                (&emlrtCoverageInstance));
  return xResult;
}

const mxArray *emlrtMexFcnResolvedFunctionsInfo(void)
{
  const mxArray *nameCaptureInfo;
  const char * data[18] = {
    "789ced1d4d6f1b4574d2a6a1452a2d5f02540912905051d46c0b12a09ee2a689e2d6494c93945469e4aed7637be8ee8cb5bb2e2ea7154828478e1c91b8202a04"
    "478ef003b8c1cf40e2007776bc76b29eae3ddbfdf2da79962ce7c5f366dee7bc79336fd668a6b881dcd70bee7bf90784e6dccfb3eefb14f25e677af08cfbfea8",
    "f7e9fd7f169defc15fba6f8d511b776cef4baa1a18f55f356610aa527be7710b23135b4c7f846bdd6fea44c73bc4c025e603d6890b186bbeaf8e00fe95d9b48e"
    "7a46ba1ff05e9c8fefd0311fb3017c7ce6e3e3620fde5f3d58b9aeec5ad8b414436d1a8cd50c4bb969b25695759472bbaa134da9dc5dd955ee61365f52ab4a65",
    "7bfbee6a59a96c14764a851b57bad095155db52c52279a6a13461597299bf7885943e37f57d425e398ce8f25749e15e83ceb89c9e6ef30f87302fe5c571b2e2b"
    "d81bbf23c12f08f81cde2fee7525553659c3548d79ae1b4bf164a0dc79ffeab50f55c5664ce752b34883aaba820d5de993dd67ff29fee702c69ff18d7faef77f",
    "849ce71f7ef567213a7edcf193c3bfecc39f09c047becf28edc7addf75c9f8af0ae3735863356c2e11773231ddbe97744c1b76b3d7dfd511fdf55ffefefa7438"
    "123a3605bccdae1c4ae105c125c0df8b5dea95c53ef98a473e174a0c7b5f3c55fa0bec3d44fb71dbfb28fbe4e39e1e18ff3432d44ea838209bc71d097e51c02f",
    "a208f6ad93aa1b186ddd8d7c35d556eb6dea829d04e673f4cf390dec3b4c7b07e543cfb279fd75810e0e0bf33a55cd06a15af3619c79fd1b091df705bcfbcf2a"
    "0faba99ab8a678b37a6f6e17a7f8234e3c11c598e75fbe7e07d63561da4f82de83e83a23d0c5e1bace9819123f6f7100eb7c76e87290441cf87df75d8803798c",
    "03c3f45c96d0f196400787853840ac1b6d771955a49b6d039b444bc40f0e25f87b02fe5e14f904aef74576968c18f6b43eff07c48369f2874b021d1c16fcc1d2"
    "545d3597fa51215ede2bf3835d016f378a5c02fd60d1e3c327a318eba21f3f7d03e2c224f9c103091def09747058f003b5d5d21f6f778d68ad4d35be995aa465",
    "5dd5b06f9c65c938178471385ceff55669aab4e6060cdecfb7927eaa423fd528720bf493e16c0edb277e06bb33fffd00fc264cfbbceb3fadb892f63a0be2cb74"
    "f98983b28d2f51f79f5e13e8e0b0e00f06a15be6466fff55b66f3b3bd0df2cd29aaa19461e65818e72147904da7f9ffc58f9c541a506769f84dd67a56799ddc3",
    "be2becbb8e73dff5000dea9dc349fbc182fb7d05776c131bed7edc07bf00bfc873fea0a241bd733815bfa812eaf78d3e7d09ac97bcf5f66a2393738af4e2699f"
    "8d58eba6cb7f6fc1ba29dfeba6413d2f4be8382fd0c16162516f0bdfe6658bd99ccf6d09f85b51e4c1f3a73ae9e05a8bb9e25006f87043420cbbf909f2e4c9b2",
    "fb28f5a5c4aa1337fd6e6661efb704fc5b51e4f094bd7bf427b07f0af61eb2fd211aade7f4ce5b8fed7da14e4ccbae9330fba56f0af470982f9fdc6e2b7566ea"
    "8cb52aec1136eb3afbbca235b1f630de399c2c2f7820e03d88221fffb98c27ae11fcc459ff383f835f846bff2b1aadf7afd1a0de399cb6de174637a834b1dec2",
    "66b87a56715f94cfbd09e51b84d670a748ed5075bd6b427f6b51e528c4917875db103fc2b61fb77e9725e387cd0fd23a4780bc603aec7cd2e341947cc0ed9a5f"
    "7348d53f12cb238eea5adc3f148ff204f208582f856c7f52fd83d049f50f42c13f8ef1d3f68f43345acf59e7d951f383b4ef2d433e30d9769ef7f3b484eaf170",
    "a755d075a605ea258d7abc1d017f2731b9f9d9897bee8c9e809f24130fb2d6f79e849eb7057a383cc22f36d98ab7f71aa48f28fe21db87dd17f0f75391578fad"
    "dec229c63eecc5c7b3e02749c493261ad43b87538927de326a20ac407d06d4670cc33fe97e01f74be17e691efc44966f16d0a0be399ce573945e14c6e730772b",
    "c32606b68eb6a88efa4beb3ee9b680b78de2ed33b196a53cc547fc75d32f905f24131f5434a86f0ea7a0ef058d1906a3de86abe5a30fe203c4873cf8c9b8e343"
    "147bf59e4c994d5d6b49c02fa164ee057a3cc4bee7f01b3c77265c7b07e543cfb2738761cfd993ada39eb52e49260f78eede74d87ddecf2312b0eb81fda3acfd",
    "04f693a6c34f1c940f3d2f4be8085bcf97b51f409d1ff8419eeeff646dff701f683aecff108dd6f3a4d429256dff50b734dd769ff73c21adbaa5a4fd44367f40"
    "1dd374f94ddef49d761d53d2fe02754d27d36ff25ebf91809dc3be141a6a67b02f15b27ddefd24ad73ecacd76570ae3d5d7ee3a0d1faceeabc4fb61e7b47a083",
    "c3821d6b8c5af626a3db8436746c337a9304af53d2a82b8ffddcbfa17e11c456ecf370781e72c8f60eca877f24bdce82fa71b0ff49b2ffa8e71c94d87812eb9f"
    "7af7af7b1cc4dea782fbd721db3b281f7a86ba57c80fc01fe2fdee22b108ad87c48f3bff275d07d89783cb4112758030ff876cefa07ce819e67f98ff27c11ff2",
    "3dff539586c4cfebfcef7200f3bf0f7fdcf69e959e61fe87f97f12fc212ffb9faf08747058f0076c9ade0f23f2fed27a0edf8640c746147904da7f97fcb8bf83"
    "f81fc6100726c9ee6571009e730fcfb93f49fe205bbf3c27d0c161b3461e911a9ec83c803f2fa1477f027980f3e4d22760ef79cc0386e919f200c803c01f8ee9",
    "90f9c3bc40078783ebb65798d1526de25a7416f541f704fc7b51e433aa3efb989d24f68be05e43c8f60eca875fac4be87849a083c3825fb8bd06cb3d8d75d26d"
    "01ff7614b904fa83cb46fcfb09dfc33a69b2f20299fd87a88f6b99ac66912fb2c913d2ab8febb3116b5d74e1dd55581785692fbbef5b40837ae6f0d89f0ba693",
    "56bb96cd3c9fceef92781cc4bfefef5c3b80fdd044e6f9acf40cf33cccf327d9fee13c00ce03c6ed0fff0399e7cc85",
    "" };

  nameCaptureInfo = NULL;
  emlrtNameCaptureMxArrayR2016a(data, 43088U, &nameCaptureInfo);
  return nameCaptureInfo;
}

/* End of code generation (_coder_eogcfilt_a_info.c) */
