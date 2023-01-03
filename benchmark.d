/*
 * A simple benchmark based on a fast 64-bit primes checker from
 * https://www.mersenneforum.org/showpost.php?p=259040&postcount=8
 */

const REPEATS = 1000000;

/*
Copyright 2011 Jim Sinclair

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. 
*/

import std.stdio, std.stdint;
import std.int128;

const HASHSIZE   = 2048;
const MASK       = (HASHSIZE-1);
const MULTIPLIER = 3141592653589793239UL;
const SHIFT      = 42;

int[HASHSIZE] SPRPlookup = [
  99,447,426,34,7,423,89,61,834,563,421,459,215,1415,778,259,541,403,1302,
  383,381,35,55,166,1407,79,638,161,166,551,2003,89,461,1574,206,2051,553,
  579,1295,2551,971,199,4375,241,171,311,715,370,257,3214,386,873,7721,155,
  146,566,149,41,223,2410,406,91,5055,431,413,2529,3113,327,253,822,1022,
  1723,113,558,557,86,539,581,5373,881,89,553,766,534,2063,874,321,171,118,
  1039,633,153,38,3881,1441,97,85,2933,119,17527,181,965,446,174,495,43,
  1370,482,1689,1405,1715,227,455,683,235,5078,286,2887,103,299,401,513,517,
  657,71,705,61,149,106,606,754,38,2265,51,494,335,166,105,1427,622,23,
  1979,1695,94,4966,1347,411,253,1518,9147,487,5633,94,15213,1307,1959,141,
  523,87,389,539,695,233,103,769,674,1691,823,219,1045,2639,137,2203,3643,
  1743,165,1969,701,713,723,279,1469,333,123,558,1231,746,521,177,257,386,
  3115,19625,749,997,419,1238,569,3397,197,865,69,470,3739,258,110,61,218,
  579,167,823,403,899,890,489,133,301,470,921,142,99,253,1443,122,57,1449,
  559,1879,1821,62,3303,1019,227,1941,1771,682,419,399,905,206,59,205,575,
  73,97,279,566,263,11701,43,87,218,1970,2411,617,1187,41,627,1362,313,266,
  1238,79,1153,229,145,239,74,438,2417,203,551,35,930,114,1359,1611,1019,
  967,614,1313,262,415,827,33,74,295,105,386,146,301,967,547,139,1603,58,
  485,19,1431,619,1730,1349,249,859,611,43,818,349,291,38,513,509,190,1691,
  237,1239,122,1907,651,89,447,2917,1579,2913,1285,3335,5897,505,67,1066,
  1977,10543,331,183,14,301,177,29,347,118,259,1078,1637,2599,437,1447,393,
  323,215,393,582,229,165,109,641,382,62,365,306,907,949,142,482,1513,29,
  2114,301,77,297,38,8647,211,119,274,199,894,339,553,42,31,542,95,213,
  659,153,51187,183,771,23,354,129,745,831,37,833,207,863,577,179,29,443,
  118,746,99,695,579,31,109,46,238,303,3199,957,1879,1727,37,29,86,1349,
  47,17,949,109,313,55,561,3378,5269,1549,374,274,966,127,93,1041,7,2153,
  4871,4199,553,699,293,849,47,178,194,778,445,353,51,307,53,134,426,1289,
  219,131,2718,273,901,83,227,1390,906,2459,301,616,447,94,33,1675,17,213,
  859,389,329,525,249,1393,209,4899,207,7,1345,326,285,57,3226,874,41,2609,
  3599,1497,635,1571,173,982,457,21,43,1685,177,278,2347,549,403,1761,103,
  354,67,99,2689,329,258,2810,66,706,19,41,1419,703,745,309,359,61,871,
  370,23,79,138,63,479,231,967,87,53,5359,1793,2010,229,199,2386,222,437,
  397,143,483,431,646,102,415,523,91,29,69,62,759,2355,259,347,141,41,342,
  119,87,61,61,299,145,354,255,267,157,693,655,761,813,370,197,1091,4181,
  2921,1665,257,261,575,86,1477,319,611,110,253,606,391,6777,417,34,123,
  1179,393,158,517,159,483,367,703,675,211,183,1951,347,854,53,827,119,91,
  547,1951,157,745,141,1651,805,151,501,2573,1507,206,545,186,71,4177,537,
  814,714,293,342,302,687,110,383,1854,1435,1122,793,1109,1837,329,371,74,
  3221,163,409,947,645,382,69,1995,2830,3702,354,299,173,251,209,47,191,
  3646,97,171,33,697,102,1095,207,307,1462,1153,1099,461,71,322,246,57,
  1478,349,230,581,739,319,222,277,201,218,331,391,1669,286,193,146,318,83,
  342,14,1497,19,478,387,1959,114,2342,339,53,1127,109,203,119,109,203,217,
  778,1161,1153,581,106,954,315,17,401,258,155,1785,3637,138,1727,157,633,
  205,189,925,74,261,387,19,218,330,2129,493,609,101,154,321,187,1982,583,
  301,107,823,201,1349,874,193,533,290,1010,151,122,358,1906,313,197,457,
  951,403,1361,523,113,909,229,118,241,583,689,46,355,99,209,19,14,942,
  267,1414,631,998,187,319,957,203,2005,2485,537,57,143,1303,829,409,9485,
  202,1185,857,17,1317,73,183,266,321,141,1113,1317,91,615,617,4003,1775,
  791,629,1926,1973,653,454,201,881,141,433,69,55,414,155,1142,1071,109,
  3545,589,2411,673,762,2426,2218,762,387,954,1421,337,138,86,3395,2821,159,
  109,365,1535,803,138,551,2299,635,71,206,329,851,1277,745,1055,899,1118,
  917,890,41,57,2901,422,271,119,4402,1131,1121,346,59,293,857,11,991,143,
  94,171,1730,471,914,217,1362,539,147,109,421,891,2667,639,393,313,145,
  855,335,435,2465,510,479,297,3206,23,1766,446,622,41,2238,82,1137,781,
  4167,391,838,1045,633,29,1463,209,2013,419,281,3243,185,618,91,154,930,
  153,79,69,1473,113,383,1334,4190,566,165,5090,133,258,567,118,57,185,825,
  2543,201,799,563,407,227,2559,501,205,1035,669,814,1026,265,11,327,119,
  2373,4333,751,333,67,235,1074,129,3763,597,1037,331,1978,1198,151,254,
  1079,309,1723,2438,177,41,719,1603,829,134,399,2467,663,107,551,3738,206,
  758,438,285,19,453,1035,233,118,1374,119,698,295,265,1027,3973,313,510,
  3846,1669,1602,287,9051,83,2098,83,201,1559,1205,467,1526,62,2717,2369,
  902,33,301,453,255,89,257,543,1335,895,487,141,621,103,3318,583,187,141,
  273,37,766,233,143,833,7,237,333,2713,535,37,382,737,327,717,2722,1309,
  181,1105,1459,255,3914,721,1057,101,1266,17,4087,143,113,105,971,1117,221,
  2109,811,255,481,3862,537,31,781,374,271,1630,358,1209,5307,91,1898,193,
  1285,1378,587,1154,801,893,146,73,5294,3111,83,3530,1285,21,55,165,87,
  395,805,53,133,205,119,879,199,61,151,167,71,562,2415,157,89,275,399,
  293,14,1465,111,297,155,919,7599,423,151,131,106,149,221,1313,257,279,
  549,287,10310,35,31,993,4854,182,85,2095,262,151,1398,263,3779,29,141,74,
  515,541,430,59,311,263,6746,1159,1613,1699,909,395,2837,550,1417,138,55,
  149,306,6086,287,11,287,590,1306,278,62,115,122,3687,997,718,4765,14,
  1021,2839,501,231,945,2127,437,878,323,1007,617,461,155,262,127,387,87,
  391,182,4437,297,185,341,14,2259,805,141,511,31,111,847,767,1159,1359,
  4567,139,393,199,77,4034,587,1506,279,3990,371,37,1138,295,73,831,1195,
  99,394,377,1147,489,1966,199,73,6757,146,766,379,389,586,639,2169,2341,
  161,221,739,97,371,1419,629,1051,279,5146,2081,55,178,267,434,97,929,371,
  29,1141,646,582,101,433,1199,111,202,1955,301,137,995,53,395,7471,373,
  279,1965,1197,326,131,173,2078,1817,161,55,690,1810,259,445,1166,193,53,
  73,1106,374,513,82,198,2318,142,822,511,2057,102,417,23,337,781,73,753,
  105,2173,917,1011,793,2005,1211,134,2011,1007,949,157,141,171,101,1850,
  3561,421,122,153,1967,277,2113,295,197,1947,1174,31,167,1549,646,93,1181,
  2710,1279,247,179,1442,1149,173,69,189,646,97,2659,1001,1373,1446,3542,
  811,1166,1387,493,171,409,282,298,19,1393,2137,1361,3793,51,2127,1047,
  2121,1909,953,645,437,57,183,545,342,2438,1865,759,11,165,387,429,826,
  1177,73,1011,142,2045,1143,607,685,299,1343,1158,1661,579,151,69,983,87,
  1257,151,983,298,319,497,93,526,74,67,943,365,601,221,77,181,691,1490,
  489,201,921,942,703,71,99,179,69,303,2954,495,777,17905,127,330,1186,194,
  101,873,359,799,190,1226,307,3217,6599,733,149,1231,51,777,1106,191,190,
  1873,7,6566,366,174,174,57,141,139,37,87,167,290,2602,58,2095,473,37,
  835,14029,1503,127,163,329,231,3713,339,131,534,253,797,497,59,1105,2309,
  1919,1033,713,171,6287,383,543,23,1427,155,471,207,305,149,221,329,91,
  654,47,871,23,393,47,71,873,91,43,23,431,31,1149,173,1118,138,89,1077,
  3181,1465,93,53,79,1025,1531,141,4174,298,901,1157,409,223,615,963,158,
  313,322,1306,214,459,711,689,253,822,170,211,406,1066,17,211,29,373,263,
  299,226,85,173,443,3239,277,449,261,134,67,394,1759,1585,1267,110,66,
  1098,1117,70,261,817,843,145,817,1043,1749,190,583,21,1057,307,291,786,
  251,349,1189,227,547,958,447,190,2045,943,1561,438,267,1046,101,1475,407,
  618,95,222,142,47,207,6542,579,459,85,2927,457,447,1054,229,215,423,322,
  61,930,4427,3533,158,213,171,395,427,337,67,295,1031,2633,2765,130,1635,
  2861,239,847,309,1461,143,354,1079,926,4813,309,654,809,122,1121,430,1469,
  2198,2893,41,2674,1771,1119,487,553,511,370,981,1206,42,373,205,3377,4809,
  461,167,679,711,145,193,1043,222,322,149,547,179,2451,365,111,1665,67,
  1249,138,485,79,205,249,2097,331,159,313,159,433,470,2643,3725,43,1075,
  773,919,11,1202,731,17,113,123,161,77,809,1177,321,118,309,549,5437,107,
  721,89,5479,807,59,427,555,783,401,133,1595,1121,1618,67,223,183,838,67,
  407,806,822,465,386,873,113,19,473,661,161,311,402,914,74,451,449,71,
  247,1133,127,11,1721,946,183,138,6687,2649,59,451,793,21,12102,667,550,
  101,323,565,969,2286,821,659,298,210,21,131,949,3930,102,190,430,1865,
  483,167,433,8675,119,163,511,251,479,941,467,1265,123,2294,571,389,2318,
  241,1207,201,37,155,837,1467,71,2969,397,1843,431,4334,1818,77,71,303,87,
  283,89,82,2417,321,209,409,619,1626,1615,47,271,151,59,53,1531,953,347,
  151,499,2774,471,199,919,1203,531,378,423,1774,291,114,1154,1386,115,1343,
  29,63,93,79,4237,787,497,5021,590,14,601,47,402,254,7,1195,3227,55,4502,
  299,1027,1455,83,2111,153,4491,3203,17,109,41,165,258,593,229,261,617,
  353,149,597,406,23,1417,333,226,317,2509,1041,74,421,521,2481,1507,893,
  271,22,2941,302,365,1819,449,438,665,563,290,89,409,1194,971,1143,207,62,
  158,1157,647,91,215,393,163,397,1025,422,137,449,278,93,23,71,1667,17,
  265,1834,201,3225,603,401,3231,954,615,127,293,419,1173,319,210,173,623,
  67,474,218,885,977,1775,77,421,258,769,1590,2746,1033,43,123
];

