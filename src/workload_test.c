#include <stdlib.h>
#include <stdio.h>
#include <fcntl.h>
#include <errno.h>
#include <unistd.h>

// #define buf_size              0x10000000
// #define OFFSET_IN_FPGA_DRAM   0x80000000

int main( int argc, char *argv[])
{
    int xdma_h2c_fd, xdma_c2h_fd;
    int i;
    int ret;
    char * file_name, * end_ptr;
    unsigned int trans_size = 4; //4B, 32bit
    unsigned int read_val, write_val;
    unsigned int offset_in_fpga_dram;

    if (argc != 3) {
        printf("Usage: %s <offset_in_fpga_dram> <number>\n", argv[0]);
        return -1;
    }

    offset_in_fpga_dram = strtoul(argv[1], &end_ptr, 0);
    write_val = strtoul(argv[2], &end_ptr, 0);    

    if ((xdma_c2h_fd = open("/dev/xdma0_c2h_0",O_RDONLY)) == -1) {
        perror("open XDMA c2h device failed with errno");
    }
    
    ret = pread(xdma_c2h_fd, &read_val, trans_size, offset_in_fpga_dram);
    if (ret < 0) {
        perror("read val failed with errno");
    }

    printf("read val 0x%x into fpga addr 0x%x\n", read_val, offset_in_fpga_dram);

    if ((xdma_h2c_fd = open("/dev/xdma0_h2c_0",O_WRONLY)) == -1) {
        perror("open XDMA h2c device failed with errno");
    }

    ret = pwrite(xdma_h2c_fd, &write_val, trans_size, offset_in_fpga_dram);
    if (ret < 0) {
        perror("write val failed with errno");
    }
    
    printf("write val 0x%x into fpga addr 0x%x\n", write_val, offset_in_fpga_dram);

    if (close(xdma_h2c_fd) < 0 || close(xdma_c2h_fd) < 0) {
        perror("xdma_fd close failed with errno");
    }
    return 0;
} 
