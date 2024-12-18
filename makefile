###############################################################################
# makefile
# makefile for the odimh5_validator software
# L. Meri, SHMU
###############################################################################


###############################################################################
# edit the HOME_DIR, CXX and H5CC variables according your system if necessary
###############################################################################
HOME_DIR = $(shell pwd)
CXX = g++
H5CC = h5cc

###############################################################################
#it is possible to edit the compiler flags but not recommended
###############################################################################
CXX_FLAGS += -std=c++11 -O2 -Wall -Wextra -DH5_USE_18_API

###############################################################################
#don`t edit anything below this unless you are sure of what you do
###############################################################################

ifdef CXX
     GCC_VERSION = $(shell $(CXX) -dumpversion -dumpfullversion | sed -r 's/\.//g' | xargs)
else
     GCC_VERSION = $(shell g++ -dumpversion -dumpfullversion | sed -r 's/\.//g' | xargs)
endif

MIN_GCC_VERISON = 490
GCC_VERSION_OK = $(shell expr $(GCC_VERSION) '>=' $(MIN_GCC_VERISON))

AR = ar
ARFLAGS = -rv

SRC_DIR = $(HOME_DIR)/src
OBJ_DIR = $(HOME_DIR)/obj
INC_DIR = $(HOME_DIR)/include
LIB_DIR = $(HOME_DIR)/lib
BIN_DIR = $(HOME_DIR)/bin

HDF_INST_DIR = $(shell $(H5CC) -showconfig | \
               grep "Installation point:" | \
               awk -F': ' '{print $$2}' )
HDF_FLAVOR_DIR = $(shell $(H5CC) -showconfig | \
                 grep "Flavor name:" | \
                 awk -F': ' '{print $$2}' )
INC_FLAGS = -I$(HDF_INST_DIR)/include -I$(HDF_INST_DIR)/include/hdf5/$(HDF_FLAVOR_DIR) -I$(INC_DIR)

ifeq ($(HDF_INST_DIR),'')
  LIB_FLAGS =
else
  LIB_FLAGS = -L$(HDF_INST_DIR)/lib
endif
LIB_FLAGS += -L$(LIB_DIR) \
            -Wl,--start-group \
            -lmyodimh5 \
            -lhdf5
LIB_FLAGS += $(shell $(H5CC) -showconfig | \
                     grep "Extra libraries:" | \
                     awk -F': ' '{print $$2}' )
LIB_FLAGS += -lpthread -Wl,--end-group




LIB_LIST = $(LIB_DIR)/libmyodimh5.a

BIN_LIST = $(BIN_DIR)/odimh5-validate \
           $(BIN_DIR)/odimh5-check-value \
           $(BIN_DIR)/odimh5-correct

OBJ_LIST = $(OBJ_DIR)/class_H5Layout.o \
           $(OBJ_DIR)/class_OdimEntry.o \
           $(OBJ_DIR)/class_OdimStandard.o \
           $(OBJ_DIR)/module_Compare.o  \
           $(OBJ_DIR)/module_Correct.o

all : check_compiler $(LIB_LIST) $(BIN_LIST)
	@echo ""
	@echo "################################################################################"
	@echo "# Congratulation! The odimh5_validator build was SUCCESSFULL.  "
	@echo "# !!! IMPORTANT !!! : Consider setting env variable: "
	@echo "#    ODIMH5_VALIDATOR_CSV_DIR=$(PWD)/data - see also in the Readme.md file"
	@echo "################################################################################"
	@echo ""

check_compiler :
	@if [ $(GCC_VERSION_OK) -eq 0 ] ; then echo "!!!ERROR - GCC version must be >= 4.9 !!!" ; false ; fi

clean:
	rm -rf $(BIN_DIR)/* \
	       $(LIB_DIR)/* \
	       $(OBJ_DIR)/*

$(LIB_DIR)/libmyodimh5.a: $(OBJ_LIST)
	@echo ""
	@echo "Creating lib ..."
	$(AR) $(ARFLAGS) $@ $(OBJ_LIST)
	@echo "Creating lib ... OK"
	@echo ""


$(BIN_DIR)/odimh5-validate: $(SRC_DIR)/odimh5-validate.cpp $(LIB_LIST)
	@echo ""
	@echo "Compiling odimh5-validate ..."
	$(CXX) $(CXX_FLAGS) $(INC_FLAGS) -o $@ $(SRC_DIR)/odimh5-validate.cpp $(LIB_FLAGS)
	@echo "Compiling odimh5-validate ... OK"
	@echo ""

$(BIN_DIR)/odimh5-check-value: $(SRC_DIR)/odimh5-check-value.cpp $(LIB_LIST)
	@echo ""
	@echo "Compiling odimh5-check-value ..."
	$(CXX) $(CXX_FLAGS) $(INC_FLAGS) -o $@ $(SRC_DIR)/odimh5-check-value.cpp $(LIB_FLAGS)
	@echo "Compiling odimh5-check-value ... OK"
	@echo ""

$(BIN_DIR)/odimh5-correct: $(SRC_DIR)/odimh5-correct.cpp $(LIB_LIST)
	@echo ""
	@echo "Compiling odimh5-correct ..."
	$(CXX) $(CXX_FLAGS) $(INC_FLAGS) -o $@ $(SRC_DIR)/odimh5-correct.cpp $(LIB_FLAGS)
	@echo "Compiling odimh5-correct ... OK"
	@echo ""

$(OBJ_DIR)/class_H5Layout.o: $(SRC_DIR)/class_H5Layout.cpp $(SRC_DIR)/class_H5Layout.hpp
	$(CXX) $(CXX_FLAGS) $(INC_FLAGS) -c -o $@ $(SRC_DIR)/class_H5Layout.cpp

$(OBJ_DIR)/class_OdimEntry.o:  $(SRC_DIR)/class_OdimEntry.cpp $(SRC_DIR)/class_OdimEntry.hpp
	$(CXX) $(CXX_FLAGS) $(INC_FLAGS) -c -o $@ $(SRC_DIR)/class_OdimEntry.cpp

$(OBJ_DIR)/class_OdimStandard.o: $(SRC_DIR)/class_OdimStandard.cpp $(SRC_DIR)/class_OdimStandard.hpp \
                                 $(OBJ_DIR)/class_OdimEntry.o
	$(CXX) $(CXX_FLAGS) -Wno-stringop-truncation $(INC_FLAGS) -c -o $@ $(SRC_DIR)/class_OdimStandard.cpp
#                     ^ turning off Warning from csv.h - max file name lenght is set to 255 in csv.h

$(OBJ_DIR)/module_Compare.o: $(SRC_DIR)/module_Compare.cpp $(SRC_DIR)/module_Compare.hpp \
                             $(OBJ_DIR)/class_H5Layout.o \
                             $(OBJ_DIR)/class_OdimStandard.o
	$(CXX) $(CXX_FLAGS) $(INC_FLAGS) -c -o $@ $(SRC_DIR)/module_Compare.cpp

$(OBJ_DIR)/module_Correct.o: $(SRC_DIR)/module_Correct.cpp $(SRC_DIR)/module_Correct.hpp \
                            $(OBJ_DIR)/class_OdimStandard.o
	$(CXX) $(CXX_FLAGS) $(INC_FLAGS) -c -o $@ $(SRC_DIR)/module_Correct.cpp

