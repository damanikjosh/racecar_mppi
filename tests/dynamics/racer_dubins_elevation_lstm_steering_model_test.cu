#include <Eigen/Dense>
#include <gtest/gtest.h>
#include <mppi/dynamics/racer_dubins/racer_dubins_elevation_lstm_steering.cuh>
#include <mppi/dynamics/dynamics_generic_kernel_tests.cuh>
#include <mppi/ddp/ddp_model_wrapper.h>
#include <cuda_runtime.h>

class RacerDubinsElevationLSTMSteeringTest : public ::testing::Test
{
public:
  cudaStream_t stream;

  void SetUp() override
  {
    CudaCheckError();
    HANDLE_ERROR(cudaStreamCreate(&stream));
  }

  void TearDown() override
  {
    CudaCheckError();
    HANDLE_ERROR(cudaStreamDestroy(stream));
  }
};

TEST_F(RacerDubinsElevationLSTMSteeringTest, Template)
{
  auto dynamics = RacerDubinsElevationLSTMSteering();
  EXPECT_EQ(8, RacerDubinsElevationLSTMSteering::STATE_DIM);
  EXPECT_EQ(2, RacerDubinsElevationLSTMSteering::CONTROL_DIM);
  EXPECT_NE(dynamics.getTextureHelper(), nullptr);
}

TEST_F(RacerDubinsElevationLSTMSteeringTest, BindStream)
{
  auto dynamics = RacerDubinsElevationLSTMSteering(stream);

  EXPECT_EQ(dynamics.stream_, stream) << "Stream binding failure.";
  EXPECT_NE(dynamics.getTextureHelper(), nullptr);
  EXPECT_EQ(dynamics.getTextureHelper()->stream_, stream);
}

/*
float c_t = 1.3;
float c_b = 2.5;
float c_v = 3.7;
float c_0 = 4.9;
float wheel_base = 0.3;
 */

// TEST_F(RacerDubinsElevationLSTMSteeringTest, ComputeDynamics)
// {
//   RacerDubinsElevationLSTMSteering dynamics = RacerDubinsElevationLSTMSteering();
//   auto params = dynamics.getParams();
//   RacerDubinsElevationLSTMSteering::state_array x = RacerDubinsElevationLSTMSteering::state_array::Zero();
//   RacerDubinsElevationLSTMSteering::control_array u = RacerDubinsElevationLSTMSteering::control_array::Zero();

//   // computeDynamics should not touch the roll/pitch element
//   RacerDubinsElevationLSTMSteering::state_array next_x = RacerDubinsElevationLSTMSteering::state_array::Ones() *
//   0.153; dynamics.computeDynamics(x, u, next_x); EXPECT_FLOAT_EQ(next_x(0), 4.9); EXPECT_FLOAT_EQ(next_x(1), 0);
//   EXPECT_FLOAT_EQ(next_x(2), 0);
//   EXPECT_FLOAT_EQ(next_x(3), 0);
//   EXPECT_FLOAT_EQ(next_x(4), 0);
//   EXPECT_FLOAT_EQ(next_x(5), 0.153);
//   EXPECT_FLOAT_EQ(next_x(6), 0.153);

//   x << 1, M_PI_2, 0, 3, 0, 0.5, -0.5, 0.0, 0.0;
//   u << 1, 0;
//   dynamics.computeDynamics(x, u, next_x);
//   EXPECT_FLOAT_EQ(next_x(0), 4.9 + 2.6 - 4.7 - sinf(-0.5) * -9.81);
//   EXPECT_FLOAT_EQ(next_x(1), 0);
//   EXPECT_NEAR(next_x(2), 0, 1e-7);
//   EXPECT_FLOAT_EQ(next_x(3), 1);
//   EXPECT_FLOAT_EQ(next_x(4), 0);
//   EXPECT_FLOAT_EQ(next_x(5), 0.153);
//   EXPECT_FLOAT_EQ(next_x(6), 0.153);

//   x << 1, M_PI_2, 0, 3, 0, 0.5, -0.5, 0.0, 0.0;
//   u << -1, 0;
//   dynamics.computeDynamics(x, u, next_x);
//   EXPECT_FLOAT_EQ(next_x(0), 4.9 - 3.5 - 4.7 - sinf(-0.5) * -9.81);
//   EXPECT_FLOAT_EQ(next_x(1), 0);
//   EXPECT_NEAR(next_x(2), 0, 1e-7);
//   EXPECT_FLOAT_EQ(next_x(3), 1);
//   EXPECT_FLOAT_EQ(next_x(4), 0);
//   EXPECT_FLOAT_EQ(next_x(5), 0.153);
//   EXPECT_FLOAT_EQ(next_x(6), 0.153);

//   x << -1, 0, 0, 3, 0, 0.5, -0.5, 0.0, 0.0;
//   u << 1, 0;
//   dynamics.computeDynamics(x, u, next_x);
//   EXPECT_FLOAT_EQ(next_x(0), 4.9 + 4.7 + 2.6 - sinf(-0.5) * -9.81);
//   EXPECT_FLOAT_EQ(next_x(1), 0);
//   EXPECT_FLOAT_EQ(next_x(2), -1);
//   EXPECT_FLOAT_EQ(next_x(3), 0);
//   EXPECT_FLOAT_EQ(next_x(4), 0);
//   EXPECT_FLOAT_EQ(next_x(5), 0.153);
//   EXPECT_FLOAT_EQ(next_x(6), 0.153);

//   x << -1, 0, 0, 3, 0, 0.5, -0.5, 0.0, 0.0;
//   u << -1, 0;
//   dynamics.computeDynamics(x, u, next_x);
//   EXPECT_FLOAT_EQ(next_x(0), 4.9 + 3.5 + 4.7 - sinf(-0.5) * -9.81);
//   EXPECT_FLOAT_EQ(next_x(1), 0);
//   EXPECT_FLOAT_EQ(next_x(2), -1);
//   EXPECT_FLOAT_EQ(next_x(3), 0);
//   EXPECT_FLOAT_EQ(next_x(4), 0);
//   EXPECT_FLOAT_EQ(next_x(5), 0.153);
//   EXPECT_FLOAT_EQ(next_x(6), 0.153);

//   x << 7, 0, 0, 3, 0, 0.5, -0.5, 0.0, 0.0;
//   u << 1, 0;
//   dynamics.computeDynamics(x, u, next_x);
//   EXPECT_FLOAT_EQ(next_x(0), 4.9 + 3.9 - 5.7 * 7 - sinf(-0.5) * -9.81);
//   EXPECT_FLOAT_EQ(next_x(1), 0);
//   EXPECT_FLOAT_EQ(next_x(2), 7);
//   EXPECT_FLOAT_EQ(next_x(3), 0);
//   EXPECT_FLOAT_EQ(next_x(4), 0);
//   EXPECT_FLOAT_EQ(next_x(5), 0.153);
//   EXPECT_FLOAT_EQ(next_x(6), 0.153);

//   x << -7, 0, 0, 3, 0, 0.5, -0.5, 0.0, 0.0;
//   u << 1, 0;
//   dynamics.computeDynamics(x, u, next_x);
//   EXPECT_FLOAT_EQ(next_x(0), 4.9 + 3.9 + 5.7 * 7 - sinf(-0.5) * -9.81);
//   EXPECT_FLOAT_EQ(next_x(1), 0);
//   EXPECT_FLOAT_EQ(next_x(2), -7);
//   EXPECT_FLOAT_EQ(next_x(3), 0);
//   EXPECT_FLOAT_EQ(next_x(4), 0);
//   EXPECT_FLOAT_EQ(next_x(5), 0.153);
//   EXPECT_FLOAT_EQ(next_x(6), 0.153);

