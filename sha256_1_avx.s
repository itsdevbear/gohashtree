#include "textflag.h"

#define OUTPUT_PTR DI
#define DATA_PTR SI
#define count DX
#define TBL CX
#define _DIGEST 32

#define RAL AX
#define RBL BX
#define RCL BP
#define RDL R8
#define REL R9
#define RFL R10
#define RGL R11
#define RHL R12

#define XTMP0 X4
#define XTMP1 X5
#define XTMP2 X6
#define XTMP3 X7
#define XTMP4 X8
#define XTMP5 X11
#define XFER X9

#define y0 R13
#define y1 R14
#define y2 R15

#define _SHUF_00BA X10
#define _SHUF_DC00 X12
#define _BYTE_FLIP_MASK X13

#define COPY_XMM_AND_BSWAP(dst,src,msk) \
	VMOVDQU		src, dst; \
	VPSHUFB		msk, dst, dst

#define FOUR_ROUNDS_AND_SCHEDA(a, b, c, d, e, f, g, h, X0_, X1_, X2_, X3_) \
	RORXL	$(25-11), e, y0; \
		VPALIGNR	$4, X2_, X3_, XTMP0; \
	RORXL	$(22-13), a, y1; \
	XORL	e, y0; \
	MOVL	f, y2; \
	RORXL	$(11-6), y0, y0; \
	XORL	a, y1; \
	XORL	g, y2; \
		VPADDD	X0_, XTMP0, XTMP0; \
	XORL	e, y0; \
	ANDL	e, y2; \
	RORXL	$(13-2), y1, y1; \ 
		VPALIGNR	$4, X0_, X1_, XTMP1; \
	XORL	a, y1; \
	RORXL	$6, y0, y0; \ 
	XORL	g, y2; \
	RORXL	$2, y1, y1; \
	ADDL	y0, y2; \
	ADDL	(0*4)(SP), y2; \
	MOVL	a, y0; \
	ADDL	y2, h; \
	MOVL	a, y2; \
		VPSRLD	$7, XTMP1, XTMP2; \
	ORL	c, y0; \
	ADDL	h, d; \
	ANDL	c, y2; \
		VPSLLD	$(32-7), XTMP1, XTMP3; \
	ANDL	b, y0; \
	ADDL	y1, h; \
		VPOR	XTMP2, XTMP3, XTMP3; \
	ORL	y2, y0; \
	ADDL	y0, h

#define FOUR_ROUNDS_AND_SCHEDB(a, b, c, d, e, f, g, h, X0_, X1_, X2_, X3_) \
	RORXL	$(25-11), e, y0; \
	RORXL	$(22-13), a, y1; \
	XORL	e, y0; \
		VPSRLD	$18, XTMP1, XTMP2; \
	MOVL	f, y2; \
	RORXL	$(11-6), y0, y0; \
	XORL	a, y1; \
	XORL	g, y2; \
		VPSRLD	$3, XTMP1, XTMP4; \
	XORL	e, y0; \
	ANDL	e, y2; \
	RORXL	$(13-2), y1, y1; \
	XORL	a, y1; \
	RORXL	$6, y0, y0; \
		VPSLLD	$(32-18), XTMP1, XTMP1; \
	XORL	g, y2; \
	RORXL	$2, y1, y1; \
		VPXOR	XTMP1, XTMP3, XTMP3; \
	ADDL	y0, y2; \
	ADDL	(1*4)(SP), y2; \
	MOVL	a, y0; \
		VPXOR	XTMP2, XTMP3, XTMP3; \
	ADDL	y2, h; \
	MOVL	a, y2; \
	ORL	c, y0; \
		VPXOR	XTMP4, XTMP3, XTMP1; \
	ADDL	h, d; \
	ANDL	c, y2; \
		VPSHUFD $0xFA, X3_, XTMP2; \
	ANDL	b, y0; \
	ADDL	y1, h; \
		VPADDD	XTMP1, XTMP0, XTMP0; \
	ORL	y2, y0; \
	ADDL	y0, h


