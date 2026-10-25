// Программа считает значения, которые мастер будет записывать в регистры slave:
// номер в группе, дата, первые 4 буквы фамилии и имени в ASCII.
#include <iostream>
#include <iomanip>
#include <string>

unsigned int pack4(const std::string& s) {
    unsigned int value = 0;
    for (int i = 0; i < 4; i++) {
        value = (value << 8) | static_cast<unsigned char>(s[i]);
    }
    return value;
}

// Печать значения: адрес регистра, название, hex
void print_reg(unsigned int offset, const std::string& name, unsigned int value) {
    std::cout << "0x" << std::hex << std::setw(2) << std::setfill('0') << offset
              << "  " << std::setfill(' ') << std::left << std::setw(10) << name << std::right
              << " = 0x" << std::setw(8) << std::setfill('0') << value << std::endl;
}

int main() {
    unsigned int number  = 10;          // номер в группе
    unsigned int date    = 0x25102026;  // 25.10.2026
    unsigned int surname = pack4("Tish");
    unsigned int name    = pack4("Arin");

    print_reg(0x00, "number",  number);
    print_reg(0x04, "date",    date);
    print_reg(0x08, "surname", surname);
    print_reg(0x0C, "name",    name);
    return 0;
}