uint64_t mulmod(uint64_t a, uint64_t b, uint64_t c)
{
  return (Int128(a) * b % c).data.lo;
}

uint64_t powmod(uint64_t i, uint64_t j, uint64_t k){
  uint64_t r = 1;
  while(j > 0){
    if(j&1)
      r=mulmod(r,i,k);
    i=mulmod(i,i,k);
    j>>=1;
  }
  return r;
}

int miller_rabin(uint64_t n, int[4] bases, int len) {
  int i, r, s=0;
  uint64_t d=n-1;
  while (0==(d&1)) {
    ++s; d>>=1;
  }
  for(i = 0; i < len; i++){
    int a = bases[i];
    uint64_t x = powmod(a,d,n);
    if (x==1 || x==n-1)
      continue;
    for (r=0; r<s; r++) {
      x = mulmod(x,x,n);
      if (x==1)
        return 0;
      else if (x==n-1){
        a = 0;
        break;
      }
    }
    if(a)
      return 0;
  }
  return 1;
}

int isPrime64Bit(uint64_t n){
  int[4] bases;
  bases[0] = 2;
  bases[1] = 325;
  bases[2] = 9375;
  bases[3] = SPRPlookup[cast(int)(((n*MULTIPLIER)>>SHIFT)&MASK)];

  if (n == 2 || n == 3 || n == 5 || n == 13)
    return 1;
  else if (n < 5 || (n & 1) == 0)
    return 0;
  else
    return miller_rabin(n, bases, 4);
}

// https://lemire.me/blog/2019/03/19/the-fastest-conventional-random-number-generator-that-can-pass-big-crush/
uint64_t lehmer64() {
  static Int128 g_lehmer64_state = Int128(1L);
  g_lehmer64_state *= 0xda942042e4dd58b5;
  return g_lehmer64_state.data.hi;
}

int main() {
  int primes_cnt = 0;
  for (int i = 0; i < REPEATS; i++) {
    uint64_t n = lehmer64() & ((1UL << 63) - 1);
    if (isPrime64Bit(n))
      primes_cnt++;
  }
  printf("Found %d primes.\n", primes_cnt);
  return 0;
}
