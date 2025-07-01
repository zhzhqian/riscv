# 编译器设置
CXX := g++
CXXFLAGS := -std=c++11 -Wall -Wextra
TARGET := myprogram

# 获取当前目录下所有.cpp和.cc文件
SRCS := $(wildcard *.cpp) $(wildcard *.cc)
OBJS := $(patsubst %.cpp,%.o,$(SRCS))
OBJS := $(patsubst %.cc,%.o,$(OBJS))

# 默认目标
all: $(TARGET)

$(TARGET): $(OBJS)
	$(CXX) $(CXXFLAGS) -o $@ $^

%.o: %.cpp
	$(CXX) $(CXXFLAGS) -c $< -o $@

%.o: %.cc
	$(CXX) $(CXXFLAGS) -c $< -o $@

clean:
	rm -f $(TARGET) $(OBJS)

.PHONY: all clean
