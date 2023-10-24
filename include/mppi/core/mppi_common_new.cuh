/**
 * Created by Bogdan Vlahov on 3/25/2023
 **/
#pragma once
#include <mppi/utils/math_utils.h>
#include <mppi/dynamics/dynamics.cuh>
#include <mppi/cost_functions/cost.cuh>

namespace mppi
{
namespace kernels
{
/**
 * Kernels Methods
 **/

template <class COST_T, class SAMPLING_T, int BLOCKSIZE_X, bool COALESCE = true>
__global__ void rolloutCostKernel(COST_T* __restrict__ costs, SAMPLING_T* __restrict__ sampling, float dt,
                                  const int num_timesteps, const int num_rollouts, float lambda, float alpha,
                                  const float* __restrict__ y_d, float* __restrict__ trajectory_costs_d);

template <class DYN_T, class COST_T, class SAMPLING_T>
__global__ void rolloutKernel(DYN_T* __restrict__ dynamics, SAMPLING_T* __restrict__ sampling,
                              COST_T* __restrict__ costs, float dt, const int num_timesteps, const int num_rollouts,
                              const float* __restrict__ init_x_d, float lambda, float alpha,
                              float* __restrict__ trajectory_costs_d);

template <class DYN_T, class SAMPLING_T>
__global__ void rolloutDynamicsKernel(DYN_T* __restrict__ dynamics, SAMPLING_T* __restrict__ sampling, float dt,
                                      const int num_timesteps, const int num_rollouts,
                                      const float* __restrict__ init_x_d, float* __restrict__ y_d);

template <class DYN_T, class COST_T, class SAMPLING_T>
__global__ void visualizeKernel(DYN_T* __restrict__ dynamics, SAMPLING_T* __restrict__ sampling,
                                COST_T* __restrict__ costs, float dt, const int num_timesteps, const int num_rollouts,
                                const float* __restrict__ init_x_d, float lambda, float alpha, float* __restrict__ y_d,
                                float* __restrict__ cost_traj_d, int* __restrict__ crash_status_d);

template <class COST_T, class SAMPLING_T, bool COALESCE = true>
__global__ void visualizeCostKernel(COST_T* __restrict__ costs, SAMPLING_T* __restrict__ sampling, float dt,
                                    const int num_timesteps, const int num_rollouts, const float lambda, float alpha,
                                    const float* __restrict__ y_d, float* __restrict__ cost_traj_d,
                                    int* __restrict__ crash_status_d);

template <int CONTROL_DIM>
__global__ void weightedReductionKernel(const float* __restrict__ exp_costs_d, const float* __restrict__ du_d,
                                        float* __restrict__ new_u_d, const float normalizer, const int num_timesteps,
                                        const int num_rollouts, const int sum_stride);

/**
 * Device-only Kernel Helper Methods
 **/

__device__ void setInitialControlToZero(int control_dim, int thread_idx, float* __restrict__ u,
                                        float* __restrict__ u_intermediate);

__device__ void strideControlWeightReduction(const int num_rollouts, const int num_timesteps, const int sum_stride,
                                             const int thread_idx, const int block_idx, const int control_dim,
                                             const float* __restrict__ exp_costs_d, const float normalizer,
                                             const float* __restrict__ du_d, float* __restrict__ u,
                                             float* __restrict__ u_intermediate);

template <int STATE_DIM, int CONTROL_DIM>
__device__ void loadGlobalToShared(const int num_rollouts, const int blocksize_y, const int global_idx,
                                   const int thread_idy, const int thread_idz, const float* __restrict__ x_device,
                                   float* __restrict__ x_thread, float* __restrict__ xdot_thread, float* u_thread);

template <int BLOCKSIZE>
__device__ void warpReduceAdd(volatile float* sdata, const int tid, const int stride = 1);

__device__ inline void costArrayReduction(float* running_cost, const int start_size, const int index, const int step,
                                          const bool catch_condition, const int stride = 1);
/**
 * Launch Kernel Methods
 **/
template <class DYN_T, class COST_T, typename SAMPLING_T>
void launchSplitRolloutKernel(DYN_T* __restrict__ dynamics, COST_T* __restrict__ costs,
                             SAMPLING_T* __restrict__ sampling, float dt, const int num_timesteps,
                             const int num_rollouts, float lambda, float alpha, float* __restrict__ init_x_d,
                             float* __restrict__ y_d, float* __restrict__ trajectory_costs, dim3 dimDynBlock,
                             dim3 dimCostBlock, cudaStream_t stream, bool synchronize = true);

template <class DYN_T, class COST_T, typename SAMPLING_T>
void launchRolloutKernel(DYN_T* __restrict__ dynamics, COST_T* __restrict__ costs, SAMPLING_T* __restrict__ sampling,
                         float dt, const int num_timesteps, const int num_rollouts, float lambda, float alpha,
                         float* __restrict__ init_x_d, float* __restrict__ trajectory_costs,
                         dim3 dimBlock, cudaStream_t stream, bool synchronize);

template <class COST_T, class SAMPLING_T>
void launchVisualizeCostKernel(COST_T* __restrict__ costs, SAMPLING_T* __restrict__ sampling, float dt,
                               const int num_timesteps, const int num_rollouts, float lambda, float alpha,
                               float* __restrict__ y_d, int* __restrict__ sampled_crash_status_d,
                               float* __restrict__ cost_traj_result, dim3 dimBlock, cudaStream_t stream,
                               bool synchronize = true);

template <class DYN_T, class COST_T, typename SAMPLING_T>
void launchVisualizeKernel(DYN_T* __restrict__ dynamics, COST_T* __restrict__ costs, SAMPLING_T* __restrict__ sampling,
                           float dt, const int num_timesteps, const int num_rollouts, float lambda, float alpha,
                           float* __restrict__ init_x_d, float* __restrict__ y_d, float* __restrict__ trajectory_costs,
                           int* __restrict__ crash_status_d, dim3 dimVisBlock, cudaStream_t stream,
                           bool synchronize = true);

template <int CONTROL_DIM>
void launchWeightedReductionKernel(const float* __restrict__ exp_costs_d, const float* __restrict__ du_d,
                                   float* __restrict__ new_u_d, const float normalizer, const int num_timesteps,
                                   const int num_rollouts, const int sum_stride, cudaStream_t stream,
                                   bool synchronize = true);

/**
 * Shared Memory Calculators for various kernels
 */
template <class DYN_T, class SAMPLER_T>
unsigned calcRolloutDynamicsKernelSharedMemSize(const DYN_T* dynamics, const SAMPLER_T* sampler, dim3& dimBlock);

template <class COST_T, class SAMPLER_T>
unsigned calcRolloutCostKernelSharedMemSize(const COST_T* cost, const SAMPLER_T* sampler, dim3& dimBlock);

template <class DYN_T, class COST_T, class SAMPLER_T>
unsigned calcRolloutCombinedKernelSharedMemSize(const DYN_T* dynamics, const COST_T* cost, const SAMPLER_T* sampler,
                                                dim3& dimBlock);

template <class DYN_T, class COST_T, class SAMPLER_T>
unsigned calcVisualizeKernelSharedMemSize(const DYN_T* dynamics, const COST_T* cost, const SAMPLER_T* sampler,
                                          const int& num_timesteps, dim3& dimBlock);

template <class COST_T, class SAMPLER_T>
unsigned calcVisCostKernelSharedMemSize(const COST_T* cost, const SAMPLER_T* sampler, const int& num_timesteps,
                                        dim3& dimBlock);

template <class DYN_T>
__host__ __device__ inline unsigned calcDynamicsSharedMemSize(const DYN_T* dynamics, const dim3& dimBlock);

template <class SAMPLER_T>
__host__ __device__ inline unsigned calcSamplerSharedMemSize(const SAMPLER_T* sampler, const dim3& dimBlock);

template <class COST_T>
__host__ __device__ inline unsigned calcCostSharedMemSize(const COST_T* cost, const dim3& dimBlock);
}  // namespace kernels
}  // namespace mppi

#if __CUDACC__
#include "mppi_common_new.cu"
#endif
