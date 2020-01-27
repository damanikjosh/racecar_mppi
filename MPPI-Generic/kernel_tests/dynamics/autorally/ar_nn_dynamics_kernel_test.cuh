#ifndef AR_NN_DYNAMICS_KERNEL_TEST_CUH
#define AR_NN_DYNAMICS_KERNEL_TEST_CUH

#include <array>
#include <dynamics/autorally/ar_nn_model.cuh>
#include <cuda_runtime.h>

template<class NETWORK_T, int THETA_SIZE, int STRIDE_SIZE, int NUM_LAYERS>
void launchParameterCheckTestKernel(NETWORK_T& model, std::array<float, THETA_SIZE>& theta, std::array<int, STRIDE_SIZE>& stride,
        std::array<int, NUM_LAYERS>& net_structure);


template <class NETWORK_T, int THETA_SIZE, int STRIDE_SIZE, int NUM_LAYERS>
__global__ void parameterCheckTestKernel(NETWORK_T* model,  float* theta, int* stride, int* net_structure);


template<class NETWORK_T, int BLOCK_DIM_Y, int STATE_DIM>
void launchIncrementStateTestKernel(NETWORK_T& model, std::array<float, STATE_DIM>& state, std::array<float, 7>& state_der);

template<class NETWORK_T, int STATE_DIM>
__global__ void incrementStateTestKernel(NETWORK_T* model, float* state, float* state_der);

template<class NETWORK_T>
void launchComputeDynamicsKernel(NETWORK_T& model, float* state, float* control, float* state_der, float* theta_s);

template<class NETWORK_T>
__global__ void computeDynamicsKernel(NETWORK_T& model, float* state, float* control, float* state_der, float* theta_s);

template<class NETWORK_T>
void launchComputeStateDerivKernel(NETWORK_T& model, float* state, float* control, float* state_der, float* theta_s);

template<class NETWORK_T>
__global__ void computeStateDerivKernel(NETWORK_T& model, float* state, float* control, float* state_der, float* theta_s);

template<class NETWORK_T>
void launchFullARNNTestKernel(NETWORK_T& model, float* state, float* control, float* state_der, float* theta_s);

template<class NETWORK_T>
__global__ void fullARNNTestKernel(NETWORK_T& model, float* state, float* control, float* state_der, float* theta_s);
// calls enforce constraints -> compute state derivative -> increment state


#endif //AR_NN_DYNAMICS_KERNEL_TEST_CUH
