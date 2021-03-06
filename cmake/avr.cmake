# Setup the toolchain
set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR avr)
set(CMAKE_CROSSCOMPILING 1)

set(CMAKE_C_COMPILER avr-gcc)
set(CMAKE_CXX_COMPILER avr-g++)

set(CMAKE_AR avr-gcc-ar)
set(CMAKE_RANLIB avr-gcc-ranlib)

SET(CMAKE_C_ARCHIVE_CREATE "<CMAKE_AR> rc <TARGET> <LINK_FLAGS> <OBJECTS>")
SET(CMAKE_C_ARCHIVE_FINISH true)

# Options
set(
	MCU_FLAGS
	"-mmcu=${MCU_NAME}"
	"-DF_CPU=${CPU_FREQ}UL"
)

set(
	LTO_FLAGS
	"-flto"
	"-fuse-linker-plugin"
)

set(
	WARNING_ERROR_FLAGS
	"-Wall"
	"-Wextra"
	"-Werror"
)

set(
	FLAGS
	"-fno-exceptions"
	"-ffunction-sections"
	"-fdata-sections"
)

set(OPTIMIZATION "-Os")

add_definitions(
	${MCU_FLAGS}
	${OPTIMIZATION}
	${LTO_FLAGS}
	${WARNING_ERROR_FLAGS}
	${FLAGS}
)

set(
	CMAKE_CXX_FLAGS
	"-std=c++20 -fno-threadsafe-statics -fpermissive"
)

add_link_options(
	"-mmcu=atmega328p"
	"-Wl,--gc-sections"
	"-flto"
	"-fuse-linker-plugin"
	"-Wl,--start-group"
	"-lm"
	"-Wl,--end-group"
)

# Function definitions
function(add_avr_executable EXECUTABLE_NAME)
	set(BIN_FOLDER ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${EXECUTABLE_NAME})
	add_executable(
		${EXECUTABLE_NAME}.elf
		${ARGN}
	)

	target_link_options(
		${EXECUTABLE_NAME}.elf
		PRIVATE
		"-Wl,-Map,${BIN_FOLDER}.map"
	)

	add_custom_command(
		OUTPUT ${EXECUTABLE_NAME}.hex
		COMMAND
		avr-objcopy -j .text -j .data -O ihex ${BIN_FOLDER}.elf ${BIN_FOLDER}.hex
		COMMAND
		avr-size -t -d ${BIN_FOLDER}.elf
		DEPENDS ${EXECUTABLE_NAME}.elf
	)

	add_custom_command(
		OUTPUT ${EXECUTABLE_NAME}.lss
		COMMAND
		avr-objdump -h -d ${BIN_FOLDER}.elf > ${BIN_FOLDER}.lss
		DEPENDS ${EXECUTABLE_NAME}.elf
	)

	add_custom_target(
		${EXECUTABLE_NAME}
		ALL
		DEPENDS ${EXECUTABLE_NAME}.hex ${EXECUTABLE_NAME}.lss
	)

	add_custom_target(
		upload_${EXECUTABLE_NAME}
		avrdude -p atmega328p -c arduino -b 115200 -D -P ${PORT} -U flash:w:${BIN_FOLDER}.hex:i
		DEPENDS ${EXECUTABLE_NAME}.hex
		COMMENT "Uploading ${EXECUTABLE_NAME}.hex to atmega328p using arduino"
	)

	get_directory_property(clean_files ADDITIONAL_MAKE_CLEAN_FILES)
	set_directory_properties(
		PROPERTIES
		ADDITIONAL_MAKE_CLEAN_FILES "${clean_files};${BIN_FOLDER}.map;${BIN_FOLDER}.hex;${BIN_FOLDER}.lss"
	)
endfunction(add_avr_executable)

function(add_zol_executable EXECUTABLE_NAME)
	add_avr_executable(
		${EXECUTABLE_NAME}
		${ARGN}
	)
	
	target_link_libraries(
		${EXECUTABLE_NAME}.elf
		zol
	)
endfunction(add_zol_executable)