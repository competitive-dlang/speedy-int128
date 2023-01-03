// These are just some cherry picked functions from 'core.int128', which
// are necessary when the inline LLVM IR from 'speedy.int128_ldc' fails to
// link on 32-bit platforms. For example, '__umodti3' is missing.

/* 128 bit integer arithmetic.
 *
 * Not optimized for speed.
 *
 * Copyright: Copyright D Language Foundation 2022.
 * License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
 * Authors:   Walter Bright
 * Source:    $(DRUNTIMESRC core/_int128.d)
 */

module speedy.int128_ldc_32bit_fallback;

nothrow:
@safe:
@nogc:

version (LDC) {
import speedy.int128_ldc;

enum Cent Zero = { lo:0 };

/****************************
 * Unsigned divide c1 / c2.
 * Params:
 *      c1 = dividend
 *      c2 = divisor
 * Returns:
 *      quotient c1 / c2
 */
pure
Cent udiv(Cent c1, Cent c2)
{
    Cent modulus;
    return udivmod(c1, c2, modulus);
}

/****************************
 * Unsigned divide c1 / c2. The remainder after division is stored to modulus.
 * Params:
 *      c1 = dividend
 *      c2 = divisor
 *      modulus = set to c1 % c2
 * Returns:
 *      quotient c1 / c2
 */
pure
Cent udivmod(Cent c1, Cent c2, out Cent modulus)
{
    //printf("udiv c1(%llx,%llx) c2(%llx,%llx)\n", c1.lo, c1.hi, c2.lo, c2.hi);
    // Based on "Unsigned Doubleword Division" in Hacker's Delight
    import core.bitop;

    // Divides a 128-bit dividend by a 64-bit divisor.
    // The result must fit in 64 bits.
    static U udivmod128_64(Cent c1, U c2, out U modulus)
    {
        // We work in base 2^^32
        enum base = 1UL << 32;
        enum divmask = (1UL << (Ubits / 2)) - 1;
        enum divshift = Ubits / 2;

        // Check for overflow and divide by 0
        if (c1.hi >= c2)
        {
            modulus = 0UL;
            return ~0UL;
        }

        // Computes [num1 num0] / den
        static uint udiv96_64(U num1, uint num0, U den)
        {
            // Extract both digits of the denominator
            const den1 = cast(uint)(den >> divshift);
            const den0 = cast(uint)(den & divmask);
            // Estimate ret as num1 / den1, and then correct it
            U ret = num1 / den1;
            const t2 = (num1 % den1) * base + num0;
            const t1 = ret * den0;
            if (t1 > t2)
                ret -= (t1 - t2 > den) ? 2 : 1;
            return cast(uint)ret;
        }

        // Determine the normalization factor. We multiply c2 by this, so that its leading
        // digit is at least half base. In binary this means just shifting left by the number
        // of leading zeros, so that there's a 1 in the MSB.
        // We also shift number by the same amount. This cannot overflow because c1.hi < c2.
        const shift = (Ubits - 1) - bsr(c2);
        c2 <<= shift;
        U num2 = c1.hi;
        num2 <<= shift;
        num2 |= (c1.lo >> (-shift & 63)) & (-cast(I)shift >> 63);
        c1.lo <<= shift;

        // Extract the low digits of the numerator (after normalizing)
        const num1 = cast(uint)(c1.lo >> divshift);
        const num0 = cast(uint)(c1.lo & divmask);

        // Compute q1 = [num2 num1] / c2
        const q1 = udiv96_64(num2, num1, c2);
        // Compute the true (partial) remainder
        const rem = num2 * base + num1 - q1 * c2;
        // Compute q0 = [rem num0] / c2
        const q0 = udiv96_64(rem, num0, c2);

        modulus = (rem * base + num0 - q0 * c2) >> shift;
        return (cast(U)q1 << divshift) | q0;
    }

    // Special cases
    if (!tst(c2))
    {
        // Divide by zero
        modulus = Zero;
        return com(modulus);
    }
    if (c1.hi == 0 && c2.hi == 0)
    {
        // Single precision divide
        const Cent rem = { lo:c1.lo % c2.lo };
        modulus = rem;
        const Cent ret = { lo:c1.lo / c2.lo };
        return ret;
    }
    if (c1.hi == 0)
    {
        // Numerator is smaller than the divisor
        modulus = c1;
        return Zero;
    }
    if (c2.hi == 0)
    {
        // Divisor is a 64-bit value, so we just need one 128/64 division.
        // If c1 / c2 would overflow, break c1 up into two halves.
        const q1 = (c1.hi < c2.lo) ? 0 : (c1.hi / c2.lo);
        if (q1)
            c1.hi = c1.hi % c2.lo;
        Cent rem;
        const q0 = udivmod128_64(c1, c2.lo, rem.lo);
        modulus = rem;
        const Cent ret = { lo:q0, hi:q1 };
        return ret;
    }

    // Full cent precision division.
    // Here c2 >= 2^^64
    // We know that c2.hi != 0, so count leading zeros is OK
    // We have 0 <= shift <= 63
    const shift = (Ubits - 1) - bsr(c2.hi);

    // Normalize the divisor so its MSB is 1
    // v1 = (c2 << shift) >> 64
    U v1 = shl(c2, shift).hi;

    // To ensure no overflow.
    Cent u1 = shr1(c1);

    // Get quotient from divide unsigned operation.
    U rem_ignored;
    const Cent q1 = { lo:udivmod128_64(u1, v1, rem_ignored) };

    // Undo normalization and division of c1 by 2.
    Cent quotient = shr(shl(q1, shift), 63);

    // Make quotient correct or too small by 1
    if (tst(quotient))
        quotient = dec(quotient);

    // Now quotient is correct.
    // Compute rem = c1 - (quotient * c2);
    Cent rem = sub(c1, mul(quotient, c2));

    // Check if remainder is larger than the divisor
    if (uge(rem, c2))
    {
        // Increment quotient
        quotient = inc(quotient);
        // Subtract c2 from remainder
        rem = sub(rem, c2);
    }
    modulus = rem;
    //printf("quotient "); print(quotient);
    //printf("modulus  "); print(modulus);
    return quotient;
}


/****************************
 * Signed divide c1 / c2.
 * Params:
 *      c1 = dividend
 *      c2 = divisor
 * Returns:
 *      quotient c1 / c2
 */
pure
Cent div(Cent c1, Cent c2)
{
    Cent modulus;
    return divmod(c1, c2, modulus);
}

/****************************
 * Signed divide c1 / c2. The remainder after division is stored to modulus.
 * Params:
 *      c1 = dividend
 *      c2 = divisor
 *      modulus = set to c1 % c2
 * Returns:
 *      quotient c1 / c2
 */
pure
Cent divmod(Cent c1, Cent c2, out Cent modulus)
{
    /* Muck about with the signs so we can use the unsigned divide
     */
    if (cast(I)c1.hi < 0)
    {
        if (cast(I)c2.hi < 0)
        {
            Cent r = udivmod(neg(c1), neg(c2), modulus);
            modulus = neg(modulus);
            return r;
        }
        Cent r = neg(udivmod(neg(c1), c2, modulus));
        modulus = neg(modulus);
        return r;
    }
    else if (cast(I)c2.hi < 0)
    {
        return neg(udivmod(c1, neg(c2), modulus));
    }
    else
        return udivmod(c1, c2, modulus);
}

} // version (LDC)
