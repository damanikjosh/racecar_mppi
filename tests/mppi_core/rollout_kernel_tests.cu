#include <gtest/gtest.h>
#include <dynamics/cartpole/cartpole_dynamics.cuh>
#include <cost_functions/cartpole/cartpole_quadratic_cost.cuh>
#include <mppi_core/rollout_kernel_test.cuh>
#include <utils/test_helper.h>
#include <random>
/*
 * Here we will test various device functions that are related to cuda kernel things.
 */

TEST(RolloutKernel, loadGlobalToShared) {
    const int STATE_DIM = 12;
    const int CONTROL_DIM = 3;
    std::vector<float> x0_host = {0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0, 1.1, 1.2};
    std::vector<float> u_var_host = {0.8, 0.9, 1.0};

    std::vector<float> x_thread_host(STATE_DIM, 0.f);
    std::vector<float> xdot_thread_host(STATE_DIM, 2.f);

    std::vector<float> u_thread_host(CONTROL_DIM, 3.f);
    std::vector<float> du_thread_host(CONTROL_DIM, 4.f);
    std::vector<float> sigma_u_thread_host(CONTROL_DIM, 0.f);

    launchGlobalToShared_KernelTest(x0_host, u_var_host, x_thread_host, xdot_thread_host, u_thread_host, du_thread_host, sigma_u_thread_host);

    array_assert_float_eq(x0_host, x_thread_host, STATE_DIM);
    array_assert_float_eq(0.f, xdot_thread_host, STATE_DIM);
    array_assert_float_eq(0.f, u_thread_host, CONTROL_DIM);
    array_assert_float_eq(0.f, du_thread_host, CONTROL_DIM);
    array_assert_float_eq(sigma_u_thread_host, u_var_host, CONTROL_DIM);
}

TEST(RolloutKernel, injectControlNoiseOnce) {
    const int NUM_ROLLOUTS = 1000;
    const int CONTROL_DIM = 3;
    int num_timesteps = 1;
    int num_rollouts = NUM_ROLLOUTS;
    std::vector<float> u_traj_host = {3.f, 4.f, 5.f};

    // Control noise
    std::vector<float> ep_v_host(num_rollouts*num_timesteps*CONTROL_DIM, 0.f);

    // Control at timestep 1 for all rollouts
    std::vector<float> control_compute(num_rollouts*CONTROL_DIM, 0.f);

    // Control variance for each control channel
    std::vector<float> sigma_u_host = {0.1f, 0.2f, 0.3f};

    launchInjectControlNoiseOnce_KernelTest(u_traj_host, num_rollouts, num_timesteps, ep_v_host, sigma_u_host, control_compute);

    // Make sure the first control is undisturbed
    int timestep = 0;
    int rollout = 0;
    for (int i = 0; i < CONTROL_DIM; ++i) {
        ASSERT_FLOAT_EQ(u_traj_host[i], control_compute[rollout*num_timesteps*CONTROL_DIM + timestep * CONTROL_DIM + i]);
    }

    // Make sure the last 99 percent are zero control with noise
    for (int j = num_rollouts*.99; j < num_rollouts; ++j) {
        for (int i = 0; i < CONTROL_DIM; ++i) {
            ASSERT_FLOAT_EQ(ep_v_host[j*num_timesteps*CONTROL_DIM + timestep * CONTROL_DIM + i] * sigma_u_host[i],
                    control_compute[j*num_timesteps*CONTROL_DIM + timestep * CONTROL_DIM + i]);
        }
    }

    // Make sure everything else are initial control plus noise
    for (int j = 1; j < num_rollouts*.99; ++j) {
        for (int i = 0; i < CONTROL_DIM; ++i) {
            ASSERT_FLOAT_EQ(ep_v_host[j*num_timesteps*CONTROL_DIM + timestep * CONTROL_DIM + i] * sigma_u_host[i] + u_traj_host[i],
                            control_compute[j*num_timesteps*CONTROL_DIM + timestep * CONTROL_DIM + i]) << "Failed at rollout number: " << j;
        }
    }
}

// TEST(RolloutKernel, injectControlNoiseAllTimeSteps) {
//     GTEST_SKIP() << "Not implemented";
// }

