/* lzo1x_c.ch -- implementation of the LZO1[XY]-1 compression algorithm

   This file is part of the LZO real-time data compression library.

   Copyright (C) 2005 Markus Franz Xaver Johannes Oberhumer
   Copyright (C) 2004 Markus Franz Xaver Johannes Oberhumer
   Copyright (C) 2003 Markus Franz Xaver Johannes Oberhumer
   Copyright (C) 2002 Markus Franz Xaver Johannes Oberhumer
   Copyright (C) 2001 Markus Franz Xaver Johannes Oberhumer
   Copyright (C) 2000 Markus Franz Xaver Johannes Oberhumer
   Copyright (C) 1999 Markus Franz Xaver Johannes Oberhumer
   Copyright (C) 1998 Markus Franz Xaver Johannes Oberhumer
   Copyright (C) 1997 Markus Franz Xaver Johannes Oberhumer
   Copyright (C) 1996 Markus Franz Xaver Johannes Oberhumer
   All Rights Reserved.

   The LZO library is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License,
   version 2, as published by the Free Software Foundation.

   The LZO library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with the LZO library; see the file COPYING.
   If not, write to the Free Software Foundation, Inc.,
   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

   Markus F.X.J. Oberhumer
   <markus@oberhumer.com>
   http://www.oberhumer.com/opensource/lzo/
 */



/***********************************************************************
// compress a block of data.
************************************************************************/