//   x << 7, 0, 0, 3, 0, 0.5, -0.5, 0.0, 0.0;
//   u << -1, 0;
//   dynamics.computeDynamics(x, u, next_x);
//   EXPECT_FLOAT_EQ(next_x(0), 4.9 - 4.5 - 5.7 * 7 - sinf(-0.5) * -9.81);
//   EXPECT_FLOAT_EQ(next_x(1), 0);
//   EXPECT_FLOAT_EQ(next_x(2), 7);
//   EXPECT_FLOAT_EQ(next_x(3), 0);
//   EXPECT_FLOAT_EQ(next_x(4), 0);
//   EXPECT_FLOAT_EQ(next_x(5), 0.153);
//   EXPECT_FLOAT_EQ(next_x(6), 0.153);

//   x << -7, 0, 0, 3, 0, 0.5, -0.5, 0.0, 0.0;
//   u << -1, 0;
//   dynamics.computeDynamics(x, u, next_x);
//   EXPECT_FLOAT_EQ(next_x(0), 4.9 + 4.5 + 5.7 * 7 - sinf(-0.5) * -9.81);
//   EXPECT_FLOAT_EQ(next_x(1), 0);
//   EXPECT_FLOAT_EQ(next_x(2), -7);
//   EXPECT_FLOAT_EQ(next_x(3), 0);
//   EXPECT_FLOAT_EQ(next_x(4), 0);
//   EXPECT_FLOAT_EQ(next_x(5), 0.153);
//   EXPECT_FLOAT_EQ(next_x(6), 0.153);

//   x << 1, M_PI_2, 0, 3, 0, 0.5, -0.5, 0.0, 0.0;
//   u << 0, 1;
//   dynamics.computeDynamics(x, u, next_x);
//   EXPECT_FLOAT_EQ(next_x(0), 4.9 - 4.7 - sinf(-0.5) * -9.81);
//   EXPECT_FLOAT_EQ(next_x(1), (1 / .3) * tan(0));
//   EXPECT_NEAR(next_x(2), 0, 1e-7);
//   EXPECT_FLOAT_EQ(next_x(3), 1);
//   EXPECT_FLOAT_EQ(next_x(4), 5 * 0.6);
//   EXPECT_FLOAT_EQ(next_x(5), 0.153);
//   EXPECT_FLOAT_EQ(next_x(6), 0.153);

//   x << -1, M_PI_2, 0, 3, 5.0, 0.5, -0.5, 0.0, 0.0;
//   u << -1, -1;
//   dynamics.computeDynamics(x, u, next_x);
//   EXPECT_FLOAT_EQ(next_x(0), 4.9 + 4.7 + 3.5 - sinf(-0.5) * -9.81);
//   EXPECT_FLOAT_EQ(next_x(1), (-1 / .3) * tan(5.0 / -10.2));
//   EXPECT_NEAR(next_x(2), 0, 1e-7);
//   EXPECT_FLOAT_EQ(next_x(3), -1);
//   EXPECT_FLOAT_EQ(next_x(4), -5);
//   EXPECT_FLOAT_EQ(next_x(5), 0.153);
//   EXPECT_FLOAT_EQ(next_x(6), 0.153);

//   x << -0.4, M_PI_2, 0, 3, 5.0, 0.5, -0.5, 0.0, 0.0;
//   u << -1, -1;
//   dynamics.computeDynamics(x, u, next_x);
//   EXPECT_FLOAT_EQ(next_x(0), 4.9 + 3.7 * 0.4 + 2.5 * 0.4 - sinf(-0.5) * -9.81);
//   EXPECT_FLOAT_EQ(next_x(1), (-0.4 / .3) * tan(5.0 / -9.1));
//   EXPECT_NEAR(next_x(2), 0, 1e-7);
//   EXPECT_FLOAT_EQ(next_x(3), -0.4);
//   EXPECT_FLOAT_EQ(next_x(4), -5);
//   EXPECT_FLOAT_EQ(next_x(5), 0.153);
//   EXPECT_FLOAT_EQ(next_x(6), 0.153);

//   x << 0.4, M_PI_2, 0, 3, 5.0, 0.5, -0.5, 0.0, 0.0;
//   u << 0.1, -1;
//   dynamics.computeDynamics(x, u, next_x);
//   EXPECT_FLOAT_EQ(next_x(0), 4.9 - 3.7 * 0.4 - sinf(-0.5) * -9.81);
//   EXPECT_FLOAT_EQ(next_x(1), (0.4 / .3) * tan(5.0 / -9.1));
//   EXPECT_NEAR(next_x(2), 0, 1e-7);
//   EXPECT_FLOAT_EQ(next_x(3), 0.4);
//   EXPECT_FLOAT_EQ(next_x(4), -5);
//   EXPECT_FLOAT_EQ(next_x(5), 0.153);
//   EXPECT_FLOAT_EQ(next_x(6), 0.153);
// }

// TEST_F(RacerDubinsElevationLSTMSteeringTest, TestModelGPU)
// {
//   RacerDubinsElevationLSTMSteering dynamics = RacerDubinsElevationLSTMSteering();
//   dynamics.GPUSetup();
//   CudaCheckError();

//   Eigen::Matrix<float, RacerDubinsElevationLSTMSteering::CONTROL_DIM, 100> control_trajectory;
//   control_trajectory = Eigen::Matrix<float, RacerDubinsElevationLSTMSteering::CONTROL_DIM, 100>::Random();
//   Eigen::Matrix<float, RacerDubinsElevationLSTMSteering::STATE_DIM, 100> state_trajectory;
//   state_trajectory = Eigen::Matrix<float, RacerDubinsElevationLSTMSteering::STATE_DIM, 100>::Random();

//   std::vector<std::array<float, 9>> s(100);
//   std::vector<std::array<float, 9>> s_der(100);
//   // steering, throttle
//   std::vector<std::array<float, 2>> u(100);
//   for (int state_index = 0; state_index < s.size(); state_index++)
//   {
//     for (int dim = 0; dim < s[0].size(); dim++)
//     {
//       s[state_index][dim] = state_trajectory.col(state_index)(dim);
//     }
//     for (int dim = 0; dim < u[0].size(); dim++)
//     {
//       u[state_index][dim] = control_trajectory.col(state_index)(dim);
//     }
//   }

//   // These variables will be changed so initialized to the right size only

//   // Run dynamics on dynamicsU
//   // Run dynamics on GPU
//   for (int y_dim = 1; y_dim <= 4; y_dim++)
//   {
//     launchComputeDynamicsTestKernel<RacerDubinsElevationLSTMSteering, 9, 2>(dynamics, s, u, s_der, y_dim);
//     for (int point = 0; point < 100; point++)
//     {
//       RacerDubinsElevationLSTMSteering::state_array state = state_trajectory.col(point);
//       RacerDubinsElevationLSTMSteering::control_array control = control_trajectory.col(point);
//       RacerDubinsElevationLSTMSteering::state_array state_der_cpu =
//       RacerDubinsElevationLSTMSteering::state_array::Zero();

//       dynamics.computeDynamics(state, control, state_der_cpu);
//       for (int dim = 0; dim < 6; dim++)
//       {
//         EXPECT_NEAR(state_der_cpu(dim), s_der[point][dim], 1e-5)
//             << "at point " << point << " dim " << dim << " with y_dim " << y_dim;
//         EXPECT_TRUE(isfinite(s_der[point][dim]));
//       }
//     }
//   }

//   dynamics.freeCudaMem();
//   CudaCheckError();
// }

// TEST_F(RacerDubinsElevationLSTMSteeringTest, TestUpdateState)
// {
//   CudaCheckError();
//   RacerDubinsElevationLSTMSteering dynamics = RacerDubinsElevationLSTMSteering();
//   RacerDubinsElevationLSTMSteering::state_array state;
//   RacerDubinsElevationLSTMSteering::state_array next_state;
//   RacerDubinsElevationLSTMSteering::state_array state_der;

