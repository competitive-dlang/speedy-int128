// This is a pretty much unmodified copy of std.int128 from Phobos with just
// 'core.int128' replaced by 'speedy.int128_core_ldc' when compiled by LDC.
// Also all methods are marked with pragma(inline, true) for more speed.

// Written in the D programming language
/**
 * Implements a signed 128 bit integer type.
 *
    Author:     Walter Bright
    Copyright:  Copyright (c) 2022, D Language Foundation
    License:    $(HTTP boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Source:     $(PHOBOSSRC std/int128.d)
 */
module speedy.int128;

private import speedy.int128_core;
private import speedy.int128_core_ldc;

/***********************************
 * 128 bit signed integer type.
 */

public struct Int128
{
  @safe pure nothrow @nogc:

    // Pick suitable implementations depending on the compiler and the platform
    version (LDC)
    {
        alias shl = ldc_shl;
        alias shr = ldc_shr;
        alias sar = ldc_sar;
        alias xor = ldc_xor;
        alias and = ldc_and;
        alias or  = ldc_or;
        alias add = ldc_add;
        alias inc = ldc_inc;
        alias dec = ldc_dec;
        alias com = ldc_com;
        alias gt  = ldc_gt;
        alias tst = ldc_tst;
        static if (size_t.sizeof == 8)
        {
            // 64-bit platforms
            alias div = ldc_div;
            alias divmod = ldc_divmod;
            alias mul = ldc_mul;
            alias sub = ldc_sub;
            alias neg = ldc_neg;
        }
        else
        {
            // Avoid "error: undefined reference to '__umodti3'" on 32-bit x86
            alias div = core_div;
            alias divmod = core_divmod;
            version (ARM)
            {
                // Avoid "error: undefined reference to '__multi3'" on 32-bit ARM
                alias mul = core_mul;
                alias sub = core_sub;
                alias neg = core_neg;
            }
            else
            {
                alias mul = ldc_mul;
                alias sub = ldc_sub;
                alias neg = ldc_neg;
            }
        }
    }
    else
    {
        alias shl = core_shl;
        alias shr = core_shr;
        alias sar = core_sar;
        alias xor = core_xor;
        alias and = core_and;
        alias or  = core_or;
        alias add = core_add;
        alias inc = core_inc;
        alias dec = core_dec;
        alias com = core_com;
        alias gt  = core_gt;
        alias tst = core_tst;
        alias div = core_div;
        alias divmod = core_divmod;
        alias mul = core_mul;
        alias sub = core_sub;
        alias neg = core_neg;
    }

    Cent data;          /// core.int128.Cent

    /****************
     * Construct an `Int128` from a `long` value.
     * The upper 64 bits are formed by sign extension.
     * Params:
     *  lo = signed lower 64 bits
     */
    pragma(inline, true)
    this(long lo)
    {
        data.lo = lo;
        data.hi = lo < 0 ? ~0L : 0;
    }

    /****************
     * Construct an `Int128` from a `ulong` value.
     * The upper 64 bits are set to zero.
     * Params:
     *  lo = unsigned lower 64 bits
     */
    pragma(inline, true)
    this(ulong lo)
    {
        data.lo = lo;
        data.hi = 0;
    }

    /****************
     * Construct an `Int128` from a `long` value.
     * Params:
     *  hi = upper 64 bits
     *  lo = lower 64 bits
     */
    pragma(inline, true)
    this(long hi, long lo)
    {
        data.hi = hi;
        data.lo = lo;
    }

    /********************
     * Construct an `Int128` from a `Cent`.
     * Params:
     *  data = Cent data
     */
    pragma(inline, true)
    this(Cent data)
    {
        this.data = data;
    }

    /********************
     * Returns: hash value for Int128
     */
    pragma(inline, true)
    size_t toHash() const
    {
        return cast(size_t)((data.lo & 0xFFFF_FFFF) + (data.hi & 0xFFFF_FFFF) + (data.lo >> 32) + (data.hi >> 32));
    }

    /************************
     * Compare for equality
     * Params: lo = signed value to compare with
     * Returns: true if Int128 equals value
     */
    pragma(inline, true)
    bool opEquals(long lo) const
    {
        return data.lo == lo && data.hi == (lo >> 63);
    }

    /************************
     * Compare for equality
     * Params: lo = unsigned value to compare with
     * Returns: true if Int128 equals value
     */
    pragma(inline, true)
    bool opEquals(ulong lo) const
    {
        return data.hi == 0 && data.lo == lo;
    }

    /************************
     * Compare for equality
     * Params: op2 = value to compare with
     * Returns: true if Int128 equals value
     */
    pragma(inline, true)
    bool opEquals(Int128 op2) const
    {
        return data.hi == op2.data.hi && data.lo == op2.data.lo;
    }

