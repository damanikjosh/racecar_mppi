#pragma once
/*
Header file for costs
*/

#ifndef COSTS_CUH_
#define COSTS_CUH_

#include<Eigen/Dense>
#include <stdio.h>
#include <math.h>
#include <mppi/utils/managed.cuh>
#include <opencv2/core/core.hpp>
#include <opencv2/highgui/highgui.hpp>

#include <stdexcept>


template<int C_DIM>
struct CostParams {
  float control_cost_coeff[C_DIM];
  float discount = 1.0;
  CostParams() {
    //Default set all controls to 1
    for (int i = 0; i < C_DIM; ++i) {
      control_cost_coeff[i] = 1.0;
    }
  }
};


// removing PARAMS_T is probably impossible
// https://cboard.cprogramming.com/cplusplus-programming/122412-crtp-how-pass-type.html
template<class CLASS_T, class PARAMS_T, int S_DIM, int C_DIM>
class Cost : public Managed
{
public:
//  EIGEN_MAKE_ALIGNED_OPERATOR_NEW

  /**
     * typedefs for access to templated class from outside classes
     */
  static const int STATE_DIM = S_DIM;
  static const int CONTROL_DIM = C_DIM;
  typedef CLASS_T COST_T;
  typedef PARAMS_T COST_PARAMS_T;
  typedef Eigen::Matrix<float, CONTROL_DIM, 1> control_array; // Control at a time t
  typedef Eigen::Matrix<float, CONTROL_DIM, CONTROL_DIM> control_matrix; // Control at a time t
  typedef Eigen::Matrix<float, STATE_DIM, 1> state_array; // State at a time t

  Cost() = default;
  /**
   * Destructor must be virtual so that children are properly
   * destroyed when called from a basePlant reference
   */
  virtual ~Cost() {
    freeCudaMem();
  }

  void GPUSetup();

  bool getDebugDisplayEnabled() {return false;}

  /**
   * returns a debug display that will be visualized based off of the state
   * @param state vector
   * @return
   */
  cv::Mat getDebugDisplay(float* s) {
    return cv::Mat();
  }

  /**
   * Updates the cost parameters
   * @param params
   */
  void setParams(PARAMS_T params) {
    params_ = params;
    if(GPUMemStatus_) {
      CLASS_T& derived = static_cast<CLASS_T&>(*this);
      derived.paramsToDevice();
    }
  }

  __host__ __device__ PARAMS_T getParams() {
    return params_;
  }

  void paramsToDevice();

  /**
   *
   * @param description
   * @param data
   */
  void updateCostmap(std::vector<int> description, std::vector<float> data) {};

  /**
   * deallocates the allocated cuda memory for an object
   */
  void freeCudaMem();

  /**
   * Computes the feedback control cost on CPU for RMPPI
   */
  float computeFeedbackCost(const Eigen::Ref<const control_array> fb_u,
                            const Eigen::Ref<const control_array> std_dev,
                            const float lambda = 1.0,
                            const float alpha = 0.0) {
    float cost = 0;
    for (int i = 0; i < CONTROL_DIM; i++) {
      cost += params_.control_cost_coeff[i] * fb_u(i) * fb_u(i) / powf(std_dev(i), 2);
    }

    return 0.5 * lambda * (1 - alpha) * cost;
  }

  /**
   * Computes the control cost on CPU. This is the normal control cost calculation
   * in MPPI and Tube-MPPI
   */
  float computeLikelihoodRatioCost(const Eigen::Ref<const control_array> u,
                                   const Eigen::Ref<const control_array> noise,
                                   const Eigen::Ref<const control_array> std_dev,
                                   const float lambda = 1.0,
                                   const float alpha = 0.0) {
    float cost = 0;
    for (int i = 0; i < CONTROL_DIM; i++) {
      cost += params_.control_cost_coeff[i] * u(i) * (u(i) + 2 * noise(i)) /
        (std_dev(i) * std_dev(i));
    }
    return 0.5 * lambda * (1 - alpha) * cost;
  }
  // =================== METHODS THAT SHOULD HAVE NO DEFAULT ==========================
  /**
   * Computes the state cost on the CPU. Should be implemented in subclasses
   */
  float computeStateCost(const Eigen::Ref<const state_array> s, int timestep = 0) {
    throw std::logic_error("SubClass did not implement computeStateCost");
  }

