#include "memory.h"
#include "memsystem.h"
#include "riscv.h"
#include <iostream>
#include <unistd.h>
void print_usage(const char *name) {
  std::cerr << "uage: " << name << " [-m] [-i]" << std::endl;
  std::cerr << "-m: mif file of instructions" << std::endl;
  std::cerr << "-i: raw image file of instructions" << std::endl;
}

int main(int argc, char *argv[]) {
  int opt;
  std::string mif_file, image_file;
  while ((opt = getopt(argc, argv, "m:i::")) != -1) {
    switch (opt) {
    case 'm':
      mif_file = optarg;
      break;
    case 'i':
      image_file = optarg;
      break;
    case '?':
      print_usage(argv[0]);
      return 1;
    default:
      print_usage(argv[0]);
      return 1;
    }
  }
  TinyRiscv cpu;

  // create memory system and connect to cpu
  MemSystem memsys;
  cpu.imem_port.connect(&memsys.port0);
  cpu.dmem_port.connect(&memsys.port1);

  if (!mif_file.empty())
    memsys.load_mif(mif_file);
  if (!image_file.empty())
    memsys.load_image(image_file);
  if (mif_file.empty() && image_file.empty())
    std::cerr << "no exection file found, mif or image is required"
              << std::endl;
  // start simulation
  unsigned long cycles = 0;
  while (cycles < 20) {
    std::cout << "simulating cycle:" << cycles << std::endl;

    cpu.tick();
    cycles++;
  }
}
