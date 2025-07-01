# 编译器设置
CXX := g++
CXXFLAGS := -std=c++11 -Wall -Wextra
TARGET := tiny-riscv-sim

# 获取当前目录下所有.cpp和.cc文件
SRCS := $(wildcard *.cpp) $(wildcard *.cc)
OBJS := $(patsubst %.cpp,%.o,$(SRCS))
OBJS := $(patsubst %.cc,%.o,$(OBJS))

# 默认目标
all: $(TARGET)

$(TARGET): $(OBJS)
	$(CXX) $(CXXFLAGS) -g -o $@ $^

%.o: %.cpp %.h
	$(CXX) $(CXXFLAGS) -c -g $< -o $@

%.o: %.cc %.h
	$(CXX) $(CXXFLAGS) -c -g $< -o $@

clean:
	rm -f $(TARGET) $(OBJS)

.PHONY: all clean
