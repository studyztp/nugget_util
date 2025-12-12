#include <llvm/TargetParser/Host.h>
#include <llvm/ADT/StringMap.h>
#include <iostream>
#include <fstream>
#include <sstream>

int main() {
    llvm::StringMap<bool> Features;
    std::ofstream outfile("llc-command.txt");

    std::string CPU = llvm::sys::getHostCPUName().str();
    std::string Triple = llvm::sys::getProcessTriple();

    // Extract the architecture part from the target triple
    std::istringstream TripleStream(Triple);

    if (llvm::sys::getHostCPUFeatures(Features)) {
        std::string Mattributes;
        for (const auto &Feature : Features) {
            Mattributes += (Feature.second ? "+" : "-") + Feature.first().str() + ",";
        }
        // Remove the trailing comma
        if (!Mattributes.empty()) {
            Mattributes.pop_back();
        }

        outfile << "-enable-machine-outliner=never " << "-mcpu=" << CPU << " -mtriple=" << Triple << " -mattr=\"" << Mattributes << "\"" << std::endl;
    } else {
        outfile << "Failed to get host CPU features." << std::endl;
    }

    outfile.close();
    return 0;
}
