#include <stdlib.h>
#include <stdio.h>
#include <fcntl.h>
#include <errno.h>
#include <unistd.h>

// #define buf_size              0x10000000
// #define OFFSET_IN_FPGA_DRAM   0x80000000

int main( int argc, char *argv[])
{
    char * srcBuf;
    int write_fd;
    int i;
    int ret;
    char * file_name, * end_ptr;
    unsigned int buf_size, offset_in_fpga_dram;

    if (argc != 4) {
        printf("Usage: %s <offset_in_fpga_dram> <buf_size> <file_name>\n", argv[0]);
        return -1;
    }

    offset_in_fpga_dram = strtoul(argv[1], &end_ptr, 0);
    buf_size = strtoul(argv[2], &end_ptr, 0);    
    file_name = argv[3];

    srcBuf = (char*)malloc(buf_size * sizeof(char));

    FILE *p;
    if ((p = fopen(file_name, "rb")) == NULL) {
        perror("open workload failed with errno");
    }

    fread(srcBuf, 1, buf_size, p); 
    /* Open a XDMA write channel (Host to Core) */
    if ((write_fd = open("/dev/xdma0_h2c_0",O_WRONLY)) == -1) {
        perror("open XDMA device failed with errno");
    }
    
    fclose(p);
    /* Write the entire source buffer to offset OFFSET_IN_FPGA_DRAM */
    ret = pwrite(write_fd , srcBuf, buf_size, offset_in_fpga_dram);
    if (ret < 0) {
        perror("write workload failed with errno");
    }
    
    printf("Tried to write %u bytes, succeeded in writing %u bytes\n", buf_size, ret);

    if (close(write_fd) < 0) {
        perror("write_fd close failed with errno");
    }
    return 0;
} 
