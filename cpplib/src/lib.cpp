#include "erl_nif.h"
#include <vector>
#include <fstream>
#include <concepts>
#include <functional>
#include <string_view>
#include <algorithm>

template <std::semiregular T>
struct Grid
{
    size_t rows;
    size_t cols;
    std::vector<T> data;

    Grid(size_t r, size_t c) : rows(r), cols(c), data(r * c) {}

    [[nodiscard]] const T &operator[](size_t r, size_t c) const
    {
        return data[r * cols + c];
    }

    [[nodiscard]] T &operator[](size_t r, size_t c)
    {
        return data[r * cols + c];
    }
};

std::vector<std::string>
read_lines(const std::string &path)
{
    std::vector<std::string> lines;
    std::ifstream file(path);
    std::string line;
    if (file.is_open())
    {
        while (std::getline(file, line))
        {
            lines.push_back(line);
        }
        file.close();
    }
    return lines;
}

template <std::ranges::forward_range R, typename F>
    requires std::invocable<F, char> && std::semiregular<std::invoke_result_t<F, char>>
auto lines_to_grid(const R &lines, F transformer)
{
    using T = std::invoke_result_t<F, char>;

    if (std::ranges::empty(lines))
    {
        return Grid<T>(0, 0);
    }

    const size_t rows = std::ranges::distance(lines);
    const size_t cols = (*std::ranges::begin(lines)).size();

    Grid<T> grid(rows, cols);

    size_t r = 0;
    for (const auto &line : lines)
    {
        for (size_t c = 0; c < cols; ++c)
        {
            grid[r, c] = std::invoke(transformer, line[c]);
        }
        r++;
    }

    return grid;
}
