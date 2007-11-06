/* NV20_TCL_PRIMITIVE_3D_0x0B00 */
#define NV20_VP_INST_0B00	0x00000000 /* always 0? */
#define NV20_VP_INST0_KNOWN	0

/* NV20_TCL_PRIMITIVE_3D_0x0B04 */
#define NV20_VP_INST_SCA_OPCODE_SHIFT				25
#define NV20_VP_INST_SCA_OPCODE_MASK				(0x0F << 25)
#define NV20_VP_INST_OPCODE_RCP	0x2
#define NV20_VP_INST_OPCODE_RCC	0x3
#define NV20_VP_INST_OPCODE_RSQ	0x4
#define NV20_VP_INST_OPCODE_EXP	0x5
#define NV20_VP_INST_OPCODE_LOG	0x6
#define NV20_VP_INST_OPCODE_LIT	0x7
#define NV20_VP_INST_VEC_OPCODE_SHIFT				21
#define NV20_VP_INST_VEC_OPCODE_MASK				(0x0F << 21)
#define NV20_VP_INST_OPCODE_NOP	0x0 /* guess */
#define NV20_VP_INST_OPCODE_MOV	0x1
#define NV20_VP_INST_OPCODE_MUL	0x2
#define NV20_VP_INST_OPCODE_ADD	0x3
#define NV20_VP_INST_OPCODE_MAD	0x4
#define NV20_VP_INST_OPCODE_DP3	0x5
#define NV20_VP_INST_OPCODE_DPH	0x6
#define NV20_VP_INST_OPCODE_DP4	0x7
#define NV20_VP_INST_OPCODE_DST	0x8
#define NV20_VP_INST_OPCODE_MIN	0x9
#define NV20_VP_INST_OPCODE_MAX	0xA
#define NV20_VP_INST_OPCODE_SLT	0xB
#define NV20_VP_INST_OPCODE_SGE	0xC
#define NV20_VP_INST_OPCODE_ARL	0xD
#define NV20_VP_INST_CONST_SRC_SHIFT				13
#define NV20_VP_INST_CONST_SRC_MASK				(0xFF << 13)
#define NV20_VP_INST_INPUT_SRC_SHIFT				9
#define NV20_VP_INST_INPUT_SRC_MASK				(0xF << 9) /* guess */
#define NV20_VP_INST_INPUT_SRC_POS	0
#define NV20_VP_INST_INPUT_SRC_COL0	3
#define NV20_VP_INST_INPUT_SRC_COL1	4
#define NV20_VP_INST_INPUT_SRC_TC(n)	(9+n)
#define NV20_VP_INST_SRC0H_SHIFT				0
#define NV20_VP_INST_SRC0H_MASK					(0x1FF << 0)
#define NV20_VP_INST1_KNOWN	( \
	NV20_VP_INST_OPCODE_MASK | \
	NV20_VP_INST_CONST_SRC_MASK | \
	NV20_VP_INST_INPUT_SRC_MASK | \
	NV20_VP_INST_SRC0H_MASK \
	)

/* NV20_TCL_PRIMITIVE_3D_0x0B08 */
#define NV20_VP_INST_SRC0L_SHIFT				26
#define NV20_VP_INST_SRC0L_MASK					(0x3F  <<26)
#define NV20_VP_INST_SRC1_SHIFT					11
#define NV20_VP_INST_SRC1_MASK					(0x7FFF<<11)
#define NV20_VP_INST_SRC2H_SHIFT				0
#define NV20_VP_INST_SRC2H_MASK					(0x7FF << 0)