TEST(RolloutKernel, injectControlNoiseCheckControl_V) {
    const int num_rollouts = 100;
    const int control_dim = 3;
    const int num_timesteps = 5;
    std::array<float, control_dim*num_timesteps> u_traj_host = {0};
    // Control variance for each control channel
    std::array<float, control_dim> sigma_u_host = {0.1f, 0.2f, 0.3f};
    // Noise
    std::array<float, num_rollouts*num_timesteps*control_dim> ep_v_host = {0.f};
    std::array<float, num_rollouts*num_timesteps*control_dim> ep_v_compute = {0.f};

    auto generator = std::default_random_engine(7.0);
    auto distribution = std::normal_distribution<float>(5.0, 0.2);

    for (size_t i = 0; i <ep_v_host.size(); ++i) {
        ep_v_host[i] = distribution(generator);
        ep_v_compute[i] = ep_v_host[i];
    }

    for (size_t i = 0; i <u_traj_host.size(); ++i) {
        u_traj_host[i] = i;
    }

    // Output vector

    // CPU known vector
    std::array<float, num_rollouts*num_timesteps*control_dim> ep_v_known = {0.f};

    for (int i = 0; i < num_rollouts; ++i) {
        for (int j =0; j < num_timesteps; ++j) {
            for (int k =0; k < control_dim; ++k) {
                int index = i*num_timesteps*control_dim + j*control_dim + k;
                if (i == 0) {
                    ep_v_known[index] = u_traj_host[j*control_dim + k];
                } else if (i >= num_rollouts*.99) {
                    ep_v_known[index] = ep_v_host[index]*sigma_u_host[k];
                } else {
                    ep_v_known[index] = u_traj_host[j*control_dim + k] + ep_v_host[index]*sigma_u_host[k];
                }
            }
        }
    }

    launchInjectControlNoiseCheckControlV_KernelTest<num_rollouts,
    num_timesteps, control_dim, 64, 8, num_rollouts>(u_traj_host, ep_v_compute, sigma_u_host);

    array_assert_float_eq<num_rollouts*num_timesteps*control_dim>(ep_v_known, ep_v_compute);

}

TEST(RolloutKernel, computeRunningCostAllRollouts) {
    // Instantiate the cost object.
    CartpoleQuadraticCost cost;
    cost.GPUSetup();

    const int num_timesteps = 100;
    const int num_rollouts = 100;
    const int state_dim = 4;
    const int control_dim = 1;
    float dt = 0.01;

    // Generate the trajectory data
    std::array<float, state_dim*num_timesteps*num_rollouts> x_traj = {0};
    x_traj.fill(2.f);
    std::array<float, control_dim*num_timesteps*num_rollouts> u_traj = {1.f};
    u_traj.fill(1.f);
    std::array<float, control_dim*num_timesteps*num_rollouts> du_traj = {0.9f};
    du_traj.fill(0.9f);
    std::array<float, control_dim> sigma_u = {0.1f};
    std::array<float, num_rollouts> cost_compute = {0.f};
    std::array<float, num_rollouts> cost_known = {0.f};

    // Compute the result on the CPU side
    computeRunningCostAllRollouts_CPU_TEST<CartpoleQuadraticCost, num_rollouts, num_timesteps, state_dim, control_dim>(cost, dt, x_traj, u_traj, du_traj, sigma_u, cost_known);

    // Launch the GPU kernel
    launchComputeRunningCostAllRollouts_KernelTest<CartpoleQuadraticCost, num_rollouts, num_timesteps, state_dim, control_dim>(cost, dt, x_traj, u_traj, du_traj, sigma_u, cost_compute);

    // Compare
    array_assert_float_eq<num_rollouts>(cost_known, cost_compute);

}

TEST(RolloutKernel, computeStateDerivAllRollouts_Cartpole) {
    CartpoleDynamics model(1, 2, 3);
    model.GPUSetup();

    const int num_rollouts = 1000; // Must match the value in rollout_kernel_test.cu
    // Generate the trajectory data
    std::array<float, CartpoleDynamics::STATE_DIM * num_rollouts> x_traj = {0};
    std::array<float, CartpoleDynamics::CONTROL_DIM * num_rollouts> u_traj = {0};
    std::array<float, CartpoleDynamics::STATE_DIM * num_rollouts> xdot_traj_known = {0};
    std::array<float, CartpoleDynamics::STATE_DIM * num_rollouts> xdot_traj_compute = {0};

    // Range based for loop that will increase each index of x_traj by 0.1
    // x_traj = {0.1, 0.2, 0.3, ...}
    for(auto& x: x_traj) {
        x = *((&x)-1)+0.1;
    }

    // Range based for loop that will increase each index of u_traj by 0.1
    // u_traj = {0.02, 0.04, 0.06, ...}
    for(auto& u: u_traj) {
        u = *((&u)-1)+0.02;
    }

    // Compute the dynamics on CPU
    for (int i = 0; i < num_rollouts; ++i) {
      Eigen::MatrixXf eigen_state(CartpoleDynamics::STATE_DIM, 1);
      Eigen::MatrixXf eigen_state_der(CartpoleDynamics::STATE_DIM, 1);
      Eigen::MatrixXf eigen_control(CartpoleDynamics::CONTROL_DIM, 1);
      for(int j = 0; j < CartpoleDynamics::STATE_DIM; j++) {
        eigen_state(j) = x_traj[i * CartpoleDynamics::STATE_DIM + j];
      }
      for(int j = 0; j < CartpoleDynamics::CONTROL_DIM; j++) {
        eigen_control(j) = u_traj[i * CartpoleDynamics::CONTROL_DIM + j];
      }
      model.computeDynamics(eigen_state, eigen_control, eigen_state_der);

      for(int j = 0; j < CartpoleDynamics::STATE_DIM; j++) {
        xdot_traj_known[i * CartpoleDynamics::STATE_DIM + j] = eigen_state_der(j);
      }
    }

    // Compute the dynamics on the GPU
    launchComputeStateDerivAllRollouts_KernelTest<CartpoleDynamics, num_rollouts, 1>(model, x_traj, u_traj, xdot_traj_compute);


    array_assert_float_near<num_rollouts * CartpoleDynamics::STATE_DIM>(xdot_traj_known, xdot_traj_compute, 1e-1);
}