//   // TODO add in the elevation map

//   state << 0, 0, 0, 0, 0, -0.5, 0.5;
//   state_der << 1, 1, 1, 1, 1, 0, 0;
//   dynamics.updateState(state, next_state, state_der, 0.1);
//   EXPECT_TRUE(state_der != RacerDubinsElevationLSTMSteering::state_array::Zero());
//   EXPECT_FLOAT_EQ(next_state(0), 0.1);
//   EXPECT_FLOAT_EQ(next_state(1), 0.1);
//   EXPECT_FLOAT_EQ(next_state(2), 0.1);
//   EXPECT_FLOAT_EQ(next_state(3), 0.1);
//   EXPECT_FLOAT_EQ(next_state(4), 0.1);
//   EXPECT_FLOAT_EQ(next_state(5), 0.0);
//   EXPECT_FLOAT_EQ(next_state(6), 0.0);

//   state << 0, M_PI - 0.1, 0, 0, 0, -0.5, 0.5;
//   state_der << 1, 1, 1, 1, 1;
//   dynamics.updateState(state, next_state, state_der, 1.0);
//   EXPECT_TRUE(state_der != RacerDubinsElevationLSTMSteering::state_array::Zero());
//   EXPECT_FLOAT_EQ(next_state(0), 1.0);
//   EXPECT_FLOAT_EQ(next_state(1), 1.0 - M_PI - 0.1);
//   EXPECT_FLOAT_EQ(next_state(2), 1.0);
//   EXPECT_FLOAT_EQ(next_state(3), 1.0);
//   EXPECT_FLOAT_EQ(next_state(4), 0.5);
//   EXPECT_FLOAT_EQ(next_state(5), 0.0);
//   EXPECT_FLOAT_EQ(next_state(6), 0.0);

//   state << 0, -M_PI + 0.1, 0, 0, 0, -0.5, 0.5;
//   state_der << 1, -1, 1, 1, 1;
//   dynamics.updateState(state, next_state, state_der, 1.0);
//   EXPECT_TRUE(state_der != RacerDubinsElevationLSTMSteering::state_array::Zero());
//   EXPECT_FLOAT_EQ(next_state(0), 1.0);
//   EXPECT_FLOAT_EQ(next_state(1), M_PI + 0.1 - 1.0);
//   EXPECT_FLOAT_EQ(next_state(2), 1.0);
//   EXPECT_FLOAT_EQ(next_state(3), 1.0);
//   EXPECT_FLOAT_EQ(next_state(4), 0.5);
//   EXPECT_FLOAT_EQ(next_state(5), 0.0);
//   EXPECT_FLOAT_EQ(next_state(6), 0.0);

//   CudaCheckError();
// }