#define FOUR_ROUNDS_AND_SCHEDC(a, b, c, d, e, f, g, h, X0_, X1_, X2_, X3_) \
	RORXL	$(25-11), e, y0; \
	RORXL	$(22-13), a, y1; \
	XORL	e, y0; \
		VPSRLD	$10, XTMP2, XTMP4; \
	MOVL	f, y2; \
	RORXL	$(11-6), y0, y0; \
	XORL	a, y1; \
		VPSRLQ	$19, XTMP2, XTMP3; \
	XORL	g, y2; \
	XORL	e, y0; \
	ANDL	e, y2; \
		VPSRLQ	$17, XTMP2, XTMP2; \
	RORXL	$(13-2), y1, y1; \
	XORL	a, y1; \
	RORXL	$6, y0, y0; \
		VPXOR	XTMP3, XTMP2, XTMP2; \
	XORL	g, y2; \
	RORXL	$2, y1, y1; \
	ADDL	y0, y2; \
		VPXOR	XTMP2, XTMP4, XTMP4; \
	ADDL	(2*4)(SP), y2; \
	MOVL	a, y0; \
	ADDL	y2, h; \
		VPSHUFB	 _SHUF_00BA, XTMP4, XTMP4; \
	MOVL	a, y2; \
	ORL	c, y0; \
	ADDL	h, d; \
		VPADDD	XTMP4, XTMP0, XTMP0; \
	ANDL	c, y2; \
	ANDL	b, y0; \
		VPSHUFD $0x50, XTMP0, XTMP2; \
	ADDL	y1, h; \
	ORL	y2, y0; \
	ADDL	y0, h

#define FOUR_ROUNDS_AND_SCHEDD(a, b, c, d, e, f, g, h, X0_, X1_, X2_, X3_) \
	RORXL	$(25-11), e, y0; \
	RORXL	$(22-13), a, y1; \
		VPSRLD	$10, XTMP2, XTMP5; \
	XORL	e, y0; \
	MOVL	f, y2; \
	RORXL	$(11-6), y0, y0; \
		VPSRLQ  $19, XTMP2, XTMP3; \
	XORL	a, y1; \
	XORL	g, y2; \
	XORL	e, y0; \
		VPSRLQ $17, XTMP2, XTMP2; \
	ANDL	e, y2; \
	RORXL	$(13-2), y1, y1; \
	XORL	a, y1; \
		VPXOR	XTMP3, XTMP2, XTMP2; \
	RORXL	$6, y0, y0; \
	XORL	g, y2; \
	RORXL	$2, y1, y1; \
		VPXOR	XTMP2, XTMP5, XTMP5; \
	ADDL	y0, y2; \
	ADDL	(3*4)(SP), y2; \
	MOVL	a, y0; \
	ADDL	y2, h; \
	MOVL	a, y2; \
		VPSHUFB	 _SHUF_DC00, XTMP5, XTMP5; \
	ORL	c, y0; \
	ADDL	h, d; \
	ANDL	c, y2; \
		VPADDD	XTMP0, XTMP5, X0_; \
	ANDL	b, y0; \
	ADDL	y1, h; \
	ORL	y2, y0; \
	ADDL	y0, h

#define FOUR_ROUNDS_AND_SCHED(a, b, c, d, e, f, g, h, X0_, X1_, X2_, X3_) \
	FOUR_ROUNDS_AND_SCHEDA(a, b, c, d, e, f, g, h, X0_, X1_, X2_, X3_); \
	FOUR_ROUNDS_AND_SCHEDB(h, a, b, c, d, e, f, g, X0_, X1_, X2_, X3_); \
	FOUR_ROUNDS_AND_SCHEDC(g, h, a, b, c, d, e, f, X0_, X1_, X2_, X3_); \
	FOUR_ROUNDS_AND_SCHEDD(f, g, h, a, b, c, d, e, X0_, X1_, X2_, X3_)

#define DO_ROUND(base, offset, a, b, c, d, e, f, g, h) \
	RORXL	$(25-11), e, y0; \
	RORXL	$(22-13), a, y1; \
	XORL	e, y0; \
	MOVL	f, y2; \
	RORXL	$(11-6), y0, y0; \
	XORL	a, y1; \
	XORL	g, y2; \
	XORL	e, y0; \
	ANDL	e, y2; \
	RORXL	$(13-2), y1, y1; \
	XORL	a, y1; \
	RORXL	$6, y0, y0; \
	XORL	g, y2; \
	RORXL	$2, y1, y1; \
	ADDL	y0, y2; \
	ADDL	(offset)(base), y2; \
	MOVL	a, y0; \
	ADDL	y2, h; \
	MOVL	a, y2; \
	ORL	c, y0; \
	ADDL	h, d; \
	ANDL	c, y2; \
	ANDL	b, y0; \
	ADDL	y1, h; \
	ORL	y2, y0; \
	ADDL	y0, h

TEXT ·sha256_1_avx(SB), 0, $104-40
	VMOVDQU		PSHUFFLE_BYTE_FLIP_MASK<>(SB), _BYTE_FLIP_MASK
	VMOVDQU 	PSHUF_00BA<>(SB), _SHUF_00BA
	VMOVDQU		PSHUF_DC00<>(SB), _SHUF_DC00 

	MOVQ digests+0(FP), OUTPUT_PTR // digests *[][32]byte
	MOVQ p_base+8(FP), DATA_PTR  // p [][32]byte
	MOVQ num_blocks+32(FP), count  // count uint32

        SHLQ         $5, count
        ADDQ         OUTPUT_PTR, count

