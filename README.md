# speedy-int128 [![Dub version](https://img.shields.io/dub/v/speedy-int128.svg)](https://code.dlang.org/packages/speedy-int128) [![Dub downloads](https://img.shields.io/dub/dt/speedy-int128.svg)](https://code.dlang.org/packages/speedy-int128) [![tests](https://github.com/ssvb/speedy-int128/actions/workflows/tests.yml/badge.svg)](https://github.com/ssvb/speedy-int128/actions/workflows/tests.yml) [![x86](https://github.com/ssvb/speedy-int128/actions/workflows/x86.yml/badge.svg)](https://github.com/ssvb/speedy-int128/actions/workflows/x86.yml) [![arm](https://github.com/ssvb/speedy-int128/actions/workflows/arm.yml/badge.svg)](https://github.com/ssvb/speedy-int128/actions/workflows/arm.yml)

An experiment to speed up the 128-bit integer type for the LDC D compiler.

## Example

```D
/+dub.sdl: dependency "speedy-int128" version="~>0.1.0" +/
import speedy.int128; // instead of "std.int128"
import std.stdint, std.stdio, std.range, std.algorithm;

// https://lemire.me/blog/2019/03/19/the-fastest-conventional-random-number-generator-that-can-pass-big-crush/
uint64_t lehmer64() {
  static Int128 g_lehmer64_state = Int128(1L); /* bad seed */
  g_lehmer64_state *= 0xda942042e4dd58b5;
  return g_lehmer64_state.data.hi;
}

void main() {
  1_000_000_000.iota.map!(i => lehmer64).sum.writeln;
}
```

Install the [DUB package manager](https://github.com/dlang/dub) and run the example in a [script-like fashion](https://dub.pm/advanced_usage):
```
$ dub example.d
```

Or compile an optimized binary using the [LDC compiler](https://github.com/ldc-developers/ldc/releases):
```
$ dub build --build release --single --compiler=ldc2 example.d
```

## Use in programming competitions

Unorthodox packaging requirements. Third party libraries in DUB packages are unavailable.
Each solution is submitted as just a single source file and the size of this source
file is limited (65535 bytes).

## Performance

Benchmarks are done using the benchmark.d / benchmark.c test program and they are a part of CI. The following
table represents results from

<details>
  <summary>GitHub Actions CI, Linux x86_64, Intel(R) Xeon(R) Platinum 8370C CPU @ 2.80GHz</summary>

https://github.com/ssvb/speedy-int128/actions/runs/3859195372/jobs/6578500703

| compiler       | 64-bit     | 32-bit     | notes                        |
|:--------------:|:----------:|:----------:|:----------------------------:|
| DMD 2.100.2    | 2999 ms    | 10755 ms   | std.int128                   |
| GDC 12.1.0     | 2943 ms    | -          | std.int128                   |
| LDC 1.30.0     | 1930 ms    | 5765 ms    | std.int128                   |
| Clang 14.0.0   | 468 ms     | -          | -O3                          |
| LDC 1.30.0     | 402 ms     | 3582 ms    | speedy.int128                |
| GCC 11.3.0     | 393 ms     | -          | -O3                          |

</details>

<details>
  <summary>GitHub Actions CI, Linux x86_64, Intel(R) Xeon(R) CPU E5-2673 v4 @ 2.30GHz</summary>

https://github.com/ssvb/speedy-int128/actions/runs/3859220724/jobs/6578545848

| compiler       | 64-bit     | 32-bit     | notes                        |
|:--------------:|:----------:|:----------:|:----------------------------:|
| DMD 2.100.2    | 3854 ms    | 11125 ms   | std.int128                   |
| GDC 12.1.0     | 3753 ms    | -          | std.int128                   |
| LDC 1.30.0     | 2735 ms    | 6068 ms    | std.int128                   |
| Clang 14.0.0   | 1885 ms    | -          | -O3                          |
| LDC 1.30.0     | 1801 ms    | 4011 ms    | speedy.int128                |
| GCC 11.3.0     | 1792 ms    | -          | -O3                          |

</details>

<details>
  <summary>BuildJet CI, Linux aarch64 </summary>

https://github.com/ssvb/speedy-int128/actions/runs/3859220721/jobs/6578545846

| compiler       | 64-bit     | 32-bit     | notes                        |
|:--------------:|:----------:|:----------:|:----------------------------:|
| GDC 12.1.0     | 2867 ms    | -          | std.int128                   |
| LDC 1.30.0     | 1657 ms    | -          | std.int128                   |
| LDC 1.28.0     | 941 ms     | 12739 ms   | speedy.int128                |
| LDC 1.30.0     | 934 ms     | -          | speedy.int128                |
| Clang 14.0.0   | 922 ms     | -          | -O3                          |
| GCC 11.2.0     | 898 ms     | -          | -O3                          |

</details>

### Others

Additionally a oneliner variant can be used to do a benchmark on programing competition websites:

| platform                                         | compiler       | 64-bit     | 32-bit     | notes                        |
|:------------------------------------------------:|:--------------:|:----------:|:----------:|:----------------------------:|
| https://atcoder.jp/contests/practice/custom_test | DMD 2.091.0    | 2938 ms    | -          | speedy.int128 oneliner       |
|                                                  | GDC 9.2.1      | 1990 ms    | -          | speedy.int128 oneliner       |
|                                                  | Clang 10       | 1453 ms    | -          |                              |
|                                                  | GCC 9.2.1      | 1440 ms    | -          |                              |
|                                                  | LDC 1.20.1     | 1437 ms    | -          | speedy.int128 oneliner       |
| **platform**                                     | **compiler**   | **64-bit** | **32-bit** | **notes**                    |
| https://codeforces.com/problemset/customtest     | DMD 2.091.0    | -          | 9032 ms    | speedy.int128 oneliner       |
|                                                  | GCC 11.2.0     | 1560 ms    | -          |                              |
