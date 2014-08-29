// -*-c++-*-

#include <math.h> // M_PI

namespace mypackage {

// [[R6:export]]
class circle {
public:
  double radius;
  circle(double r) : radius(r) {}
  double area() const {
    return M_PI * radius * radius;
  }
  double circumference() const {
    return M_PI * 2 * radius;
  }
  void set_circumference(double c=1) {
    radius = c / (2 * M_PI);
  }
};

struct foo {
  double x;
};

// Simple homgeneous pair.
template <typename T>
class pair1 {
public:
  typedef T data_type;
  pair1(const T& first_, const T& second_)
    : first(first_), second(second_) {}
  T first;
  T second;
};

}
