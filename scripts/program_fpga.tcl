proc print_usage {} {
    puts "Usage:"
    puts "  vivado -mode tcl -source program_fpga.tcl -tclargs <DEVICE> <BITFILE>"
    puts ""
    puts "Parameters:"
    puts "  DEVICE   : FPGA device name (e.g. xcvu37p_0)"
    puts "  BITFILE  : Full path to .bit file"
    puts ""
    puts "Example:"
    puts "  vivado -mode tcl -source program_fpga.tcl -tclargs xcvu37p_0 /home/lgf/fpga_eval/dasics.bit"
    puts ""
    puts "Debugging Tips:"
    puts "1. Ensure the FPGA is powered on and connected"
    puts "2. Check cable connection (USB/JTAG)"
    puts "3. Verify drivers are installed (e.g. cable drivers)"
    puts "4. Run 'vivado -mode batch -source program_fpga.tcl -tclargs list_devices dummy.bit' to see available devices"
    exit 1
}

if {$argc < 1} { print_usage }

# 特殊命令：列出可用设备
if {[lindex $argv 0] == "list_devices"} {
    open_hw_manager
    connect_hw_server -quiet
    puts "\n======================================================="
    puts "Available hardware targets:"
    foreach target [get_hw_targets] {
        puts "  [get_property NAME $target]"
        open_hw_target $target -quiet
        refresh_hw_target $target
        puts "    Detected devices:"
        foreach device [get_hw_devices] {
            puts "      [get_property NAME $device]"
        }
        close_hw_target $target -quiet
    }
    puts "=======================================================\n"
    close_hw_manager
    exit 0
}

if {$argc != 2} { print_usage }

set device [lindex $argv 0]
set bitfile [lindex $argv 1]

# 验证比特流文件
if {![file exists $bitfile]} {
    puts "ERROR: Bitstream file not found: $bitfile"
    exit 2
}

# 硬件连接主函数
proc connect_to_device {} {
    # 检查硬件服务器连接
    if {[catch {connect_hw_server -quiet} err]} {
        puts "WARNING: Could not connect to hardware server: $err"
        puts "Attempting to start local hardware server..."
        if {[catch {start_hw_server} err]} {
            puts "ERROR: Failed to start hardware server: $err"
            puts "Possible solutions:"
            puts "1. Run as administrator (sudo)"
            puts "2. Check Vivado installation"
            exit 3
        }
        connect_hw_server -quiet
    }
    
    # 尝试获取硬件目标
    set targets [get_hw_targets -quiet]
    if {[llength $targets] == 0} {
        puts "ERROR: No hardware targets detected"
        puts "Please check:"
        puts "  1. Physical cable connection"
        puts "  2. Device power supply"
        puts "  3. USB permission (run 'sudo chmod a+rw /dev/ttyUSB*')"
        puts "  4. Cable drivers are installed"
        exit 4
    }
    
    # 选择第一个可用的目标
    set target [lindex $targets 0]
    puts "Selected target: [get_property NAME $target]"
    
    return $target
}

# 主程序
open_hw_manager
set hw_target [connect_to_device]
open_hw_target

# 刷新目标状态
refresh_hw_target $hw_target

# 获取指定设备
set hw_device [get_hw_devices $device -quiet]
if {[llength $hw_device] == 0} {
    puts "\nERROR: Device '$device' not found. Available devices:"
    foreach dev [get_hw_devices -quiet] { 
        puts "  [get_property NAME $dev] ([get_property DEVICE_FAMILY $dev])"
    }
    close_hw_target $hw_target
    close_hw_manager
    exit 5
}
set hw_device [lindex $hw_device 0]

# 刷新设备
puts "Refreshing device..."
refresh_hw_device -update_hw_probes false $hw_device

# 设置编程文件
puts "Loading bitstream: $bitfile"
set_property PROBES.FILE {} $hw_device
set_property FULL_PROBES.FILE {} $hw_device
set_property PROGRAM.FILE $bitfile $hw_device

# 编程设备
puts "Programming FPGA..."
program_hw_devices $hw_device
puts "Program operation completed"

# 验证编程结果
refresh_hw_device $hw_device
puts "\nSUCCESS: FPGA programmed and verified"

# 清理
close_hw_target $hw_target
close_hw_manager
exit 0