static __lzo_noinline lzo_uint
do_compress ( const lzo_bytep in , lzo_uint  in_len,
                    lzo_bytep out, lzo_uintp out_len,
                    lzo_voidp wrkmem )
{
    const lzo_bytep ip;
    lzo_bytep op;
    const lzo_bytep const in_end = in + in_len;
    const lzo_bytep const ip_end = in + in_len - M2_MAX_LEN - 5;
    const lzo_bytep ii;
    lzo_dict_p const dict = (lzo_dict_p) wrkmem;

    op = out;
    ip = in;
    ii = ip;

    ip += 4;
    for (;;)
    {
         const lzo_bytep m_pos;
        lzo_uint m_off;
        lzo_uint m_len;
        lzo_uint dindex;

        DINDEX1(dindex,ip);
        GINDEX(m_pos,m_off,dict,dindex,in);
        if (LZO_CHECK_MPOS_NON_DET(m_pos,m_off,in,ip,M4_MAX_OFFSET))
            goto literal;
#if 1
        if (m_off <= M2_MAX_OFFSET || m_pos[3] == ip[3])
            goto try_match;
        DINDEX2(dindex,ip);
#endif
        GINDEX(m_pos,m_off,dict,dindex,in);
        if (LZO_CHECK_MPOS_NON_DET(m_pos,m_off,in,ip,M4_MAX_OFFSET))
            goto literal;
        if (m_off <= M2_MAX_OFFSET || m_pos[3] == ip[3])
            goto try_match;
        goto literal;


try_match:
#if 1 && defined(LZO_UNALIGNED_OK_2)
        if (* (const lzo_ushortp) m_pos != * (const lzo_ushortp) ip)
#else
        if (m_pos[0] != ip[0] || m_pos[1] != ip[1])
#endif
        {
        }
        else
        {
            if __lzo_likely(m_pos[2] == ip[2])
            {
#if 0
                if (m_off <= M2_MAX_OFFSET)
                    goto match;
                if (lit <= 3)
                    goto match;
                if (lit == 3)           /* better compression, but slower */
                {
                    assert(op - 2 > out); op[-2] |= LZO_BYTE(3);
                    *op++ = *ii++; *op++ = *ii++; *op++ = *ii++;
                    goto code_match;
                }
                if (m_pos[3] == ip[3])
#endif
                    goto match;
            }
            else
            {
                /* still need a better way for finding M1 matches */
#if 0
                /* a M1 match */
#if 0
                if (m_off <= M1_MAX_OFFSET && lit > 0 && lit <= 3)
#else
                if (m_off <= M1_MAX_OFFSET && lit == 3)
#endif
                {
                     lzo_uint t;

                    t = lit;
                    assert(op - 2 > out); op[-2] |= LZO_BYTE(t);
                    do *op++ = *ii++; while (--t > 0);
                    assert(ii == ip);
                    m_off -= 1;
                    *op++ = LZO_BYTE(M1_MARKER | ((m_off & 3) << 2));
                    *op++ = LZO_BYTE(m_off >> 2);
                    ip += 2;
                    goto match_done;
                }
#endif
            }
        }


    /* a literal */
literal:
        UPDATE_I(dict,0,dindex,ip,in);
        ++ip;
        if __lzo_unlikely(ip >= ip_end)
            break;
        continue;


    /* a match */
match:
        UPDATE_I(dict,0,dindex,ip,in);
        /* store current literal run */
        if (pd(ip,ii) > 0)
        {
             lzo_uint t = pd(ip,ii);

            if (t <= 3)
            {
                assert(op - 2 > out);
                op[-2] |= LZO_BYTE(t);
            }
            else if (t <= 18)
                *op++ = LZO_BYTE(t - 3);
            else
            {
                 lzo_uint tt = t - 18;

                *op++ = 0;
                while (tt > 255)
                {
                    tt -= 255;
                    *op++ = 0;
                }
                assert(tt > 0);
                *op++ = LZO_BYTE(tt);
            }
            do *op++ = *ii++; while (--t > 0);
        }

        /* code the match */
        assert(ii == ip);
        ip += 3;
        if (m_pos[3] != *ip++ || m_pos[4] != *ip++ || m_pos[5] != *ip++ ||
            m_pos[6] != *ip++ || m_pos[7] != *ip++ || m_pos[8] != *ip++
#ifdef LZO1Y
            || m_pos[ 9] != *ip++ || m_pos[10] != *ip++ || m_pos[11] != *ip++
            || m_pos[12] != *ip++ || m_pos[13] != *ip++ || m_pos[14] != *ip++
#endif
           )
        {
            --ip;
            m_len = pd(ip, ii);
            assert(m_len >= 3); assert(m_len <= M2_MAX_LEN);

            if (m_off <= M2_MAX_OFFSET)
            {
                m_off -= 1;
#if defined(LZO1X)
                *op++ = LZO_BYTE(((m_len - 1) << 5) | ((m_off & 7) << 2));
                *op++ = LZO_BYTE(m_off >> 3);
#elif defined(LZO1Y)
                *op++ = LZO_BYTE(((m_len + 1) << 4) | ((m_off & 3) << 2));
                *op++ = LZO_BYTE(m_off >> 2);
#endif
            }
            else if (m_off <= M3_MAX_OFFSET)
            {
                m_off -= 1;
                *op++ = LZO_BYTE(M3_MARKER | (m_len - 2));
                goto m3_m4_offset;
            }
            else
#if defined(LZO1X)
            {
                m_off -= 0x4000;
                assert(m_off > 0); assert(m_off <= 0x7fff);
                *op++ = LZO_BYTE(M4_MARKER |
                                 ((m_off & 0x4000) >> 11) | (m_len - 2));
                goto m3_m4_offset;
            }
#elif defined(LZO1Y)
                goto m4_match;
#endif
        }
        else
        {
            {
                const lzo_bytep end = in_end;
                const lzo_bytep m = m_pos + M2_MAX_LEN + 1;
                while (ip < end && *m == *ip)
                    m++, ip++;
                m_len = pd(ip, ii);
            }
            assert(m_len > M2_MAX_LEN);

            if (m_off <= M3_MAX_OFFSET)
            {
                m_off -= 1;
                if (m_len <= 33)
                    *op++ = LZO_BYTE(M3_MARKER | (m_len - 2));
                else
                {
                    m_len -= 33;
                    *op++ = M3_MARKER | 0;
                    goto m3_m4_len;
                }
            }
            else
            {
#if defined(LZO1Y)
m4_match:
#endif
                m_off -= 0x4000;
                assert(m_off > 0); assert(m_off <= 0x7fff);
                if (m_len <= M4_MAX_LEN)
                    *op++ = LZO_BYTE(M4_MARKER |
                                     ((m_off & 0x4000) >> 11) | (m_len - 2));
                else
                {
                    m_len -= M4_MAX_LEN;
                    *op++ = LZO_BYTE(M4_MARKER | ((m_off & 0x4000) >> 11));
m3_m4_len:
                    while (m_len > 255)
                    {
                        m_len -= 255;
                        *op++ = 0;
                    }
                    assert(m_len > 0);
                    *op++ = LZO_BYTE(m_len);
                }
            }

m3_m4_offset:
            *op++ = LZO_BYTE((m_off & 63) << 2);
            *op++ = LZO_BYTE(m_off >> 6);
        }

#if 0
match_done:
#endif
        ii = ip;
        if __lzo_unlikely(ip >= ip_end)
            break;
    }

    *out_len = pd(op, out);
    return pd(in_end,ii);
}


/***********************************************************************
// public entry point
************************************************************************/

LZO_PUBLIC(int)
DO_COMPRESS      ( const lzo_bytep in , lzo_uint  in_len,
                         lzo_bytep out, lzo_uintp out_len,
                         lzo_voidp wrkmem )
{
    lzo_bytep op = out;
    lzo_uint t;

    if __lzo_unlikely(in_len <= M2_MAX_LEN + 5)
        t = in_len;
    else
    {
        t = do_compress(in,in_len,op,out_len,wrkmem);
        op += *out_len;
    }

    if (t > 0)
    {
        const lzo_bytep ii = in + in_len - t;

        if (op == out && t <= 238)
            *op++ = LZO_BYTE(17 + t);
        else if (t <= 3)
            op[-2] |= LZO_BYTE(t);
        else if (t <= 18)
            *op++ = LZO_BYTE(t - 3);
        else
        {
            lzo_uint tt = t - 18;

            *op++ = 0;
            while (tt > 255)
            {
                tt -= 255;
                *op++ = 0;
            }
            assert(tt > 0);
            *op++ = LZO_BYTE(tt);
        }
        do *op++ = *ii++; while (--t > 0);
    }

    *op++ = M4_MARKER | 1;
    *op++ = 0;
    *op++ = 0;

    *out_len = pd(op, out);
    return LZO_E_OK;
}


/*
vi:ts=4:et
*/

