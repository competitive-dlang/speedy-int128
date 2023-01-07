# speedy-int128 [![Dub version](https://img.shields.io/dub/v/speedy-int128.svg)](https://code.dlang.org/packages/speedy-int128) [![Dub downloads](https://img.shields.io/dub/dt/speedy-int128.svg)](https://code.dlang.org/packages/speedy-int128) [![tests](https://github.com/ssvb/speedy-int128/actions/workflows/tests.yml/badge.svg)](https://github.com/ssvb/speedy-int128/actions/workflows/tests.yml) [![x86](https://github.com/ssvb/speedy-int128/actions/workflows/x86.yml/badge.svg)](https://github.com/ssvb/speedy-int128/actions/workflows/x86.yml) [![arm](https://github.com/ssvb/speedy-int128/actions/workflows/arm.yml/badge.svg)](https://github.com/ssvb/speedy-int128/actions/workflows/arm.yml)

This is a fork of [std.int128](https://dlang.org/phobos/std_int128.html) with added
[inline LLVM IR](https://github.com/ssvb/speedy-int128/blob/readme/speedy/int128_core_ldc.d)
for the LDC compiler to make it faster at handling 128-bit integers. This makes it as
fast as Clang, because Clang was actually used as a "donor" of this LLVM IR code via a
[simple script](https://github.com/ssvb/speedy-int128/blob/readme/speedy/gen_int128_core_ldc.rb).

This package is also a way to backport 128-bit arithmetics support to the ancient versions
of DMD, GDC and LDC which don't have it in their standard library yet.

Additionally, a [oneliner variant](https://raw.githubusercontent.com/ssvb/speedy-int128/readme/speedy_int128_oneliner.d)
is provided for [use on programming competition websites](https://github.com/ssvb/speedy-int128/tree/readme#use-on-programming-competition-websites).

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

## Performance

Benchmarks are done using the [benchmark.d](https://raw.githubusercontent.com/ssvb/speedy-int128/main/benchmark.d) /
[benchmark.c](https://raw.githubusercontent.com/ssvb/speedy-int128/main/benchmark.c) test programs as part of CI.
Some examples:

<details>
  <summary>GitHub Actions CI, Linux x86_64, Intel(R) Xeon(R) Platinum 8370C CPU @ 2.80GHz</summary>

https://github.com/ssvb/speedy-int128/actions/runs/3859195372/jobs/6578500703

| language | compiler       | 64-bit     | 32-bit     | notes                        |
|:--------:|:--------------:|:----------:|:----------:|:----------------------------:|
| D        | DMD 2.100.2    | 2999 ms    | 10755 ms   | std.int128                   |
| D        | GDC 12.1.0     | 2943 ms    | -          | std.int128                   |
| D        | LDC 1.30.0     | 1930 ms    | 5765 ms    | std.int128                   |
| C/C++    | Clang 14.0.0   | 468 ms     | -          | -O3                          |
| D        | LDC 1.30.0     | 402 ms     | 3582 ms    | speedy.int128 v0.1.0         |
| C/C++    | GCC 11.3.0     | 393 ms     | -          | -O3                          |

</details>

<details>
  <summary>GitHub Actions CI, Linux x86_64, Intel(R) Xeon(R) CPU E5-2673 v4 @ 2.30GHz</summary>

https://github.com/ssvb/speedy-int128/actions/runs/3859220724/jobs/6578545848

| language | compiler       | 64-bit     | 32-bit     | notes                        |
|:--------:|:--------------:|:----------:|:----------:|:----------------------------:|
| D        | DMD 2.100.2    | 3854 ms    | 11125 ms   | std.int128                   |
| D        | GDC 12.1.0     | 3753 ms    | -          | std.int128                   |
| D        | LDC 1.30.0     | 2735 ms    | 6068 ms    | std.int128                   |
| C/C++    | Clang 14.0.0   | 1885 ms    | -          | -O3                          |
| D        | LDC 1.30.0     | 1801 ms    | 4011 ms    | speedy.int128 v0.1.0         |
| C/C++    | GCC 11.3.0     | 1792 ms    | -          | -O3                          |

</details>

<details>
  <summary>BuildJet CI, Linux aarch64, ARM Neoverse-N1</summary>

https://github.com/ssvb/speedy-int128/actions/runs/3859220721/jobs/6578545846

| language | compiler       | 64-bit     | 32-bit     | notes                        |
|:--------:|:--------------:|:----------:|:----------:|:----------------------------:|
| D        | GDC 12.1.0     | 2867 ms    | -          | std.int128                   |
| D        | LDC 1.30.0     | 1657 ms    | -          | std.int128                   |
| D        | LDC 1.28.0     | 941 ms     | 12739 ms   | speedy.int128 v0.1.0         |
| D        | LDC 1.30.0     | 934 ms     | -          | speedy.int128 v0.1.0         |
| C/C++    | Clang 14.0.0   | 922 ms     | -          | -O3                          |
| C/C++    | GCC 11.2.0     | 898 ms     | -          | -O3                          |

</details>

## Use on programming competition websites

Programming competition websites, such as [Codeforces](https://codeforces.com/) and
[AtCoder](https://atcoder.jp/) allow using D language for submitting solutions. But
their compilers are typically very old and also installed without any third-party
libraries. Needless to say that DUB packages can't be used there in a normal way.

Another challenge is that each solution has to be submitted as a single source file
with a certain size limit (only 65535 bytes on Codeforces!).

The [onelinerizer.rb](https://github.com/ssvb/speedy-int128/blob/readme/onelinerizer.rb)
script can be used to compress the original 42K of D code into a single 16K line
by removing comments, extra whitespaces and unittests. The result is
[speedy_int128_oneliner.d](https://raw.githubusercontent.com/ssvb/speedy-int128/readme/speedy_int128_oneliner.d),
which can be pasted into the source code instead of the "import speedy.int128;" line.