sha256_avx_1_loop:
        CMPQ     OUTPUT_PTR, count
        JEQ      sha256_1_avx_epilog

	// load initial digest
	MOVL $0x6A09E667, RAL  // a = H0
	MOVL $0xBB67AE85, RBL  // b = H1
	MOVL $0x3C6EF372, RCL // c = H2
	MOVL $0xA54FF53A, RDL // d = H3
	MOVL $0x510E527F, REL // e = H4
	MOVL $0x9B05688C, RFL // f = H5
	MOVL $0x1F83D9AB, RGL // g = H6
	MOVL $0x5BE0CD19, RHL // h = H7

	MOVQ	$K256<>(SB), TBL

	// byte swap first 16 dwords
	COPY_XMM_AND_BSWAP(X0, 0*16(DATA_PTR), _BYTE_FLIP_MASK)
	COPY_XMM_AND_BSWAP(X1, 1*16(DATA_PTR), _BYTE_FLIP_MASK)
	COPY_XMM_AND_BSWAP(X2, 2*16(DATA_PTR), _BYTE_FLIP_MASK)
	COPY_XMM_AND_BSWAP(X3, 3*16(DATA_PTR), _BYTE_FLIP_MASK)

	// schedule 48 input dwords, by doing 3 rounds of 16 each
	VPADDD	0*16(TBL), X0, XFER
	VMOVDQU	XFER, (SP)
	FOUR_ROUNDS_AND_SCHED(RAL, RBL, RCL, RDL, REL, RFL, RGL, RHL, X0, X1, X2, X3)

	VPADDD	1*16(TBL), X1, XFER
	VMOVDQU	XFER, (SP)
	FOUR_ROUNDS_AND_SCHED(REL, RFL, RGL, RHL, RAL, RBL, RCL, RDL, X1, X2, X3, X0)

	VPADDD	2*16(TBL), X2, XFER
	VMOVDQU	XFER, (SP)
	FOUR_ROUNDS_AND_SCHED(RAL, RBL, RCL, RDL, REL, RFL, RGL, RHL, X2, X3, X0, X1)

	VPADDD	3*16(TBL), X3, XFER
	VMOVDQU	XFER, (SP)
	ADDQ	$(4*16), TBL
	FOUR_ROUNDS_AND_SCHED(REL, RFL, RGL, RHL, RAL, RBL, RCL, RDL, X3, X0, X1, X2)
	
	VPADDD	0*16(TBL), X0, XFER
	VMOVDQU	XFER, (SP)
	FOUR_ROUNDS_AND_SCHED(RAL, RBL, RCL, RDL, REL, RFL, RGL, RHL, X0, X1, X2, X3)

	VPADDD	1*16(TBL), X1, XFER
	VMOVDQU	XFER, (SP)
	FOUR_ROUNDS_AND_SCHED(REL, RFL, RGL, RHL, RAL, RBL, RCL, RDL, X1, X2, X3, X0)

	VPADDD	2*16(TBL), X2, XFER
	VMOVDQU	XFER, (SP)
	FOUR_ROUNDS_AND_SCHED(RAL, RBL, RCL, RDL, REL, RFL, RGL, RHL, X2, X3, X0, X1)

	VPADDD	3*16(TBL), X3, XFER
	VMOVDQU	XFER, (SP)
	ADDQ	$(4*16), TBL
	FOUR_ROUNDS_AND_SCHED(REL, RFL, RGL, RHL, RAL, RBL, RCL, RDL, X3, X0, X1, X2)

	VPADDD	0*16(TBL), X0, XFER
	VMOVDQU	XFER, (SP)
	FOUR_ROUNDS_AND_SCHED(RAL, RBL, RCL, RDL, REL, RFL, RGL, RHL, X0, X1, X2, X3)

	VPADDD	1*16(TBL), X1, XFER
	VMOVDQU	XFER, (SP)
	FOUR_ROUNDS_AND_SCHED(REL, RFL, RGL, RHL, RAL, RBL, RCL, RDL, X1, X2, X3, X0)

	VPADDD	2*16(TBL), X2, XFER
	VMOVDQU	XFER, (SP)
	FOUR_ROUNDS_AND_SCHED(RAL, RBL, RCL, RDL, REL, RFL, RGL, RHL, X2, X3, X0, X1)

	VPADDD	3*16(TBL), X3, XFER
	VMOVDQU	XFER, (SP)
	ADDQ	$(4*16), TBL
	FOUR_ROUNDS_AND_SCHED(REL, RFL, RGL, RHL, RAL, RBL, RCL, RDL, X3, X0, X1, X2)

	// Final 16 rounds 
	VPADDD	0*16(TBL), X0, XFER 
	VMOVDQU	XFER, (SP)
	DO_ROUND(SP, 0, RAL, RBL, RCL, RDL, REL, RFL, RGL, RHL)
	DO_ROUND(SP, 4, RHL, RAL, RBL, RCL, RDL, REL, RFL, RGL)
	DO_ROUND(SP, 8, RGL, RHL, RAL, RBL, RCL, RDL, REL, RFL)
	DO_ROUND(SP, 12, RFL, RGL, RHL, RAL, RBL, RCL, RDL, REL)

	VPADDD	1*16(TBL), X1, XFER 
	VMOVDQU	XFER, (SP)
	ADDQ	$(2*16), TBL
	DO_ROUND(SP, 0, REL, RFL, RGL, RHL, RAL, RBL, RCL, RDL)
	DO_ROUND(SP, 4, RDL, REL, RFL, RGL, RHL, RAL, RBL, RCL)
	DO_ROUND(SP, 8, RCL, RDL, REL, RFL, RGL, RHL, RAL, RBL)
	DO_ROUND(SP, 12, RBL, RCL, RDL, REL, RFL, RGL, RHL, RAL)

	VMOVDQA	X2, X0
	VMOVDQA	X3, X1

	VPADDD	0*16(TBL), X0, XFER 
	VMOVDQU	XFER, (SP)
	DO_ROUND(SP, 0*4, RAL, RBL, RCL, RDL, REL, RFL, RGL, RHL)
	DO_ROUND(SP, 1*4, RHL, RAL, RBL, RCL, RDL, REL, RFL, RGL)
	DO_ROUND(SP, 2*4, RGL, RHL, RAL, RBL, RCL, RDL, REL, RFL)
	DO_ROUND(SP, 3*4, RFL, RGL, RHL, RAL, RBL, RCL, RDL, REL)

	VPADDD	1*16(TBL), X1, XFER 
	VMOVDQU	XFER, (SP)
	DO_ROUND(SP, 0, REL, RFL, RGL, RHL, RAL, RBL, RCL, RDL)
	DO_ROUND(SP, 4, RDL, REL, RFL, RGL, RHL, RAL, RBL, RCL)
	DO_ROUND(SP, 8, RCL, RDL, REL, RFL, RGL, RHL, RAL, RBL)
	DO_ROUND(SP, 12, RBL, RCL, RDL, REL, RFL, RGL, RHL, RAL)

	// Add initial digest and save it
	ADDL $0x6A09E667, RAL  // H0 = a + H0
	ADDL $0xBB67AE85, RBL  // H1 = b + H1
	ADDL $0x3C6EF372, RCL // H2 = c + H2
	ADDL $0xA54FF53A, RDL // H3 = d + H3
	ADDL $0x510E527F, REL // H4 = e + H4
	ADDL $0x9B05688C, RFL // H5 = f + H5
	ADDL $0x1F83D9AB, RGL // H6 = g + H6
	ADDL $0x5BE0CD19, RHL // H7 = h + H7


	MOVL RAL, (0*4+_DIGEST)(SP)
	MOVL RBL, (1*4+_DIGEST)(SP)
	MOVL RCL, (2*4+_DIGEST)(SP)
	MOVL RDL, (3*4+_DIGEST)(SP)
	MOVL REL, (4*4+_DIGEST)(SP)
	MOVL RFL, (5*4+_DIGEST)(SP)
	MOVL RGL, (6*4+_DIGEST)(SP)
	MOVL RHL, (7*4+_DIGEST)(SP)

	MOVQ	$PADDING<>(SB), TBL

	DO_ROUND(TBL, 0, RAL, RBL, RCL, RDL, REL, RFL, RGL, RHL)
	DO_ROUND(TBL, 4, RHL, RAL, RBL, RCL, RDL, REL, RFL, RGL)
	DO_ROUND(TBL, 8, RGL, RHL, RAL, RBL, RCL, RDL, REL, RFL)
	DO_ROUND(TBL, 12, RFL, RGL, RHL, RAL, RBL, RCL, RDL, REL)
	DO_ROUND(TBL, 16, REL, RFL, RGL, RHL, RAL, RBL, RCL, RDL)
	DO_ROUND(TBL, 20, RDL, REL, RFL, RGL, RHL, RAL, RBL, RCL)
	DO_ROUND(TBL, 24, RCL, RDL, REL, RFL, RGL, RHL, RAL, RBL)
	DO_ROUND(TBL, 28, RBL, RCL, RDL, REL, RFL, RGL, RHL, RAL)
	ADDQ	$32, TBL

	DO_ROUND(TBL, 0, RAL, RBL, RCL, RDL, REL, RFL, RGL, RHL)
	DO_ROUND(TBL, 4, RHL, RAL, RBL, RCL, RDL, REL, RFL, RGL)
	DO_ROUND(TBL, 8, RGL, RHL, RAL, RBL, RCL, RDL, REL, RFL)
	DO_ROUND(TBL, 12, RFL, RGL, RHL, RAL, RBL, RCL, RDL, REL)
	DO_ROUND(TBL, 16, REL, RFL, RGL, RHL, RAL, RBL, RCL, RDL)
	DO_ROUND(TBL, 20, RDL, REL, RFL, RGL, RHL, RAL, RBL, RCL)
	DO_ROUND(TBL, 24, RCL, RDL, REL, RFL, RGL, RHL, RAL, RBL)
	DO_ROUND(TBL, 28, RBL, RCL, RDL, REL, RFL, RGL, RHL, RAL)
	ADDQ	$32, TBL


	DO_ROUND(TBL, 0, RAL, RBL, RCL, RDL, REL, RFL, RGL, RHL)
	DO_ROUND(TBL, 4, RHL, RAL, RBL, RCL, RDL, REL, RFL, RGL)
	DO_ROUND(TBL, 8, RGL, RHL, RAL, RBL, RCL, RDL, REL, RFL)
	DO_ROUND(TBL, 12, RFL, RGL, RHL, RAL, RBL, RCL, RDL, REL)
	DO_ROUND(TBL, 16, REL, RFL, RGL, RHL, RAL, RBL, RCL, RDL)
	DO_ROUND(TBL, 20, RDL, REL, RFL, RGL, RHL, RAL, RBL, RCL)
	DO_ROUND(TBL, 24, RCL, RDL, REL, RFL, RGL, RHL, RAL, RBL)
	DO_ROUND(TBL, 28, RBL, RCL, RDL, REL, RFL, RGL, RHL, RAL)
	ADDQ	$32, TBL


	DO_ROUND(TBL, 0, RAL, RBL, RCL, RDL, REL, RFL, RGL, RHL)
	DO_ROUND(TBL, 4, RHL, RAL, RBL, RCL, RDL, REL, RFL, RGL)
	DO_ROUND(TBL, 8, RGL, RHL, RAL, RBL, RCL, RDL, REL, RFL)
	DO_ROUND(TBL, 12, RFL, RGL, RHL, RAL, RBL, RCL, RDL, REL)
	DO_ROUND(TBL, 16, REL, RFL, RGL, RHL, RAL, RBL, RCL, RDL)
	DO_ROUND(TBL, 20, RDL, REL, RFL, RGL, RHL, RAL, RBL, RCL)
	DO_ROUND(TBL, 24, RCL, RDL, REL, RFL, RGL, RHL, RAL, RBL)
	DO_ROUND(TBL, 28, RBL, RCL, RDL, REL, RFL, RGL, RHL, RAL)
	ADDQ	$32, TBL


	DO_ROUND(TBL, 0, RAL, RBL, RCL, RDL, REL, RFL, RGL, RHL)
	DO_ROUND(TBL, 4, RHL, RAL, RBL, RCL, RDL, REL, RFL, RGL)
	DO_ROUND(TBL, 8, RGL, RHL, RAL, RBL, RCL, RDL, REL, RFL)
	DO_ROUND(TBL, 12, RFL, RGL, RHL, RAL, RBL, RCL, RDL, REL)
	DO_ROUND(TBL, 16, REL, RFL, RGL, RHL, RAL, RBL, RCL, RDL)
	DO_ROUND(TBL, 20, RDL, REL, RFL, RGL, RHL, RAL, RBL, RCL)
	DO_ROUND(TBL, 24, RCL, RDL, REL, RFL, RGL, RHL, RAL, RBL)
	DO_ROUND(TBL, 28, RBL, RCL, RDL, REL, RFL, RGL, RHL, RAL)
	ADDQ	$32, TBL


	DO_ROUND(TBL, 0, RAL, RBL, RCL, RDL, REL, RFL, RGL, RHL)
	DO_ROUND(TBL, 4, RHL, RAL, RBL, RCL, RDL, REL, RFL, RGL)
	DO_ROUND(TBL, 8, RGL, RHL, RAL, RBL, RCL, RDL, REL, RFL)
	DO_ROUND(TBL, 12, RFL, RGL, RHL, RAL, RBL, RCL, RDL, REL)
	DO_ROUND(TBL, 16, REL, RFL, RGL, RHL, RAL, RBL, RCL, RDL)
	DO_ROUND(TBL, 20, RDL, REL, RFL, RGL, RHL, RAL, RBL, RCL)
	DO_ROUND(TBL, 24, RCL, RDL, REL, RFL, RGL, RHL, RAL, RBL)
	DO_ROUND(TBL, 28, RBL, RCL, RDL, REL, RFL, RGL, RHL, RAL)
	ADDQ	$32, TBL


	DO_ROUND(TBL, 0, RAL, RBL, RCL, RDL, REL, RFL, RGL, RHL)
	DO_ROUND(TBL, 4, RHL, RAL, RBL, RCL, RDL, REL, RFL, RGL)
	DO_ROUND(TBL, 8, RGL, RHL, RAL, RBL, RCL, RDL, REL, RFL)
	DO_ROUND(TBL, 12, RFL, RGL, RHL, RAL, RBL, RCL, RDL, REL)
	DO_ROUND(TBL, 16, REL, RFL, RGL, RHL, RAL, RBL, RCL, RDL)
	DO_ROUND(TBL, 20, RDL, REL, RFL, RGL, RHL, RAL, RBL, RCL)
	DO_ROUND(TBL, 24, RCL, RDL, REL, RFL, RGL, RHL, RAL, RBL)
	DO_ROUND(TBL, 28, RBL, RCL, RDL, REL, RFL, RGL, RHL, RAL)
	ADDQ	$32, TBL


	DO_ROUND(TBL, 0, RAL, RBL, RCL, RDL, REL, RFL, RGL, RHL)
	DO_ROUND(TBL, 4, RHL, RAL, RBL, RCL, RDL, REL, RFL, RGL)
	DO_ROUND(TBL, 8, RGL, RHL, RAL, RBL, RCL, RDL, REL, RFL)
	DO_ROUND(TBL, 12, RFL, RGL, RHL, RAL, RBL, RCL, RDL, REL)
	DO_ROUND(TBL, 16, REL, RFL, RGL, RHL, RAL, RBL, RCL, RDL)
	DO_ROUND(TBL, 20, RDL, REL, RFL, RGL, RHL, RAL, RBL, RCL)
	DO_ROUND(TBL, 24, RCL, RDL, REL, RFL, RGL, RHL, RAL, RBL)
	DO_ROUND(TBL, 28, RBL, RCL, RDL, REL, RFL, RGL, RHL, RAL)

	// add the previous digest

	ADDL (_DIGEST + 0*4)(SP), RAL
	ADDL (_DIGEST + 1*4)(SP), RBL
	ADDL (_DIGEST + 2*4)(SP), RCL
	ADDL (_DIGEST + 3*4)(SP), RDL
	ADDL (_DIGEST + 4*4)(SP), REL
	ADDL (_DIGEST + 5*4)(SP), RFL
	ADDL (_DIGEST + 6*4)(SP), RGL
	ADDL (_DIGEST + 7*4)(SP), RHL

	BSWAPL	RAL
	BSWAPL	RBL
	BSWAPL	RCL
	BSWAPL	RDL
	BSWAPL	REL
	BSWAPL	RFL
	BSWAPL	RGL
	BSWAPL	RHL

	MOVL	RAL, (0*4)(OUTPUT_PTR)
	MOVL	RBL, (1*4)(OUTPUT_PTR)
	MOVL	RCL, (2*4)(OUTPUT_PTR)
	MOVL	RDL, (3*4)(OUTPUT_PTR)
	MOVL	REL, (4*4)(OUTPUT_PTR)
	MOVL	RFL, (5*4)(OUTPUT_PTR)
	MOVL	RGL, (6*4)(OUTPUT_PTR)
	MOVL	RHL, (7*4)(OUTPUT_PTR)

	ADDQ $64, DATA_PTR
	ADDQ $32, OUTPUT_PTR
	JMP sha256_avx_1_loop

