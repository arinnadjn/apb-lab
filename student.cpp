#include <iostream>
#include <iomanip>

int main() {
    unsigned int number = 10;  //номер в группе и его в 16 ричном и 10 виде

    std::cout << "Student number: " << std::dec << number
              << " = 0x" << std::hex << std::setw(8) << std::setfill('0') << number
              << std::endl;
    return 0;
}
