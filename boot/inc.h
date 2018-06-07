/**
 * @file   inc.h
 * @brief  Self-defined macros
 * @author Hingon Miu (hmiu@andrew.cmu.edu)
 * @author An Wu (anwu@andrew.cmu.edu)
 */

#ifndef BOOT_INC_H
#define BOOT_INC_H

/* self-defined variables */
#define KERNEL_PRELOAD_ADDR_ES ((KERNEL_PRELOAD_ADDR) >> 4)
#define BYTES_PER_TRACK_ES  ((BYTES_PER_TRACK) >> 4)

/* segment descriptor entry macros */
/* the 1st word: Segment Limit 15:00 */
#define SEGDES_W1_SET (0xffff)

/* the 2nd word: Segment Base Address 15:00 */
/* the 3rd word */
#define SEGDES_W3_TYPE_CODE (0x800)
#define SEGDES_W3_TYPE_CODE_CF (0x400)
#define SEGDES_W3_TYPE_CODE_RE (0x200)
#define SEGDES_W3_TYPE_CODE_AC (0x100)
#define SEGDES_W3_TYPE_DATA (0x0)
#define SEGDES_W3_TYPE_DATA_EU (0x0)
#define SEGDES_W3_TYPE_DATA_WE (0x200)
#define SEGDES_W3_TYPE_DATA_AC (0x100)
#define SEGDES_W3_S (0x1000)
#define SEGDES_W3_P (0x8000)

/* the 4th word */
#define SEGDES_W4_SEGLIM_SET (0xf)
#define SEGDES_W4_DB (0x40)
#define SEGDES_W4_G (0x80)

/* page size */
#define PAGE_SIZE 0x10000

#endif
