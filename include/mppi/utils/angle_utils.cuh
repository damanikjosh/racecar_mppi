#ifndef ANGLES_CUH_
#define ANGLES_CUH_

#define M_PIf float(M_PI)
#define M_PI_2f float(M_PI_2)
#define M_PI_4f float(M_PI_4)

namespace angle_utils
{
/**
 *
 * @param angle
 * @return
 */
__host__ __device__ static inline double normalizeAngle(double angle)
{
  const double result = fmod(angle + M_PI, 2.0 * M_PI);
  if (result <= 0.0)
    return result + M_PI;
  return result - M_PI;
}
// float version might not be exact
// different systems will have slightly different values.
__host__ __device__ static inline float normalizeAngle(float angle)
{
  const float result = fmodf(angle + M_PIf, 2.0f * M_PIf);
  if (result <= 0.0f)
    return result + M_PIf;
  return result - M_PIf;
}

/**
 *
 * @param from
 * @param to
 * @return
 */
__host__ __device__ static inline double shortestAngularDistance(double from, double to)
{
  return normalizeAngle(to - from);
}
__host__ __device__ static inline float shortestAngularDistance(float from, float to)
{
  return normalizeAngle(to - from);
}

/**
 * Does a linear interpolation of the euler angle while respecting -pi to pi wrapping
 * solution from https://www.ri.cmu.edu/pub_files/pub4/kuffner_james_2004_1/kuffner_james_2004_1.pdf algorithm 6
 * @param angle_1
 * @param angle_2
 * @param alpha
 * @return
 */
__host__ __device__ static inline double interpolateEulerAngleLinear(double angle_1, double angle_2, double alpha)
{
  double angle_diff = shortestAngularDistance(angle_1, angle_2);
  return normalizeAngle(angle_1 + alpha * angle_diff);
}
__host__ __device__ static inline float interpolateEulerAngleLinear(float angle_1, float angle_2, float alpha)
{
  float angle_diff = shortestAngularDistance(angle_1, angle_2);
  return normalizeAngle(angle_1 + alpha * angle_diff);
}
}  // namespace angle_utils

#endif  // ANGLES_CUH_