  /**
   *
   * @param s current state as a float array
   * @return state cost on GPU
   */
  __device__ float computeStateCost(float* s, int timestep = 0);


  /**
   * Computes the state cost on the CPU. Should be implemented in subclasses
   */
  float terminalCost(const Eigen::Ref<const state_array> s) {
    throw std::logic_error("SubClass did not implement terminalCost");
  }

  /**
   *
   * @param s terminal state as float array
   * @return terminal cost on GPU
   */
  __device__ float terminalCost(float* s);

  // ================ END OF METHODS WITH NO DEFAULT ===========================

  // =================== METHODS THAT SHOULD NOT BE OVERWRITTEN ================
  /**
   * Computes the feedback control cost on GPU used in RMPPI. There is an
   * assumption that we are provided std_dev and the covriance matrix is
   * diagonal.
   */
  __device__ float computeFeedbackCost(float* fb_u, float* std_dev,
                                       float lambda = 1.0, float alpha = 0.0) {
    float cost = 0;
    for (int i = 0; i < CONTROL_DIM; i++) {
      cost += params_.control_cost_coeff[i] * powf(fb_u[i] / std_dev[i], 2);
    }
    return 0.5 * lambda * (1 - alpha) * cost;
  }

  /**
   * Computes the normal control cost for MPPI and Tube-MPPI
   * 0.5 * lambda * (u*^T \Sigma^{-1} u*^T + 2 * u*^T \Sigma^{-1} (u*^T + noise))
   * On the GPU, u = u* + noise already, so we need the following to create
   * the original cost:
   * 0.5 * lambda * (u - noise)^T \Sigma^{-1} (u + noise)
   */
  __device__ float computeLikelihoodRatioCost(float* u,
                                              float* noise,
                                              float* std_dev,
                                              float lambda = 1.0,
                                              float alpha = 0.0) {
    float cost = 0;
    for (int i = 0; i < CONTROL_DIM; i++) {
      cost += params_.control_cost_coeff[i] * (u[i] - noise[i]) * (u[i] + noise[i]) /
        (std_dev[i] * std_dev[i]);
    }
    return 0.5 * lambda * (1 - alpha) * cost;
  }
  // =================== END METHODS THAT SHOULD NOT BE OVERWRITTEN ============

  // =================== METHODS THAT CAN BE OVERWRITTEN =======================
  float computeRunningCost(const Eigen::Ref<const state_array> s,
                           const Eigen::Ref<const control_array> u,
                           const Eigen::Ref<const control_array> noise,
                           const Eigen::Ref<const control_array> std_dev,
                           float lambda, float alpha, int timestep) {
    CLASS_T* derived = static_cast<CLASS_T*>(this);
    return  (derived->computeStateCost(s) + derived->computeLikelihoodRatioCost(u, noise, std_dev, lambda, alpha));
  }

  __device__ float computeRunningCost(float* s, float* u, float* du, float* std_dev, float lambda, float alpha, int timestep) {
    CLASS_T* derived = static_cast<CLASS_T*>(this);
    return derived->computeStateCost(s) + derived->computeLikelihoodRatioCost(u, du, std_dev, lambda, alpha);
  }
  // =================== END METHODS THAT CAN BE OVERWRITTEN ===================


  inline __host__ __device__ PARAMS_T getParams() const {return params_;}


  CLASS_T* cost_d_ = nullptr;
protected:
  PARAMS_T params_;
};

#if __CUDACC__
#include "cost.cu"
#endif

#endif // COSTS_CUH_
