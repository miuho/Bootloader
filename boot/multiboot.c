/*
 * @file    multibook.c
 * @brief   Implement the parsing of multiboot header.
 *
 * @author  HingOn Miu (hmiu)
 * @author  An Wu (anwu)
 *
 */

#define CONSOLE_MEM_BASE 0xB8000
#define CONSOLE_WIDTH 80
#define CONSOLE_HEIGHT 25

#include "multiboot.h"
#include "boot.h"
#include "inc.h"
#include "boot1.h"

/*
 * @brief Parse the multiboot header.
 *
 * @param mb_header The structure containing the header.
 * @param mb_info The multiboot information structure.
 * @param mem_lower The lower memory size.
 * @param mem_upper The upper memory size.
 *
 * @return The kernel entry address if successful, 0 otherwise.
 */
int parse_header(struct multiboot_header *mb_header, 
                    struct multiboot_info *mb_info,
                    multiboot_uint32_t mem_lower,
                    multiboot_uint32_t mem_upper) {
    /* check flags */
    int page_align = (mb_header->flags) & MULTIBOOT_PAGE_ALIGN;
    int memory_info = (mb_header->flags) & MULTIBOOT_MEMORY_INFO;
    //int video_mode = (mb_header->flags) & MULTIBOOT_VIDEO_MODE;
    int aout_kludge = (mb_header->flags) & MULTIBOOT_AOUT_KLUDGE;

    /* we don't parse ELF format images */
    if (!aout_kludge) {
        return 0;
    }

    /* mem_upper and mem_lower must be set */
    if (!memory_info) {
        return 0;
    }

    /* retrieve the fields */
    multiboot_uint32_t header_addr = mb_header->header_addr;
    multiboot_uint32_t load_addr = mb_header->load_addr;
    multiboot_uint32_t load_end_addr = mb_header->load_end_addr;
    multiboot_uint32_t bss_end_addr = mb_header->bss_end_addr;
    multiboot_uint32_t entry_addr = mb_header->entry_addr;

    /* check page align */
    if ((load_addr & (PAGE_SIZE - 1)) != 0 && page_align) {
        return 0;
    }

    char *temp;
    /* load the text and data section */
    multiboot_uint32_t offset = ((multiboot_uint32_t)mb_header) - 
                                KERNEL_PRELOAD_ADDR - (header_addr - load_addr);
    char *start_addr = (char *)load_addr;

    if (load_end_addr == 0) {
        temp = start_addr;
        /* load the whole OS image file from offset */
        while (offset != KERNEL_MAX_SIZE) {
            *(temp) = *(char *)(KERNEL_PRELOAD_ADDR + offset);
            temp++;
            offset++;
        }
    }
    else {
        /* load the image from offset to laod_end */
        for (temp = start_addr; temp < (char *)load_end_addr; temp++) {
            *(temp) = *(char *)(KERNEL_PRELOAD_ADDR + offset);
            offset++;
        }
    }

    /* load the bss section */
    if (bss_end_addr != 0) {
        /* start from temp */
        while ((multiboot_uint32_t) temp != bss_end_addr) {
            *(temp) = '\0';
            temp++;
        }
    }

    /* set flag[0] and flag[1] */
    mb_info->flags = 0x3;

    /* set mem_lower and mem_upper */
    mb_info->mem_lower = mem_lower;
    mb_info->mem_upper = mem_upper;

    /* set boot device */
    mb_info->boot_device = 0x00ffffff;

    return entry_addr;
}


/*
 * @brief Invoke the multiboot parser.
 *
 * @param mb_info The multiboot information structure.
 * @param mem_lower The lower memory size.
 * @param mem_upper The upper memory size.
 *
 * @return The kernel entry address if successful, 0 otherwise.
 */
multiboot_uint32_t invoke_multiboot(struct multiboot_info *mb_info, 
                                    multiboot_uint32_t mem_lower,
                                    multiboot_uint32_t mem_upper) {
    
    unsigned long *kern_addr;
    unsigned long *start_addr = (unsigned long *)KERNEL_PRELOAD_ADDR;
    unsigned long *dest_addr = 
        (unsigned long *)(KERNEL_PRELOAD_ADDR + MULTIBOOT_SEARCH);
    for (kern_addr = start_addr; kern_addr < dest_addr; kern_addr++) {
        
        /* found the magic field of the multiboot header.
         * make sure checksum is also valid */
        if (*(kern_addr) == MULTIBOOT_HEADER_MAGIC &&
            (*(kern_addr) + *(kern_addr + 1) + *(kern_addr + 2) == 0)) {
             
             /* parse the multiboot header and fill in multiboot_info */
            return parse_header((struct multiboot_header *)kern_addr, mb_info,
                                mem_lower, mem_upper);
        }
    }

    return 0;
}

/*
 * @brief Write a character to a location on console.
 *
 * @param row The row index on console.
 * @param col The column index on console.
 * @param c The character to write to console.
 *
 * @return Void..
 */
void draw_char(int row, int col, char c) {
    *(char *)(CONSOLE_MEM_BASE + 2 * (row * CONSOLE_WIDTH + col)) = c;
    *(char *)(CONSOLE_MEM_BASE + 2 * (row * CONSOLE_WIDTH + col) + 1) = 
                                                                LGRAY_ATTRIB;
    return;
}


/*
 * @brief Print panic message to console.
 *
 * @param start_row The row index of the message.
 * @param start_col The column index of the message.
 *
 * @return Void.
 */
void multiboot_panic(int start_row, int start_col) {
    char *panic_str = "Parse multiboot header failed";
    char *temp;

    for (temp = panic_str; *temp != '\0'; temp++) {
        draw_char(start_row, start_col++, *temp);
    }
}