sha256_1_avx_epilog:
	RET


DATA K256<>+0x00(SB)/4, 	$0x428a2f98
DATA K256<>+0x04(SB)/4, 	$0x71374491
DATA K256<>+0x08(SB)/4, 	$0xb5c0fbcf
DATA K256<>+0x0c(SB)/4, 	$0xe9b5dba5
DATA K256<>+0x10(SB)/4, 	$0x3956c25b
DATA K256<>+0x14(SB)/4, 	$0x59f111f1
DATA K256<>+0x18(SB)/4, 	$0x923f82a4
DATA K256<>+0x1c(SB)/4, 	$0xab1c5ed5
DATA K256<>+0x20(SB)/4, 	$0xd807aa98
DATA K256<>+0x24(SB)/4, 	$0x12835b01
DATA K256<>+0x28(SB)/4, 	$0x243185be
DATA K256<>+0x2c(SB)/4, 	$0x550c7dc3
DATA K256<>+0x30(SB)/4, 	$0x72be5d74
DATA K256<>+0x34(SB)/4, 	$0x80deb1fe
DATA K256<>+0x38(SB)/4, 	$0x9bdc06a7
DATA K256<>+0x3c(SB)/4, 	$0xc19bf174
DATA K256<>+0x40(SB)/4, 	$0xe49b69c1
DATA K256<>+0x44(SB)/4, 	$0xefbe4786
DATA K256<>+0x48(SB)/4, 	$0x0fc19dc6
DATA K256<>+0x4c(SB)/4, 	$0x240ca1cc
DATA K256<>+0x50(SB)/4, 	$0x2de92c6f
DATA K256<>+0x54(SB)/4, 	$0x4a7484aa
DATA K256<>+0x58(SB)/4, 	$0x5cb0a9dc
DATA K256<>+0x5c(SB)/4, 	$0x76f988da
DATA K256<>+0x60(SB)/4, 	$0x983e5152
DATA K256<>+0x64(SB)/4, 	$0xa831c66d
DATA K256<>+0x68(SB)/4, 	$0xb00327c8
DATA K256<>+0x6c(SB)/4, 	$0xbf597fc7
DATA K256<>+0x70(SB)/4, 	$0xc6e00bf3
DATA K256<>+0x74(SB)/4, 	$0xd5a79147
DATA K256<>+0x78(SB)/4, 	$0x06ca6351
DATA K256<>+0x7c(SB)/4, 	$0x14292967
DATA K256<>+0x80(SB)/4, 	$0x27b70a85
DATA K256<>+0x84(SB)/4, 	$0x2e1b2138
DATA K256<>+0x88(SB)/4, 	$0x4d2c6dfc
DATA K256<>+0x8c(SB)/4, 	$0x53380d13
DATA K256<>+0x90(SB)/4, 	$0x650a7354
DATA K256<>+0x94(SB)/4, 	$0x766a0abb
DATA K256<>+0x98(SB)/4, 	$0x81c2c92e
DATA K256<>+0x9c(SB)/4, 	$0x92722c85
DATA K256<>+0xa0(SB)/4, 	$0xa2bfe8a1
DATA K256<>+0xa4(SB)/4, 	$0xa81a664b
DATA K256<>+0xa8(SB)/4, 	$0xc24b8b70
DATA K256<>+0xac(SB)/4, 	$0xc76c51a3
DATA K256<>+0xb0(SB)/4, 	$0xd192e819
DATA K256<>+0xb4(SB)/4, 	$0xd6990624
DATA K256<>+0xb8(SB)/4, 	$0xf40e3585
DATA K256<>+0xbc(SB)/4, 	$0x106aa070
DATA K256<>+0xc0(SB)/4, 	$0x19a4c116
DATA K256<>+0xc4(SB)/4, 	$0x1e376c08
DATA K256<>+0xc8(SB)/4, 	$0x2748774c
DATA K256<>+0xcc(SB)/4, 	$0x34b0bcb5
DATA K256<>+0xd0(SB)/4, 	$0x391c0cb3
DATA K256<>+0xd4(SB)/4, 	$0x4ed8aa4a
DATA K256<>+0xd8(SB)/4, 	$0x5b9cca4f
DATA K256<>+0xdc(SB)/4, 	$0x682e6ff3
DATA K256<>+0xe0(SB)/4, 	$0x748f82ee
DATA K256<>+0xe4(SB)/4, 	$0x78a5636f
DATA K256<>+0xe8(SB)/4, 	$0x84c87814
DATA K256<>+0xec(SB)/4, 	$0x8cc70208
DATA K256<>+0xf0(SB)/4, 	$0x90befffa
DATA K256<>+0xf4(SB)/4, 	$0xa4506ceb
DATA K256<>+0xf8(SB)/4, 	$0xbef9a3f7
DATA K256<>+0xfc(SB)/4, 	$0xc67178f2
GLOBL K256<>(SB),(NOPTR+RODATA),$256

