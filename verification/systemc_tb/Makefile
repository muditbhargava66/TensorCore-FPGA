CXX = g++
CXXFLAGS = -I. -I/opt/homebrew/include -L/opt/homebrew/lib -lsystemc -lm -std=c++17

SC_SA_DIR = ../../model/systemc/sa_model
SC_VPU_DIR = ../../model/systemc/vpu_model

SRCS = $(SC_SA_DIR)/testbench.cpp
OBJS = $(SRCS:.cpp=.o)

TARGET = run_sa_test

all: $(TARGET)

$(TARGET): $(SRCS)
	$(CXX) $(CXXFLAGS) -o $(TARGET) $(SRCS)

run: $(TARGET)
	./$(TARGET)
	@echo "Comparing results..."
	@# Add python verify script here if needed

clean:
	rm -f $(TARGET) *.o *.vcd
