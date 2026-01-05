#include "erl_nif.h"
#include <concepts>
#include <fstream>
#include <functional>
#include <iostream>
#include <vector>

struct Coordinate2D {
  size_t row;
  size_t col;
};

template <std::semiregular T> struct Grid {
  size_t rows;
  size_t cols;
  std::vector<T> data;

  Grid(size_t r, size_t c) : rows(r), cols(c), data(r * c) {}

  [[nodiscard]] const T &operator[](size_t r, size_t c) const {
    return data[r * cols + c];
  }

  [[nodiscard]] T &operator[](size_t r, size_t c) { return data[r * cols + c]; }

  [[nodiscard]] Coordinate2D find_first(const T &value) const {
    for (size_t r = 0; r < rows; ++r) {
      for (size_t c = 0; c < cols; ++c) {
        if (data[r * cols + c] == value) {
          return Coordinate2D{r, c};
        }
      }
    }
    return Coordinate2D{rows, cols};
  }
};

std::vector<std::string> read_lines(const std::string &path) {
  std::vector<std::string> lines;
  std::ifstream file(path);
  std::string line;
  if (file.is_open()) {
    while (std::getline(file, line)) {
      lines.push_back(line);
    }
    file.close();
  }
  return lines;
}

std::vector<std::string> read_input_lines(int quest, int part) {
  std::string path = "data/quest" + std::to_string(quest) + "_" +
                     std::to_string(part) + ".txt";
  return read_lines(path);
}

template <std::ranges::forward_range R, typename F>
  requires std::invocable<F, char> &&
           std::semiregular<std::invoke_result_t<F, char>>
auto lines_to_grid(const R &lines, F transformer) {
  using T = std::invoke_result_t<F, char>;

  if (std::ranges::empty(lines)) {
    return Grid<T>(0, 0);
  }

  const size_t rows = std::ranges::distance(lines);
  const size_t cols = (*std::ranges::begin(lines)).size();

  Grid<T> grid(rows, cols);

  size_t r = 0;
  for (const auto &line : lines) {
    for (size_t c = 0; c < cols; ++c) {
      grid[r, c] = std::invoke(transformer, line[c]);
    }
    r++;
  }

  return grid;
}

std::string quest17_1() {
  auto radius = 10;
  auto input_lines = read_input_lines(17, 1);
  auto grid = lines_to_grid(
      input_lines, [](char c) { return c == '@' ? 0 : (int)(c - '0'); });
  std::cout << "Grid loaded: " << grid.rows << "x" << grid.cols << std::endl;
  auto center = grid.find_first(0);

  auto sum = 0;
  for (size_t r = 0; r < grid.rows; ++r) {
    for (size_t c = 0; c < grid.cols; ++c) {
      auto xx = (r - center.row) * (r - center.row);
      auto yy = (c - center.col) * (c - center.col);
      if (xx + yy <= radius * radius) {
        sum += grid[r, c];
      }
    }
  }
  return std::to_string(sum);
}

std::string quest17_2() {
  auto input_lines = read_input_lines(17, 2);
  auto grid = lines_to_grid(
      input_lines, [](char c) { return c == '@' ? 0 : (int)(c - '0'); });
  auto visited = Grid<uint8_t>(grid.rows, grid.cols);
  auto center = grid.find_first(0);
  visited[center.row, center.col] = 1;

  auto max_so_far = -1;
  auto radius_ans = 0;

  for (size_t radius = 1; radius <= grid.rows / 2; radius++) {
    auto sum = 0;
    for (size_t r = 0; r < grid.rows; ++r) {
      for (size_t c = 0; c < grid.cols; ++c) {
        auto xx = (r - center.row) * (r - center.row);
        auto yy = (c - center.col) * (c - center.col);
        if (xx + yy <= radius * radius && visited[r, c] == 0) {
          sum += grid[r, c];
          visited[r, c] = 1;
        }
      }
    }
    if (sum > max_so_far) {
      max_so_far = sum;
      radius_ans = radius;
    }
  }

  return std::to_string(max_so_far * radius_ans);
}

extern "C" {
ERL_NIF_TERM q17_1(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  auto result = quest17_1();
  return enif_make_string(env, result.c_str(), ERL_NIF_LATIN1);
}

ERL_NIF_TERM q17_2(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  auto result = quest17_2();
  return enif_make_string(env, result.c_str(), ERL_NIF_LATIN1);
}

ErlNifFunc nif_funcs[] = {
    {"q17_1", 0, q17_1},
    {"q17_2", 0, q17_2},
};

ERL_NIF_INIT(libcppnif, nif_funcs, NULL, NULL, NULL, NULL)
}