TEST_F(RacerDubinsElevationLSTMSteeringTest, TestStep)
{
  CudaCheckError();
  using DYN = RacerDubinsElevationLSTMSteering;
  const float tol = 1e-6;
  DYN dynamics = DYN();
  auto params = dynamics.getParams();
  params.c_0 = 0;
  params.c_b[0] = 1;
  params.c_b[1] = 10;
  params.c_b[2] = 100;
  params.c_v[0] = 0.25;
  params.c_v[1] = 0.5;
  params.c_v[2] = 0.75;
  params.c_t[0] = 2;
  params.c_t[1] = 20;
  params.c_t[2] = 200;
  params.low_min_throttle = 0.2;
  params.steer_command_angle_scale = 0.5;
  params.steering_constant = 0.5;
  params.wheel_base = 0.5;
  params.max_steer_rate = 5;
  params.max_steer_angle = 5;
  dynamics.setParams(params);
  DYN::state_array state;
  DYN::state_array next_state;
  DYN::state_array state_der = DYN::state_array::Zero();
  DYN::control_array control;
  DYN::output_array output;
  float dt = 0.1;
  // TODO add in the elevation map

  auto model = dynamics.getHelper();
  std::vector<float> theta_vec(DYN::NN::OUTPUT_PARAMS_T::NUM_PARAMS);
  for (int i = 0; i < theta_vec.size(); i++)
  {
    theta_vec[i] = 0.1f;
  }
  model->updateOutputModel({ 11, 20, 1 }, theta_vec);

  theta_vec.resize(DYN::NN::INIT_OUTPUT_PARAMS_T::NUM_PARAMS);
  for (int i = 0; i < theta_vec.size(); i++)
  {
    theta_vec[i] = 0.01;
  }
  model->updateOutputModelInit({ 65, 100, 10 }, theta_vec);

  auto lstm_params = model->getLSTMParams();
  lstm_params.setAllValues(0.3f);
  model->setLSTMParams(lstm_params);

  auto init_params = model->getInitLSTMParams();
  init_params.setAllValues(0.01f);
  model->setInitParams(init_params);

  DYN::NN::init_buffer buffer = DYN::NN::init_buffer::Ones() * 0.01;
  model->initializeLSTM(buffer);

  // Basic initial state and no movement should stay still
  state << 0, 0, 0, 0, 0, -0.0, 0.0, 0, 0;
  control << 0, 0;
  dynamics.step(state, next_state, state_der, control, output, 0, dt);
  EXPECT_NEAR(next_state(0), 0.0, tol);
  EXPECT_NEAR(next_state(1), 0.0, tol);
  EXPECT_NEAR(next_state(2), 0.0, tol);
  EXPECT_NEAR(next_state(3), 0.0, tol);
  EXPECT_NEAR(next_state(4), 4.1513447761535645 * dt, tol);
  EXPECT_NEAR(next_state(5), 0.0, tol);
  EXPECT_NEAR(next_state(6), 0.0, tol);
  EXPECT_NEAR(next_state(7), 4.1513447761535645, tol);
  EXPECT_NEAR(output(23), 0.0, tol);

  // Apply full throttle from zero state
  state << 0, 0, 0, 0, 0, -0.0, 0.0, 0, 0;
  control << 1, 0;
  dynamics.step(state, next_state, state_der, control, output, 0, dt);
  EXPECT_NEAR(state_der(0), 1.6, tol);
  EXPECT_NEAR(next_state(0), 0.16, tol);
  EXPECT_NEAR(next_state(1), 0.0, tol);
  EXPECT_NEAR(next_state(2), 0.0, tol);
  EXPECT_NEAR(next_state(3), 0.0, tol);
  EXPECT_NEAR(next_state(4), 5.2766318321228027 * dt, tol);
  EXPECT_NEAR(next_state(5), 0.0, tol);
  EXPECT_NEAR(next_state(6), 0.0, tol);
  EXPECT_NEAR(next_state(7), 5.2766318321228027, tol);
  EXPECT_NEAR(output(23), 1.6, tol);

  // Apply throttle to a state with positive velocity
  state << 1, 0, 0, 0, 0, -0.0, 0.0, 0, 0;
  control << 1, 0;
  model->initializeLSTM(buffer);
  dynamics.step(state, next_state, state_der, control, output, 0, dt);
  EXPECT_NEAR(state_der(0), 19.5, tol);
  EXPECT_NEAR(next_state(0), 2.95, tol);
  EXPECT_NEAR(next_state(1), 0.0, tol);
  EXPECT_NEAR(next_state(2), 0.1, tol);
  EXPECT_NEAR(next_state(3), 0.0, tol);
  EXPECT_NEAR(next_state(4), 7.1914091110229492 * dt, tol);
  EXPECT_NEAR(next_state(5), 0.0, tol);
  EXPECT_NEAR(next_state(6), 0.0, tol);
  EXPECT_NEAR(next_state(7), 7.1914091110229492, tol);
  EXPECT_NEAR(output(23), 19.5, tol);

  // Apply full throttle and half left turn to origin state
  state << 0, 0, 0, 0, 0, -0.0, 0.0, 0, 0;
  control << 1, 0.5;
  model->initializeLSTM(buffer);
  dynamics.step(state, next_state, state_der, control, output, 0, dt);
  EXPECT_NEAR(state_der(0), 1.6, tol);
  EXPECT_NEAR(next_state(0), 0.16, tol);
  EXPECT_NEAR(next_state(1), 0.0, tol);
  EXPECT_NEAR(next_state(2), 0.0, tol);
  EXPECT_NEAR(next_state(3), 0.0, tol);
  EXPECT_NEAR(next_state(4), 6.1980991363525391 * dt, tol);
  EXPECT_NEAR(next_state(5), 0.0, tol);
  EXPECT_NEAR(next_state(6), 0.0, tol);
  EXPECT_NEAR(next_state(7), 6.1980991363525391, tol);
  EXPECT_NEAR(output(23), 1.6, tol);

  // Apply full throttle and half left turn to a moving state oriented 30 degrees to the left
  float yaw = M_PI / 6;
  state << 1.0, yaw, 0, 0, 0, -0.0, 0.0, 0, 0;
  control << 1, 0.5;
  model->initializeLSTM(buffer);
  dynamics.step(state, next_state, state_der, control, output, 0, dt);
  EXPECT_NEAR(state_der(0), 19.5, tol);
  EXPECT_NEAR(next_state(0), 2.95, tol);
  EXPECT_NEAR(next_state(1), yaw, tol);
  EXPECT_NEAR(next_state(2), 1 * cos(yaw) * dt, tol);
  EXPECT_NEAR(next_state(3), 1 * sin(yaw) * dt, tol);
  EXPECT_NEAR(next_state(4), 9.0653514862060547 * dt, tol);
  EXPECT_NEAR(next_state(5), 0.0, tol);
  EXPECT_NEAR(next_state(6), 0.0, tol);
  EXPECT_NEAR(next_state(7), 9.0653514862060547, tol);
  EXPECT_NEAR(output(23), 19.5, tol);

  // Apply full throttle and half left turn to a moving state oriented 30 degrees to the left which is already turning
  float steer_angle = M_PI / 8;
  state << 1.0, yaw, 0, 0, steer_angle, -0.0, 0.0, 0, 0;
  control << 1, 0.5;
  model->initializeLSTM(buffer);
  dynamics.step(state, next_state, state_der, control, output, 0, dt);
  EXPECT_NEAR(state_der(0), 19.5, tol);
  EXPECT_NEAR(next_state(0), 2.95, tol);
  EXPECT_NEAR(next_state(1), yaw + -0.0385189 * dt * 2, tol);
  EXPECT_NEAR(next_state(2), 1 * cos(yaw) * dt, tol);
  EXPECT_NEAR(next_state(3), 1 * sin(yaw) * dt, tol);
  EXPECT_NEAR(next_state(4), steer_angle + 9.3820228576660156 * dt, tol);
  EXPECT_NEAR(next_state(5), 0.0, tol);
  EXPECT_NEAR(next_state(6), 0.0, tol);
  EXPECT_NEAR(next_state(7), 9.3820228576660156, tol);
  EXPECT_NEAR(output(23), 19.5, tol);

  // Apply full brake and half left turn to a moving state oriented 30 degrees to the left which is already turning
  state << 1.0, yaw, 0, 0, steer_angle, -0.0, 0.0, 0, 0;
  control << -1, 0.5;
  model->initializeLSTM(buffer);
  dynamics.step(state, next_state, state_der, control, output, 0, dt);
  EXPECT_NEAR(state_der(0), -10 - 0.5, tol);
  EXPECT_NEAR(next_state(0), 1 - 10.5 * dt, tol);
  EXPECT_NEAR(next_state(1), yaw + -0.0385189 * dt * 2, tol);
  EXPECT_NEAR(next_state(2), 1 * cos(yaw) * dt, tol);
  EXPECT_NEAR(next_state(3), 1 * sin(yaw) * dt, tol);
  EXPECT_NEAR(next_state(4), steer_angle + 9.3820228576660156 * dt, tol);
  EXPECT_NEAR(next_state(5), 0.0, tol);
  EXPECT_NEAR(next_state(6), 0.0, tol);
  EXPECT_NEAR(next_state(7), 9.3820228576660156, tol);
  EXPECT_NEAR(output(23), -10.5, tol);

  /**
   * Apply full brake and half left turn to a moving state oriented 30 degrees to the left which is already turning
   * and on a downward facing hill
   */
  float pitch = 20 * M_PI / 180;
  state << 1.0, yaw, 0, 0, steer_angle, -0.0, pitch, 0, 0;
  control << -1, 0.5;
  model->initializeLSTM(buffer);
  dynamics.step(state, next_state, state_der, control, output, 0, dt);
  EXPECT_NEAR(next_state(0), 1 + (-10.5 + 9.81 * sinf(pitch)) * dt, tol);
  EXPECT_NEAR(next_state(1), yaw + -0.0385189 * dt * 2, tol);
  EXPECT_NEAR(next_state(2), 1 * cos(yaw) * dt, tol);
  EXPECT_NEAR(next_state(3), 1 * sin(yaw) * dt, tol);
  EXPECT_NEAR(next_state(4), steer_angle + 9.3820228576660156 * dt, tol);
  EXPECT_NEAR(next_state(5), 0.0, tol);
  EXPECT_NEAR(next_state(6), 0.0, tol);
  EXPECT_NEAR(next_state(7), 9.3820228576660156, tol);
  EXPECT_NEAR(output(23), (-10.5 + 9.81 * sinf(pitch)), tol);

  /**
   * Apply full brake and half left turn to a backwards moving state oriented 30 degrees to the left which is already
   * turning and on a downward facing hill
   */
  state << -1.0, yaw, 0, 0, steer_angle, -0.0, pitch, 0, 0;
  control << -1, 0.5;
  model->initializeLSTM(buffer);
  dynamics.step(state, next_state, state_der, control, output, 0, dt);
  EXPECT_NEAR(next_state(0), -1 + (10.5 + 9.81 * sinf(pitch)) * dt, tol);
  EXPECT_NEAR(next_state(1), yaw + 0.0385189 * dt * 2, tol);
  EXPECT_NEAR(next_state(2), -1 * cos(yaw) * dt, tol);
  EXPECT_NEAR(next_state(3), -1 * sin(yaw) * dt, tol);
  EXPECT_NEAR(next_state(4), steer_angle + 3.5296125411987305 * dt, tol);
  EXPECT_NEAR(next_state(5), 0.0, tol);
  EXPECT_NEAR(next_state(6), 0.0, tol);
  EXPECT_NEAR(next_state(7), 3.5296125411987305, tol);
  EXPECT_NEAR(output(23), (10.5 + 9.81 * sinf(pitch)), tol);

  /**
   * Apply full brake and half right turn to a backwards moving state oriented 30 degrees to the left which is already
   * turning and on a downward facing hill
   */
  state << -1.0, yaw, 0, 0, steer_angle, -0.0, pitch, 0, 0;
  control << -1, -0.5;
  model->initializeLSTM(buffer);
  dynamics.step(state, next_state, state_der, control, output, 0, dt);
  EXPECT_NEAR(next_state(0), -1 + (10.5 + 9.81 * sinf(pitch)) * dt, tol);
  EXPECT_NEAR(next_state(1), yaw + 0.0385189 * dt * 2, tol);
  EXPECT_NEAR(next_state(2), -1 * cos(yaw) * dt, tol);
  EXPECT_NEAR(next_state(3), -1 * sin(yaw) * dt, tol);
  EXPECT_NEAR(next_state(4), steer_angle + -0.32692205905914307 * dt, tol);
  EXPECT_NEAR(next_state(5), 0.0, tol);
  EXPECT_NEAR(next_state(6), 0.0, tol);
  EXPECT_NEAR(next_state(7), -0.32692205905914307, tol);
  EXPECT_NEAR(output(23), (10.5 + 9.81 * sinf(pitch)), tol);

  /**
   * Apply full brake and half right turn to a backwards moving state with a huge steering angle to test max steer
   * angle and steering rate. We are also on a downward facing hill and are already oriented 30 degrees to the left
   */
  steer_angle *= 100;
  state << -1.0, yaw, 0, 0, steer_angle, -0.0, pitch, 0, 0;
  control << -1, -0.5;
  model->initializeLSTM(buffer);
  dynamics.step(state, next_state, state_der, control, output, 0, dt);
  EXPECT_NEAR(next_state(0), -1 + (10.5 + 9.81 * sinf(pitch)) * dt, tol);
  EXPECT_NEAR(next_state(1), yaw + tan(steer_angle / -10.2) * dt * -2, tol);
  EXPECT_NEAR(next_state(2), -1 * cos(yaw) * dt, tol);
  EXPECT_NEAR(next_state(3), -1 * sin(yaw) * dt, tol);
  EXPECT_NEAR(next_state(4), params.max_steer_angle, tol);
  EXPECT_NEAR(next_state(5), 0.0, tol);
  EXPECT_NEAR(next_state(6), 0.0, tol);
  EXPECT_NEAR(next_state(7), 15.97845268249511, tol);
  EXPECT_NEAR(output(23), (10.5 + 9.81 * sinf(pitch)), tol);
}