    /** Support unary arithmentic operator +
     * Params: op = "+"
     * Returns: lvalue of result
     */
    pragma(inline, true)
    Int128 opUnary(string op)() const
        if (op == "+")
    {
        return this;
    }

    /** Support unary arithmentic operator - ~
     * Params: op = "-", "~"
     * Returns: lvalue of result
     */
    pragma(inline, true)
    Int128 opUnary(string op)() const
        if (op == "-" || op == "~")
    {
        static if (op == "-")
            return Int128(neg(this.data));
        else static if (op == "~")
            return Int128(com(this.data));
    }

    /** Support unary arithmentic operator ++ --
     * Params: op = "++", "--"
     * Returns: lvalue of result
     */
    pragma(inline, true)
    Int128 opUnary(string op)()
        if (op == "++" || op == "--")
    {
        static if (op == "++")
            this.data = inc(this.data);
        else static if (op == "--")
            this.data = dec(this.data);
        else
            static assert(0, op);
        return this;
    }

    /** Support casting to a bool
     * Params: T = bool
     * Returns: boolean result
     */
    pragma(inline, true)
    bool opCast(T : bool)() const
    {
        return tst(this.data);
    }

    /** Support binary arithmetic operators + - * / % & | ^ << >> >>>
     * Params:
     *   op = one of the arithmetic binary operators
     *   op2 = second operand
     * Returns: value after the operation is applied
     */
    pragma(inline, true)
    Int128 opBinary(string op)(Int128 op2) const
        if (op == "+" || op == "-" ||
            op == "*" || op == "/" || op == "%" ||
            op == "&" || op == "|" || op == "^")
    {
        static if (op == "+")
            return Int128(add(this.data, op2.data));
        else static if (op == "-")
            return Int128(sub(this.data, op2.data));
        else static if (op == "*")
            return Int128(mul(this.data, op2.data));
        else static if (op == "/")
            return Int128(div(this.data, op2.data));
        else static if (op == "%")
        {
            Cent modulus;
            divmod(this.data, op2.data, modulus);
            return Int128(modulus);
        }
        else static if (op == "&")
            return Int128(and(this.data, op2.data));
        else static if (op == "|")
            return Int128(or(this.data, op2.data));
        else static if (op == "^")
            return Int128(xor(this.data, op2.data));
        else
            static assert(0, "wrong op value");
    }

    /// ditto
    pragma(inline, true)
    Int128 opBinary(string op)(long op2) const
        if (op == "+" || op == "-" ||
            op == "*" || op == "/" || op == "%" ||
            op == "&" || op == "|" || op == "^")
    {
        return mixin("this " ~ op ~ " Int128(0, op2)");
    }

    /// ditto
    pragma(inline, true)
    Int128 opBinaryRight(string op)(long op2) const
        if (op == "+" || op == "-" ||
            op == "*" || op == "/" || op == "%" ||
            op == "&" || op == "|" || op == "^")
    {
        mixin("return Int128(0, op2) " ~ op ~ " this;");
    }

    /// ditto
    pragma(inline, true)
    Int128 opBinary(string op)(long op2) const
        if (op == "<<")
    {
        return Int128(shl(this.data, cast(uint) op2));
    }

    /// ditto
    pragma(inline, true)
    Int128 opBinary(string op)(long op2) const
        if (op == ">>")
    {
        return Int128(sar(this.data, cast(uint) op2));
    }

    /// ditto
    pragma(inline, true)
    Int128 opBinary(string op)(long op2) const
        if (op == ">>>")
    {
        return Int128(shr(this.data, cast(uint) op2));
    }

    /** arithmetic assignment operators += -= *= /= %= &= |= ^= <<= >>= >>>=
     * Params: op = one of +, -, etc.
     *   op2 = second operand
     * Returns: lvalue of updated left operand
     */
    pragma(inline, true)
    ref Int128 opOpAssign(string op)(Int128 op2)
        if (op == "+" || op == "-" ||
            op == "*" || op == "/" || op == "%" ||
            op == "&" || op == "|" || op == "^" ||
            op == "<<" || op == ">>" || op == ">>>")
    {
        mixin("this = this " ~ op ~ " op2;");
        return this;
    }

    /// ditto
    pragma(inline, true)
    ref Int128 opOpAssign(string op)(long op2)
        if (op == "+" || op == "-" ||
            op == "*" || op == "/" || op == "%" ||
            op == "&" || op == "|" || op == "^" ||
            op == "<<" || op == ">>" || op == ">>>")
    {
        mixin("this = this " ~ op ~ " op2;");
        return this;
    }

