# vivado -mode tcl -source pkg_ip.tcl
create_project -force three-wire-spi-ip-dev /home/midimaster21b/src/three-wire-spi-ip-dev -part xczu7ev-ffvc1156-2-e

set_property target_language VHDL [current_project]

add_files -norecurse {/home/midimaster21b/src/three-wire-spi/src/rtl/three_wire_spi_cdc.vhd /home/midimaster21b/src/cdc/src/rtl/cdc_pulse.vhd /home/midimaster21b/src/three-wire-spi/src/rtl/three_wire_spi.vhd /home/midimaster21b/src/three-wire-spi/src/rtl/three_wire_spi_regs.vhd /home/midimaster21b/src/cdc/src/rtl/cdc_array.vhd /home/midimaster21b/src/three-wire-spi/src/rtl/three_wire_spi_top.vhd /home/midimaster21b/src/cdc/src/rtl/cdc_bit.vhd}

update_compile_order -fileset sources_1

ipx::package_project -root_dir /home/midimaster21b/src/ip_repo -vendor midimaster21b -library comm -taxonomy /Communication -import_files -set_current false

ipx::unload_core /home/midimaster21b/src/ip_repo/component.xml
ipx::edit_ip_in_project -upgrade true -name tmp_edit_project -directory /home/midimaster21b/src/ip_repo /home/midimaster21b/src/ip_repo/component.xml
update_compile_order -fileset sources_1
set_property core_revision 1 [ipx::current_core]
ipx::update_source_project_archive -component [ipx::current_core]
ipx::create_xgui_files [ipx::current_core]
ipx::update_checksums [ipx::current_core]
ipx::check_integrity [ipx::current_core]
ipx::save_core [ipx::current_core]
ipx::move_temp_component_back -component [ipx::current_core]
close_project -delete
set_property  ip_repo_paths  /home/midimaster21b/src/ip_repo [current_project]
update_ip_catalog
quit