TEST_F(RacerDubinsElevationLSTMSteeringTest, TestStepGPUvsCPU)
{
  const int num_rollouts = 1000;
  const float dt = 0.1f;
  CudaCheckError();
  using DYN = RacerDubinsElevationLSTMSteering;
  RacerDubinsElevationLSTMSteering dynamics = RacerDubinsElevationLSTMSteering();

  cudaExtent extent = make_cudaExtent(10, 20, 0);
  TwoDTextureHelper<float>* helper = dynamics.getTextureHelper();
  helper->setExtent(0, extent);

  std::vector<float> data_vec;
  data_vec.resize(10 * 20);
  for (int i = 0; i < data_vec.size(); i++)
  {
    data_vec[i] = i * 1.0f;
  }

  std::array<float3, 3> new_rot_mat{};
  new_rot_mat[0] = make_float3(0, 1, 0);
  new_rot_mat[1] = make_float3(1, 0, 0);
  new_rot_mat[2] = make_float3(0, 0, 1);
  helper->updateRotation(0, new_rot_mat);
  helper->updateOrigin(0, make_float3(1, 2, 3));

  helper->updateTexture(0, data_vec);
  helper->updateResolution(0, 10);
  helper->enableTexture(0);
  helper->copyToDevice(true);

  auto model = dynamics.getHelper();
  std::vector<float> theta_vec(DYN::NN::OUTPUT_PARAMS_T::NUM_PARAMS);
  for (int i = 0; i < theta_vec.size(); i++)
  {
    theta_vec[i] = 0.1f;
  }
  model->updateOutputModel({ 11, 20, 1 }, theta_vec);

  theta_vec.resize(DYN::NN::INIT_OUTPUT_PARAMS_T::NUM_PARAMS);
  for (int i = 0; i < theta_vec.size(); i++)
  {
    theta_vec[i] = 0.01;
  }
  model->updateOutputModelInit({ 65, 100, 10 }, theta_vec);

  auto lstm_params = model->getLSTMParams();
  lstm_params.setAllValues(0.3f);
  model->setLSTMParams(lstm_params);

  auto init_params = model->getInitLSTMParams();
  init_params.setAllValues(0.01f);
  model->setInitParams(init_params);

  DYN::NN::init_buffer buffer = DYN::NN::init_buffer::Ones() * 0.01;
  model->initializeLSTM(buffer);

  CudaCheckError();
  dynamics.GPUSetup();
  CudaCheckError();

  EXPECT_NE(dynamics.getHelper()->getLSTMDevicePtr(), nullptr);
  EXPECT_NE(dynamics.network_d_, nullptr);
  EXPECT_EQ(dynamics.network_d_, dynamics.getHelper()->getLSTMDevicePtr());

  Eigen::Matrix<float, RacerDubinsElevationLSTMSteering::CONTROL_DIM, num_rollouts> control_trajectory;
  control_trajectory = Eigen::Matrix<float, RacerDubinsElevationLSTMSteering::CONTROL_DIM, num_rollouts>::Random();
  Eigen::Matrix<float, RacerDubinsElevationLSTMSteering::STATE_DIM, num_rollouts> state_trajectory;
  state_trajectory = Eigen::Matrix<float, RacerDubinsElevationLSTMSteering::STATE_DIM, num_rollouts>::Random();

  std::vector<std::array<float, RacerDubinsElevationLSTMSteering::STATE_DIM>> s(num_rollouts);
  std::vector<std::array<float, RacerDubinsElevationLSTMSteering::STATE_DIM>> s_next(num_rollouts);
  std::vector<std::array<float, RacerDubinsElevationLSTMSteering::STATE_DIM>> s_der(num_rollouts);
  // steering, throttle
  std::vector<std::array<float, RacerDubinsElevationLSTMSteering::CONTROL_DIM>> u(num_rollouts);

  RacerDubinsElevationLSTMSteering::state_array state;
  RacerDubinsElevationLSTMSteering::state_array next_state_cpu;
  RacerDubinsElevationLSTMSteering::control_array control;
  RacerDubinsElevationLSTMSteering::output_array output;
  RacerDubinsElevationLSTMSteering::state_array state_der_cpu = RacerDubinsElevationLSTMSteering::state_array::Zero();

  // Run dynamics on dynamicsU
  // Run dynamics on GPU
  for (int y_dim = 1; y_dim <= 16; y_dim++)
  {
    for (int state_index = 0; state_index < num_rollouts; state_index++)
    {
      for (int dim = 0; dim < s[0].size(); dim++)
      {
        s[state_index][dim] = state_trajectory.col(state_index)(dim);
      }
      for (int dim = 0; dim < u[0].size(); dim++)
      {
        u[state_index][dim] = control_trajectory.col(state_index)(dim);
      }
    }
    model->initializeLSTM(buffer);
    launchStepTestKernel<RacerDubinsElevationLSTMSteering>(dynamics, s, u, s_der, s_next, 0, dt, y_dim);
    for (int point = 0; point < num_rollouts; point++)
    {
      dynamics.initializeDynamics(state, control, output, 0, 0);
      state = state_trajectory.col(point);
      control = control_trajectory.col(point);
      state_der_cpu = RacerDubinsElevationLSTMSteering::state_array::Zero();

      dynamics.step(state, next_state_cpu, state_der_cpu, control, output, 0, dt);
      // for (int dim = 0; dim < RacerDubinsElevationLSTMSteering::STATE_DIM; dim++)
      for (int dim = 0; dim < RacerDubinsElevationLSTMSteering::STATE_DIM; dim++)
      {
        EXPECT_NEAR(state_der_cpu(dim), s_der[point][dim], 1e-4)
            << "at index " << point << " with y_dim " << y_dim << " dim " << dim;
        // EXPECT_NEAR(state(dim), s[point][dim], 1e-4) << "at index " << point << " with y_dim " << y_dim;
        EXPECT_NEAR(next_state_cpu(dim), s_next[point][dim], 1e-4)
            << "at index " << point << " with y_dim " << y_dim << " dim " << dim;
        EXPECT_TRUE(isfinite(s_next[point][dim]));
      }
    }
  }
  dynamics.freeCudaMem();
}
//
// TEST_F(RacerDubinsElevationLSTMSteeringTest, TestStepReverse)
// {
//   CudaCheckError();
//   using DYN = RacerDubinsElevationLSTMSteering;
//   const float tol = 1e-6;
//   DYN dynamics = DYN();
//   auto params = dynamics.getParams();
//   params.c_0 = 0;
//   params.c_b[0] = 1;
//   params.c_b[1] = 10;
//   params.c_b[2] = 100;
//   params.c_v[0] = 0.25;
//   params.c_v[1] = 0.5;
//   params.c_v[2] = 0.75;
//   params.c_t[0] = 2;
//   params.c_t[1] = 20;
//   params.c_t[2] = 200;
//   params.low_min_throttle = 0.2;
//   params.steer_command_angle_scale = 0.5;
//   params.steering_constant = 0.5;
//   params.wheel_base = 0.5;
//   params.max_steer_rate = 5;
//   params.gear_sign = -1;
//   dynamics.setParams(params);
//   DYN::state_array state;
//   DYN::state_array next_state;
//   DYN::state_array state_der = DYN::state_array::Zero();
//   DYN::control_array control;
//   DYN::output_array output;
//   float dt = 0.1;
//   // TODO add in the elevation map
//
//   // Basic initial state and no movement should stay still
//   state << 0, 0, 0, 0, 0, -0.0, 0.0, 0, 0;
//   control << 0, 0;
//   dynamics.step(state, next_state, state_der, control, output, 0, dt);
//   EXPECT_TRUE(state_der == DYN::state_array::Zero());
//   EXPECT_NEAR(next_state(0), 0.0, tol);
//   EXPECT_NEAR(next_state(1), 0.0, tol);
//   EXPECT_NEAR(next_state(2), 0.0, tol);
//   EXPECT_NEAR(next_state(3), 0.0, tol);
//   EXPECT_NEAR(next_state(4), 0.0, tol);
//   EXPECT_NEAR(next_state(5), 0.0, tol);
//   EXPECT_NEAR(next_state(6), 0.0, tol);
//   EXPECT_NEAR(next_state(7), 0.0, tol);
//   EXPECT_NEAR(next_state(8), 0.0, tol);
//
//   // Apply full throttle from zero state
//   state << 0, 0, 0, 0, 0, -0.0, 0.0, 0, 0;
//   control << 1, 0;
//   dynamics.step(state, next_state, state_der, control, output, 0, dt);
//   EXPECT_NEAR(state_der(0), -1.6, tol);
//   EXPECT_NEAR(next_state(0), -0.16, tol);
//   EXPECT_NEAR(next_state(1), 0.0, tol);
//   EXPECT_NEAR(next_state(2), 0.0, tol);
//   EXPECT_NEAR(next_state(3), 0.0, tol);
//   EXPECT_NEAR(next_state(4), 0.0, tol);
//   EXPECT_NEAR(next_state(5), 0.0, tol);
//   EXPECT_NEAR(next_state(6), 0.0, tol);
//   EXPECT_NEAR(next_state(7), 0.0, tol);
//   EXPECT_NEAR(next_state(8), -1.6, tol);
//
//   // Apply throttle to a state with positive velocity
//   state << 1, 0, 0, 0, 0, -0.0, 0.0, 0, 0;
//   control << 1, 0;
//   dynamics.step(state, next_state, state_der, control, output, 0, dt);
//   EXPECT_NEAR(state_der(0), -20.5, tol);
//   EXPECT_NEAR(next_state(0), -1.05, tol);
//   EXPECT_NEAR(next_state(1), 0.0, tol);
//   EXPECT_NEAR(next_state(2), 0.1, tol);
//   EXPECT_NEAR(next_state(3), 0.0, tol);
//   EXPECT_NEAR(next_state(4), 0.0, tol);
//   EXPECT_NEAR(next_state(5), 0.0, tol);
//   EXPECT_NEAR(next_state(6), 0.0, tol);
//   EXPECT_NEAR(next_state(7), 0.0, tol);
//   EXPECT_NEAR(next_state(8), -20.5, tol);
//
//   // Apply full throttle and half left turn to origin state
//   state << 0, 0, 0, 0, 0, -0.0, 0.0, 0, 0;
//   control << 1, 0.5;
//   dynamics.step(state, next_state, state_der, control, output, 0, dt);
//   EXPECT_NEAR(state_der(0), -1.6, tol);
//   EXPECT_NEAR(next_state(0), -0.16, tol);
//   EXPECT_NEAR(next_state(1), 0.0, tol);
//   EXPECT_NEAR(next_state(2), 0.0, tol);
//   EXPECT_NEAR(next_state(3), 0.0, tol);
//   EXPECT_NEAR(next_state(4), powf(0.5, 3) * dt, tol);
//   EXPECT_NEAR(next_state(5), 0.0, tol);
//   EXPECT_NEAR(next_state(6), 0.0, tol);
//   EXPECT_NEAR(next_state(7), powf(0.5, 3), tol);
//   EXPECT_NEAR(next_state(8), -1.6, tol);
//
//   // Apply full throttle and half left turn to a moving state oriented 30 degrees to the left
//   float yaw = M_PI / 6;
//   state << 1.0, yaw, 0, 0, 0, -0.0, 0.0, 0, 0;
//   control << 1, 0.5;
//   dynamics.step(state, next_state, state_der, control, output, 0, dt);
//   EXPECT_NEAR(state_der(0), -20.5, tol);
//   EXPECT_NEAR(next_state(0), -1.05, tol);
//   EXPECT_NEAR(next_state(1), yaw, tol);
//   EXPECT_NEAR(next_state(2), 1 * cos(yaw) * dt, tol);
//   EXPECT_NEAR(next_state(3), 1 * sin(yaw) * dt, tol);
//   EXPECT_NEAR(next_state(4), powf(0.5, 3) * dt, tol);
//   EXPECT_NEAR(next_state(5), 0.0, tol);
//   EXPECT_NEAR(next_state(6), 0.0, tol);
//   EXPECT_NEAR(next_state(7), powf(0.5, 3), tol);
//   EXPECT_NEAR(next_state(8), -20.5, tol);
//
//   // Apply full throttle and half left turn to a moving state oriented 30 degrees to the left which is already
//   turning float steer_angle = M_PI / 8; state << 1.0, yaw, 0, 0, steer_angle, -0.0, 0.0, 0, 0; control << 1, 0.5;
//   dynamics.step(state, next_state, state_der, control, output, 0, dt);
//   EXPECT_NEAR(state_der(0), -20.5, tol);
//   EXPECT_NEAR(next_state(0), -1.05, tol);
//   EXPECT_NEAR(next_state(1), yaw + -0.0385189 * dt * 2, tol);
//   EXPECT_NEAR(next_state(2), 1 * cos(yaw) * dt, tol);
//   EXPECT_NEAR(next_state(3), 1 * sin(yaw) * dt, tol);
//   EXPECT_NEAR(next_state(4), steer_angle + (0.25 - steer_angle) * 0.5 * dt, tol);
//   EXPECT_NEAR(next_state(5), 0.0, tol);
//   EXPECT_NEAR(next_state(6), 0.0, tol);
//   EXPECT_NEAR(next_state(7), (0.25 - steer_angle) * 0.5, tol);
//   EXPECT_NEAR(next_state(8), -20.5, tol);
//
//   // Apply full brake and half left turn to a moving state oriented 30 degrees to the left which is already turning
//   state << 1.0, yaw, 0, 0, steer_angle, -0.0, 0.0, 0, 0;
//   control << -1, 0.5;
//   dynamics.step(state, next_state, state_der, control, output, 0, dt);
//   EXPECT_NEAR(state_der(0), -10 - 0.5, tol);
//   EXPECT_NEAR(next_state(0), 1 - 10.5 * dt, tol);
//   EXPECT_NEAR(next_state(1), yaw + -0.0385189 * dt * 2, tol);
//   EXPECT_NEAR(next_state(2), 1 * cos(yaw) * dt, tol);
//   EXPECT_NEAR(next_state(3), 1 * sin(yaw) * dt, tol);
//   EXPECT_NEAR(next_state(4), steer_angle + (0.25 - steer_angle) * 0.5 * dt, tol);
//   EXPECT_NEAR(next_state(5), 0.0, tol);
//   EXPECT_NEAR(next_state(6), 0.0, tol);
//   EXPECT_NEAR(next_state(7), (0.25 - steer_angle) * 0.5, tol);
//   EXPECT_NEAR(next_state(8), -10.5, tol);
//
//   /**
//    * Apply full brake and half left turn to a moving state oriented 30 degrees to the left which is already turning
//    * and on a downward facing hill
//    */
//   float pitch = 20 * M_PI / 180;
//   state << 1.0, yaw, 0, 0, steer_angle, -0.0, pitch, 0, 0;
//   control << -1, 0.5;
//   dynamics.step(state, next_state, state_der, control, output, 0, dt);
//   EXPECT_NEAR(next_state(0), 1 + (-10.5 + 9.81 * sinf(pitch)) * dt, tol);
//   EXPECT_NEAR(next_state(1), yaw + -0.0385189 * dt * 2, tol);
//   EXPECT_NEAR(next_state(2), 1 * cos(yaw) * dt, tol);
//   EXPECT_NEAR(next_state(3), 1 * sin(yaw) * dt, tol);
//   EXPECT_NEAR(next_state(4), steer_angle + (0.25 - steer_angle) * 0.5 * dt, tol);
//   EXPECT_NEAR(next_state(5), 0.0, tol);
//   EXPECT_NEAR(next_state(6), 0.0, tol);
//   EXPECT_NEAR(next_state(7), (0.25 - steer_angle) * 0.5, tol);
//   EXPECT_NEAR(next_state(8), (-10.5 + 9.81 * sinf(pitch)), tol);
//
//   /**
//    * Apply full brake and half left turn to a backwards moving state oriented 30 degrees to the left which is already
//    * turning and on a downward facing hill
//    */
//   state << -1.0, yaw, 0, 0, steer_angle, -0.0, pitch, 0, 0;
//   control << -1, 0.5;
//   dynamics.step(state, next_state, state_der, control, output, 0, dt);
//   EXPECT_NEAR(next_state(0), -1 + (10.5 + 9.81 * sinf(pitch)) * dt, tol);
//   EXPECT_NEAR(next_state(1), yaw + 0.0385189 * dt * 2, tol);
//   EXPECT_NEAR(next_state(2), -1 * cos(yaw) * dt, tol);
//   EXPECT_NEAR(next_state(3), -1 * sin(yaw) * dt, tol);
//   EXPECT_NEAR(next_state(4), steer_angle + (0.25 - steer_angle) * 0.5 * dt, tol);
//   EXPECT_NEAR(next_state(5), 0.0, tol);
//   EXPECT_NEAR(next_state(6), 0.0, tol);
//   EXPECT_NEAR(next_state(7), (0.25 - steer_angle) * 0.5, tol);
//   EXPECT_NEAR(next_state(8), (10.5 + 9.81 * sinf(pitch)), tol);
//
//   /**
//    * Apply full brake and half right turn to a backwards moving state oriented 30 degrees to the left which is
//    already
//    * turning and on a downward facing hill
//    */
//   state << -1.0, yaw, 0, 0, steer_angle, -0.0, pitch, 0, 0;
//   control << -1, -0.5;
//   dynamics.step(state, next_state, state_der, control, output, 0, dt);
//   EXPECT_NEAR(next_state(0), -1 + (10.5 + 9.81 * sinf(pitch)) * dt, tol);
//   EXPECT_NEAR(next_state(1), yaw + 0.0385189 * dt * 2, tol);
//   EXPECT_NEAR(next_state(2), -1 * cos(yaw) * dt, tol);
//   EXPECT_NEAR(next_state(3), -1 * sin(yaw) * dt, tol);
//   EXPECT_NEAR(next_state(4), steer_angle + (-0.25 - steer_angle) * 0.5 * dt, tol);
//   EXPECT_NEAR(next_state(5), 0.0, tol);
//   EXPECT_NEAR(next_state(6), 0.0, tol);
//   EXPECT_NEAR(next_state(7), (-0.25 - steer_angle) * 0.5, tol);
//   EXPECT_NEAR(next_state(8), (10.5 + 9.81 * sinf(pitch)), tol);
//
//   /**
//    * Apply full brake and half right turn to a backwards moving state with a huge steering angle to test max steer
//    * angle and steering rate. We are also on a downward facing hill and are already oriented 30 degrees to the left
//    */
//   steer_angle *= 100;
//   state << -1.0, yaw, 0, 0, steer_angle, -0.0, pitch, 0, 0;
//   control << -1, -0.5;
//   dynamics.step(state, next_state, state_der, control, output, 0, dt);
//   EXPECT_NEAR(next_state(0), -1 + (10.5 + 9.81 * sinf(pitch)) * dt, tol);
//   EXPECT_NEAR(next_state(1), yaw + tan(steer_angle / -10.2) * dt * -2, tol);
//   EXPECT_NEAR(next_state(2), -1 * cos(yaw) * dt, tol);
//   EXPECT_NEAR(next_state(3), -1 * sin(yaw) * dt, tol);
//   EXPECT_NEAR(next_state(4), params.max_steer_angle, tol);
//   EXPECT_NEAR(next_state(5), 0.0, tol);
//   EXPECT_NEAR(next_state(6), 0.0, tol);
//   EXPECT_NEAR(next_state(7), -params.max_steer_rate, tol);
//   EXPECT_NEAR(next_state(8), (10.5 + 9.81 * sinf(pitch)), tol);
// }
//
// TEST_F(RacerDubinsElevationLSTMSteeringTest, TestStepGPUvsCPUReverse)
// {
//   const int num_rollouts = 75;
//   const float dt = 0.1f;
//   CudaCheckError();
//   RacerDubinsElevationLSTMSteering dynamics = RacerDubinsElevationLSTMSteering();
//   auto params = dynamics.getParams();
//   params.gear_sign = -1;
//   dynamics.setParams(params);
//
//   cudaExtent extent = make_cudaExtent(10, 20, 0);
//   TwoDTextureHelper<float>* helper = dynamics.getTextureHelper();
//   helper->setExtent(0, extent);
//
//   std::vector<float> data_vec;
//   data_vec.resize(10 * 20);
//   for (int i = 0; i < data_vec.size(); i++)
//   {
//     data_vec[i] = i * 1.0f;
//   }
//
//   std::array<float3, 3> new_rot_mat{};
//   new_rot_mat[0] = make_float3(0, 1, 0);
//   new_rot_mat[1] = make_float3(1, 0, 0);
//   new_rot_mat[2] = make_float3(0, 0, 1);
//   helper->updateRotation(0, new_rot_mat);
//   helper->updateOrigin(0, make_float3(1, 2, 3));
//
//   helper->updateTexture(0, data_vec);
//   helper->updateResolution(0, 10);
//   helper->enableTexture(0);
//   helper->copyToDevice(true);
//
//   CudaCheckError();
//   dynamics.GPUSetup();
//   CudaCheckError();
//
//   Eigen::Matrix<float, RacerDubinsElevationLSTMSteering::CONTROL_DIM, num_rollouts> control_trajectory;
//   control_trajectory = Eigen::Matrix<float, RacerDubinsElevationLSTMSteering::CONTROL_DIM, num_rollouts>::Random();
//   Eigen::Matrix<float, RacerDubinsElevationLSTMSteering::STATE_DIM, num_rollouts> state_trajectory;
//   state_trajectory = Eigen::Matrix<float, RacerDubinsElevationLSTMSteering::STATE_DIM, num_rollouts>::Random();
//
//   std::vector<std::array<float, RacerDubinsElevationLSTMSteering::STATE_DIM>> s(num_rollouts);
//   std::vector<std::array<float, RacerDubinsElevationLSTMSteering::STATE_DIM>> s_next(num_rollouts);
//   std::vector<std::array<float, RacerDubinsElevationLSTMSteering::STATE_DIM>> s_der(num_rollouts);
//   // steering, throttle
//   std::vector<std::array<float, RacerDubinsElevationLSTMSteering::CONTROL_DIM>> u(num_rollouts);
//
//   RacerDubinsElevationLSTMSteering::state_array state;
//   RacerDubinsElevationLSTMSteering::state_array next_state_cpu;
//   RacerDubinsElevationLSTMSteering::control_array control;
//   RacerDubinsElevationLSTMSteering::output_array output;
//   RacerDubinsElevationLSTMSteering::state_array state_der_cpu =
//   RacerDubinsElevationLSTMSteering::state_array::Zero();
//
//   // Run dynamics on dynamicsU
//   // Run dynamics on GPU
//   for (int y_dim = 1; y_dim <= 10; y_dim++)
//   {
//     for (int state_index = 0; state_index < num_rollouts; state_index++)
//     {
//       for (int dim = 0; dim < s[0].size(); dim++)
//       {
//         s[state_index][dim] = state_trajectory.col(state_index)(dim);
//       }
//       for (int dim = 0; dim < u[0].size(); dim++)
//       {
//         u[state_index][dim] = control_trajectory.col(state_index)(dim);
//       }
//     }
//
//     launchStepTestKernel<RacerDubinsElevationLSTMSteering>(dynamics, s, u, s_der, s_next, 0, dt, y_dim);
//     for (int point = 0; point < num_rollouts; point++)
//     {
//       state = state_trajectory.col(point);
//       control = control_trajectory.col(point);
//       state_der_cpu = RacerDubinsElevationLSTMSteering::state_array::Zero();
//
//       dynamics.step(state, next_state_cpu, state_der_cpu, control, output, 0, dt);
//       for (int dim = 0; dim < RacerDubinsElevationLSTMSteering::STATE_DIM; dim++)
//       {
//         EXPECT_NEAR(state_der_cpu(dim), s_der[point][dim], 1e-4) << "at index " << point << " with y_dim " << y_dim;
//         // EXPECT_NEAR(state(dim), s[point][dim], 1e-4) << "at index " << point << " with y_dim " << y_dim;
//         EXPECT_NEAR(next_state_cpu(dim), s_next[point][dim], 1e-4) << "at index " << point << " with y_dim " <<
//         y_dim; EXPECT_TRUE(isfinite(s_next[point][dim]));
//       }
//     }
//   }
//   dynamics.freeCudaMem();
// }
//
// TEST_F(RacerDubinsElevationLSTMSteeringTest, ComputeStateTrajectoryFiniteTest)
// {
//   RacerDubinsElevationLSTMSteering dynamics = RacerDubinsElevationLSTMSteering();
//   using PARAMS = RacerDubinsElevationLSTMSteering::DYN_PARAMS_T;
//   PARAMS params;
//   params.c_t[0] = 3.0;
//   params.c_b[0] = 0.2;
//   params.c_v[0] = 0.2;
//   params.c_0 = 0.2;
//   params.wheel_base = 3.0;
//   params.steering_constant = 1.0;
//   dynamics.setParams(params);
//
//   Eigen::Matrix<float, RacerDubinsElevationLSTMSteering::CONTROL_DIM, 500> control_trajectory;
//   control_trajectory = Eigen::Matrix<float, RacerDubinsElevationLSTMSteering::CONTROL_DIM, 500>::Zero();
//   Eigen::Matrix<float, RacerDubinsElevationLSTMSteering::STATE_DIM, 500> state_trajectory;
//   state_trajectory = Eigen::Matrix<float, RacerDubinsElevationLSTMSteering::STATE_DIM, 500>::Zero();
//   RacerDubinsElevationLSTMSteering::state_array state_der;
//   RacerDubinsElevationLSTMSteering::state_array x, x_next;
//   RacerDubinsElevationLSTMSteering::output_array output;
//   x << 0, 1.46919e-6, 0.0140179, 1.09739e-8, -0.000735827;
//
//   for (int i = 0; i < 500; i++)
//   {
//     RacerDubinsElevationLSTMSteering::control_array u = control_trajectory.col(i);
//     dynamics.step(x, x_next, state_der, u, output, i, 0.02);
//     dynamics.computeDynamics(x, u, state_der);
//     EXPECT_TRUE(x.allFinite());
//     EXPECT_TRUE(x_next.allFinite());
//     EXPECT_TRUE(state_der.allFinite());
//     EXPECT_TRUE(u.allFinite());
//     EXPECT_TRUE(state_der != RacerDubinsElevationLSTMSteering::state_array::Zero());
//     x = x_next;
//   }
//   params.steering_constant = 0.5;
//   dynamics.setParams(params);
//
//   x << 0, 1.46919e-6, 0.0140179, 1.09739e-8, -1.0;
//   for (int i = 0; i < 500; i++)
//   {
//     RacerDubinsElevationLSTMSteering::control_array u = control_trajectory.col(i);
//     dynamics.step(x, x_next, state_der, u, output, i, 0.02);
//     dynamics.computeDynamics(x, u, state_der);
//     EXPECT_TRUE(x.allFinite());
//     EXPECT_TRUE(x_next.allFinite());
//     EXPECT_TRUE(state_der.allFinite());
//     EXPECT_TRUE(u.allFinite());
//     EXPECT_TRUE(state_der != RacerDubinsElevationLSTMSteering::state_array::Zero());
//     x = x_next;
//   }
// }