DATA PADDING<>+0x00(SB)/4, $0xc28a2f98
DATA PADDING<>+0x04(SB)/4, $0x71374491
DATA PADDING<>+0x08(SB)/4, $0xb5c0fbcf
DATA PADDING<>+0x0c(SB)/4, $0xe9b5dba5
DATA PADDING<>+0x10(SB)/4, $0x3956c25b
DATA PADDING<>+0x14(SB)/4, $0x59f111f1
DATA PADDING<>+0x18(SB)/4, $0x923f82a4
DATA PADDING<>+0x1c(SB)/4, $0xab1c5ed5
DATA PADDING<>+0x20(SB)/4, $0xd807aa98
DATA PADDING<>+0x24(SB)/4, $0x12835b01
DATA PADDING<>+0x28(SB)/4, $0x243185be
DATA PADDING<>+0x2c(SB)/4, $0x550c7dc3
DATA PADDING<>+0x30(SB)/4, $0x72be5d74
DATA PADDING<>+0x34(SB)/4, $0x80deb1fe
DATA PADDING<>+0x38(SB)/4, $0x9bdc06a7
DATA PADDING<>+0x3c(SB)/4, $0xc19bf374
DATA PADDING<>+0x40(SB)/4, $0x649b69c1
DATA PADDING<>+0x44(SB)/4, $0xf0fe4786
DATA PADDING<>+0x48(SB)/4, $0x0fe1edc6
DATA PADDING<>+0x4c(SB)/4, $0x240cf254
DATA PADDING<>+0x50(SB)/4, $0x4fe9346f
DATA PADDING<>+0x54(SB)/4, $0x6cc984be
DATA PADDING<>+0x58(SB)/4, $0x61b9411e
DATA PADDING<>+0x5c(SB)/4, $0x16f988fa
DATA PADDING<>+0x60(SB)/4, $0xf2c65152
DATA PADDING<>+0x64(SB)/4, $0xa88e5a6d
DATA PADDING<>+0x68(SB)/4, $0xb019fc65
DATA PADDING<>+0x6c(SB)/4, $0xb9d99ec7
DATA PADDING<>+0x70(SB)/4, $0x9a1231c3
DATA PADDING<>+0x74(SB)/4, $0xe70eeaa0
DATA PADDING<>+0x78(SB)/4, $0xfdb1232b
DATA PADDING<>+0x7c(SB)/4, $0xc7353eb0
DATA PADDING<>+0x80(SB)/4, $0x3069bad5
DATA PADDING<>+0x84(SB)/4, $0xcb976d5f
DATA PADDING<>+0x88(SB)/4, $0x5a0f118f
DATA PADDING<>+0x8c(SB)/4, $0xdc1eeefd
DATA PADDING<>+0x90(SB)/4, $0x0a35b689
DATA PADDING<>+0x94(SB)/4, $0xde0b7a04
DATA PADDING<>+0x98(SB)/4, $0x58f4ca9d
DATA PADDING<>+0x9c(SB)/4, $0xe15d5b16
DATA PADDING<>+0xa0(SB)/4, $0x007f3e86
DATA PADDING<>+0xa4(SB)/4, $0x37088980
DATA PADDING<>+0xa8(SB)/4, $0xa507ea32
DATA PADDING<>+0xac(SB)/4, $0x6fab9537
DATA PADDING<>+0xb0(SB)/4, $0x17406110
DATA PADDING<>+0xb4(SB)/4, $0x0d8cd6f1
DATA PADDING<>+0xb8(SB)/4, $0xcdaa3b6d
DATA PADDING<>+0xbc(SB)/4, $0xc0bbbe37
DATA PADDING<>+0xc0(SB)/4, $0x83613bda
DATA PADDING<>+0xc4(SB)/4, $0xdb48a363
DATA PADDING<>+0xc8(SB)/4, $0x0b02e931
DATA PADDING<>+0xcc(SB)/4, $0x6fd15ca7
DATA PADDING<>+0xd0(SB)/4, $0x521afaca
DATA PADDING<>+0xd4(SB)/4, $0x31338431
DATA PADDING<>+0xd8(SB)/4, $0x6ed41a95
DATA PADDING<>+0xdc(SB)/4, $0x6d437890
DATA PADDING<>+0xe0(SB)/4, $0xc39c91f2
DATA PADDING<>+0xe4(SB)/4, $0x9eccabbd
DATA PADDING<>+0xe8(SB)/4, $0xb5c9a0e6
DATA PADDING<>+0xec(SB)/4, $0x532fb63c
DATA PADDING<>+0xf0(SB)/4, $0xd2c741c6
DATA PADDING<>+0xf4(SB)/4, $0x07237ea3
DATA PADDING<>+0xf8(SB)/4, $0xa4954b68
DATA PADDING<>+0xfc(SB)/4, $0x4c191d76
GLOBL PADDING<>(SB),(NOPTR+RODATA),$256

DATA PSHUFFLE_BYTE_FLIP_MASK<>+0X00(SB)/8, $0x0405060700010203 
DATA PSHUFFLE_BYTE_FLIP_MASK<>+0X08(SB)/8, $0x0c0d0e0f08090a0b
GLOBL PSHUFFLE_BYTE_FLIP_MASK<>(SB),(NOPTR+RODATA),$16

DATA PSHUF_00BA<>+0x00(SB)/8, $0x0b0a090803020100
DATA PSHUF_00BA<>+0x08(SB)/8, $0xFFFFFFFFFFFFFFFF
GLOBL PSHUF_00BA<>(SB),(NOPTR+RODATA),$16


DATA PSHUF_DC00<>+0x00(SB)/8, $0xFFFFFFFFFFFFFFFF
DATA PSHUF_DC00<>+0x08(SB)/8, $0x0b0a090803020100
GLOBL PSHUF_DC00<>(SB),(NOPTR+RODATA),$16