    /** support signed arithmentic comparison operators < <= > >=
     * Params: op2 = right hand operand
     * Returns: -1 for less than, 0 for equals, 1 for greater than
     */
    pragma(inline, true)
    int opCmp(Int128 op2) const
    {
        return this == op2 ? 0 : gt(this.data, op2.data) * 2 - 1;
    }

    /** support signed arithmentic comparison operators < <= > >=
     * Params: op2 = right hand operand
     * Returns: -1 for less than, 0 for equals, 1 for greater than
     */
    pragma(inline, true)
    int opCmp(long op2) const
    {
        return opCmp(Int128(0, op2));
    }

    enum min = Int128(long.min, 0);             /// minimum value
    enum max = Int128(long.max, ulong.max);     /// maximum value
}

/********************************************* Tests ************************************/

version (unittest)
{
import core.stdc.stdio;

@trusted void print(Int128 c)
{
    printf("%lld, %lld\n", c.data.hi, c.data.lo);
}

@trusted void printx(Int128 c)
{
    printf("%llx, %llx\n", c.data.hi, c.data.lo);
}
}

/// Int128 tests
@safe pure nothrow @nogc
unittest
{
    Int128 c = Int128(5, 6);
    assert(c == c);
    assert(c == +c);
    assert(c == - -c);
    assert(~c == Int128(~5, ~6));
    ++c;
    assert(c == Int128(5, 7));
    assert(--c == Int128(5, 6));
    assert(!!c);
    assert(!Int128());

    assert(c + Int128(10, 20) == Int128(15, 26));
    assert(c - Int128(1, 2)   == Int128(4, 4));
    assert(c * Int128(100, 2) == Int128(610, 12));
    assert(c / Int128(3, 2)   == Int128(0, 1));
    assert(c % Int128(3, 2)   == Int128(2, 4));
    assert((c & Int128(3, 2)) == Int128(1, 2));
    assert((c | Int128(3, 2)) == Int128(7, 6));
    assert((c ^ Int128(3, 2)) == Int128(6, 4));

    assert(c + 15   == Int128(5, 21));
    assert(c - 15   == Int128(4, -9));
    assert(c * 15   == Int128(75, 90));
    assert(c / 15   == Int128(0, 6148914691236517205));
    assert(c % 15   == Int128(0, 11));
    assert((c & 15) == Int128(0, 6));
    assert((c | 15) == Int128(5, 15));
    assert((c ^ 15) == Int128(5, 9));

    assert(15 + c   == Int128(5, 21));
    assert(15 - c   == Int128(-5, 9));
    assert(15 * c   == Int128(75, 90));
    assert(15 / c   == Int128(0, 0));
    assert(15 % c   == Int128(0, 15));
    assert((15 & c) == Int128(0, 6));
    assert((15 | c) == Int128(5, 15));
    assert((15 ^ c) == Int128(5, 9));

    assert(c << 1 == Int128(10, 12));
    assert(-c >> 1 == Int128(-3, 9223372036854775805));
    assert(-c >>> 1 == Int128(9223372036854775805, 9223372036854775805));

    assert((c += 1) == Int128(5, 7));
    assert((c -= 1) == Int128(5, 6));
    assert((c += Int128(0, 1)) == Int128(5, 7));
    assert((c -= Int128(0, 1)) == Int128(5, 6));
    assert((c *= 2) == Int128(10, 12));
    assert((c /= 2) == Int128(5, 6));
    assert((c %= 2) == Int128());
    c += Int128(5, 6);
    assert((c *= Int128(10, 20)) == Int128(160, 120));
    assert((c /= Int128(10, 20)) == Int128(0, 15));
    c += Int128(72, 0);
    assert((c %= Int128(10, 20)) == Int128(1, -125));
    assert((c &= Int128(3, 20)) == Int128(1, 0));
    assert((c |= Int128(8, 2)) == Int128(9, 2));
    assert((c ^= Int128(8, 2)) == Int128(1, 0));
    c |= Int128(10, 5);
    assert((c <<= 1) == Int128(11 * 2, 5 * 2));
    assert((c >>>= 1) == Int128(11, 5));
    c = Int128(long.min, long.min);
    assert((c >>= 1) == Int128(long.min >> 1, cast(ulong) long.min >> 1));

    assert(-Int128.min == Int128.min);
    assert(Int128.max + 1 == Int128.min);

    c = Int128(5, 6);
    assert(c < Int128(6, 5));
    assert(c > 10);

    c = Int128(-1UL);
    assert(c == -1UL);
    c = Int128(-1L);
    assert(c == -1L);
}