/* NV20_TCL_PRIMITIVE_3D_0x0B0C */
#define NV20_VP_INST_SRC2L_SHIFT				28
#define NV20_VP_INST_SRC2L_MASK					(0x0F  <<28)
#define NV20_VP_INST_VTEMP_WRITEMASK_SHIFT			24
#define NV20_VP_INST_VTEMP_WRITEMASK_MASK			(0x0F  <<24)
#    define NV20_VP_INST_TEMP_WRITEMASK_X	(1<<27)
#    define NV20_VP_INST_TEMP_WRITEMASK_Y	(1<<26)
#    define NV20_VP_INST_TEMP_WRITEMASK_Z	(1<<25)
#    define NV20_VP_INST_TEMP_WRITEMASK_W	(1<<24)
#define NV20_VP_INST_DEST_TEMP_ID_SHIFT				20
#define NV20_VP_INST_DEST_TEMP_ID_MASK				(0x0F  <<20)
#define NV20_VP_INST_STEMP_WRITEMASK_SHIFT			16
#define NV20_VP_INST_STEMP_WRITEMASK_MASK			(0x0F  <<16)
#    define NV20_VP_INST_STEMP_WRITEMASK_X	(1<<19)
#    define NV20_VP_INST_STEMP_WRITEMASK_Y	(1<<18)
#    define NV20_VP_INST_STEMP_WRITEMASK_Z	(1<<17)
#    define NV20_VP_INST_STEMP_WRITEMASK_W	(1<<16)
#define NV20_VP_INST_DEST_WRITEMASK_SHIFT			12
#define NV20_VP_INST_DEST_WRITEMASK_MASK			(0x0F  <<12)
#    define NV20_VP_INST_DEST_WRITEMASK_X	(1<<15)
#    define NV20_VP_INST_DEST_WRITEMASK_Y	(1<<14)
#    define NV20_VP_INST_DEST_WRITEMASK_Z	(1<<13)
#    define NV20_VP_INST_DEST_WRITEMASK_W	(1<<12)
#define NV20_VP_INST_DEST_SHIFT					3
#define NV20_VP_INST_DEST_MASK					(0xF << 3) /* guess */
#define NV20_VP_INST_DEST_POS	0
#define NV20_VP_INST_DEST_COL0	3
#define NV20_VP_INST_DEST_COL1	4
#define NV20_VP_INST_DEST_TC(n)	(9+n)
#define NV20_VP_INST_INDEX_CONST				(1<<1)
#define NV20_VP_INST3_KNOWN ( \
	NV20_VP_INST_SRC2L_MASK | \
	NV20_VP_INST_TEMP_WRITEMASK_MASK | \
	NV20_VP_INST_DEST_TEMP_ID_MASK | \
	NV20_VP_INST_STEMP_WRITEMASK_MASK | \
	NV20_VP_INST_DEST_WRITEMASK_MASK | \
	NV20_VP_INST_DEST_MASK | \
	NV20_VP_INST_INDEX_CONST \
	)

/* Useful to split the source selection regs into their pieces */
#define NV20_VP_SRC0_HIGH_SHIFT 6
#define NV20_VP_SRC0_HIGH_MASK  0x00007FC0
#define NV20_VP_SRC0_LOW_MASK   0x0000003F
#define NV20_VP_SRC2_HIGH_SHIFT 4
#define NV20_VP_SRC2_HIGH_MASK  0x00007FF0
#define NV20_VP_SRC2_LOW_MASK   0x0000000F

#define NV20_VP_SRC_REG_NEGATE					(1<<14)
#define NV20_VP_SRC_REG_SWZ_X_SHIFT				12
#define NV20_VP_SRC_REG_SWZ_X_MASK				(0x03  <<12)
#define NV20_VP_SRC_REG_SWZ_Y_SHIFT				10
#define NV20_VP_SRC_REG_SWZ_Y_MASK				(0x03  <<10)
#define NV20_VP_SRC_REG_SWZ_Z_SHIFT				8
#define NV20_VP_SRC_REG_SWZ_Z_MASK				(0x03  << 8)
#define NV20_VP_SRC_REG_SWZ_W_SHIFT				6
#define NV20_VP_SRC_REG_SWZ_W_MASK				(0x03  << 6)
#define NV20_VP_SRC_REG_SWZ_ALL_SHIFT				6
#define NV20_VP_SRC_REG_SWZ_ALL_MASK				(0xFF  << 6)
#define NV20_VP_SRC_REG_TEMP_ID_SHIFT				2
#define NV20_VP_SRC_REG_TEMP_ID_MASK				(0x0F  << 0)
#define NV20_VP_SRC_REG_TYPE_SHIFT				0
#define NV20_VP_SRC_REG_TYPE_MASK				(0x03  << 0)
#define NV20_VP_SRC_REG_TYPE_TEMP	1
#define NV20_VP_SRC_REG_TYPE_INPUT	2
#define NV20_VP_SRC_REG_TYPE_CONST	3	/* guess */