// TEST(RolloutKernel, computeStateDerivAllRollouts_AR) {
//     GTEST_SKIP() << "Requires implementation.";
// }

TEST(RolloutKernel, incrementStateAllRollouts) {
    float dt = 0.1;
  CartpoleDynamics model(1, 2, 3);

  const int num_rollouts = 5000; // Must match the value in rollout_kernel_test.cu
    // Generate the trajectory data
    std::array<float, CartpoleDynamics::STATE_DIM * num_rollouts> x_traj_known= {0};
    std::array<float, CartpoleDynamics::STATE_DIM * num_rollouts> x_traj_compute = {0};
    std::array<float, CartpoleDynamics::STATE_DIM * num_rollouts> xdot_traj_known= {0};
    std::array<float, CartpoleDynamics::STATE_DIM * num_rollouts> xdot_traj_compute = {0};

    // Range based for loop that will increase each index of x_traj by 0.1
    // x_traj = {0.12, 0.24, 0.36, ...}
    for(auto& x: x_traj_compute) {
        x = *((&x)-1)+0.12;
    }

    x_traj_known = x_traj_compute;

    // Range based for loop that will increase each index of u_traj by 0.1
    // u_traj = {0.03, 0.06, 0.09, ...}
    for(auto& xdot: xdot_traj_compute) {
        xdot = *((&xdot)-1)+0.03;
    }

    xdot_traj_known = xdot_traj_compute;

    // Compute increment the state on the CPU
    for (int i = 0; i < num_rollouts; ++i) {
        for (int j = 0; j < CartpoleDynamics::STATE_DIM; ++j) {
            x_traj_known[i * CartpoleDynamics::STATE_DIM + j] += xdot_traj_known[i * CartpoleDynamics::STATE_DIM + j] * dt;
            xdot_traj_known[i * CartpoleDynamics::STATE_DIM + j] = 0;
        }
    }

    // Compute the dynamics on the GPU
    launchIncrementStateAllRollouts_KernelTest<CartpoleDynamics, CartpoleDynamics::STATE_DIM, num_rollouts>(model, dt, x_traj_compute, xdot_traj_compute);

    array_assert_float_eq<num_rollouts * CartpoleDynamics::STATE_DIM>(x_traj_known, x_traj_compute);
    array_assert_float_eq<num_rollouts * CartpoleDynamics::STATE_DIM>(xdot_traj_known, xdot_traj_compute);
}

TEST(RolloutKernel, computeAndSaveCostAllRollouts) {
    // Define an assortment of costs for a given number of rollouts
    CartpoleQuadraticCost cost;
    cost.GPUSetup();

    const int num_rollouts = 1234;
    std::array<float, num_rollouts> cost_all_rollouts = {0};
    std::array<float, CartpoleDynamics::STATE_DIM * num_rollouts> x_traj_terminal = {0};
    std::array<float, num_rollouts> cost_known = {0};
    std::array<float, num_rollouts> cost_compute = {0};

    std::default_random_engine generator(7.0);
    std::normal_distribution<float> distribution(1.0,2.0);

    for(auto& costs: cost_all_rollouts) {
        costs = 10*distribution(generator);
    }

    for (auto& state: x_traj_terminal) {
        state = distribution(generator);
    }
    // Compute terminal cost on CPU
    for (int i = 0; i < num_rollouts; ++i) {
        cost_known[i] = cost_all_rollouts[i] +
                (x_traj_terminal[CartpoleDynamics::STATE_DIM * i] * x_traj_terminal[CartpoleDynamics::STATE_DIM * i] * cost.getParams().cart_position_coeff +
                 x_traj_terminal[CartpoleDynamics::STATE_DIM * i + 1] * x_traj_terminal[CartpoleDynamics::STATE_DIM * i + 1] * cost.getParams().cart_velocity_coeff +
                 x_traj_terminal[CartpoleDynamics::STATE_DIM * i + 2] * x_traj_terminal[CartpoleDynamics::STATE_DIM * i + 2] * cost.getParams().pole_angle_coeff +
                 x_traj_terminal[CartpoleDynamics::STATE_DIM * i + 3] * x_traj_terminal[CartpoleDynamics::STATE_DIM * i + 3] * cost.getParams().pole_angular_velocity_coeff) *
                cost.getParams().terminal_cost_coeff;
    }

    // Compute the dynamics on the GPU
    launchComputeAndSaveCostAllRollouts_KernelTest<CartpoleQuadraticCost, CartpoleDynamics::STATE_DIM, num_rollouts>(cost,
                                                                                                                     cost_all_rollouts, x_traj_terminal, cost_compute);

    array_assert_float_eq<num_rollouts>(cost_known, cost_compute);
}