/*
class LinearDummy : public RacerDubinsElevationLSTMSteering {
public:
  bool computeGrad(const Eigen::Ref<const state_array> & state,
                   const Eigen::Ref<const control_array>& control,
                   Eigen::Ref<dfdx> A,
                   Eigen::Ref<dfdu> B) {
    return false;
  };
};

TEST_F(RacerDubinsElevationLSTMSteeringTest, TestComputeGradComputation) {
  Eigen::Matrix<float, RacerDubinsElevationLSTMSteering::STATE_DIM, RacerDubinsElevationLSTMSteering::STATE_DIM +
RacerDubinsElevationLSTMSteering::CONTROL_DIM> numeric_jac; Eigen::Matrix<float,
RacerDubinsElevationLSTMSteering::STATE_DIM, RacerDubinsElevationLSTMSteering::STATE_DIM +
RacerDubinsElevationLSTMSteering::CONTROL_DIM> analytic_jac; RacerDubinsElevationLSTMSteering::state_array state; state
<< 1, 2, 3, 4; RacerDubinsElevationLSTMSteering::control_array control; control << 5;

  auto analytic_grad_model = RacerDubinsElevationLSTMSteering();

  RacerDubinsElevationLSTMSteering::dfdx A_analytic = RacerDubinsElevationLSTMSteering::dfdx::Zero();
  RacerDubinsElevationLSTMSteering::dfdu B_analytic = RacerDubinsElevationLSTMSteering::dfdu::Zero();

  analytic_grad_model.computeGrad(state, control, A_analytic, B_analytic);

  auto numerical_grad_model = LinearDummy();

  std::shared_ptr<ModelWrapperDDP<LinearDummy>> ddp_model =
std::make_shared<ModelWrapperDDP<LinearDummy>>(&numerical_grad_model);

  analytic_jac.leftCols<RacerDubinsElevationLSTMSteering::STATE_DIM>() = A_analytic;
  analytic_jac.rightCols<RacerDubinsElevationLSTMSteering::CONTROL_DIM>() = B_analytic;
  numeric_jac = ddp_model->df(state, control);

  ASSERT_LT((numeric_jac - analytic_jac).norm(), 1e-3) << "Numeric Jacobian\n" << numeric_jac << "\nAnalytic Jacobian\n"
<< analytic_jac;
}

*/
